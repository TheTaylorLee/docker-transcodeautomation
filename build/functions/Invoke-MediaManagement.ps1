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