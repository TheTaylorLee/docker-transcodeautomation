function Move-FileToMEDIAFolder {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$MEDIAshowfolders,
        [Parameter(Mandatory = $true)][string[]]$MEDIAmoviefolders,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "info: Move-FileToMEDIAFolder Start"
    if ((Invoke-SqliteQuery -DataSource $datasource -Query "PRAGMA integrity_check").integrity_check -eq 'ok') {
        #Pull list of existing media
        $query = "Select * from Shows"
        $showsdb = Invoke-SqliteQuery -DataSource $DataSource -Query $query
        $query = "Select * from Movies"
        $moviesdb = Invoke-SqliteQuery -DataSource $DataSource -Query $query

        #Get a list of files in processed folder
        $processeddir = "$env:FFToolsTarget" + "processed"
        [psobject]$filestomove = Get-ChildItem -LiteralPath $processeddir -r -File -Include "*.mkv", "*.mp4" | Select-Object name, fullname, directory, @{ Name = "NewsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }


        foreach ($file in $filestomove) {

            # Get comment from file
            $probefile = $file.fullname
            $Probe = ffprobe -loglevel 0 -print_format json -show_format $probefile
            $convert = $Probe | ConvertFrom-Json
            $comment = $convert.format.tags.comment

            #Move processed movie files
            $destination = $moviesdb | Where-Object { $_.comment -eq $comment }
            if ($null -ne $destination) {
                $oldsizemb = (Get-ChildItem -LiteralPath $destination.fullname | Select-Object @{ Name = "oldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }).oldsizeMB
                if (Test-Path -LiteralPath $destination.fullname -ErrorAction SilentlyContinue) {
                    # log stats and changes to database
                    $TableName = 'Movies'
                    $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $newsizeMB = $file.newsizeMB
                    $oldsizeMB = $oldsizemb
                    $fullname = $destination.fullname
                    $query = "Update $TableName SET comment = `"$comment`", modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
                    Invoke-SqliteQuery -DataSource $DataSource -Query $query

                    Move-Item -LiteralPath $file.fullname -Destination $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue -Verbose
                }
                # If for any reason an interuption occurs, the original file might be deleted. This will prevent oldsizeMB from being nulled out.
                else {
                    $fname = $file.fullname
                    $destination = $moviesdb | Where-Object { $_.comment -eq $comment }

                    if ($null -ne $destination) {
                        Write-Output "error: Previous File move failed for $fname. Attempting the file move now for movie files. If a verbose file move message is seen then the error is successfully handled. Otherwise manual intervention will be required to move the file. This is only likely to occur if the destination directory cannot be written to, doesn't exist, or something corrupted the database."

                        # Handle database updates
                        $TableName = 'Movies'
                        $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $filesizeMB = $file.newsizeMB
                        $fullname = $destination.fullname
                        $query = "Update $TableName SET comment = `"$comment`", fileexists = 'true', modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$filesizeMB`" WHERE fullname = `"$fullname`""
                        Invoke-SqliteQuery -DataSource $DataSource -Query $query

                        # Move File
                        Move-Item -LiteralPath $file.fullname -Destination $destination.fullname -Force -Confirm:$false -Verbose
                    }
                }
            }

            #Move processed show files
            $destination = $showsdb | Where-Object { $_.comment -eq $comment }
            if ($null -ne $destination) {
                $oldsizemb = (Get-ChildItem -LiteralPath $destination.fullname | Select-Object @{ Name = "oldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }).oldsizeMB
                if (Test-Path -LiteralPath $destination.fullname -ErrorAction SilentlyContinue) {
                    # log stats and changes to database
                    $TableName = 'Shows'
                    $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $newsizeMB = $file.newsizeMB
                    $oldsizeMB = $oldsizemb
                    $fullname = $destination.fullname
                    $query = "Update $TableName SET comment = `"$comment`", modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
                    Invoke-SqliteQuery -DataSource $DataSource -Query $query

                    Move-Item -LiteralPath $file.fullname -Destination $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue -Verbose
                }
                # If for any reason an interuption occurs, the original file might be deleted. This will prevent oldsizeMB from being nulled out.
                else {
                    $fname = $file.fullname
                    $destination = $showsdb | Where-Object { $_.comment -eq $comment }

                    if ($null -ne $destination) {
                        Write-Output "error: Previous File move failed for $fname. Attempting the file move now for show files. If a verbose file move message is seen then the error is successfully handled. Otherwise manual intervention will be required to move the file. This is only likely to occur if the destination directory cannot be written to, doesn't exist, or something corrupted the database."

                        # Handle database updates
                        $TableName = 'Shows'
                        $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $filesizeMB = $file.newsizeMB
                        $fullname = $destination.fullname
                        $query = "Update $TableName SET comment = `"$comment`", fileexists = 'true', modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$filesizeMB`" WHERE fullname = `"$fullname`""
                        Invoke-SqliteQuery -DataSource $DataSource -Query $query

                        # Move file
                        Move-Item -LiteralPath $file.fullname -Destination $destination.fullname -Force -Confirm:$false -Verbose
                    }
                }
            }

            #Output updated table entry into the log
            $query = "select * from movies where comment = `"$comment`""
            Invoke-SqliteQuery -DataSource $DataSource -Query $query
            $query = "select * from shows where comment = `"$comment`""
            Invoke-SqliteQuery -DataSource $DataSource -Query $query
        }
    }
    else {
        Write-Output "error: Database Integrity Check failed. Aborting process"
    }

    #Used in debug logs
    Write-Output "info: Move-FileToMEDIAFolder End"
}