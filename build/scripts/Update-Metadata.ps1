param (
    [Parameter(Mandatory = $true)][string]$DataSource
)

Write-Output "info: UPDATEMETADATA Start"

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
            $comment = (Update-Lastindex -DataSource $datasource).newcomment
            $fullname = $file.fullname
            $oldname = $file.fullname + ".old"
            Rename-Item $fullname $oldname -Verbose
            ffmpeg -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$comment -c copy $fullname
            Remove-Item -LiteralPath $oldname -Force -Confirm:$false -Verbose

            # If file already existed in the database and this is used due to a migration run upgrading to v4+ then update the database with the new comment.
            $TableName = 'Movies'
            $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $query = "Update $TableName set comment = `"$comment`", updatedby = 'Update-Metadata', modified = `"$modified`" WHERE fullname = `"$fullname`""
            Invoke-SqliteQuery -DataSource $DataSource -Query $query
        }
    }
}

#Shows
foreach ($path in $MEDIAshowfolders) {
    [string[]]$extensions = "*.mkv", "*.mp4"
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -LiteralPath $path -Filter $ext -Recurse
        foreach ($file in $files) {
            $comment = (Update-Lastindex -DataSource $datasource).newcomment
            $fullname = $file.fullname
            $oldname = $file.fullname + ".old"
            Rename-Item $fullname $oldname -Verbose
            ffmpeg -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$comment -c copy $fullname
            Remove-Item -LiteralPath $oldname -Force -Confirm:$false -Verbose

            # If file already existed in the database and this is used due to a migration run upgrading to v4+ then update the database with the new comment.
            $TableName = 'Shows'
            $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $query = "Update $TableName set comment = `"$comment`", updatedby = 'Update-Metadata', modified = `"$modified`" WHERE fullname = `"$fullname`""
            Invoke-SqliteQuery -DataSource $DataSource -Query $query
        }
    }
}

Write-Output "info: UPDATEMETADATA End"
Write-Output "warning: Metadata cleanup for existing media is complete. Stop the container and remove the UPDATEMETADATA environment Variable"