<#
.Description
Get a list of files not yet transcoded.

.Example
Get-NotProcessed
#>

Function Get-NotProcessed {

    [CmdletBinding()]
    Param (
    )

    [string[]]$mediashowfolders = $env:MEDIASHOWFOLDERS -split ', '
    [string[]]$mediamoviefolders = $env:MEDIAMOVIEFOLDERS -split ', '
    [string]$DataSource = "/docker-transcodeautomation/data/MediaDB.SQLite"

    #Movies
    foreach ($mediamoviefolder in $mediamoviefolders) {
        Set-Location $mediamoviefolder
        $TableName = 'Movies'
        # Identify media files that might not be transcoded through a comparison with the database. Should occasionally run update-processed to correct invalid data cause by re-downloaded media files and upgrades.
        $files = (Get-ChildItem -LiteralPath $mediamoviefolder -r -File -Include "*.mkv", "*.mp4").fullname
        $query = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $TableName WHERE comment = 'transcoded' and directory like `"%$mediamoviefolder%`""
        $transcoded = ($query).fullname
        if ($null -eq $transcoded) {
            $filesforprocessing = $files
        }
        else {
            $filesforprocessing = (Compare-Object $files $transcoded).inputobject
        }

        foreach ($filefor in $filesforprocessing) {
            try {
                $file = Get-ChildItem -LiteralPath $filefor -ErrorAction Stop | Select-Object Name, LastWriteTime, FullName, Directory
                $createdtime = $file.LastWriteTime
                $now = Get-Date
                $timesincedownload = $now - $createdtime
                [pscustomobject]@{
                    Name                    = $file.name
                    FileAgeDaysHoursMinutes = [string]$timesincedownload.Days + ":" + [string]$timesincedownload.hours + ":" + [string]$timesincedownload.minutes
                    Path                    = $file.directory
                }
            }
            catch {

            }
        }
    }

    #Shows
    foreach ($mediashowfolder in $mediashowfolders) {
        Set-Location $mediashowfolder
        $TableName = 'Shows'
        # Identify media files that might not be transcoded through a comparison with the database. Should occasionally run update-processed to correct invalid data cause by re-downloaded media files and upgrades.
        $files = (Get-ChildItem -LiteralPath $mediashowfolder -r -File -Include "*.mkv", "*.mp4").fullname
        $query = Invoke-SqliteQuery -DataSource $DataSource -Query "Select fullname FROM $TableName WHERE comment = 'transcoded' and directory like `"%$mediashowfolder%`" and fileexists = 'true'"
        $transcoded = ($query).fullname
        if ($null -eq $transcoded) {
            $filesforprocessing = $files
        }
        else {
            $filesforprocessing = (Compare-Object $files $transcoded).inputobject
        }

        foreach ($filefor in $filesforprocessing) {
            try {
                $file = Get-ChildItem -LiteralPath $filefor -ErrorAction Stop | Select-Object Name, LastWriteTime, FullName, Directory
                $createdtime = $file.LastWriteTime
                $now = Get-Date
                $timesincedownload = $now - $createdtime
                [pscustomobject]@{
                    Name                    = $file.name
                    FileAgeDaysHoursMinutes = [string]$timesincedownload.Days + ":" + [string]$timesincedownload.hours + ":" + [string]$timesincedownload.minutes
                    Path                    = $file.directory
                }
            }
            catch {

            }
        }
    }
}