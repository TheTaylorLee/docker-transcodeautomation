#TODO
# THIS NEEDS MODIFYING TO REPLACE PROBEDATA WITH SPECIFIC PROBEDATA.
# NEED TO INTEGRATE WITH EXISTING PROCESS FLOW, UPDATE EXISTING DATABASE TO ADD A TABLE, AND UPDATE DESCRIPTION TABLE.
# ADD GRAFANA STATS FOR PROBE DATA
# METADATA TO LOG
## While recording streams I'll need to number them or concat them in some way to properly match similar. Such as audio codec, language, channels
### video codec + codec long name
### video aspect
### video size quality 480,720, 1080, etc
## audio codecs + codec long name
## audio language
## audio channels
## subtitles and their languages
## subtitles if forced exists


$files = Get-ChildItem ".\New folder" -r -File -Include "*.mkv", "*.mp4"
ForEach ($file in $files) {
    # Get video stream codec
    ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $file.fullname

    # Get video stream codec long name
    ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_long_name -of default=noprint_wrappers=1:nokey=1 $file.fullname

    # video aspect ratio
    ffprobe -v quiet -select_streams v:0 -show_entries stream=display_aspect_ratio -of default=noprint_wrappers=1:nokey=1 $file.fullname

    # video picture size 480,720, 1080, etc
    $height = ffprobe -v quiet -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 $file.fullname
    $width = ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 $file.fullname
    $picturesize = $height + 'x' + $width
    $picturesize
}


#test block
ForEach ($file in $files) {
    Write-Output $file.fullname
    ffprobe -v quiet -select_streams a -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $file.fullname
}