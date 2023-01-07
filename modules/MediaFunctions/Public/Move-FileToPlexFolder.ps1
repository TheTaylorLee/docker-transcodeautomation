<#
.Description
Moves transcoded files into plex folders

.Example
Move-FileToPlexFolder -plexshowfolders "\R-cowboy-Media\Kids Shows", "\R-cowboy-Media\Shows", "\R-Others-Media\Shows", "P:\R-cowboy-Media2\Shows" -plexmoviefolders "\R-cowboy-Media\Kids Movies", "\R-cowboy-Media\Movies", "\R-Others-Media\Movies" -Datasource ($env:FFToolsTarget + "processed\MediaDB.SQLite")
#>

function Move-FileToPlexFolder {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$plexshowfolders,
        [Parameter(Mandatory = $true)][string[]]$plexmoviefolders,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Generate list of existing files for moving new files in their place
    ##Delete old comparison file and make a new one
    [psobject]$plexmoviefiles = foreach ($plexmoviefolder in $plexmoviefolders) {
        Get-ChildItem $plexmoviefolder -r -File -Exclude "*.txt", "*.srt", "*.md", "*.jpg", "*.jpeg", "*.bat", "*.png", "*.idx", "*.sub", "*.SQLite" |
        Select-Object name, fullname, directory, @{ Name = "OldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
    }
    [psobject]$plexshowfiles = foreach ($plexshowfolder in $plexshowfolders) {
        Get-ChildItem $plexshowfolder -r -File -Exclude "*.txt", "*.srt", "*.md", "*.jpg", "*.jpeg", "*.bat", "*.png", "*.idx", "*.sub", "*.SQLite" |
        Select-Object name, fullname, directory, @{ Name = "OldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
    }

    #Get a list of files in process folder
    $processeddir = "$env:FFToolsTarget" + "processed"
    [psobject]$filestomove = Get-ChildItem $processeddir -r -File -Exclude "*.txt", "*.srt", "*.md", "*.jpg", "*.jpeg", "*.bat", "*.png", "*.idx", "*.sub", "*.csv", "*.xlsx", "*.SQLite" | Select-Object name, fullname, directory, @{ Name = "NewsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }

    #Move processed movie files
    try {
        foreach ($file in $filestomove) {
            #move the file
            $destination = $plexmoviefiles | Where-Object { $_.name -eq $file.name }
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue

                # log stats and changes to database
                $TableName = 'Movies'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $destination.OldsizeMB
                $fullname = $destination.fullname
                $query = "Update $TableName SET comment = 'transcoded', modified = `"$modified`", updatedby = 'Move-FileToPlexFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
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
            $destination = $plexshowfiles | Where-Object { $_.name -eq $file.name }
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue

                # log stats and changes to database
                $TableName = 'Shows'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $destination.OldsizeMB
                $fullname = $destination.fullname
                $query = "Update $TableName SET comment = 'transcoded', modified = `"$modified`", updatedby = 'Move-FileToPlexFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
                Invoke-SqliteQuery -DataSource $DataSource -Query $query
            }
        }
    }
    catch {
        $_
    }
}
