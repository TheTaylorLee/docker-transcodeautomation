Write-Output "[+] UPDATEMETADATA Start"
#Movies
foreach ($path in $MEDIAmoviefolders) {
    [string[]]$extensions = "*.mkv", "*.mp4"
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -Path $path -Filter $ext -Recurse
        foreach ($file in $files) {
            $name = $file.fullname
            $oldname = $file.fullname + ".old"
            Rename-Item $name $oldname -Verbose
            ffmpeg -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c copy $name
            Remove-Item $oldname -Force -Confirm:$false -Verbose
        }
    }
}

#Shows
foreach ($path in $MEDIAshowfolders) {
    [string[]]$extensions = "*.mkv", "*.mp4"
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -Path $path -Filter $ext -Recurse
        foreach ($file in $files) {
            $name = $file.fullname
            $oldname = $file.fullname + ".old"
            Rename-Item $name $oldname -Verbose
            ffmpeg -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c copy $name
            Remove-Item $oldname -Force -Confirm:$false -Verbose
        }
    }
}

Write-Warning "[-] Metadata cleanup for existing media is complete. Stop the container and remove the UPDATEMETADATA environment Variable"
Write-Output "[+] UPDATEMETADATA End"
