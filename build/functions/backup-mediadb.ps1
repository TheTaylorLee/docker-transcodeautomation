<#
.SYNOPSIS
    Backs up the media database to a specified folder.

.DESCRIPTION
    The Backup-Mediadb function checks if a backup of the media database has been created in the last 7 days.
    If not, it creates a new backup in the specified folder. It also removes backups older than 30 days.

.PARAMETER backupfolder
    The folder where the backup will be stored.

.PARAMETER DataSource
    The path to the media database that needs to be backed up.

.EXAMPLE
    Backup-Mediadb -backupfolder $backupfolder -datasource $datasource

.NOTES
    The function uses the current date in "yyyy-MM-dd" format to name the backup file.
    It logs the start and end of the backup process for debugging purposes.
#>

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