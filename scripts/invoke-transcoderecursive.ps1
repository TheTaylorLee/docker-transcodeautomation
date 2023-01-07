# MUST FIRST UPDATE PATH VARIABLE AND THEN RUN ONE OF THESE SCRIPTS
# MUST BE RUN IN POWERSHELL. SNAP or your package manager of choice can be used to install PowerShell
$path = "/folderpath"


#Single folder
[string[]]$extensions = "*.wma", "*.mkv", "*.avi", "*.wmv", "*.m4v", "*.mov", "*.mpg", "*.mp4"
foreach ($ext in $extensions) {
    $files = Get-ChildItem -Path $path -Filter $ext -Recurse
    foreach ($file in $files) {
        $name = $file.fullname
        $oldname = $file.fullname + ".old"
        Rename-Item $name $oldname
        ffmpeg -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c copy $name
        Remove-Item $oldname -Force -Confirm:$false
    }
}

#multiple folders
$folders = Get-ChildItem $path -Directory | Select-Object name, fullname
foreach ($folder in $folders) {
    [string[]]$extensions = "*.wma", "*.mkv", "*.avi", "*.wmv", "*.m4v", "*.mov", "*.mpg", "*.mp4"
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -Path $folder.fullname -Filter $ext -Recurse
        foreach ($file in $files) {
            $name = $file.fullname
            $oldname = $file.fullname + ".old"
            $Probe = ffprobe -loglevel 0 -print_format json -show_format $name
            $convert = $Probe | ConvertFrom-Json
            if ($convert.format.tags.COMMENT -eq "transcoded") {
                Write-Output "Already transcoded $name" | Out-File $env:USERPROFILE\desktop\transcode.log -Append
            }
            else {
                Write-Output "Transcoding $name" | Out-File $env:USERPROFILE\desktop\transcode.log -Append
                Rename-Item $name $oldname
                ffmpeg -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c copy $name
                Remove-Item $oldname -Force -Confirm:$false
            }
        }
    }
}