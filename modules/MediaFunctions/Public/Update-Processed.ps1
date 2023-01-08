<#
.Description
Updates SQL database to mark transcoded files as not transcoded if an ffprobe of those files indicates such. Occasionally running this is useful for identifying replaced/upgraded files.

.Example
Update-Processed -DataSource /docker-transcodeautomation/data/MediaDB.SQLite

.Notes
- For all db updates mark updated by and modified time
- sql query for movies/tv marked as transcoded
    - test-path fullname of transcoded file
        - If path exists
            - ffprobe transcoded file
            - If transcoded file has comment transcoded do nothing
            - If transcoded file does not have comment transcoded update sql entry with null for comment
        - elseif path doesn't exist mark null transcode comment, null filesizeMB, and filesexists false.
#>

function Update-Processed {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    # Movies
    $tablename = "Movies"
    $sqlmovies = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $TableName"
    foreach ($sqlmovie in $sqlmovies) {
        $fullname = $sqlmovie.fullname
        if (Test-Path $fullname) {
            $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
            $convert = $Probe | ConvertFrom-Json
            $comment = $convert.format.tags.comment
            if ($comment -ne 'transcoded') {
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Invoke-SqliteQuery -DataSource $DataSource -Query "Update $TableName set comment = NULL, updatedby = 'Update-Processed', modified = `"$modified`" WHERE fullname = `"$fullname`""
            }
        }
        else {
            if ($null -ne $sqlshow.comment -or $null -ne $sqlshow.filesizeMB -or $sqlshow.fileexists -ne 'false') {
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Invoke-SqliteQuery -DataSource $DataSource -Query "Update $TableName set comment = NULL, updatedby = 'Update-Processed', modified = `"$modified`", filesizeMB = NULL, fileexists = 'false' WHERE fullname = `"$fullname`""
            }
        }
    }

    # Shows
    $tablename = "Shows"
    $sqlshows = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $TableName"
    foreach ($sqlshow in $sqlshows) {
        $fullname = $sqlshow.fullname
        if (Test-Path $fullname) {
            $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
            $convert = $Probe | ConvertFrom-Json
            $comment = $convert.format.tags.comment
            if ($comment -ne 'transcoded') {
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Invoke-SqliteQuery -DataSource $DataSource -Query "Update $TableName set comment = NULL, updatedby = 'Update-Processed', modified = `"$modified`" WHERE fullname = `"$fullname`""
            }
        }
        else {
            if ($null -ne $sqlshow.comment -or $null -ne $sqlshow.filesizeMB -or $sqlshow.fileexists -ne 'false') {
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Invoke-SqliteQuery -DataSource $DataSource -Query "Update $TableName set comment = NULL, updatedby = 'Update-Processed', modified = `"$modified`", filesizeMB = NULL, fileexists = 'false' WHERE fullname = `"$fullname`""
            }
        }
    }
}