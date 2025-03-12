<#
.SYNOPSIS
Probes a video file to determine if it should skip processing based on various criteria.

.DESCRIPTION
The Skip-Analysis function examines a video file and determines whether it should be skipped for transcoding based on multiple configurable criteria:
- Video codec (AV1, HEVC)
- Minimum bitrate threshold
- Presence of HDR or Dolby Vision metadata

.PARAMETER video
The path to the video file that needs to be analyzed.

.EXAMPLE
$result = Skip-Analysis -video "/path/to/video.mkv"
if ($result.skip -eq $true) {
    # Remuxing only
}
else {
    # Transcoding options
}

.NOTES
Environment Variables:
- skipav1: When set to $true, files with AV1 codec will be skipped
- skiphevc: When set to $true, files with HEVC codec will be skipped
- skipkbpsbitratemin: Minimum bitrate threshold in kbps; files below this will be skipped
- skiphdr: When set to $true, files containing HDR or Dolby Vision metadata will be skipped
#>

Function Skip-Analysis {

    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]$video
    )

    # Cleanup variables
    $skip = $false
    $skipreason = $null
    $skipreason = @()

    # Strict Typing
    $env:SKIPAV1 = [string]$env:SKIPAV1
    $env:SKIPHEVC = [string]$env:SKIPHEVC
    $env:SKIPDOVI = [string]$env:SKIPDOVI
    $env:SKIPHDR = [string]$env:SKIPHDR
    $env:SKIPKBPSBITRATEMIN = [int]$env:SKIPKBPSBITRATEMIN

    # Skip matched codecs
    $codec = ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $video
    switch ($codec) {
        "av1" {
            if ($env:SKIPAV1 -eq 'true') {
                $skip = $true
                $skipreason += "av1 codec found"
            }
        }
        "hevc" {
            if ($env:SKIPHEVC -eq 'true') {
                $skip = $true
                $skipreason += "hevc codec found"
            }
        }
    }

    # Skip low bitrate
    $duration = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $video
    if ($duration -match "^\d+(\.\d+)?$" -and [double]$duration -gt 0) {
        $fileInfo = Get-Item $video
        $fileSizeInBits = $fileInfo.Length * 8
        $bitrate = [int]($fileSizeInBits / [double]$duration / 1000) # Convert to kbps
    }

    if ($env:SKIPKBPSBITRATEMIN -match "^\d+$" -and $bitrate -gt 0) {
        $minBitrate = [int]$env:SKIPKBPSBITRATEMIN
        if ($bitrate -lt $minBitrate) {
            $skip = $true
            $skipreason += "bitrate $bitrate kbps below minimum $minBitrate kbps"
        }
    }

    # Skip files containing HDR or Dolby Vision metadata
    $out = ffprobe -hide_banner -loglevel error -select_streams v -print_format json -show_frames -read_intervals "%+#1" -show_entries "frame=color_space,color_primaries,color_transfer,side_data_list,color_range,color_matrix,bit_depth,chroma_subsampling,stream_side_data=type,stream=codec_tag_string,profile" -i $video
    $frames = ($out | ConvertFrom-Json -ErrorAction SilentlyContinue).frames
    if ($null -ne $frames.side_data_list) {
        foreach ($side_data in $frames.side_data_list) {
            if ($env:SKIPHDR -eq 'true' -and ($side_data.side_data_type -like "*DHDR10*" -or $side_data.side_data_type -like "*HDR10+*" -or $side_data.side_data_type -like "*SMPTE2094-40*")) {
                if ($skipreason -notcontains "HDR metadata found") {
                    $skipreason += "HDR metadata found"
                }
                $skip = $true
            }
            if ($env:SKIPDOVI -eq 'true' -and ($side_data.side_data_type -eq "DOVI" -or $side_data.side_data_type -like "*Dolby Vision*")) {
                if ($skipreason -notcontains "Dolby Vision metadata found") {
                    $skipreason += "Dolby Vision metadata found"
                }
                $skip = $true
            }
        }
    }

    # Return skip status
    [pscustomobject]@{
        bitrate    = $bitrate
        codec      = $codec
        skip       = $skip
        skipreason = $skipreason
    }
}