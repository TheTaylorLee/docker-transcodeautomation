<#
.Description
Moves transcoded files into media folders

.Example
Move-FileTomediaFolder
#>

function Move-FileToMediaFolder {

    [CmdletBinding()]
    Param (
    )

    [string[]]$mediashowfolders = $env:MEDIASHOWFOLDERS -split ', '
    [string[]]$mediamoviefolders = $env:MEDIAMOVIEFOLDERS -split ', '
    [string]$DataSource = "/docker-transcodeautomation/data/MediaDB.SQLite"

    #Pull list of existing media
    $query = Select-Object * from Shows
    $showsdb = Invoke-SqliteQuery -DataSource $DataSource -Query $query
    $query = Select-Object * from Movies
    $moviesdb = Invoke-SqliteQuery -DataSource $DataSource -Query $query

    #Get a list of files in process folder
    $processeddir = "$env:FFToolsTarget" + "processed"
    [psobject]$filestomove = Get-ChildItem $processeddir -r -File -Include "*.mkv", "*.mp4" | Select-Object name, fullname, directory, @{ Name = "NewsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }

    #Move processed movie files
    try {
        foreach ($file in $filestomove) {
            #move the file
            $destination = $moviesdb | Where-Object { $_.filename -eq $file.name }
            $oldsizemb = Get-ChildItem $destination.fullname | Select-Object @{ Name = "NewsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue

                # log stats and changes to database
                $TableName = 'Movies'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $oldsizemb
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
            $destination = $showsdb | Where-Object { $_.filename -eq $file.name }
            $oldsizemb = Get-ChildItem $destination.fullname | Select-Object @{ Name = "NewsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue

                # log stats and changes to database
                $TableName = 'Shows'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $oldsizemb
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