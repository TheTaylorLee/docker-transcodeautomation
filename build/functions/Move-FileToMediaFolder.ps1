function Move-FileToMEDIAFolder {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$MEDIAshowfolders,
        [Parameter(Mandatory = $true)][string[]]$MEDIAmoviefolders,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "[+] Move-FileToMEDIAFolder Start"

    #Pull list of existing media
    $query = "Select * from Shows"
    $showsdb = Invoke-SqliteQuery -DataSource $DataSource -Query $query
    $query = "Select * from Movies"
    $moviesdb = Invoke-SqliteQuery -DataSource $DataSource -Query $query

    #Get a list of files in processed folder
    $processeddir = "$env:FFToolsTarget" + "processed"
    [psobject]$filestomove = Get-ChildItem $processeddir -r -File -Include "*.mkv", "*.mp4" | Select-Object name, fullname, directory, @{ Name = "NewsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }

    #Move processed movie files
    foreach ($file in $filestomove) {
        try {
            #move the file
            $destination = $moviesdb | Where-Object { $_.filename -eq $file.name }
            $oldsizemb = (Get-ChildItem $destination.fullname -ErrorAction SilentlyContinue | Select-Object @{ Name = "oldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }).oldsizeMB
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                # log stats and changes to database
                $TableName = 'Movies'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $oldsizemb
                $fullname = $destination.fullname
                $query = "Update $TableName SET comment = 'transcoded', modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
                Invoke-SqliteQuery -DataSource $DataSource -Query $query

                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue
            }
            # Fix for Issue 29. This will move the file and update the database.
            # If for any reason an interuption occurs, the original file might be deleted. This results consecutive runs of this foreach loop failing to move the file.
            # The else block adds handling for this specific scenario.
            else {
                Write-Output "[-] Previous File move failed for $fname. Attempting the file move now for movie files. If a verbose file move message is seen then the error is successfully handled. Otherwise manual intervention will be required to move the file. This is only likely to occur if the destination directory cannot be written to, doesn't exist, or something corrupted the database."
                $fname = $file.fullname
                $destination = $moviesdb | Where-Object { $_.filename -eq $file.name }
                if ($null -ne $destination) {
                    # Handle database updates
                    $TableName = 'Movies'
                    $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $filesizeMB = $file.newsizeMB
                    $fullname = $destination.fullname
                    $query = "Update $TableName SET comment = 'transcoded', fileexists = 'true', modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$filesizeMB`" WHERE fullname = `"$fullname`""
                    Invoke-SqliteQuery -DataSource $DataSource -Query $query

                    # Move File
                    Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -Verbose
                }
            }
        }
        catch {
            $_
        }
    }


    #Move processed show files
    foreach ($file in $filestomove) {
        try {
            #move the file
            $destination = $showsdb | Where-Object { $_.filename -eq $file.name }
            $oldsizemb = (Get-ChildItem $destination.fullname -ErrorAction SilentlyContinue | Select-Object @{ Name = "oldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }).oldsizeMB
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                # log stats and changes to database
                $TableName = 'Shows'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $oldsizemb
                $fullname = $destination.fullname
                $query = "Update $TableName SET comment = 'transcoded', modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
                Invoke-SqliteQuery -DataSource $DataSource -Query $query

                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue
            }
            # Fix for Issue 29. This will move the file and update the database.
            # If for any reason an interuption occurs, the original file might be deleted. This results consecutive runs of this foreach loop failing to move the file.
            # The else block adds handling for this specific scenario.
            else {
                Write-Output "[-] Previous File move failed for $fname. Attempting the file move now for show files. If a verbose file move message is seen then the error is successfully handled. Otherwise manual intervention will be required to move the file. This is only likely to occur if the destination directory cannot be written to, doesn't exist, or something corrupted the database."
                $fname = $file.fullname
                $destination = $showsdb | Where-Object { $_.filename -eq $file.name }
                if ($null -ne $destination) {
                    # Handle database updates
                    $TableName = 'Shows'
                    $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $filesizeMB = $file.newsizeMB
                    $fullname = $destination.fullname
                    $query = "Update $TableName SET comment = 'transcoded', fileexists = 'true', modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$filesizeMB`" WHERE fullname = `"$fullname`""
                    Invoke-SqliteQuery -DataSource $DataSource -Query $query

                    # Move file
                    Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -Verbose
                }
            }
        }
        catch {
            $_
        }
    }

    #Used in debug logs
    Write-Output "[+] Move-FileToMEDIAFolder End"
}