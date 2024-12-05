param (
    [Parameter(Mandatory = $true)][string]$DataSource
)

Write-Output "info: UPDATEMETADATA Start"

# Create temp DB if it doesn't exist.
$tempdb = '/docker-transcodeautomation/data/update-metadata.db'
if ((Test-Path $tempdb) -eq $false) {
    Write-Output "info: create update-metadata temp db"
    Invoke-SqliteQuery -Query "CREATE TABLE path (filename TEXT, fullname TEXT, tempname TEXT)" -DataSource $tempdb
}

# Update Database Log Table. This ensures update-processed is not running unnecessarily after a first run or migration of media.
$TableName = 'UpdateProcessedLog'
$daterun = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$query = "INSERT INTO $TableName (daterun) Values (`"$daterun`")"
Invoke-SqliteQuery -DataSource $DataSource -Query $query

#Movies
foreach ($path in $MEDIAmoviefolders) {
    [string[]]$extensions = "*.mkv", "*.mp4"
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -LiteralPath $path -Filter $ext -Recurse
        foreach ($file in $files) {

            # Conditional checks to ensure it is safe to proceed with the file
            $testnofiles = Get-ChildItem -LiteralPath $env:FFToolsSource -File
            $testnofiles2 = Get-ChildItem -LiteralPath $env:FFToolsTarget -File
            $transcodingfreespace = (Get-PSDrive transcoding | Select-Object @{ Name = "FreeGB"; Expression = { [math]::round(($_.free / 1gb), 2) } }).FreeGB
            $filesizemultiplied = ((Get-ChildItem -LiteralPath $file | Select-Object @{ Name = "filesizeGB"; Expression = { [math]::round(($_.length / 1gb), 3) } }).filesizeGB) * 3
            $fullname = $file.fullname
            $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
            $convert = $Probe | ConvertFrom-Json
            $filecomment = $convert.format.tags.comment

            if ($null -eq $testnofiles -and $null -eq $testnofiles2 -and $transcodingfreespace -gt $filesizemultiplied -and $filecomment -notlike "dta-*") {
                # Populate variables, copy file into processing directory, and update the tempdb
                $basename = $file.basename
                $extension = $file.extension
                $filename = $file.name
                $newcomment = (Update-Lastindex -DataSource $datasource).newcomment
                $destination = $env:FFToolsSource + "$basename$newcomment$extension"
                $tempname = "$basename$newcomment$extension"
                Copy-Item -LiteralPath $fullname $destination -Verbose

                $query = "INSERT INTO path (filename, fullname, tempname) Values (@filename, @fullname, @tempname)"
                Invoke-SqliteQuery -ErrorAction Inquire -DataSource $tempdb -Query $query -SqlParameters @{
                    filename = $filename
                    fullname = $fullname
                    tempname = $tempname
                }

                # Remux the file
                ffmpeg -hide_banner -loglevel error -stats -i $destination -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$newcomment -c copy -stats_period 60 $env:FFToolsTarget$tempname
                Remove-Item -LiteralPath $destination -Force -Confirm:$false -Verbose
                if ((Get-ChildItem -LiteralPath $env:FFToolsTarget -File).length -gt 0) {
                    Move-Item -LiteralPath "$env:FFToolsTarget$tempname" -Destination "$env:FFToolsTarget/processed" -Verbose
                }

                # Processing of file complete. Move it back and make any needed database updates
                $filestomove = Get-ChildItem "$env:FFToolsTarget/processed" -File | Select-Object name, fullname
                foreach ($filetomove in $filestomove) {
                    # Get the original sourcefile from the tempdb and move the file
                    $filetomovename = $filetomove.name
                    $filetomovefullname = $filetomove.fullname
                    $query = "Select * from path where tempname = `"$filetomovename`""
                    $filetomovedestination = (Invoke-SqliteQuery -DataSource $tempdb -Query $query).fullname
                    Move-Item -LiteralPath $filetomovefullname -Destination $filetomovedestination -Force -Confirm:$false -Verbose

                    # If file already existed in the MediaDB database and this is used due to a migration run upgrading to v4+ then update the database with the new comment.
                    $TableName = 'Movies'
                    $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $query = "Update $TableName set comment = `"$newcomment`", updatedby = 'Update-Metadata', modified = `"$modified`" WHERE fullname = `"$filetomovedestination`""
                    Invoke-SqliteQuery -DataSource $DataSource -Query $query
                }

            }
        }
    }
}

#Shows
foreach ($path in $MEDIAshowfolders) {
    [string[]]$extensions = "*.mkv", "*.mp4"
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -LiteralPath $path -Filter $ext -Recurse
        foreach ($file in $files) {

            # Conditional checks to ensure it is safe to proceed with the file
            $testnofiles = Get-ChildItem -LiteralPath $env:FFToolsSource -File
            $testnofiles2 = Get-ChildItem -LiteralPath $env:FFToolsTarget -File
            $transcodingfreespace = (Get-PSDrive transcoding | Select-Object @{ Name = "FreeGB"; Expression = { [math]::round(($_.free / 1gb), 2) } }).FreeGB
            $filesizemultiplied = ((Get-ChildItem -LiteralPath $file | Select-Object @{ Name = "filesizeGB"; Expression = { [math]::round(($_.length / 1gb), 3) } }).filesizeGB) * 3
            $fullname = $file.fullname
            $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
            $convert = $Probe | ConvertFrom-Json
            $filecomment = $convert.format.tags.comment

            if ($null -eq $testnofiles -and $null -eq $testnofiles2 -and $transcodingfreespace -gt $filesizemultiplied -and $filecomment -notlike "dta-*") {
                # Populate variables, copy file into processing directory, and update the tempdb
                $basename = $file.basename
                $extension = $file.extension
                $filename = $file.name
                $newcomment = (Update-Lastindex -DataSource $datasource).newcomment
                $destination = $env:FFToolsSource + "$basename$newcomment$extension"
                $tempname = "$basename$newcomment$extension"
                Copy-Item -LiteralPath $fullname $destination -Verbose

                $query = "INSERT INTO path (filename, fullname, tempname) Values (@filename, @fullname, @tempname)"
                Invoke-SqliteQuery -ErrorAction Inquire -DataSource $tempdb -Query $query -SqlParameters @{
                    filename = $filename
                    fullname = $fullname
                    tempname = $tempname
                }

                # Remux the file
                ffmpeg -hide_banner -loglevel error -stats -i $destination -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$newcomment -c copy -stats_period 60 $env:FFToolsTarget$tempname
                Remove-Item -LiteralPath $destination -Force -Confirm:$false -Verbose
                if ((Get-ChildItem -LiteralPath $env:FFToolsTarget -File).length -gt 0) {
                    Move-Item -LiteralPath "$env:FFToolsTarget$tempname" -Destination "$env:FFToolsTarget/processed" -Verbose
                }

                # Processing of file complete. Move it back and make any needed database updates
                $filestomove = Get-ChildItem "$env:FFToolsTarget/processed" -File | Select-Object name, fullname
                foreach ($filetomove in $filestomove) {
                    # Get the original sourcefile from the tempdb and move the file
                    $filetomovename = $filetomove.name
                    $filetomovefullname = $filetomove.fullname
                    $query = "Select * from path where tempname = `"$filetomovename`""
                    $filetomovedestination = (Invoke-SqliteQuery -DataSource $tempdb -Query $query).fullname
                    Move-Item -LiteralPath $filetomovefullname -Destination $filetomovedestination -Force -Confirm:$false -Verbose

                    # If file already existed in the MediaDB database and this is used due to a migration run upgrading to v4+ then update the database with the new comment.
                    $TableName = 'Shows'
                    $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $query = "Update $TableName set comment = `"$newcomment`", updatedby = 'Update-Metadata', modified = `"$modified`" WHERE fullname = `"$filetomovedestination`""
                    Invoke-SqliteQuery -DataSource $DataSource -Query $query
                }

            }
        }
    }
}

Write-Output "info: UPDATEMETADATA End"
Write-Output "warning: Metadata cleanup for existing media is complete. Stop the container and remove the UPDATEMETADATA environment Variable."