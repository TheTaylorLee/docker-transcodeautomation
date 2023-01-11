<#
.Description
Find Movies and Shows missing the year in their name

.Example
Get-MissingYear -mediafolders "\R-User-Media\Kids Movies", "\R-User-Media\Movies", "\R-Others-Media\Movies", "P:\R-User-Media2\Shows", "\R-User-Media\Kids Shows", "\R-User-Media\Shows", "\R-Others-Media\Shows"
#>

function Get-MissingYear {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$mediafolders
    )

    foreach ($mediafolder in $mediafolders) {
        Get-ChildItem $mediafolder -r -Include "*.mkv", "*.mp4", !nocollection, !trailers, *.png, "*The Hobbit The Ultimate Edit*" | Select-Object name, fullname | Where-Object { $_.name -notlike "*(*)*" }
    }

}
