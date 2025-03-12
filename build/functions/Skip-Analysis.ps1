<#
.SYNOPSIS
Probes the file being processed to determine if it matches criteria that would have this file skip processing.
#>

Function Skip-Analysis {

    [cmdletbinding()]
    [Alias('Transcode')]
    param (
        [Parameter(Mandatory = $true)]$video
    )

    # Cleanup variables
    $skip = $false
    $skipreason = $null
    $skipreason = @()

    # Skip matched codecs
    $codec = ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $video
    switch ($codec) {
        "av1" {
            if ($env:skipav1) {
                $skip = $true
                $skipreason += "av1 codec found"
            }
        }
        "hevc" {
            if ($env:skiphevc) {
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

    if ($env:skipkbpsbitratemin -and $bitrate -gt 0) {
        $minBitrate = [int]$env:skipkbpsbitratemin
        if ($bitrate -lt $minBitrate) {
            $skip = $true
            $skipreason += "bitrate $bitrate kbps below minimum $minBitrate kbps"
        }
    }

    # Skip below file size
    if ($env:skipfilesizeminMB) {
        $minFileSizeMB = [int]$env:skipfilesizemin
        $minFileSizeBytes = $minFileSizeMB * 1MB
        if ($fileInfo.Length -lt $minFileSizeBytes) {
            $skip = $true
            $skipreason += "file size $($fileInfo.Length) bytes below minimum $minFileSizeMB MB"
        }
    }

    # Skip files containing HDR or Dolby Vision metadata
    $out = ffprobe -hide_banner -loglevel error -select_streams v -print_format json -show_frames -read_intervals "%+#1" -show_entries "frame=color_space,color_primaries,color_transfer,side_data_list,color_range,color_matrix,bit_depth,chroma_subsampling,stream_side_data=type,stream=codec_tag_string,profile" -i $video
    $frames = ($out | ConvertFrom-Json -ErrorAction SilentlyContinue).frames
    if ($null -ne $frames.side_data_list) {
        foreach ($side_data in $frames.side_data_list) {
            if ($env:skiphdr -and ($side_data.side_data_type -like "*DHDR10*" -or $side_data.side_data_type -like "*HDR10+*" -or $side_data.side_data_type -like "*SMPTE2094-40*")) {
                $skip = $true
                $skipreason += "HDR metadata found"
            }
            if ($env:skiphdr -and ($side_data.side_data_type -eq "DOVI" -or $side_data.side_data_type -like "*Dolby Vision*")) {
                $skip = $true
                $skipreason += "Dolby Vision metadata found"
            }
        }
    }

    # Return skip status
    [pscustomobject]@{
        bitrate    = $bitrate
        codec      = $codec
        filesize   = $minFileSizeBytes
        skip       = $skip
        skipreason = $skipreason
    }
}