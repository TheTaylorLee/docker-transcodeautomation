- Get probe data
```pwsh
$videofile = "C:\Users\taylo\Downloads\RPO HDR 10-bit.mp4"
$out = ffprobe -hide_banner -loglevel error -select_streams v -print_format json -show_frames -read_intervals "%+#1" -show_entries "frame=color_space,color_primaries,color_transfer,side_data_list,pix_fmt,color_range,color_matrix" -i $videofile
$frames = ($out | ConvertFrom-Json -ErrorAction SilentlyContinue).frames
$side_data_list = (($out | ConvertFrom-Json -ErrorAction SilentlyContinue).frames).side_data_list
```
- Probe data results
```pwsh
# Result of ($out | ConvertFrom-Json).frames
pix_fmt         : yuv420p10le
color_range     : tv
color_space     : bt2020nc
color_primaries : bt2020
color_transfer  : smpte2084
side_data_list  : {@{side_data_type=Mastering display metadata; red_x=35400/50000; red_y=14600/50000; green_x=8500/50000; green_y=39850/50000; blue_x=6550/50000; blue_y=2300/50000; white_point_x=15635/50000; white_point_y=16450/50000;
                  min_luminance=50/10000; max_luminance=40000000/10000}, @{side_data_type=Content light level metadata; max_content=725; max_average=162}, @{side_data_type=H.26[45] User Data Unregistered SEI message},
                  @{side_data_type=H.26[45] User Data Unregistered SEI message}}

# results of (($out | ConvertFrom-Json).frames).side_data_list
side_data_type : Mastering display metadata
red_x          : 35400/50000
red_y          : 14600/50000
green_x        : 8500/50000
green_y        : 39850/50000
blue_x         : 6550/50000
blue_y         : 2300/50000
white_point_x  : 15635/50000
white_point_y  : 16450/50000
min_luminance  : 50/10000
max_luminance  : 40000000/10000

side_data_type : Content light level metadata
max_content    : 725
max_average    : 162

side_data_type : H.26[45] User Data Unregistered SEI message

side_data_type : H.26[45] User Data Unregistered SEI message
```


- Performing the conversion (options may be missing here. Values will need to be fed back into ffmpeg using variables if they exist.)
```pwsh
if ($null -ne $frames -and $null -ne ($frames.pix_fmt)) {
    $pxf = $frames.pix_fmt
    $pix_fmt = "-pix_fmt $pxf"
}
if ($null -ne $frames -and $null -ne ($frames.color_space)) {
    $cosp = $frames.color_space
    $colorspace = "-colorspace $cosp"
}
if ($null -ne $frames -and $null -ne ($frames.color_transfer)) {
    $cotr = $frames.color_transfer
    $color_trc = "-color_trc $cotr"
}
if ($null -ne $frames -and $null -ne ($frames.color_primaries)) {
    $coprim = $frames.color_primaries
    $color_primaries = "-color_primaries $coprim"
}
if ($null -ne $frames -and $null -ne ($frames.color_range)) {
    $coran = $frames.color_range
    $color_range = "-color_range $coran"
}
if ($null -ne $frames -and $null -ne ($frames.color_matrix)) {
    $colmat = $frames.color_matrix
    $color_matrix = "-color_matrix $colmat"
}
if ($null -ne $side_data_list -and $null -ne ($side_data_list.max_content)) {
    $cllmax = ([string]$side_data_list.max_content).Trim()
    $cllavg = ([string]$side_data_list.max_average).Trim()
    $max_cll = "-max_cll ""$cllmax,$cllavg"""
}
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
    $master_display = "-master_display ""G($greenx,$greeny)B($bluex,$bluey)R($redx,$redy)WP($whitepointx,$whitepointy)L($maxluminance,$minluminance)"""
}
if ($null -ne $colorspace -or $null -ne $color_trc -or $null -ne $color_primaries -or $null -ne $color_matrix -or $null -ne $max_cll -or $null -ne $master_display) {
    # handle extra hdr metadata and don't fail on experimental
    $exexp = "-copy_unknown -strict -2"
}


ffmpeg -hide_banner -loglevel error -stats -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$comment -c:v libx265 -crf $crf -c:a copy -c:s copy -preset veryfast $pix_fmt $colorspace $color_trc $color_primaries $color_range $color_matrix $max_cll $master_display $exexp -stats_period 60 "$env:FFToolsTarget$video"
```