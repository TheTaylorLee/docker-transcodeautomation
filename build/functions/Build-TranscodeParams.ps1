<#
.SYNOPSIS
Generates FFmpeg arguments for processing HDR video files.

.DESCRIPTION
This script constructs an array of arguments to be used with FFmpeg for processing HDR video files. By probing the source file and re-submitting the parameters to the ffmpeg command.

.PARAMETER comment
The comment to be added to the video file.

.PARAMETER crf
The constant rate factor to be used for the video file.

.PARAMETER output
The fullpath for the output file to be processed.

.PARAMETER video
The fullpath for the video file to be processed and not the fullpath.

.EXAMPLE
Write-Output "info: Build-TranscodeParams Start"
$ffmpegargs = Build-TranscodeParams -video $env:FFToolsSource$video -comment $comment -crf $crf -output $env:FFToolsTarget$video
$outargs = ($ffmpegArgs -join " ")
Write-Output "debug FFmpeg arguments being used: $outargs"
Write-Output "info: Build-TranscodeParams End"
ffmpeg $ffmpegArgs

Example usage of this helper function.

.NOTES
Not needed for remuxing files, because the remuxing process will include HDR metadata.
#>

function Build-TranscodeParams {

    param (
        [Parameter(Mandatory = $true, HelpMessage = "This should be the immutable index.")][ValidateNotNullOrEmpty()][string]$comment,
        [Parameter(Mandatory = $true, HelpMessage = "This is the constant rate factor.")][ValidateNotNullOrEmpty()][string]$crf,
        [Parameter(Mandatory = $true, HelpMessage = "This is the video out file.")][ValidateNotNullOrEmpty()][string]$output,
        [Parameter(Mandatory = $true, HelpMessage = "This accepts a filename, but not fullname.")][ValidateNotNullOrEmpty()][string]$video
    )

    $out = ffprobe -hide_banner -loglevel error -select_streams v -print_format json -show_frames -read_intervals "%+#1" -show_entries "frame=color_space,color_primaries,color_transfer,side_data_list,color_range,color_matrix,bit_depth,chroma_subsampling,stream_side_data=type,stream=codec_tag_string,profile" -i $video
    $frames = ($out | ConvertFrom-Json -ErrorAction SilentlyContinue).frames
    $side_data_list = (($out | ConvertFrom-Json -ErrorAction SilentlyContinue).frames).side_data_list
    $streams = ($out | ConvertFrom-Json -ErrorAction SilentlyContinue).streams

    # Build array of arguments
    $ffmpegArgs = @(
        "-hide_banner",
        "-loglevel", "error",
        "-stats",
        "-i", $video,
        "-map", "0:v:0?",
        "-map", "0:a?",
        "-map", "0:s?",
        "-metadata", "title=",
        "-metadata", "description=",
        "-metadata", "COMMENT=$comment",
        "-c:v", "libx265",
        "-crf", "$crf",
        "-c:a", "copy",
        "-c:s", "copy",
        "-preset", "veryfast"
    )

    # Add color parameters if they exist
    if ($null -ne $frames -and $null -ne ($frames.pix_fmt)) {
        $pxf = $frames.pix_fmt
        $ffmpegArgs += "-pix_fmt", $pxf
    }
    if ($null -ne $frames -and $null -ne ($frames.color_space)) {
        $ffmpegArgs += "-colorspace", $frames.color_space
    }
    if ($null -ne $frames -and $null -ne ($frames.color_transfer)) {
        $ffmpegArgs += "-color_trc", $frames.color_transfer
    }
    if ($null -ne $frames -and $null -ne ($frames.color_primaries) -and ($frames.color_primaries) -ne "reserved") {
        $ffmpegArgs += "-color_primaries", $frames.color_primaries
    }
    if ($null -ne $frames -and $null -ne ($frames.color_range)) {
        $ffmpegArgs += "-color_range", $frames.color_range
    }
    if ($null -ne $frames -and $null -ne ($frames.color_matrix)) {
        $ffmpegArgs += "-colormatrix", $frames.color_matrix
    }
    if ($null -ne $frames -and $null -ne ($frames.bit_depth)) {
        $ffmpegArgs += "-bit_depth", $frames.bit_depth
    }
    if ($null -ne $frames -and $null -ne ($frames.chroma_subsampling)) {
        $ffmpegArgs += "-chroma_subsampling", $frames.chroma_subsampling
    }

    # HDR Metadata as x265 params
    $x265Params = @()

    # Add HDR10+ parameter only if the source has HDR10+ metadata
    if ($null -ne $frames.side_data_list) {
        foreach ($side_data in $frames.side_data_list) {
            if ($side_data.side_data_type -like "*DHDR10*" -or $side_data.side_data_type -like "*HDR10+*" -or $side_data.side_data_type -like "*SMPTE2094-40*") {
                $x265Params += "hdr10_plus=1"
                break
            }
        }
    }

    # Dolby Vision Detection and parameter add
    $dolbyVisionProfile = $null
    $hasDolbyVision = $false

    if ($null -ne $frames.side_data_list) {
        foreach ($side_data in $frames.side_data_list) {
            if ($side_data.side_data_type -eq "DOVI" -or $side_data.side_data_type -like "*Dolby Vision*") {
                $hasDolbyVision = $true
                break
            }
        }
    }

    $dvCodecTags = @("dvhe", "dvh1", "dvav", "dvh2")
    if ($streams.codec_tag_string -match ($dvCodecTags -join '|')) {
        $hasDolbyVision = $true
        break
    }

    if ($hasDolbyVision) {
        if ($streams.profile -match "^Dolby Vision (\d+)") {
            $dolbyVisionProfile = $Matches[1]
        }

        $x265Params += "dolby-vision-rpu=1"
        $x265Params += "vbv-maxrate=160000"
        $x265Params += "vbv-bufsize=160000"
        $x265Params += "vbv-init=0.9"
        $x265Params += "hrd=1"

        switch ($dolbyVisionProfile) {
            "5" { $x265Params += "dolby-vision-profile=5" }
            "7" { $x265Params += "dolby-vision-profile=7" }
            "8" { $x265Params += "dolby-vision-profile=8.1" }
            "9" { $x265Params += "dolby-vision-profile=9" }
            default { $x265Params += "dolby-vision-profile=8.1" }
        }
    }

    # Add CLL information if it exists
    $cllmax = ([string]$side_data_list.max_content).Trim()
    $cllavg = ([string]$side_data_list.max_average).Trim()
    if ($cllavg -match '\d' -and $cllmax -match '\d') {
        $x265Params += "max-cll=$cllmax,$cllavg"
    }

    # Add mastering display information if it exists
    $greenx = ([string]$side_data_list.green_x).split('/')[0]
    $greeny = ([string]$side_data_list.green_y).split('/')[0]
    $bluex = ([string]$side_data_list.blue_x).split('/')[0]
    $bluey = ([string]$side_data_list.blue_y).split('/')[0]
    $redx = ([string]$side_data_list.red_x).split('/')[0]
    $redy = ([string]$side_data_list.red_y).split('/')[0]
    $whitepointx = ([string]$side_data_list.white_point_x).split('/')[0]
    $whitepointy = ([string]$side_data_list.white_point_y).split('/')[0]
    $maxluminance = ([string]$side_data_list.max_luminance).split('/')[0]
    $minluminance = ([string]$side_data_list.min_luminance).split('/')[0]

    if ($greenx -match '\d' -and $greeny -match '\d' -and $bluex -match '\d' -and $bluey -match '\d' -and $redx -match '\d' -and $redy -match '\d' -and $whitepointx -match '\d' -and $whitepointy -match '\d' -and $maxluminance -match '\d' -and $minluminance -match '\d') {
        $masterDisplay = "G($greenx,$greeny)B($bluex,$bluey)R($redx,$redy)WP($whitepointx,$whitepointy)L($maxluminance,$minluminance)"
        $x265Params += "master-display=$masterDisplay"
    }

    # Add x265 params if we have any
    if ($x265Params.Count -gt 0) {
        $x265Params += "repeat-headers=1"
        $ffmpegArgs += "-x265-params", ($x265Params -join ":")
    }

    # Add output parameters
    $ffmpegArgs += "-stats_period", "60", $output
    $ffmpegArgs
}