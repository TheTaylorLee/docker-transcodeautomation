<#
.DESCRIPTION
Find Movies and Shows missing the year in their name

.EXAMPLE
Get-MissingYear

.Notes
Additional notes go here.

.Link
https://github.com/TheTaylorLee/AdminToolbox
#>

function Get-MissingYear {

    [CmdletBinding()]
    param (
    )

    [string[]]$mediashowfolders = $env:MEDIASHOWFOLDERS -split ', '
    [string[]]$mediamoviefolders = $env:MEDIAMOVIEFOLDERS -split ', '
    [string[]]$mediafolders = $mediashowfolders + $mediamoviefolders

    if (Test-Path '/docker-transcodeautomation/data/logs/missingyear.log') {
        Remove-Item /docker-transcodeautomation/data/logs/missingyear.log -Force
    }
    foreach ($mediafolder in $mediafolders) {
        $results = Get-ChildItem -LiteralPath $mediafolder -r |
            Sort-Object fullname |
            Select-Object name, fullname, extension |
            Where-Object { $_.name -notlike "*(*)*" -and $_.extension -notmatch "(?i)\.(txt|url|db|ini|log|json|xml|png|jpg)$" -and $_.fullname -notmatch "(?i)youtube" }
        $results | Select-Object name, fullname
    }
}