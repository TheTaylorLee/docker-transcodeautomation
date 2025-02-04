Function Invoke-MEDIAMoviesToProcess {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$MEDIAshowfolders,
        [Parameter(Mandatory = $true)][string[]]$MEDIAmoviefolders,
        [Parameter(Mandatory = $true)][decimal]$MinSizeMB,
        [Parameter(Mandatory = $true)][int]$hours,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "info: Invoke-MEDIAMoviesToProcess Start"

    if ((Invoke-SqliteQuery -DataSource $datasource -Query "PRAGMA integrity_check").integrity_check -eq 'ok') {
        # Set static Table parameters
        $TableName = "Movies"

        # Iterate Movie libraries
        foreach ($MEDIAmoviefolder in $MEDIAmoviefolders) {
            Set-Location $MEDIAmoviefolder

            # Identify media files that might not be transcoded through a comparison with the database. Should occasionally run update-processed to correct invalid data cause by re-downloaded media files and upgrades.
            $files = Get-ChildItem -ErrorAction Inquire -LiteralPath $MEDIAmoviefolder -r -File -Include "*.mkv", "*.mp4" |
                Select-Object fullname, @{ Name = "filesizemb"; Expression = { [math]::round(($_.length / 1mb), 3) } } |
                Where-Object { $_.filesizemb -ge $MINSIZEMB }
            $files = $files.fullname
            $query = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $TableName WHERE comment like 'dta-%' and directory like `"%$MEDIAmoviefolder%`" and filesizeMB >= `"$MinSizeMB`"" -ErrorAction Inquire
            $transcoded = ($query).fullname
            if ($null -eq $transcoded) {
                $filesforprocessing = $files
            }
            else {
                $filesforprocessing = (Compare-Object $files $transcoded | Sort-Object sideindicator).inputobject
            }

            # Iterate possibly untranscoded Files
            foreach ($file in $filesforprocessing) {
                ##Make sure no previous failures occurred prior to stepping forward
                $testnofiles = Get-ChildItem -LiteralPath $env:FFToolsSource -File
                $testnofiles2 = Get-ChildItem -LiteralPath $env:FFToolsTarget -File

                if ($null -eq $testnofiles -and $null -eq $testnofiles2) {
                    # Test if file exists by path or matching immutable index in table.
                    $test = Test-Path -LiteralPath $file

                    $Probe = ffprobe -loglevel 0 -print_format json -show_format $file
                    $convert = $Probe | ConvertFrom-Json -ErrorAction SilentlyContinue
                    $comment = $convert.format.tags.comment
                    if ($null -eq $comment) {
                        $query = $null
                    }
                    else {
                        $query = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $TableName WHERE (comment = `"$comment`" and comment IS NOT NULL)" -ErrorAction Inquire
                    }

                    # If File Exists on disk or matches immutable index in table
                    if ($test -eq 'True' -or $null -ne $query) {
                        # Check that 3 times the file size exists in free space on transcoding drive
                        $transcodingfreespace = (Get-PSDrive transcoding | Select-Object @{ Name = "FreeGB"; Expression = { [math]::round(($_.free / 1gb), 2) } }).FreeGB
                        $filesizemultiplied = ((Get-ChildItem -LiteralPath $file | Select-Object @{ Name = "filesizeGB"; Expression = { [math]::round(($_.length / 1gb), 3) } }).filesizeGB) * 3

                        if ($transcodingfreespace -gt $filesizemultiplied) {
                            $file = Get-ChildItem -LiteralPath $file | Select-Object name, basename, extension, fullname, directory, LastWriteTime, @{ Name = "filesizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
                            $basename = $file.basename
                            $extension = $file.extension
                            $fullname = $file.fullname
                            $filename = $file.name
                            $directory = $file.directory
                            $lastupdatetime = $file.LastWriteTime
                            $filesizeMB = $file.filesizeMB
                            $nowtime = Get-Date

                            # If file age greater than or equal to hours old process file
                            if (($nowtime - $lastupdatetime).totalhours -ge $hours) {

                                # If database entry doesn't exist for file create table entry.
                                $query = "SELECT * FROM $TableName WHERE fullname = `"$fullname`""
                                $result01 = Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query
                                $query = "SELECT * FROM $TableName WHERE (comment = `"$comment`" and comment != 'transcoded')"
                                $result02 = Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query
                                if ($null -eq $result01 -and $null -eq $result02) {
                                    # If comment tag of media file is dta-*, update database only.
                                    if ($comment -like "dta-*") {
                                        if ($comment -eq "dta-remuxed") {
                                            # Remux an immutable index into the file.
                                            $newcomment = (Update-Lastindex -DataSource $datasource).newcomment
                                            [string]$oldname = $fullname + ".old"
                                            Rename-Item $fullname $oldname -Verbose
                                            ffmpeg -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$newcomment -c copy $fullname
                                            Remove-Item -LiteralPath $oldname -Force -Confirm:$false -Verbose
                                        }
                                        else {
                                            $newcomment = $comment
                                        }

                                        $query = "INSERT INTO $TableName (filename, fullname, directory, comment, Added, modified, filesizeMB, fileexists, updatedby) Values (@filename, @fullname, @directory, @comment, @Added, @modified, @filesizeMB, @fileexists, @updatedby)"
                                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query -SqlParameters @{
                                            filename   = $filename
                                            fullname   = $fullname
                                            directory  = $directory
                                            comment    = $newcomment
                                            Added      = Get-Date
                                            modified   = Get-Date
                                            filesizeMB = $filesizeMB
                                            fileexists = "true"
                                            updatedby  = "Invoke-MEDIAMoviesToProcess"
                                        }
                                    }
                                    # else comment tag of media file is not dta-*, copy file for processing and update database
                                    else {
                                        $newcomment = (Update-Lastindex -DataSource $datasource).newcomment
                                        $destination = $env:FFToolsSource + "$basename$newcomment$extension"
                                        Copy-Item -LiteralPath $fullname $destination -Verbose
                                        $query = "INSERT INTO $TableName (filename, fullname, directory, comment, Added, modified, filesizeMB, fileexists, updatedby) Values (@filename, @fullname, @directory, @comment, @Added, @modified, @filesizeMB, @fileexists, @updatedby)"

                                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query -SqlParameters @{
                                            filename   = $filename
                                            fullname   = $fullname
                                            directory  = $directory
                                            comment    = $newcomment
                                            Added      = Get-Date
                                            modified   = Get-Date
                                            filesizeMB = $filesizeMB
                                            fileexists = "true"
                                            updatedby  = "Invoke-MEDIAMoviesToProcess"
                                        }
                                        invoke-processmovie -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $DataSource
                                    }
                                }
                                # else database entry exists, update existing entry. This prevents duplicate table entries and supports files moved to new directories or renamed.
                                else {
                                    # If ffprobe indicates comment tag of media file is transcoded and file directory has changed, update database only
                                    if ($comment -like "dta-*") {
                                        $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                                        $query = "Update $TableName SET comment = `"$comment`", fileexists = 'true', modified = `"$modified`", updatedby = 'Invoke-MEDIAMoviesToProcess', filename = `"$filename`", fullname = `"$fullname`", directory = `"$directory`", filesizeMB = `"$filesizeMB`" WHERE comment = `"$comment`""
                                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query
                                    }
                                    # else ffprobe indicates comment tag of media file is not transcoded, copy and update database. Useful for when file has been replace by another download.
                                    else {
                                        $newcomment = (Update-Lastindex -DataSource $datasource).newcomment
                                        $destination = $env:FFToolsSource + "$basename$newcomment$extension"
                                        Copy-Item -LiteralPath $fullname $destination -Verbose
                                        $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                                        $query = "Update $TableName SET comment = `"$newcomment`", fileexists = 'true', modified = `"$modified`", updatedby = 'Invoke-MEDIAMoviesToProcess', fullname= `"$fullname`", directory = `"$directory`", filesizeMB = `"$filesizeMB`" WHERE fullname = `"$fullname`""
                                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query
                                        invoke-processmovie -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $DataSource
                                    }
                                }
                            }
                        }
                        else {
                            Write-Output " error:The Transcoding volume is too low on free space. $file is being skipped for processing"
                        }
                    }
                    # else File Doesn't Exist update existing table entry
                    else {
                        $fullname = $file
                        $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $query = "Update $TableName SET filesizeMB = NULL, fileexists = 'false', modified = `"$modified`", updatedby = 'Invoke-MEDIAMoviesToProcess' WHERE fullname = `"$fullname`" and fileexists is NOT false and filesizeMB is NOT NULL"
                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query
                    }
                }
                else {
                    Write-Output "error: Files in fftools folders preventing this function from running. Clear up this issue first"
                }
            }
        }
    }
    else {
        Write-Output "error: Database Integrity Check failed. Aborting process"
    }

    #Used in debug logs
    Write-Output "info: Invoke-MEDIAMoviesToProcess End"
}