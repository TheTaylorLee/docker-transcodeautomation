function Start-TranscodeShows {

    [cmdletbinding()]
    [Alias('Transcode')]
    param (
        [Parameter(Mandatory = $true)]$crf
    )
    #Used in debug logs
    Write-Output "info: Start-Transcode Start"

    if ($env:FFToolsSource -and $env:FFToolsTarget) {
        #Change directory to the source folder
        Set-Location $env:FFToolsSource
        $CustomShowOptionsApplied = Test-Path /docker-transcodeautomation/data/showscustomoptions.ps1

        $ext = "*.mkv"
        $array = @(Get-ChildItem -Filter $ext)
        Foreach ($video in $array.Name) {
            if ($CustomShowOptionsApplied -eq $true) {
                Write-Output "info: Using Custom Show Parameters"
                /docker-transcodeautomation/data/showscustomoptions.ps1
            }
            else {
                ffmpeg -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf $crf -c:a copy -c:s copy -preset veryfast -stats_period 60 "$env:FFToolsTarget$video"
            }
        }

        $ext = "*.mp4"
        $array = @(Get-ChildItem -Filter $ext)
        Foreach ($video in $array.Name) {
            if ($CustomShowOptionsApplied -eq $true) {
                Write-Output "info: Using Custom Show Parameters"
                /docker-transcodeautomation/data/showscustomoptions.ps1
            }
            else {
                ffmpeg -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf $crf -c:a copy -c:s copy -preset veryfast -stats_period 60 "$env:FFToolsTarget$video"
            }
        }
    }

    else {
        Write-Output "error: Required FFTools Variables Missing"
    }
    #Used in debug logs
    Write-Output "info: Start-Transcode End"
}