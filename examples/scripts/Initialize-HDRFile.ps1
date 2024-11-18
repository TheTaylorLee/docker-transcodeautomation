$video = "HDRTestfile.mkv"
New-Item out -ItemType Directory
ffmpeg -i $video -metadata comment="" -c copy .\out\$video
(Get-ChildItem -LiteralPath $video).lastwritetime = (Get-Date).AddDays(-1)