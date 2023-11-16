$files = Get-ChildItem ".\New folder"
ForEach ($file in $files) {
    # Get video stream codec
    ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $file.fullname
}