<#
.SYNOPSIS
Generates FFmpeg arguments for processing HDR video files.

.DESCRIPTION
This script constructs an array of arguments to be used with FFmpeg for processing HDR video files. By probing the source file and re-submitting the parameters to the ffmpeg command.

.PARAMETER video
The filename for the video file to be processed and not the fullpath.

.EXAMPLE
Write-Output "info: Get-HDRValues Start"
$ffmpegargs = Get-HDRValues -video $video
$outargs = ($ffmpegArgs -join " ")
Write-Output "debug FFmpeg arguments being used: $outargs"
Write-Output "info: Get-HDRValues End"
ffmpeg $ffmpegArgs

Example usage of this helper function.
#>

function Get-HDRValues {

    param (
        [Parameter(Mandatory = $true, HelpMessage = "This accepts a filename, but not fullname.")][ValidateNotNullOrEmpty()][string]$video
    )

    $videoin = $env:FFToolsSource + $video
    $out = ffprobe -hide_banner -loglevel error -select_streams v -print_format json -show_frames -read_intervals "%+#1" -show_entries "frame=color_space,color_primaries,color_transfer,side_data_list,color_range,color_matrix" -i $videoin
    $frames = ($out | ConvertFrom-Json -ErrorAction SilentlyContinue).frames
    $side_data_list = (($out | ConvertFrom-Json -ErrorAction SilentlyContinue).frames).side_data_list

    # Build array of arguments
    $ffmpegArgs = @(
        "-hide_banner",
        "-loglevel", "error",
        "-stats",
        "-i", $videoin,
        "-map", "0:v:0?",
        "-map", "0:a?",
        "-map", "0:s?",
        "-metadata", "title=",
        "-metadata", "description=",
        "-metadata", "COMMENT=dta0123456789",
        "-c:v", "libx265",
        "-crf", "21",
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
    if ($null -ne $frames -and $null -ne ($frames.color_primaries)) {
        $ffmpegArgs += "-color_primaries", $frames.color_primaries
    }
    if ($null -ne $frames -and $null -ne ($frames.color_range)) {
        $ffmpegArgs += "-color_range", $frames.color_range
    }
    if ($null -ne $frames -and $null -ne ($frames.color_matrix)) {
        $ffmpegArgs += "-colormatrix", $frames.color_matrix
    }

    # HDR Metadata as x265 params
    $x265Params = @()

    # Add CLL (Content Light Level) information if it exists
    if ($null -ne $side_data_list -and $null -ne ($side_data_list.max_content)) {
        $cllmax = ([string]$side_data_list.max_content).Trim()
        $cllavg = ([string]$side_data_list.max_average).Trim()
        $x265Params += "max-cll=$cllmax,$cllavg"
    }

    # Add mastering display information if it exists
    if ($null -ne $side_data_list -and $null -ne ($side_data_list.red_x)) {
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
        $masterDisplay = "G($greenx,$greeny)B($bluex,$bluey)R($redx,$redy)WP($whitepointx,$whitepointy)L($maxluminance,$minluminance)"
        $x265Params += "master-display=$masterDisplay"
    }

    # Add x265 params if we have any
    if ($x265Params.Count -gt 0) {
        $ffmpegArgs += "-x265-params", ($x265Params -join ":")
    }

    # Add output parameters
    $videoout = $env:FFToolsTarget + $video
    $ffmpegArgs += "-stats_period", "60", $videoout
    $ffmpegArgs
}