# Updates the database for any missing tables
$DataSource = "/docker-transcodeautomation/data/MediaDB.SQLite"


Write-Output "[+] Update-Database Start"

# Check for and Create StatisticsLive Table IF NOT EXISTS
$Tablename = "StatisticsLive"
$Query = "CREATE TABLE IF NOT EXISTS $Tablename (tablename TEXT, mediacount NUMERIC, oldsizeMB NUMERIC, newsizeMB NUMERIC, differenceMB NUMERIC, percent NUMERIC, existssumsizeMB NUMERIC, existsoldsizeMB NUMERIC, existsnewsizeMB NUMERIC, existsdifferenceMB NUMERIC, existspercent NUMERIC, added DATETIME, updatedby TEXT, growth30daysMB NUMERIC, growth90daysMB NUMERIC, growth180daysMB NUMERIC, growth365daysMB NUMERIC)"
Invoke-SqliteQuery -Query $Query -DataSource $DataSource

# Check for and Create UpdateProcessedLog
$Tablename = "UpdateProcessedLog"
$Query = "CREATE TABLE IF NOT EXISTS $Tablename (daterun DATETIME)"
Invoke-SqliteQuery -Query $Query -DataSource $DataSource

Write-Output "[+] Update-Database End"