<#
.Description
Get a list of files not yet transcoded.

.Example
Get-NotProcessed -Plexmoviefolders "\R-User-Media\Kids Movies", "\R-User-Media\Movies", "\R-Others-Media\Movies" -plexshowfolders "P:\R-User-Media2\Shows", "\R-User-Media\Kids Shows", "\R-User-Media\Shows", "\R-Others-Media\Shows" -DataSource /docker-transcodeautomation/data/MediaDB.SQLite
#>

Function Get-NotProcessed {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$plexmoviefolders,
        [Parameter(Mandatory = $true)][string[]]$plexshowfolders,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Movies
    foreach ($plexmoviefolder in $plexmoviefolders) {
        Set-Location $plexmoviefolder
        $TableName = 'Movies'
        # Identify media files that might not be transcoded through a comparison with the database. Should occasionally run update-processed to correct invalid data cause by re-downloaded media files and upgrades.
        $files = (Get-ChildItem $plexmoviefolder -r -File -Exclude "*.txt", "*.srt", "*.md", "*.jpg", "*.jpeg", "*.bat", "*.png", "*.idx", "*.sub", "*.SQLite").fullname
        $query = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $TableName WHERE comment = 'transcoded' and directory like `"%$plexmoviefolder%`""
        $transcoded = ($query).fullname
        if ($null -eq $transcoded) {
            $filesforprocessing = $files
        }
        else {
            $filesforprocessing = (Compare-Object $files $transcoded).inputobject
        }

        foreach ($filefor in $filesforprocessing) {
            try {
                $file = Get-ChildItem $filefor -ErrorAction Stop | Select-Object Name, LastWriteTime, FullName, Directory
                $createdtime = $file.LastWriteTime
                $now = Get-Date
                $timesincedownload = $now - $createdtime
                [pscustomobject]@{
                    Name            = $file.name
                    AgeHoursMinutes = [string]$timesincedownload.hours + ":" + [string]$timesincedownload.minutes
                    Path            = $file.directory
                }
            }
            catch {

            }
        }
    }

    #Shows
    foreach ($plexshowfolder in $plexshowfolders) {
        Set-Location $plexshowfolder
        $TableName = 'Shows'
        # Identify media files that might not be transcoded through a comparison with the database. Should occasionally run update-processed to correct invalid data cause by re-downloaded media files and upgrades.
        $files = (Get-ChildItem $plexshowfolder -r -File -Exclude "*.txt", "*.srt", "*.md", "*.jpg", "*.jpeg", "*.bat", "*.png", "*.idx", "*.sub", "*.SQLite").fullname
        $query = Invoke-SqliteQuery -DataSource $DataSource -Query "Select fullname FROM $TableName WHERE comment = 'transcoded' and directory like `"%$plexshowfolder%`" and fileexists = 'true'"
        $transcoded = ($query).fullname
        if ($null -eq $transcoded) {
            $filesforprocessing = $files
        }
        else {
            $filesforprocessing = (Compare-Object $files $transcoded).inputobject
        }

        foreach ($filefor in $filesforprocessing) {
            try {
                $file = Get-ChildItem $filefor -ErrorAction Stop | Select-Object Name, LastWriteTime, FullName, Directory
                $createdtime = $file.LastWriteTime
                $now = Get-Date
                $timesincedownload = $now - $createdtime
                [pscustomobject]@{
                    Name            = $file.name
                    AgeHoursMinutes = [string]$timesincedownload.hours + ":" + [string]$timesincedownload.minutes
                    Path            = $file.directory
                }
            }
            catch {

            }
        }
    }
}