# This is to probe and test the source.
$videofile = "C:\Users\taylo\Downloads\RPO HDR 10-bit.mp4"
$out = ffprobe -hide_banner -loglevel error -select_streams v -print_format json -show_frames -read_intervals "%+#1" -show_entries "frame=color_space,color_primaries,color_transfer,side_data_list,pix_fmt" -i $videofile
($out | ConvertFrom-Json).frames
(($out | ConvertFrom-Json).frames).side_data_list


# This is the original command
ffmpeg -hide_banner -loglevel error -stats -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$comment -c:v libx265 -crf $crf -c:a copy -c:s copy -preset veryfast -stats_period 60 "$env:FFToolsTarget$video"


# This is the modified command based on claude ai output
ffmpeg -hide_banner -loglevel error -stats -i $video -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$comment -c:v libx265 -crf $crf -c:a copy -c:s copy -preset veryfast -pix_fmt copy -colorspace copy -color_trc copy -color_primaries copy -color_range copy -color_matrix copy -max_cll copy -master_display copy -copy_unknown -copy_side_data all -strict -2 -stats_period 60 "$env:FFToolsTarget$video"



# Test based on claude ai output
ffmpeg -hide_banner -loglevel error -stats -i "C:\Users\taylo\Downloads\RPO HDR 10-bit.mp4" -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=transcoded -c:v libx265 -crf 21 -c:a copy -c:s copy -preset veryfast -pix_fmt copy -colorspace copy -color_trc copy -color_primaries copy -color_range copy -color_matrix copy -max_cll copy -master_display copy -copy_unknown -copy_side_data all -strict -2 -stats_period 60 "C:\Users\taylo\Downloads\RPO HDR 10-bit - test out.mp4"


# Maybe working (Assumes parameters pulled from probe and provided)
## Side data -copy_side_data all is not a real option. Side data must be probed and then provided to the missing parameters.
### only including first 300 seconds
ffmpeg -hide_banner -loglevel error -stats -i "C:\Users\taylo\Downloads\RPO HDR 10-bit.mp4" -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=transcoded -c:v libx265 -crf 21 -c:a copy -c:s copy -preset veryfast -pix_fmt yuv420p10le -colorspace bt2020nc -color_trc smpte2084 -color_primaries bt2020 -copy_unknown -strict -2 -stats_period 60 -t 300 "C:\Users\taylo\Downloads\RPO HDR 10-bit - test out.mp4"