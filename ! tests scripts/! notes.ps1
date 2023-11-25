#TODO
# THIS NEEDS MODIFYING TO REPLACE PROBEDATA WITH SPECIFIC PROBEDATA.
# NEED TO INTEGRATE WITH EXISTING PROCESS FLOW, UPDATE EXISTING DATABASE TO ADD A TABLE, AND UPDATE DESCRIPTION TABLE.
# Need Columns defining shows vs movies or seperate tables for both
# ADD GRAFANA STATS FOR PROBE DATA

## While recording streams I'll need to number them or concat them in some way to properly match each with their index. Such as audio codec, language, channels
### I can use a for loop with an integer condition to group the various audio or subtitle indexes properly. Then how do I intend to store them in the database?
## It then becomes a question of how do I display this data in grafana in a useful manner.

# METADATA TO LOG
## video codec + codec long name
## video aspect
## video size quality 480,720, 1080, etc
## audio codecs + codec long name
## audio language
## audio channels
## Audio Channel Layout
## subtitles and their languages
## subtitles if forced exists


$files = Get-ChildItem ".\" -r -File -Include "*.mkv", "*.mp4"
#video
ForEach ($file in $files) {
    Write-Output $file.fullname
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


#audio
ForEach ($file in $files) {
    Write-Output $file.fullname
    #audio codec
    $codec = ffprobe -v quiet -select_streams a -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $file.fullname
    #codec long name
    $codeclongname = ffprobe -v quiet -select_streams a -show_entries stream=codec_long_name -of default=noprint_wrappers=1:nokey=1 $file.fullname
    # audio language
    $language = ffprobe -v quiet -select_streams a -show_entries stream=:stream_tags=language -of default=noprint_wrappers=1:nokey=1 $file.fullname
    # audio channels
    $channels = ffprobe -v quiet -select_streams a -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 $file.fullname
    # Channel Layout
    $channellayout = ffprobe -v quiet -select_streams a -show_entries stream=channel_layout -of default=noprint_wrappers=1:nokey=1 $file.fullname

    $count = $codec.count
    for ( $i = 0; $i -lt $count; $i++) {
        $codec[$i] + "  -  " + $codeclongname[$i] + "  -  " + $language[$i] + "  -  " + $channels[$i] + "  -  " + $channellayout[$i]
    }
}

#subtitles
ForEach ($file in $files) {
    Write-Output $file.fullname
    #Subtitle Language
    $subtitle = ffprobe -v quiet -select_streams s -show_entries stream=:stream_tags=language -of default=noprint_wrappers=1:nokey=1 $file.fullname
    # Subtitle Forced
    $forced = ffprobe -v quiet -select_streams s -show_entries stream=:stream_disposition=forced -of default=noprint_wrappers=1:nokey=1 $file.fullname
    # Hearing impaired
    $hi = ffprobe -v quiet -select_streams s -show_entries stream=:stream_disposition=hearing_impaired -of default=noprint_wrappers=1:nokey=1 $file.fullname

    $count = $subtitle.count
    for ( $i = 0; $i -lt $count; $i++) {
        $subtitle[$i] + " - " + $forced[$i] + " - " + $hi[$i]
    }
}