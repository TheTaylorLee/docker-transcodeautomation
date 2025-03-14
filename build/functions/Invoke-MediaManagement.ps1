<#
.SYNOPSIS
    Manages media files by processing TV shows and movies, and performing cleanup tasks.

.DESCRIPTION
    The Invoke-MediaManagement function processes media files by first ensuring no previous failures occurred.
    It then processes TV shows and movies by copying files to processing folders.
    Finally, it removes recovery files older than a specified retention period.

.PARAMETER MEDIAshowfolders
    An array of strings specifying the folders containing TV shows to be processed.

.PARAMETER MEDIAmoviefolders
    An array of strings specifying the folders containing movies to be processed.

.PARAMETER hours
    An integer specifying the number of hours old a file must be prior to processing.

.PARAMETER DataSource
    A string specifying the location of the sqlite database.

.EXAMPLE
    Invoke-MediaManagement -hours $env:MINAGE -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $datasource
#>

Function Invoke-MediaManagement {

    [CmdletBinding()]
    [Alias('mediapro')]
    Param (
        [Parameter(Mandatory = $true)][string[]]$MEDIAshowfolders,
        [Parameter(Mandatory = $true)][string[]]$MEDIAmoviefolders,
        [Parameter(Mandatory = $true)][int]$hours,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "info: Invoke-MediaManagement Start"

    ##Shows
    ##Make sure no previous failures occurred prior to stepping forward with shows
    $testnofiles = Get-ChildItem -LiteralPath $env:FFToolsSource -File
    $testnofiles2 = Get-ChildItem -LiteralPath $env:FFToolsTarget -File
    if ($null -eq $testnofiles -and $null -eq $testnofiles2) {
        # Delete update-metadata tempdb if it exists.
        Remove-Item '/docker-transcodeautomation/data/update-metadata.db' -ErrorAction SilentlyContinue

        #Copy Files to processing folders
        Invoke-MEDIAShowsToProcess -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -hours $hours -DataSource $DataSource
    }
    else {
        Write-Output "error: Files in transcoding folders preventing this function from running. Clear up this issue first"
    }

    ##Movies
    ##Make sure no previous failures occurred prior to stepping forward with movies
    $testnofiles = Get-ChildItem -LiteralPath $env:FFToolsSource -File
    $testnofiles2 = Get-ChildItem -LiteralPath $env:FFToolsTarget -File
    if ($null -eq $testnofiles -and $null -eq $testnofiles2) {
        # Delete update-metadata tempdb if it exists.
        Remove-Item '/docker-transcodeautomation/data/update-metadata.db' -ErrorAction SilentlyContinue

        #Copy Files to processing folders
        Invoke-MEDIAMoviesToProcess -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders  -hours $hours -DataSource $DataSource
    }
    else {
        Write-Output "error: Files in transcoding folders preventing this function from running. Clear up this issue first"
    }

    #Remove recover files older than 14 days.
    Write-Output "info: Deleting backup files over $env:BACKUPRETENTION days old"
    Get-ChildItem -LiteralPath $env:FFToolsTarget/recover |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$env:BACKUPRETENTION) } |
        Remove-Item -Verbose

    #Used in debug logs
    Write-Output "info: Invoke-MediaManagement End"
}