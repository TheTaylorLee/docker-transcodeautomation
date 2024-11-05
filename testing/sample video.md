- Get probe data
```pwsh
$videofile = "C:\Users\taylo\Downloads\RPO HDR 10-bit.mp4"
$out = ffprobe -hide_banner -loglevel error -select_streams v -print_format json -show_frames -read_intervals "%+#1" -show_entries "frame=color_space,color_primaries,color_transfer,side_data_list,pix_fmt" -i $videofile
$frames = ($out | ConvertFrom-Json).frames
$side_data_list = (($out | ConvertFrom-Json).frames).side_data_list

```
- Probe data results
```pwsh
# Result of ($out | ConvertFrom-Json).frames
pix_fmt         : yuv420p10le
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


- Command to convert it. (options may be missing here. Values will need to be fed back into ffmpeg using a single string.)
```pwsh
$redx = ([string]$side_data_list.red_x).split('/')[0]

ffmpeg -hide_banner -loglevel error -stats -i "C:\Users\taylo\Downloads\RPO HDR 10-bit.mp4" \
-map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" \
-metadata COMMENT=transcoded -c:v libx265 -crf 21 -c:a copy -c:s copy \
-preset veryfast -colorspace bt2020nc -color_trc smpte2084 -color_primaries bt2020 \
-master_display "G(13250,34500)B(7500,3000)R($redx,16000)WP(15635,16450)L(40000000,50)" \
-max_cll "1000,400" -strict -2 -stats_period 60 \
"C:\Users\taylo\Downloads\RPO HDR 10-bit - test out.mp4"
```