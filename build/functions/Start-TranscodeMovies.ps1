function Start-TranscodeMovies {

    [cmdletbinding()]
    [Alias('Transcode')]
    param (
        [Parameter(Mandatory = $true)]$crf
    )
    #Used in debug logs
    Write-Output "[+] Start-Transcode Start"

    if ($env:FFToolsSource -and $env:FFToolsTarget) {
        #Change directory to the source folder
        Set-Location $env:FFToolsSource
        $CustomMovieOptionsApplied = Test-Path /docker-transcodeautomation/data/moviescustomoptions.ps1

        $ext = "*.mkv"
        $array = @(Get-ChildItem -Filter $ext)
        Foreach ($video in $array.Name) {
            if ($CustomMovieOptionsApplied -eq $true) {
                Write-Output "[+] Using Custom Movies Parameters"
                /docker-transcodeautomation/data/moviescustomoptions.ps1
            }
            else {
                ffmpeg -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf $crf -c:a copy -c:s copy -preset veryfast -stats_period 60 "$env:FFToolsTarget$video"
            }
        }

        $ext = "*.mp4"
        $array = @(Get-ChildItem -Filter $ext)
        Foreach ($video in $array.Name) {
            if ($CustomMovieOptionsApplied -eq $true) {
                Write-Output "[+] Using Custom Movies Parameters"
                /docker-transcodeautomation/data/moviescustomoptions.ps1
            }
            else {
                ffmpeg -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf $crf -c:a copy -c:s copy -preset veryfast -stats_period 60 "$env:FFToolsTarget$video"
            }
        }
    }

    else {
        Write-Warning "[-] Required FFtools Variables Missing"
    }
    #Used in debug logs
    Write-Output "[+] Start-Transcode End"
}