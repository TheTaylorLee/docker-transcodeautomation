function Invoke-DBSetup {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$DataSource
    )

    #Used in debug logs
    Write-Output "info: Invoke-DBSetup Start"

    # Create Movies Table
    $Tablename = "Movies"
    $Query = "CREATE TABLE $TableName (filename TEXT, fullname TEXT, directory TEXT, comment TEXT, added DATETIME, modified DATETIME, filesizeMB NUMERIC, oldsizeMB NUMERIC, newsizeMB NUMERIC, fileexists TEXT, updatedby TEXT)"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource

    # Create Shows Table
    $Tablename = "Shows"
    $Query = "CREATE TABLE $TableName (filename TEXT, fullname TEXT, directory TEXT, comment TEXT, added DATETIME, modified DATETIME, filesizeMB NUMERIC, oldsizeMB NUMERIC, newsizeMB NUMERIC, fileexists TEXT, updatedby TEXT)"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource

    # Create Descriptions Table
    $Tablename = "Descriptions"
    $Query = "CREATE TABLE $Tablename (columnname TEXT, description TEXT, tablename TEXT)"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource

    [string]$query = "INSERT INTO $TableName (columnname, description, tablename) Values ('filename', 'name of the media file minus the path','Movies'),
('fullname', 'name of the media file plus the file path','Movies'),
('directory', 'directory containing the media file','Movies'),
('comment', 'comment tag metadata of media file','Movies'),
('added', 'date and time file is first added to the table','Movies'),
('modified', 'date and time the table entry was last modified','Movies'),
('filesizeMB', 'current file size of media file. useful for reporting if file existed prior to database implementation and wanting to be able to use file size in reports sans oldsizeMB and newsizeMB.','Movies'),
('oldsizeMB', 'old file size of media file','Movies'),
('newsizeMB', 'new file size of media file','Movies'),
('fileexists', 'true if filename exists otherwise false','Movies'),
('updatedby', 'function that last updated the table entry. could prove useful if troubleshooting bad table updates.','Movies'),
('filename', 'name of the media file minus the path','Shows'),
('fullname', 'name of the media file plus the file path','Shows'),
('directory', 'directory containing the media file','Shows'),
('comment', 'comment tag metadata of media file','Shows'),
('added', 'date and time file is first added to the table','Shows'),
('modified', 'date and time the table entry was last modified','Shows'),
('filesizeMB', 'current file size of media file. useful for reporting if file existed prior to database implementation and wanting to be able to use file size in reports sans oldsizeMB and newsizeMB.','Shows'),
('oldsizeMB', 'old file size of media file','Shows'),
('newsizeMB', 'new file size of media file','Shows'),
('fileexists', 'true if filename exists otherwise false','Shows'),
('updatedby', 'function that last updated the table entry. could prove useful if troubleshooting bad table updates.','Shows'),
('tablename', 'name of the table the stats are for', 'Statistics'),
('mediacount', 'total number of existing media files', 'Statistics'),
('oldsizeMB', 'old size of media that had been transcoded. regardless of if file still exists.', 'Statistics'),
('newsizeMB', 'new size of media that had been transcoded. regardless of if file still exists.', 'Statistics'),
('differenceMB', 'amount of space saved by transcoding the media. regardless of if file still exists.', 'Statistics'),
('percent', 'percent of new size as compared to old size of media. regardless of if file still exists.', 'Statistics'),
('existssumsizeMB', 'total size of existing media files', 'Statistics'),
('existsoldsizeMB', 'old size of media that had been transcoded. only if it still exists.', 'Statistics'),
('existsnewsizeMB', 'new size of media that had been transcoded. only if it still exists.', 'Statistics'),
('existsdifferenceMB', 'amount of space saved by transcoding the media. only if it still exists.', 'Statistics'),
('existspercent', 'percent of new size as compared to old size of media. only if file still exists.', 'Statistics'),
('added', 'date the table entry was added', 'Statistics'),
('updatedby', 'function that last updated the table entry. could prove useful if troubleshooting bad table updates.', 'Statistics'),
('growth30daysMB', 'this shows how much storage usage has increased in the past x days for existing media only', 'Statistics'),
('growth90daysMB', 'this shows how much storage usage has increased in the past x days for existing media only', 'Statistics'),
('growth180daysMB', 'this shows how much storage usage has increased in the past x days for existing media only', 'Statistics'),
('growth365daysMB', 'this shows how much storage usage has increased in the past x days for existing media only', 'Statistics'),
('daterun', 'tracks last run of the update-processed script, so it does not run again in the minimum delay period', 'UpdateProcessedLog'),
('nextindex', 'next index to be used for the next transcoded file', 'ImmutableIndex')"

    Invoke-SqliteQuery -DataSource $DataSource -Query $query

    # Create Statistics Table
    $Tablename = "Statistics"
    $Query = "CREATE TABLE $Tablename (tablename TEXT, mediacount NUMERIC, oldsizeMB NUMERIC, newsizeMB NUMERIC, differenceMB NUMERIC, percent NUMERIC, existssumsizeMB NUMERIC, existsoldsizeMB NUMERIC, existsnewsizeMB NUMERIC, existsdifferenceMB NUMERIC, existspercent NUMERIC, added DATETIME, updatedby TEXT, growth30daysMB NUMERIC, growth90daysMB NUMERIC, growth180daysMB NUMERIC, growth365daysMB NUMERIC)"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource

    # Create StatisticsLive Table
    $Tablename = "StatisticsLive"
    $Query = "CREATE TABLE $Tablename (tablename TEXT, mediacount NUMERIC, oldsizeMB NUMERIC, newsizeMB NUMERIC, differenceMB NUMERIC, percent NUMERIC, existssumsizeMB NUMERIC, existsoldsizeMB NUMERIC, existsnewsizeMB NUMERIC, existsdifferenceMB NUMERIC, existspercent NUMERIC, added DATETIME, updatedby TEXT, growth30daysMB NUMERIC, growth90daysMB NUMERIC, growth180daysMB NUMERIC, growth365daysMB NUMERIC)"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource

    # Check for and Create UpdateProcessedLog
    $Tablename = "UpdateProcessedLog"
    $Query = "CREATE TABLE $Tablename (daterun DATETIME)"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource

    # Check for and Create ImmutableIndex
    $Tablename = "ImmutableIndex"
    $Query = "CREATE TABLE $Tablename (nextindext TEXT)"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource

    ## Add initial entry to ImmutableIndex if it doesn't exists
    [string]$query = "INSERT INTO $TableName (nextindex) Values ('dta-0000000000')"
    Invoke-SqliteQuery -DataSource $DataSource -Query $query

    # Create Views
    $query = "CREATE VIEW View_Movies_ExistsTrue AS
SELECT *
FROM Movies
WHERE fileexists = 'true'
ORDER BY modified DESC;

CREATE VIEW View_Movies_ExistsFalse AS
SELECT *
FROM Movies
WHERE fileexists = 'false'
ORDER BY modified DESC;

CREATE VIEW View_Shows_ExistsTrue AS
SELECT *
FROM Shows
WHERE fileexists = 'true'
ORDER BY modified DESC;

CREATE VIEW View_Shows_ExistsFalse AS
SELECT *
FROM Shows
WHERE fileexists = 'false'
ORDER BY modified DESC;

CREATE VIEW View_Statistics_Movies AS
SELECT *
FROM Statistics
WHERE tablename = 'Movies'
ORDER BY added DESC;

CREATE VIEW View_Statistics_Shows AS
SELECT *
FROM Statistics
WHERE tablename = 'Shows'
ORDER BY added DESC;
"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource

    #Used in debug logs
    Write-Output "info: Invoke-DBSetup End"
}