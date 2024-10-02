<#
.Description
Find Movies and Shows missing the year in their name

.Example
Get-MissingYear
#>

function Get-MissingYear {

    [CmdletBinding()]
    Param (
    )

    [string[]]$mediashowfolders = $env:MEDIASHOWFOLDERS -split ', '
    [string[]]$mediamoviefolders = $env:MEDIAMOVIEFOLDERS -split ', '
    [string[]]$mediafolders = $mediashowfolders + $mediamoviefolders

    if (Test-Path '/docker-transcodeautomation/data/logs/missingyear.log') {
        Remove-Item /docker-transcodeautomation/data/logs/missingyear.log -Force
    }
    foreach ($mediafolder in $mediafolders) {
        Get-ChildItem -LiteralPath $mediafolder -r |
        Sort-Object fullname |
        Select-Object name, fullname |
        Where-Object { $_.name -notlike "*(*)*" } |
        #Format-Table -AutoSize |
        Out-File /docker-transcodeautomation/data/logs/missingyear.log -Width 10000 -Append
    }
    Write-Output "Results can be found at /docker-transcodeautomation/data/logs/missingyear.log"
}