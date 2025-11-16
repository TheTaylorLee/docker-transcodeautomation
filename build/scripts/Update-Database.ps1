# Updates the database for any missing tables
$DataSource = "/docker-transcodeautomation/data/media.db"


Write-Output "info: Update-Database Start"

# Check for and Create StatisticsLive Table IF NOT EXISTS
$Tablename = "StatisticsLive"
$Query = "CREATE TABLE IF NOT EXISTS $Tablename (tablename TEXT, mediacount NUMERIC, oldsizeMB NUMERIC, newsizeMB NUMERIC, differenceMB NUMERIC, percent NUMERIC, existssumsizeMB NUMERIC, existsoldsizeMB NUMERIC, existsnewsizeMB NUMERIC, existsdifferenceMB NUMERIC, existspercent NUMERIC, added DATETIME, updatedby TEXT, growth30daysMB NUMERIC, growth90daysMB NUMERIC, growth180daysMB NUMERIC, growth365daysMB NUMERIC)"
Invoke-SqliteQuery -Query $Query -DataSource $DataSource

# Check for and Create UpdateProcessedLog
$Tablename = "UpdateProcessedLog"
$Query = "CREATE TABLE IF NOT EXISTS $Tablename (daterun DATETIME)"
Invoke-SqliteQuery -Query $Query -DataSource $DataSource

## Update descriptions table if entry doesn't exists
$Tablename = "Descriptions"
[string]$checkQuery = "SELECT * FROM $TableName WHERE columnname = 'daterun' AND tablename = 'UpdateProcessedLog'"
$result = Invoke-SqliteQuery -DataSource $DataSource -Query $checkQuery

if ($null -eq $result) {
    [string]$query = "INSERT INTO $TableName (columnname, description, tablename) Values ('daterun', 'tracks last run of the update-processed script, so it does not run again in the minimum delay period', 'UpdateProcessedLog')"
    Invoke-SqliteQuery -DataSource $DataSource -Query $query
}

# Check for and Create ImmutableIndex
$Tablename = "ImmutableIndex"
$Query = "CREATE TABLE IF NOT EXISTS $Tablename (lastindex TEXT)"
Invoke-SqliteQuery -Query $Query -DataSource $DataSource

## Add initial entry to ImmutableIndex if it doesn't exists
[string]$checkQuery = "SELECT * FROM $TableName"
$result = Invoke-SqliteQuery -DataSource $DataSource -Query $checkQuery

if ($null -eq $result) {
    [string]$query = "INSERT INTO $TableName (lastindex) Values ('0000000000')"
    Invoke-SqliteQuery -DataSource $DataSource -Query $query
}

## Update descriptions table if entry doesn't exists
$Tablename = "Descriptions"
[string]$checkQuery = "SELECT * FROM $TableName WHERE columnname = 'lastindex' AND tablename = 'ImmutableIndex'"
$result = Invoke-SqliteQuery -DataSource $DataSource -Query $checkQuery

if ($null -eq $result) {
    [string]$query = "INSERT INTO $TableName (columnname, description, tablename) Values ('lastindex', 'last index used for the previous transcoded file', 'ImmutableIndex')"
    Invoke-SqliteQuery -DataSource $DataSource -Query $query
}

$Tablename = "Descriptions"
[string]$checkQuery = "SELECT * FROM $TableName WHERE columnname = 'transcodeskipreason' AND tablename = 'movies'"
$result = Invoke-SqliteQuery -DataSource $DataSource -Query $checkQuery

if ($null -eq $result) {
    [string]$query = "INSERT INTO $TableName (columnname, description, tablename) Values ('transcodeskipreason', 'reason why a file was not transcoded', 'movies')"
    Invoke-SqliteQuery -DataSource $DataSource -Query $query
}

$Tablename = "Descriptions"
[string]$checkQuery = "SELECT * FROM $TableName WHERE columnname = 'transcodeskipreason' AND tablename = 'shows'"
$result = Invoke-SqliteQuery -DataSource $DataSource -Query $checkQuery

if ($null -eq $result) {
    [string]$query = "INSERT INTO $TableName (columnname, description, tablename) Values ('transcodeskipreason', 'reason why a file was not transcoded', 'shows')"
    Invoke-SqliteQuery -DataSource $DataSource -Query $query
}

# update shows and movies to add a column for transcodeskipreason
$Tablename = "movies"
$Query = "PRAGMA table_info($Tablename)"
$result = Invoke-SqliteQuery -Query $Query -DataSource $DataSource
if ($result.name -notcontains "transcodeskipreason") {
    $Query = "ALTER TABLE $Tablename ADD COLUMN transcodeskipreason TYPE TEXT"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource
}

$Tablename = "shows"
$Query = "PRAGMA table_info($Tablename)"
$result = Invoke-SqliteQuery -Query $Query -DataSource $DataSource
if ($result.name -notcontains "transcodeskipreason") {
    $Query = "ALTER TABLE $Tablename ADD COLUMN transcodeskipreason TYPE TEXT"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource
}

Write-Output "info: Update-Database End"