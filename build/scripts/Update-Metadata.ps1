Write-Output "info: UPDATEMETADATA Start"
#Movies
foreach ($path in $MEDIAmoviefolders) {
    [string[]]$extensions = "*.mkv", "*.mp4"
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -LiteralPath $path -Filter $ext -Recurse
        foreach ($file in $files) {
            $name = $file.fullname
            $oldname = $file.fullname + ".old"
            Rename-Item $name $oldname -Verbose
            ffmpeg -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c copy $name
            Remove-Item -LiteralPath $oldname -Force -Confirm:$false -Verbose
        }
    }
}

#Shows
foreach ($path in $MEDIAshowfolders) {
    [string[]]$extensions = "*.mkv", "*.mp4"
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -LiteralPath $path -Filter $ext -Recurse
        foreach ($file in $files) {
            $name = $file.fullname
            $oldname = $file.fullname + ".old"
            Rename-Item $name $oldname -Verbose
            ffmpeg -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c copy $name
            Remove-Item -LiteralPath $oldname -Force -Confirm:$false -Verbose
        }
    }
}

Write-Output "info: UPDATEMETADATA End"
Write-Output "warning: Metadata cleanup for existing media is complete. Stop the container and remove the UPDATEMETADATA environment Variable"