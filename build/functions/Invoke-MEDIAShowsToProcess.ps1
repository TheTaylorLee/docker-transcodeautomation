Function Invoke-MEDIAShowsToProcess {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$MEDIAshowfolders,
        [Parameter(Mandatory = $true)][string[]]$MEDIAmoviefolders,
        [Parameter(Mandatory = $true)][int]$hours,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "info: Invoke-MEDIAShowsToProcess Start"

    if ((Invoke-SqliteQuery -DataSource $datasource -Query "PRAGMA integrity_check").integrity_check -eq 'ok') {
        # Set static Table parameters
        $TableName = "Shows"

        # Iterate Show libraries
        foreach ($MEDIAshowfolder in $MEDIAshowfolders) {
            Set-Location $MEDIAshowfolder

            # Identify media files that might not be transcoded through a comparison with the database. Should occasionally run update-processed to correct invalid data cause by re-downloaded media files and upgrades.
            $files = (Get-ChildItem -ErrorAction Inquire $MEDIAshowfolder -r -File -Include "*.mkv", "*.mp4").fullname
            $query = Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query "Select * FROM $TableName WHERE comment = 'transcoded' and directory like `"%$MEDIAshowfolder%`""
            $transcoded = ($query).fullname
            if ($null -eq $transcoded) {
                $filesforprocessing = $files
            }
            else {
                $filesforprocessing = (Compare-Object $files $transcoded).inputobject
            }

            # Iterate possibly untranscoded Files
            foreach ($file in $filesforprocessing) {
                ##Make sure no previous failures occurred prior to stepping forward
                $testnofiles = Get-ChildItem $env:FFToolsSource -File
                $testnofiles2 = Get-ChildItem $env:FFToolsTarget -File

                if ($null -eq $testnofiles -and $null -eq $testnofiles2) {
                    $test = Test-Path -Path $file

                    # If File Exists
                    if ($test -eq 'True') {
                        # Check that 3 times the file size exists in free space on transcoding drive
                        $transcodingfreespace = (Get-PSDrive transcoding | Select-Object @{ Name = "FreeGB"; Expression = { [math]::round(($_.free / 1gb), 2) } }).FreeGB
                        $filesizemultiplied = ((Get-ChildItem $file | Select-Object @{ Name = "filesizeGB"; Expression = { [math]::round(($_.length / 1gb), 3) } }).filesizeGB) * 3

                        if ($transcodingfreespace -gt $filesizemultiplied) {
                            $file = Get-ChildItem $file | Select-Object name, fullname, directory, LastWriteTime, @{ Name = "filesizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
                            $fullname = $file.fullname
                            $filename = $file.name
                            $directory = $file.directory
                            $lastupdatetime = $file.LastWriteTime
                            $filesizeMB = $file.filesizeMB
                            $nowtime = Get-Date

                            # If file age greater than or equal to hours old process file
                            if (($nowtime - $lastupdatetime).totalhours -ge $hours) {
                                $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
                                $convert = $Probe | ConvertFrom-Json
                                $comment = $convert.format.tags.comment

                                # If database entry doesn't exist for file create table entry.
                                $query = "SELECT * FROM $TableName WHERE filename = `"$filename`""
                                $result = Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query
                                if ($null -eq $result) {
                                    # If comment tag of media file is transcoded, update database only
                                    if ($comment -eq 'transcoded') {
                                        $query = "INSERT INTO $TableName (filename, fullname, directory, comment, Added, modified, filesizeMB, fileexists, updatedby) Values (@filename, @fullname, @directory, @comment, @Added, @modified, @filesizeMB, @fileexists, @updatedby)"

                                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query -SqlParameters @{
                                            filename   = $filename
                                            fullname   = $fullname
                                            directory  = $directory
                                            comment    = $comment
                                            Added      = Get-Date
                                            modified   = Get-Date
                                            filesizeMB = $filesizeMB
                                            fileexists = "true"
                                            updatedby  = "Invoke-MEDIAShowsToProcess"
                                        }
                                    }
                                    # else comment tag of media file is not transcoded copy file for processing and update database
                                    else {
                                        Copy-Item $fullname $env:FFToolsSource -Verbose
                                        $query = "INSERT INTO $TableName (filename, fullname, directory, Added, modified, filesizeMB, fileexists, updatedby) Values (@filename, @fullname, @directory, @Added, @modified, @filesizeMB, @fileexists, @updatedby)"

                                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query -SqlParameters @{
                                            filename   = $filename
                                            fullname   = $fullname
                                            directory  = $directory
                                            Added      = Get-Date
                                            modified   = Get-Date
                                            filesizeMB = $filesizeMB
                                            fileexists = "true"
                                            updatedby  = "Invoke-MEDIAShowsToProcess"
                                        }
                                        invoke-processshow -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $DataSource
                                    }
                                }
                                # else database entry exists, update existing entry. This prevents duplicate table entries and supports files moved to new directories
                                else {
                                    # If ffprobe indicates comment tag of media file is transcoded and file directory has changed, update database only
                                    if ($comment -eq 'transcoded') {
                                        $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                                        $query = "Update $TableName SET comment = `"$comment`", fileexists = 'true', modified = `"$modified`", updatedby = 'Invoke-MEDIAShowsToProcess', fullname= `"$fullname`", directory = `"$directory`", filesizeMB = `"$filesizeMB`" WHERE filename = `"$filename`" and directory != `"$directory`""
                                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query
                                    }
                                    # else ffprobe indicates comment tag of media file is not transcoded, copy and update database. Will update if file is moved or not moved to new directory. Useful for when file has been replace by another download.
                                    else {
                                        Copy-Item $fullname $env:FFToolsSource -Verbose
                                        $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                                        $query = "Update $TableName SET fileexists = 'true', modified = `"$modified`", updatedby = 'Copy-MEDIAShowsToProcess', fullname= `"$fullname`", directory = `"$directory`", filesizeMB = `"$filesizeMB`" WHERE filename = `"$filename`""
                                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query
                                        invoke-processshow -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $DataSource
                                    }
                                }
                            }
                        }
                        else {
                            Write-Error " error:The Transcoding volume is too low on free space. $file is being skipped for processing" -ErrorAction Continue
                        }
                    }
                    # else File Doesn't Exist update existing table entry
                    else {
                        $fullname = $file
                        $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $query = "Update $TableName SET comment = NULL, filesizeMB = NULL,  fileexists = 'false', modified = `"$modified`", updatedby = 'Invoke-MEDIAShowsToProcess' WHERE fullname = `"$fullname`""
                        Invoke-SqliteQuery -ErrorAction Inquire -DataSource $DataSource -Query $query
                    }
                }
                else {
                    Write-Error "error: Files in fftools folders preventing this function from running. Clear up this issue first" -ErrorAction Continue
                }
            }
        }
    }
    else {
        Write-Error "error: Database Integrity Check failed. Aborting process" -ErrorAction Continue
    }

    #Used in debug logs
    Write-Output "info: Invoke-MEDIAShowsToProcess End"
}