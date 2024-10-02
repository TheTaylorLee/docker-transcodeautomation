function Backup-Mediadb {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string]$backupfolder,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "info: Backup-Mediadb Start"

    $exists = Get-ChildItem -LiteralPath $backupfolder |
        Where-Object { $_.CreationTime -gt (Get-Date).AddDays(-7) }

    if ($null -ne $exists) {
        Write-Output "info: Skipping backup, database already backed up this week."
    }
    else {
        $date = Get-Date -Format "yyyy-MM-dd"
        $database = (Get-ChildItem $datasource).fullname
        Copy-Item -Path $database -Destination "$backupfolder/$date.sqlite" -Verbose
    }

    Get-ChildItem -LiteralPath $backupfolder |
        Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-30) } |
        Remove-Item -Verbose

    #Used in debug logs
    Write-Output "info: Backup-Mediadb End"
}