Function Get-MediaFunctions {

    #Media Management
    Write-Host " "
    Write-Host "Media Management Functions"                                                                                     -ForegroundColor Magenta
    Write-Host "Get-MissingYear           Gets media missing the year of release in the name"                                   -ForegroundColor Cyan
    Write-Host "Get-NotProcessed          Get files not yet transcoded"                                                         -ForegroundColor Cyan
    Write-Host "Invoke-MediaManagement    Manage media files for Plex"                                                          -ForegroundColor Cyan
    Write-Host "Move-FileToPlexFolder     Move transcoded files back to plex folders"                                           -ForegroundColor Cyan
    Write-Host "Update-Processed          Updates transcoded files sql entries for replaced/upgraded files"                     -ForegroundColor Cyan
    Write-Host "Update-Statistics         Updates and pulls transcoded and media stats"                                         -ForegroundColor Cyan
}