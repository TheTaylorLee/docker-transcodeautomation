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
            $testnofiles = Get-ChildItem -LiteralPath $env:FFToolsSource -File
            $testnofiles2 = Get-ChildItem -LiteralPath $env:FFToolsTarget -File
            if ($null -eq $testnofiles -and $null -eq $testnofiles2) {
                $fullname = $file.fullname
                $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
                $convert = $Probe | ConvertFrom-Json
                $filecomment = $convert.format.tags.comment

                if ($filecomment -notlike "dta-*") {
                    $basename = $file.basename
                    $extension = $file.extension
                    $fullname = $file.fullname
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

                    # continue from here with remuxing
                    Rename-Item $fullname $oldname -Verbose
                    ffmpeg -hide_banner -loglevel error -stats -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$newcomment -c copy -stats_period 60 $fullname
                    Remove-Item -LiteralPath $oldname -Force -Confirm:$false -Verbose

                    # If file already existed in the database and this is used due to a migration run upgrading to v4+ then update the database with the new comment.
                    $TableName = 'Movies'
                    $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $query = "Update $TableName set comment = `"$newcomment`", updatedby = 'Update-Metadata', modified = `"$modified`" WHERE fullname = `"$fullname`""
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
            $testnofiles = Get-ChildItem -LiteralPath $env:FFToolsSource -File
            $testnofiles2 = Get-ChildItem -LiteralPath $env:FFToolsTarget -File
            if ($null -eq $testnofiles -and $null -eq $testnofiles2) {
                $fullname = $file.fullname
                $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
                $convert = $Probe | ConvertFrom-Json
                $filecomment = $convert.format.tags.comment

                if ($filecomment -notlike "dta-*") {
                    $basename = $file.basename
                    $extension = $file.extension
                    $fullname = $file.fullname
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

                    # continue from here with remuxing
                    Rename-Item $fullname $oldname -Verbose
                    ffmpeg -hide_banner -loglevel error -stats -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$newcomment -c copy -stats_period 60 $fullname
                    Remove-Item -LiteralPath $oldname -Force -Confirm:$false -Verbose

                    # If file already existed in the database and this is used due to a migration run upgrading to v4+ then update the database with the new comment.
                    $TableName = 'Shows'
                    $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $query = "Update $TableName set comment = `"$newcomment`", updatedby = 'Update-Metadata', modified = `"$modified`" WHERE fullname = `"$fullname`""
                    Invoke-SqliteQuery -DataSource $DataSource -Query $query
                }
            }
        }
    }
}

Write-Output "info: UPDATEMETADATA End"
Write-Output "warning: Metadata cleanup for existing media is complete. Stop the container and remove the UPDATEMETADATA environment Variable"