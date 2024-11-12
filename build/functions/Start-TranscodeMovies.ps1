function Start-TranscodeMovies {

    [cmdletbinding()]
    [Alias('Transcode')]
    param (
        [Parameter(Mandatory = $true)]$crf,
        [Parameter(Mandatory = $true)]$comment
    )

    #Used in debug logs
    Write-Output "info: Start-Transcode Start"

    if ($env:FFToolsSource -and $env:FFToolsTarget) {
        #Change directory to the source folder
        Set-Location $env:FFToolsSource
        $CustomMovieOptionsApplied = Test-Path /docker-transcodeautomation/data/moviescustomoptions.ps1

        [string[]]$ext = "*.mkv", "*.mp4"
        foreach ($extension in $ext) {
            $array = @(Get-ChildItem -Filter $extension)
            Foreach ($video in $array.Name) {
                if ($CustomMovieOptionsApplied -eq $true) {
                    Write-Output "info: Using Custom Movies Parameters"
                    /docker-transcodeautomation/data/moviescustomoptions.ps1
                }
                else {
                    # Command prior to refactoring this else block
                    ## ffmpeg -hide_banner -loglevel error -stats -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$comment -c:v libx265 -crf $crf -c:a copy -c:s copy -preset veryfast -stats_period 60 "$env:FFToolsTarget$video"

                    Write-Output "info: Build-TranscodeParams Start"
                    $ffmpegargs = Build-TranscodeParams -video $env:FFToolsSource$video -comment $comment -crf $crf -output $env:FFToolsTarget$output
                    $outargs = ($ffmpegArgs -join " ")
                    Write-Output "debug FFmpeg arguments being used: $outargs"
                    Write-Output "info: Build-TranscodeParams End"
                    ffmpeg $ffmpegArgs
                }
            }
        }
    }

    else {
        Write-Output "error: Required FFtools Variables Missing"
    }
    #Used in debug logs
    Write-Output "info: Start-Transcode End"
}