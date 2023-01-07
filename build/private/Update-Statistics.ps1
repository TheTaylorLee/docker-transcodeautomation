function Update-Statistics {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string]$DataSource,
        [Parameter(Mandatory = $false)][switch]$force,
        [Parameter(Mandatory = $false)][switch]$livestats
    )

    #Used in debug logs
    Write-Output "Update-Statistics Start"

    if ($livestats) {
        $tablename = "Movies"
        $media = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename"
        $mediaexists = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename Where fileexists = 'true'"

        [pscustomobject]@{
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
            growth30daysMB     = (($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-30) }).newsizemb | Measure-Object -Sum).sum
            growth90daysMB     = (($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-90) }).newsizemb | Measure-Object -Sum).sum
            growth180daysMB    = (($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-180) }).newsizemb | Measure-Object -Sum).sum
            growth365daysMB    = (($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-365) }).newsizemb | Measure-Object -Sum).sum
        }

        $tablename = "Shows"
        $media = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename"
        $mediaexists = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename Where fileexists = 'true'"

        [pscustomobject]@{
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
            growth30daysMB     = (($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-30) }).newsizemb | Measure-Object -Sum).sum
            growth90daysMB     = (($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-90) }).newsizemb | Measure-Object -Sum).sum
            growth180daysMB    = (($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-180) }).newsizemb | Measure-Object -Sum).sum
            growth365daysMB    = (($mediaexists | Where-Object { $_.added -gt (Get-Date).AddDays(-365) }).newsizemb | Measure-Object -Sum).sum
        }
    }

    else {
        # Update statistics only if not updated in over 24 hours
        $tablename = "Statistics"
        $query = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename" | Where-Object { $_.added -gt (Get-Date).AddDays(-1) }

        if ($null -eq $query -or $force) {
            #Movies
            $tablename = "Movies"
            $media = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename"
            $mediaexists = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * FROM $tablename Where fileexists = 'true'"

            #forumlas that cause hash literal error if put directly in sqlparameters block


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

        #Return results to powershell
        $query = "SELECT * FROM Statistics"
        Invoke-SqliteQuery -DataSource $DataSource -Query $query
    }

    #Used in debug logs
    Write-Output "Update-Statistics End"
}