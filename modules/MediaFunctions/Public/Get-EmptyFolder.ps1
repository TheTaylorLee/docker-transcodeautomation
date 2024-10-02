<#
.Description
Find empty media directories

.Example
Get-EmptyFolder
#>

function Get-EmptyFolder {

    [CmdletBinding()]
    Param (
    )

    [string[]]$mediashowfolders = $env:MEDIASHOWFOLDERS -split ', '
    [string[]]$mediamoviefolders = $env:MEDIAMOVIEFOLDERS -split ', '
    [string[]]$mediafolders = $mediashowfolders + $mediamoviefolders

    foreach ($mediafolder in $mediafolders) {
        Get-ChildItem -LiteralPath $mediafolder -Directory -Recurse |
        Where-Object { $_.GetFileSystemInfos().Count -eq 0 } |
        Select-Object FullName
    }
}