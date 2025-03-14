<#
.SYNOPSIS
Starts the transcoding process by determining if a file should be skipped or transcoded.

.PARAMETER crf
The Constant Rate Factor (CRF) value to be used for transcoding.

.PARAMETER comment
A comment or tag to be associated with the transcoding process.

.EXAMPLE
Start-TranscodeShows -crf 23 -comment "dta-0000000001"
#>

function Start-TranscodeShows {

    [cmdletbinding()]
    [Alias('Transcode')]
    param (
        [Parameter(Mandatory = $true)]$crf,
        [Parameter(Mandatory = $true)]$comment,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "info: Start-Transcode Start"

    if ($env:FFToolsSource -and $env:FFToolsTarget) {
        #Change directory to the source folder
        Set-Location $env:FFToolsSource
        $CustomShowOptionsApplied = Test-Path /docker-transcodeautomation/data/showscustomoptions.ps1

        [string[]]$ext = "*.mkv", "*.mp4"
        foreach ($extension in $ext) {
            $array = @(Get-ChildItem -Filter $extension)
            Foreach ($video in $array.Name) {
                Write-Output "[+] Info: Skip-Analysis Results"
                $skipanalysis = Skip-Analysis -video $env:FFToolsSource$video
                $skipanalysis | Select-Object bitrate, codec, minutes, skip, skipreason

                if ($CustomShowOptionsApplied -eq $true -and $skipanalysis.skip -eq $false) {
                    Write-Output "info: Using Custom Show Parameters"
                    /docker-transcodeautomation/data/showscustomoptions.ps1
                }
                elseif ($skipanalysis.skip -eq $true) {
                    New-Item /docker-transcodeautomation/data/logs/skipcheck/$comment -ItemType file | Out-Null
                    $reason = ($skipanalysis.skipreason) -join " and "
                    $reasondb = ($skipanalysis.skipreason) -join ", "

                    $tablename = "shows"
                    $query = "Update $tableName SET transcodeskipreason = `"$reasondb`", updatedby = 'Start-TranscodeShows' WHERE comment = `"$comment`""
                    Invoke-SqliteQuery -DataSource $DataSource -Query $query

                    Write-Output "[+] info: Skipping transcode for $video due to $reason"
                }
                else {
                    Write-Output "info: Build-TranscodeParams Start"
                    $ffmpegargs = Build-TranscodeParams -video $env:FFToolsSource$video -comment $comment -crf $crf -output $env:FFToolsTarget$video
                    $outargs = ($ffmpegArgs -join " ")
                    Write-Output "debug: ffmpeg $outargs"
                    Write-Output "info: Build-TranscodeParams End"
                    ffmpeg $ffmpegArgs
                }

            }
        }
    }

    else {
        Write-Output "error: Required FFTools Variables Missing"
    }
    #Used in debug logs
    Write-Output "info: Start-Transcode End"
}