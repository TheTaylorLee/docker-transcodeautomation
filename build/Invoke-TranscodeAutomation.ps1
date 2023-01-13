# Fix for environment variables not being pulled in by the service
$env:FFToolsSource = "/docker-transcodeautomation/transcoding/"
$env:FFToolsTarget = "/docker-transcodeautomation/transcoding/new/"

# Create directories if missing
New-Item /docker-transcodeautomation/transcoding/new/ -ItemType Directory -ErrorAction silentlycontinue
New-Item /docker-transcodeautomation/transcoding/new/recover -ItemType Directory -ErrorAction silentlycontinue
New-Item /docker-transcodeautomation/transcoding/new/processed -ItemType Directory -ErrorAction silentlycontinue
New-Item /docker-transcodeautomation/data/logs -ItemType Directory -ErrorAction silentlycontinue
New-Item /docker-transcodeautomation/data/Backups -ItemType Directory -ErrorAction silentlycontinue

#Debug log management
Get-ChildItem -Path $PSScriptRoot/data/logs/ |
Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-90) } |
Remove-Item
$time = Get-Date -Format "yyyy-MM-dd HHmmss"

#Used in Debug Logs
Start-Transcript "$PSScriptRoot/data/logs/$time debug.log"
Write-Output "TranscodeAutomation Service Start"

# Import PSSqlite
Import-Module $PSScriptRoot/PSSQLite/1.1.0/PSSQLite.psm1 -ErrorAction Stop

# Test for existence of media database
$datasource = ("/docker-transcodeautomation/data/MediaDB.SQLite")
$test3 = Test-Path $datasource
if ($test3 -eq $false) {
    . $PSScriptRoot/private/Invoke-DBSetup.ps1
    invoke-dbsetup -datasource "/docker-transcodeautomation/data/MediaDB.SQLite"
}

# Import transcode automation scripts and continue with transcode automation
if ($host.version.major -eq '7') {
    ##Import Functions
    $FunctionPathPrivate = $PSScriptRoot + "\private\"
    $scripts = (Get-ChildItem $FunctionPathPrivate).fullname
    foreach ($script in $scripts) {
        . $script
    }

    #set variables
    $backupfolder = "$PSScriptRoot/data/Backups"
    [string[]]$MEDIAmoviefolders = $env:MEDIAMOVIEFOLDERS -split ', '
    [string[]]$MEDIAshowfolders = $env:MEDIASHOWFOLDERS -split ', '

    # Begin Automation
    # If set update metadata of existing media only
    if ($env:UPDATEMETADATA -eq 'true') {
        /docker-transcodeautomation/updatemetadata.ps1
        while ($true) {
            Start-Sleep -Seconds 2147483
        }
    }

    else {
        while ($true) {

            # Transcode Automation Execution
            else {
                #begin processing
                $dt = Get-Date
                Write-Output "Transcodeautomation while loop started at $dt"
                Invoke-MediaManagement -hours 4 -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $datasource
                Backup-Mediadb -backupfolder $backupfolder -datasource $datasource

                Update-Statistics -DataSource $datasource | Select-Object -Last 2

                $timenow = Get-Date
                $seconds = 14400
                Write-Output "Start Sleep at $timenow for $seconds"
                Start-Sleep -Seconds $seconds
            }
        }
    }
}