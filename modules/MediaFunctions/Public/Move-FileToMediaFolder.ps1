<#
.Description
Moves transcoded files into media folders

.Example
Move-FileTomediaFolder -mediashowfolders "\R-User-Media\Kids Shows", "\R-User-Media\Shows", "\R-Others-Media\Shows", "P:\R-User-Media2\Shows" -mediamoviefolders "\R-User-Media\Kids Movies", "\R-User-Media\Movies", "\R-Others-Media\Movies" -Datasource /docker-transcodeautomation/data/MediaDB.SQLite
#>

function Move-FileToMediaFolder {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$mediashowfolders,
        [Parameter(Mandatory = $true)][string[]]$mediamoviefolders,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Generate list of existing files for moving new files in their place
    ##Delete old comparison file and make a new one
    [psobject]$mediamoviefiles = foreach ($mediamoviefolder in $mediamoviefolders) {
        Get-ChildItem $mediamoviefolder -r -File -Exclude "*.txt", "*.srt", "*.md", "*.jpg", "*.jpeg", "*.bat", "*.png", "*.idx", "*.sub", "*.SQLite" |
        Select-Object name, fullname, directory, @{ Name = "OldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
    }
    [psobject]$mediashowfiles = foreach ($mediashowfolder in $mediashowfolders) {
        Get-ChildItem $mediashowfolder -r -File -Exclude "*.txt", "*.srt", "*.md", "*.jpg", "*.jpeg", "*.bat", "*.png", "*.idx", "*.sub", "*.SQLite" |
        Select-Object name, fullname, directory, @{ Name = "OldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
    }

    #Get a list of files in process folder
    $processeddir = "$env:FFToolsTarget" + "processed"
    [psobject]$filestomove = Get-ChildItem $processeddir -r -File -Exclude "*.txt", "*.srt", "*.md", "*.jpg", "*.jpeg", "*.bat", "*.png", "*.idx", "*.sub", "*.csv", "*.xlsx", "*.SQLite" | Select-Object name, fullname, directory, @{ Name = "NewsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }

    #Move processed movie files
    try {
        foreach ($file in $filestomove) {
            #move the file
            $destination = $mediamoviefiles | Where-Object { $_.name -eq $file.name }
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue

                # log stats and changes to database
                $TableName = 'Movies'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $destination.OldsizeMB
                $fullname = $destination.fullname
                $query = "Update $TableName SET comment = 'transcoded', modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
                Invoke-SqliteQuery -DataSource $DataSource -Query $query
            }
        }
    }
    catch {
        $_
    }

    #Move processed show files
    try {
        foreach ($file in $filestomove) {
            #move the file
            $destination = $mediashowfiles | Where-Object { $_.name -eq $file.name }
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue

                # log stats and changes to database
                $TableName = 'Shows'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $destination.OldsizeMB
                $fullname = $destination.fullname
                $query = "Update $TableName SET comment = 'transcoded', modified = `"$modified`", updatedby = 'Move-FileTomediaFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
                Invoke-SqliteQuery -DataSource $DataSource -Query $query
            }
        }
    }
    catch {
        $_
    }
}
