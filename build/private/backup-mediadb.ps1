function Backup-Mediadb {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string]$backupfolder,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "Backup-Mediadb Start"

    $date = Get-Date -Format "yyyy-MM-dd"
    $database = (Get-ChildItem $datasource).fullname

    if (Test-Path "$backupfolder/$date.sqlite" -ErrorAction SilentlyContinue) {
        Write-Output "Skipping backup, database already backed up today."
    }
    else {
        Copy-Item -Path $database -Destination "$backupfolder/$date.sqlite" -Verbose
    }

    Get-ChildItem -Path $backupfolder |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Verbose

    #Used in debug logs
    Write-Output "Backup-Mediadb End"
}