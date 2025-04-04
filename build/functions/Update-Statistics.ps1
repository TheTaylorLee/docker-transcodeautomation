<#
.SYNOPSIS
    Updates the statistics for Movies and Shows in the database.

.DESCRIPTION
    The Update-Statistics function updates the statistics for Movies and Shows in the database.
    It updates the statistics table if it hasn't been updated in the last 24 hours or if the -force switch is used.
    It also updates the StatisticsLive table with the latest statistics.

.PARAMETER DataSource
    The path to the SQLite database file.

.PARAMETER force
    A switch to force the update of the statistics table regardless of the last update time.

.EXAMPLE
    Update-Statistics -DataSource $datasource

    This example updates the statistics for the specified database.

.EXAMPLE
    Update-Statistics -DataSource $datasource -force

    This example forces the update of the statistics for the specified database.
#>

function Update-Statistics {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string]$DataSource,
        [Parameter(Mandatory = $false)][switch]$force
    )

    #Used in debug logs
    Write-Output "info: Update-Statistics Start"


    # Update statistics (history) table only if not updated in over 24 hours
    $tablename = "Statistics"
    $query = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename" | Where-Object { $_.added -gt (Get-Date).AddDays(-1) }

    if ($null -eq $query -or $force) {
        Write-Output "info: Updating Statistics Table"
        #Movies
        $tablename = "Movies"
        $media = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename"
        $mediaexists = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename Where fileexists = 'true'"

        $query = "INSERT INTO Statistics (tablename, mediacount, oldsizeMB, newsizeMB, differenceMB, percent, existssumsizeMB, existsoldsizeMB, existsnewsizeMB, existsdifferenceMB, existspercent, added, updatedby, growth30daysMB, growth90daysMB, growth180daysMB, growth365daysMB) Values
    (@tablename, @mediacount, @oldsizeMB, @newsizeMB, @differenceMB, @percent, @existssumsizeMB, @existsoldsizeMB, @existsnewsizeMB, @existsdifferenceMB, @existspercent, @added, @updatedby, @growth30daysMB, @growth90daysMB, @growth180daysMB, @growth365daysMB)"

        Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
            tablename          = $tablename
            mediacount         = $mediaexists.count
            oldsizeMB          = [math]::Round(($media.oldsizeMB | Measure-Object -Sum).sum, 2)
            newsizeMB          = [math]::Round(($media.newsizeMB | Measure-Object -Sum).sum, 2)
            differenceMB       = [math]::Round((($media.oldsizeMB | Measure-Object -Sum).sum - ($media.newsizeMB | Measure-Object -Sum).sum), 2)
            percent            = [math]::Round(((100 / ($media.oldsizeMB | Measure-Object -Sum).sum) * ($media.newsizeMB | Measure-Object -Sum).sum), 2)
            existssumsizeMB    = [math]::Round(($mediaexists.filesizeMB | Measure-Object -Sum).sum, 2)
            existsoldsizeMB    = [math]::Round(($mediaexists.oldsizeMB | Measure-Object -Sum).sum, 2)
            existsnewsizeMB    = [math]::Round(($mediaexists.newsizeMB | Measure-Object -Sum).sum, 2)
            existsdifferenceMB = [math]::Round((($mediaexists.oldsizeMB | Measure-Object -Sum).sum - ($mediaexists.newsizeMB | Measure-Object -Sum).sum), 2)
            existspercent      = [math]::Round(((100 / ($mediaexists.oldsizeMB | Measure-Object -Sum).sum) * ($mediaexists.newsizeMB | Measure-Object -Sum).sum), 2)
            added              = Get-Date
            updatedby          = "Update-Statistics"
            growth30daysMB     = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-30) }).newsizemb | Measure-Object -Sum).sum, 2)
            growth90daysMB     = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-90) }).newsizemb | Measure-Object -Sum).sum, 2)
            growth180daysMB    = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-180) }).newsizemb | Measure-Object -Sum).sum, 2)
            growth365daysMB    = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-365) }).newsizemb | Measure-Object -Sum).sum, 2)
        }

        #Shows
        $tablename = "Shows"
        $media = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename"
        $mediaexists = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename Where fileexists = 'true'"

        $query = "INSERT INTO Statistics (tablename, mediacount, oldsizeMB, newsizeMB, differenceMB, percent, existssumsizeMB, existsoldsizeMB, existsnewsizeMB, existsdifferenceMB, existspercent, added, updatedby, growth30daysMB, growth90daysMB, growth180daysMB, growth365daysMB) Values
    (@tablename, @mediacount, @oldsizeMB, @newsizeMB, @differenceMB, @percent, @existssumsizeMB, @existsoldsizeMB, @existsnewsizeMB, @existsdifferenceMB, @existspercent, @added, @updatedby, @growth30daysMB, @growth90daysMB, @growth180daysMB, @growth365daysMB)"

        Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
            tablename          = $tablename
            mediacount         = $mediaexists.count
            oldsizeMB          = [math]::Round(($media.oldsizeMB | Measure-Object -Sum).sum, 2)
            newsizeMB          = [math]::Round(($media.newsizeMB | Measure-Object -Sum).sum, 2)
            differenceMB       = [math]::Round((($media.oldsizeMB | Measure-Object -Sum).sum - ($media.newsizeMB | Measure-Object -Sum).sum), 2)
            percent            = [math]::Round(((100 / ($media.oldsizeMB | Measure-Object -Sum).sum) * ($media.newsizeMB | Measure-Object -Sum).sum), 2)
            existssumsizeMB    = [math]::Round(($mediaexists.filesizeMB | Measure-Object -Sum).sum, 2)
            existsoldsizeMB    = [math]::Round(($mediaexists.oldsizeMB | Measure-Object -Sum).sum, 2)
            existsnewsizeMB    = [math]::Round(($mediaexists.newsizeMB | Measure-Object -Sum).sum, 2)
            existsdifferenceMB = [math]::Round((($mediaexists.oldsizeMB | Measure-Object -Sum).sum - ($mediaexists.newsizeMB | Measure-Object -Sum).sum), 2)
            existspercent      = [math]::Round(((100 / ($mediaexists.oldsizeMB | Measure-Object -Sum).sum) * ($mediaexists.newsizeMB | Measure-Object -Sum).sum), 2)
            added              = Get-Date
            updatedby          = "Update-Statistics"
            growth30daysMB     = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-30) }).newsizemb | Measure-Object -Sum).sum, 2)
            growth90daysMB     = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-90) }).newsizemb | Measure-Object -Sum).sum, 2)
            growth180daysMB    = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-180) }).newsizemb | Measure-Object -Sum).sum, 2)
            growth365daysMB    = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-365) }).newsizemb | Measure-Object -Sum).sum, 2)
        }
    }

    # Drop StatisticsLive table and create new record. This will provide updated statistics each run instead of every 24 hours
    Write-Output "info: Updating StatisticsLive Table"
    Invoke-SqliteQuery -DataSource $DataSource -Query "DELETE FROM StatisticsLive"

    #Movies into StatisticsLive
    $tablename = "Movies"
    $media = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename"
    $mediaexists = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename Where fileexists = 'true'"

    $query = "INSERT INTO StatisticsLive (tablename, mediacount, oldsizeMB, newsizeMB, differenceMB, percent, existssumsizeMB, existsoldsizeMB, existsnewsizeMB, existsdifferenceMB, existspercent, added, updatedby, growth30daysMB, growth90daysMB, growth180daysMB, growth365daysMB) Values
    (@tablename, @mediacount, @oldsizeMB, @newsizeMB, @differenceMB, @percent, @existssumsizeMB, @existsoldsizeMB, @existsnewsizeMB, @existsdifferenceMB, @existspercent, @added, @updatedby, @growth30daysMB, @growth90daysMB, @growth180daysMB, @growth365daysMB)"

    Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
        tablename          = $tablename
        mediacount         = $mediaexists.count
        oldsizeMB          = [math]::Round(($media.oldsizeMB | Measure-Object -Sum).sum, 2)
        newsizeMB          = [math]::Round(($media.newsizeMB | Measure-Object -Sum).sum, 2)
        differenceMB       = [math]::Round((($media.oldsizeMB | Measure-Object -Sum).sum - ($media.newsizeMB | Measure-Object -Sum).sum), 2)
        percent            = [math]::Round(((100 / ($media.oldsizeMB | Measure-Object -Sum).sum) * ($media.newsizeMB | Measure-Object -Sum).sum), 2)
        existssumsizeMB    = [math]::Round(($mediaexists.filesizeMB | Measure-Object -Sum).sum, 2)
        existsoldsizeMB    = [math]::Round(($mediaexists.oldsizeMB | Measure-Object -Sum).sum, 2)
        existsnewsizeMB    = [math]::Round(($mediaexists.newsizeMB | Measure-Object -Sum).sum, 2)
        existsdifferenceMB = [math]::Round((($mediaexists.oldsizeMB | Measure-Object -Sum).sum - ($mediaexists.newsizeMB | Measure-Object -Sum).sum), 2)
        existspercent      = [math]::Round(((100 / ($mediaexists.oldsizeMB | Measure-Object -Sum).sum) * ($mediaexists.newsizeMB | Measure-Object -Sum).sum), 2)
        added              = Get-Date
        updatedby          = "Update-Statistics"
        growth30daysMB     = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-30) }).newsizemb | Measure-Object -Sum).sum, 2)
        growth90daysMB     = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-90) }).newsizemb | Measure-Object -Sum).sum, 2)
        growth180daysMB    = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-180) }).newsizemb | Measure-Object -Sum).sum, 2)
        growth365daysMB    = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-365) }).newsizemb | Measure-Object -Sum).sum, 2)
    }

    #Shows into StatisticsLive
    $tablename = "Shows"
    $media = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename"
    $mediaexists = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename Where fileexists = 'true'"

    $query = "INSERT INTO StatisticsLive (tablename, mediacount, oldsizeMB, newsizeMB, differenceMB, percent, existssumsizeMB, existsoldsizeMB, existsnewsizeMB, existsdifferenceMB, existspercent, added, updatedby, growth30daysMB, growth90daysMB, growth180daysMB, growth365daysMB) Values
    (@tablename, @mediacount, @oldsizeMB, @newsizeMB, @differenceMB, @percent, @existssumsizeMB, @existsoldsizeMB, @existsnewsizeMB, @existsdifferenceMB, @existspercent, @added, @updatedby, @growth30daysMB, @growth90daysMB, @growth180daysMB, @growth365daysMB)"

    Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
        tablename          = $tablename
        mediacount         = $mediaexists.count
        oldsizeMB          = [math]::Round(($media.oldsizeMB | Measure-Object -Sum).sum, 2)
        newsizeMB          = [math]::Round(($media.newsizeMB | Measure-Object -Sum).sum, 2)
        differenceMB       = [math]::Round((($media.oldsizeMB | Measure-Object -Sum).sum - ($media.newsizeMB | Measure-Object -Sum).sum), 2)
        percent            = [math]::Round(((100 / ($media.oldsizeMB | Measure-Object -Sum).sum) * ($media.newsizeMB | Measure-Object -Sum).sum), 2)
        existssumsizeMB    = [math]::Round(($mediaexists.filesizeMB | Measure-Object -Sum).sum, 2)
        existsoldsizeMB    = [math]::Round(($mediaexists.oldsizeMB | Measure-Object -Sum).sum, 2)
        existsnewsizeMB    = [math]::Round(($mediaexists.newsizeMB | Measure-Object -Sum).sum, 2)
        existsdifferenceMB = [math]::Round((($mediaexists.oldsizeMB | Measure-Object -Sum).sum - ($mediaexists.newsizeMB | Measure-Object -Sum).sum), 2)
        existspercent      = [math]::Round(((100 / ($mediaexists.oldsizeMB | Measure-Object -Sum).sum) * ($mediaexists.newsizeMB | Measure-Object -Sum).sum), 2)
        added              = Get-Date
        updatedby          = "Update-Statistics"
        growth30daysMB     = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-30) }).newsizemb | Measure-Object -Sum).sum, 2)
        growth90daysMB     = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-90) }).newsizemb | Measure-Object -Sum).sum, 2)
        growth180daysMB    = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-180) }).newsizemb | Measure-Object -Sum).sum, 2)
        growth365daysMB    = [math]::Round((($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-365) }).newsizemb | Measure-Object -Sum).sum, 2)
    }

    #Used in debug logs
    Write-Output "info: Update-Statistics End"
}