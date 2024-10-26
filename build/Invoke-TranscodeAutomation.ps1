if ($host.version.major -eq '7') {
    # Setup Environment
    ##Used in Debug Logs
    $time = Get-Date -Format "yyyy-MM-dd HHmmss"
    Start-Transcript "$PSScriptRoot/data/logs/$time debug.log"
    Write-Output "info: TranscodeAutomation Start"

    ##Debug log management
    Get-ChildItem -Path $PSScriptRoot/data/logs/ |
        Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-14) } |
        Remove-Item

    ##Fix for environment variables not being pulled in by the service
    $env:FFToolsSource = "/docker-transcodeautomation/transcoding/"
    $env:FFToolsTarget = "/docker-transcodeautomation/transcoding/new/"

    ##Create directories if missing
    New-Item /docker-transcodeautomation/transcoding/new/ -ItemType Directory -ErrorAction silentlycontinue -Verbose
    New-Item /docker-transcodeautomation/transcoding/new/recover -ItemType Directory -ErrorAction silentlycontinue -Verbose
    New-Item /docker-transcodeautomation/transcoding/new/processed -ItemType Directory -ErrorAction silentlycontinue -Verbose
    New-Item /docker-transcodeautomation/data/logs -ItemType Directory -ErrorAction silentlycontinue -Verbose
    New-Item /docker-transcodeautomation/data/Backups -ItemType Directory -ErrorAction silentlycontinue -Verbose

    ##Import PSSqlite
    Import-Module /root/.local/share/powershell/Modules/PSSQLite/1.1.0/PSSQLite.psm1 -ErrorAction Stop

    ##Test for existence of media database
    $datasource = ("/docker-transcodeautomation/data/MediaDB.SQLite")
    $test3 = Test-Path $datasource
    if ($test3 -eq $false) {
        Write-Output "info: Creating sqlite database"
        . $PSScriptRoot/functions/Invoke-DBSetup.ps1
        Invoke-DBSetup -DataSource "/docker-transcodeautomation/data/MediaDB.SQLite"
    }

    ##Update the database for missing tables added in new versions of docker-transcodeautomation
    /docker-transcodeautomation/scripts/Update-Database.ps1

    ##Create PS Drive for available free space checking
    New-PSDrive -Name transcoding -Root /docker-transcodeautomation/transcoding -PSProvider FileSystem

    ##Check for required variables
    if ($null -eq $env:BACKUPPROCESSED -or $null -eq $env:BACKUPRETENTION -or $null -eq $env:MEDIAMOVIEFOLDERS -or $null -eq $env:MEDIASHOWFOLDERS) {
        Write-Output "error: Required environment Variable not set. Review the Github README for help. Processing will not continue."
        while ($true) {
            Start-Sleep -Seconds 2147483
        }
    }

    ##Import transcode automation functions and continue with transcode automation
    ##Import Functions
    $FunctionPath = $PSScriptRoot + "\functions\"
    $scripts = (Get-ChildItem $FunctionPath).fullname
    foreach ($script in $scripts) {
        . $script
    }

    ##set variables
    $backupfolder = "$PSScriptRoot/data/Backups"
    [string[]]$MEDIAmoviefolders = $env:MEDIAMOVIEFOLDERS -split ', '
    [string[]]$MEDIAshowfolders = $env:MEDIASHOWFOLDERS -split ', '
    if ($null -eq $env:STARTTIMEUTC) {
        $env:STARTTIMEUTC = "00:00"
        $env:ENDTIMEUTC = "23:59:59"
    }
    if ($null -eq $env:MINAGE) {
        $env:MINAGE = "4"
    }
    if ($null -eq $env:PROCDELAY) {
        [int]$minseconds = "14400"
    }
    else {
        [int]$minseconds = 3600 * $env:PROCDELAY
    }

    # Begin Automation
    ##If set update metadata of existing media only
    if ($env:UPDATEMETADATA -eq 'true') {
        /docker-transcodeautomation/scripts/Update-Metadata.ps1 -datasource $datasource
        while ($true) {
            Start-Sleep -Seconds 2147483
        }
    }

    ##Else begin transcode processing
    else {
        while ($true) {
            ###Transcode Automation Execution
            ###begin processing

            if (Invoke-Timecompare -STARTTIMEUTC $env:STARTTIMEUTC -ENDTIMEUTC $env:ENDTIMEUTC) {
                $dt = Get-Date
                Write-Output "info: Transcodeautomation while loop started at $dt"
                ###The Move-FiletoMediaFolder function is run here as a part of the fix for issue #29 Having it run here ensures even if there are no files to transcode, the failed file move is processed during the next window.
                Move-FileToMEDIAFolder -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $datasource #Issue 29
                Invoke-MediaManagement -hours $env:MINAGE -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $datasource
                # Update-Processed can only run after the all possible file handling delays have passed. This ensures that if a file name changed but still exists, other functions update the database first.
                if ($null -eq $runthisonetimeonly) {
                    Write-Output "info: Set runthisonetimeonly to true and populate a date variable for update-processed to leverage."
                    $runthisonetimeonly = $true
                    $updateprocesseddate = Get-Date
                    [int]$updateprocessedsecondsdelay = 90000 + $minseconds + ([int]$env:MINAGE * 3600)
                }
                if ($updateprocesseddate -lt (Get-Date).AddSeconds(-$updateprocessedsecondsdelay)) {
                    /docker-transcodeautomation/scripts/Update-Processed.ps1 -DataSource $datasource
                }
                else {
                    $delayinfo = "{0:N3}" -f (($updateprocesseddate - (Get-Date).AddSeconds(-$updateprocessedsecondsdelay)).TotalHours)
                    Write-Output "info: Update-Processed skipped. Will not run until the container is running for another $delayinfo hours."
                }
                Backup-Mediadb -backupfolder $backupfolder -datasource $datasource
                Update-Statistics -DataSource $datasource
            }
            else {
                $dt = Get-Date
                $startime = Get-Date -Date $env:STARTTIMEUTC
                $endtime = Get-Date -Date $env:ENDTIMEUTC
                if ($endtime -lt $startime) {
                    $endtime = $endtime.AddDays(1)
                    Write-Output "info: Transcode Processing skipped. $dt is not within the processing window of $startime to $endtime"
                }
                else {
                    Write-Output "info: Transcode Processing skipped. $dt is not within the processing window of $startime to $endtime"
                }
            }

            $timenow = Get-Date
            Write-Output "info: Start Sleep at $timenow for $minseconds seconds"
            Start-Sleep -Seconds $minseconds
        }
    }
}