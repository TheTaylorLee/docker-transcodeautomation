function Start-Transcode {

    [cmdletbinding()]
    [Alias('Transcode')]
    param (
        [Parameter(Mandatory = $true)]$crf
    )
    #Used in debug logs
    Write-Output "Start-Transcode Start"

    if ($env:FFToolsSource -and $env:FFToolsTarget) {
        #Change directory to the source folder
        Set-Location $env:FFToolsSource
        $CustomOptionsApplied = Test-Path /docker-transcodeautomation/data/customoptions.ps1

        $ext = "*.mkv"
        $array = @(Get-ChildItem -Filter $ext)
        Foreach ($video in $array.Name) {
            if ($CustomOptionsApplied -eq $true) {
                /docker-transcodeautomation/data/customoptions.ps1
            }
            else {
                ffmpeg -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf $crf -ac 8 -c:a aac -c:s copy -preset veryfast -stats_period 60 "$env:FFToolsTarget$video"
            }
        }

        $ext = "*.mp4"
        $array = @(Get-ChildItem -Filter $ext)
        Foreach ($video in $array.Name) {
            if ($CustomOptionsApplied -eq $true) {
                /docker-transcodeautomation/data/customoptions.ps1
            }
            else {
                ffmpeg -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf $crf -ac 8 -c:a aac -c:s copy -preset veryfast -stats_period 60 "$env:FFToolsTarget$video"
            }
        }
    }

    else {
        Write-Warning "You must first run Set-FFToolsVariables! This is only required once."
    }
    #Used in debug logs
    Write-Output "Start-Transcode End"
}