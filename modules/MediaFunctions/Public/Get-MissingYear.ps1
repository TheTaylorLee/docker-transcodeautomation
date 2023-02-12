<#
.Description
Find Movies and Shows missing the year in their name

.Example
remove-item /docker-transcodeautomation/data/logs/missingyear.log -force
Get-MissingYear | out-file /docker-transcodeautomation/data/logs/missingyear.log -append
#>

function Get-MissingYear {

    [CmdletBinding()]
    Param (
    )

    [string[]]$mediashowfolders = $env:MEDIASHOWFOLDERS -split ', '
    [string[]]$mediamoviefolders = $env:MEDIAMOVIEFOLDERS -split ', '
    [string[]]$mediafolders = $mediashowfolders + $mediamoviefolders

    foreach ($mediafolder in $mediafolders) {
        Get-ChildItem $mediafolder -r | Select-Object name, fullname | Where-Object { $_.name -notlike "*(*)*" }
    }

}