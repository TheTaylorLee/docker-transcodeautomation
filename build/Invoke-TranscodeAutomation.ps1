#Used in Debug Logs
$time = Get-Date -Format "yyyy-MM-dd HHmmss"
Start-Transcript "$PSScriptRoot/data/logs/$time debug.log"
Write-Output "[+] TranscodeAutomation Start"

#Debug log management
Get-ChildItem -Path $PSScriptRoot/data/logs/ |
Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-90) } |
Remove-Item

# Fix for environment variables not being pulled in by the service
$env:FFToolsSource = "/docker-transcodeautomation/transcoding/"
$env:FFToolsTarget = "/docker-transcodeautomation/transcoding/new/"

# Create directories if missing
New-Item /docker-transcodeautomation/transcoding/new/ -ItemType Directory -ErrorAction silentlycontinue -Verbose
New-Item /docker-transcodeautomation/transcoding/new/recover -ItemType Directory -ErrorAction silentlycontinue -Verbose
New-Item /docker-transcodeautomation/transcoding/new/processed -ItemType Directory -ErrorAction silentlycontinue -Verbose
New-Item /docker-transcodeautomation/data/logs -ItemType Directory -ErrorAction silentlycontinue -Verbose
New-Item /docker-transcodeautomation/data/Backups -ItemType Directory -ErrorAction silentlycontinue -Verbose

# Import PSSqlite
Import-Module /root/.local/share/powershell/Modules/PSSQLite/1.1.0/PSSQLite.psm1 -ErrorAction Stop

# Test for existence of media database
$datasource = ("/docker-transcodeautomation/data/MediaDB.SQLite")
$test3 = Test-Path $datasource
if ($test3 -eq $false) {
    Write-Output "[+] Creating sqlite database"
    . $PSScriptRoot/functions/Invoke-DBSetup.ps1
    Invoke-DBSetup -DataSource "/docker-transcodeautomation/data/MediaDB.SQLite"
}

# Update the database for missing tables added in new versions of docker-transcodeautomation
/docker-transcodeautomation/scripts/Update-Database.ps1

# Check for required variables
if ($null -eq $env:BACKUPPROCESSED -or $null -eq $env:BACKUPRETENTION -or $null -eq $env:MEDIAMOVIEFOLDERS -or $null -eq $env:MEDIASHOWFOLDERS -or $null -eq $env:MOVIESCRF -or $null -eq $env:SHOWSCRF) {
    Write-Warning "[-] Required environment Variable not set. Review the README documentation for help. Processing will not continue."
    while ($true) {
        Start-Sleep -Seconds 2147483
    }
}

# Import transcode automation scripts and continue with transcode automation
if ($host.version.major -eq '7') {
    ##Import Functions
    $FunctionPath = $PSScriptRoot + "\functions\"
    $scripts = (Get-ChildItem $FunctionPath).fullname
    foreach ($script in $scripts) {
        . $script
    }

    #set variables
    $backupfolder = "$PSScriptRoot/data/Backups"
    [string[]]$MEDIAmoviefolders = $env:MEDIAMOVIEFOLDERS -split ', '
    [string[]]$MEDIAshowfolders = $env:MEDIASHOWFOLDERS -split ', '
    if ($null -eq $env:STARTTIMEUTC) {
        $env:STARTTIMEUTC = "00:00"
        $env:ENDTIMEUTC = "23:59:59"
    }

    # Begin Automation
    # If set update metadata of existing media only
    if ($env:UPDATEMETADATA -eq 'true') {
        /docker-transcodeautomation/scripts/Update-Metadata.ps1
        while ($true) {
            Start-Sleep -Seconds 2147483
        }
    }

    # Else begin transcode processing
    else {
        while ($true) {
            # Transcode Automation Execution
            #begin processing

            if (Invoke-Timecompare -STARTTIMEUTC $env:STARTTIMEUTC -ENDTIMEUTC $env:ENDTIMEUTC) {
                $dt = Get-Date
                Write-Output "[+] Transcodeautomation while loop started at $dt"
                Invoke-MediaManagement -hours 4 -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $datasource
                Backup-Mediadb -backupfolder $backupfolder -datasource $datasource
                Update-Statistics -DataSource $datasource
            }
            else {
                $dt = Get-Date
                $startime = Get-Date -Date $env:STARTTIMEUTC
                $endtime = Get-Date -Date $env:ENDTIMEUTC
                if ($endtime -lt $startime) {
                    $endtime = $endtime.AddDays(1)
                    Write-Output "[+] Transcode Processing skipped. $dt is not within the processing window of $startime to $endtime"
                }
                else {
                    Write-Output "[+] Transcode Processing skipped. $dt is not within the processing window of $startime to $endtime"
                }
            }

            $timenow = Get-Date
            $seconds = 14400
            Write-Output "[+] Start Sleep at $timenow for $seconds seconds"
            Start-Sleep -Seconds $seconds
        }
    }
}