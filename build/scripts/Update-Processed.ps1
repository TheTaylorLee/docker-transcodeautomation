Write-Output "info: Update-Processed Start"

[string]$DataSource = "/docker-transcodeautomation/data/MediaDB.SQLite"

# Test to see if update-processed has run in the last 7 days
$getcount = Invoke-SqliteQuery -DataSource $DataSource -Query "select * from UpdateProcessedLog"
if ($null -eq $getcount) {
    $queryrun = $null
}
else {
    [int]$i = $getcount.count - 1
    $queryrun = (Invoke-SqliteQuery -DataSource $DataSource -Query "select * from UpdateProcessedLog")[$i] |
        Where-Object { $_.daterun -gt (Get-Date).AddDays(-7) }
}

# If not run in the last 7 days, then update-processed
if ($null -eq $queryrun) {
    $startdt = Get-Date
    Write-Output "info: Update-Processed media check started at $startdt"

    # Movies
    $tablename = "Movies"
    $sqlmovies = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $TableName"
    foreach ($sqlmovie in $sqlmovies) {
        $fullname = $sqlmovie.fullname
        if (Test-Path -LiteralPath "$fullname") {
            $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
            $convert = $Probe | ConvertFrom-Json
            $comment = $convert.format.tags.comment
            if ($comment -notlike "dta-*") {
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Invoke-SqliteQuery -DataSource $DataSource -Query "Update $TableName set comment = NULL, updatedby = 'Update-Processed', modified = `"$modified`" WHERE fullname = `"$fullname`""
            }
        }
        else {
            if ($null -ne $sqlmovie.comment -or $null -ne $sqlmovie.filesizeMB -or $sqlmovie.fileexists -ne 'false') {
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
        if (Test-Path -LiteralPath "$fullname") {
            $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
            $convert = $Probe | ConvertFrom-Json
            $comment = $convert.format.tags.comment
            if ($comment -notlike "dta-*") {
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

    # Update Database Log Table
    $TableName = 'UpdateProcessedLog'
    $daterun = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $query = "INSERT INTO $TableName (daterun) Values (`"$daterun`")"
    Invoke-SqliteQuery -DataSource $DataSource -Query $query

    $enddt = Get-Date
    Write-Output "info: Update-Processed media check ended at $enddt"
}

Write-Output "info: Update-Processed End"