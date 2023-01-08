<#
.Description
Transcode new media files and delete the larger size copy.

.PARAMETER plexshowfolders
String array of show folders

.PARAMETER plexmoviefolders
String array of movie folders

.PARAMETER hours
Minimum time since file downloaded to consider for processing

.PARAMETER DataSource
Location of the sqlite database that is used for change tracking and reporting

.Example
mediapro -hours 48 -plexshowfolders "/R-User-Media/Kids Shows", "/R-User-Media/Shows", "/R-Others-Media/Shows", "P:/R-User-Media2/Shows" -plexmoviefolders "/R-User-Media/Kids Movies", "/R-User-Media/Movies", "/R-Others-Media/Movies" -datasource /docker-transcodeautomation/data/MediaDB.SQLite

.notes
fftools environment variables must be set and the admintoolbox module imported
#>

Function Invoke-MediaManagement {

    [CmdletBinding()]
    [Alias('mediapro')]
    Param (
        [Parameter(Mandatory = $true)][string[]]$plexshowfolders,
        [Parameter(Mandatory = $true)][string[]]$plexmoviefolders,
        [Parameter(Mandatory = $true)][int]$hours,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    ##Shows
    ##Make sure no previous failures occurred prior to stepping forward with shows
    $testnofiles = Get-ChildItem $env:FFToolsSource -File
    $testnofiles2 = Get-ChildItem $env:FFToolsTarget -File
    if ($null -eq $testnofiles -and $null -eq $testnofiles2) {
        #Copy Files to processing folders
        Copy-PlexShowsToProcess -plexshowfolders $plexshowfolders -hours $hours -DataSource $DataSource

        ##Process files
        Start-Transcode -crf 23 -mapall

        ##Compare processed files to the original files.
        ##Source files will be moved into a recover folder in case transcode failed.
        ##If source files is smaller it's metadata will be cleaned up and the transcoded file removed.
        ##If target files has a length of 0 ffmpeg failed and processing aborts. This avoids transcode failures overwriting good files
        $sourcefiles = Get-ChildItem $env:FFToolsSource -File | Select-Object fullname, Name, length
        $targetfiles = Get-ChildItem $env:FFToolsTarget -File | Select-Object fullname, Name, length
        $scount = ($sourcefiles | Measure-Object).count
        $tcount = ($targetfiles | Measure-Object).count

        if ($scount -eq $tcount) {
            [int]$max = $scount
            for ($i = 0; $i -lt $max; $i++) {
                if ($targetfiles[$i].Length -gt 0) {
                    if ($sourcefiles[$i].Length -lt $targetfiles[$i].Length) {
                        Remove-Item $targetfiles[$i].FullName -Force
                        ffmpeg -i $sourcefiles[$i].fullname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c copy $targetfiles[$i].FullName
                        Remove-Item $sourcefiles[$i].fullname -Force
                    }
                    else {
                        Move-Item $sourcefiles[$i].fullname $env:FFToolsTarget/recover -Force
                    }
                }
                else {
                    break
                }
            }
        }

        ##Move transcoded files into a processed folder so future file handling may proceed without issue
        $processedfiles = Get-ChildItem $env:FFToolsTarget -File | Select-Object fullname, Name, length
        $pcount = ($processedfiles | Measure-Object).count
        [int]$max = $pcount
        for ($i = 0; $i -lt $max; $i++) {
            if ($processedfiles[$i].Length -gt 0) {
                Move-Item $processedfiles[$i].fullname -Destination "$env:FFToolsTarget/processed"
            }
            else {
                break
            }
        }

        # Move transcoded files back into plex folders. This overwrites the original files
        Move-FileToPlexFolder -plexshowfolders $plexshowfolders -plexmoviefolders $plexmoviefolders -DataSource $DataSource
    }

    else {
        Write-Warning "Files in fftools folders preventing this function from running. Clear up this issue first"
    }

    ##Movies
    ##Make sure no previous failures occurred prior to stepping forward with movies
    $testnofiles = Get-ChildItem $env:FFToolsSource -File
    $testnofiles2 = Get-ChildItem $env:FFToolsTarget -File
    if ($null -eq $testnofiles -and $null -eq $testnofiles2) {
        #Copy Files to processing folders
        Copy-PlexMoviesToProcess -plexmoviefolders $plexmoviefolders  -hours $hours -DataSource $DataSource

        ##Process files
        Start-Transcode -crf 21 -mapall

        ##Compare processed files to the original files.
        ##Source files will be moved into a recover folder in case transcode failed.
        ##If source files is smaller it's metadata will be cleaned up and the transcoded file removed.
        ##If target files has a length of 0 ffmpeg failed and processing aborts. This avoids transcode failures overwriting good files
        $sourcefiles = Get-ChildItem $env:FFToolsSource -File | Select-Object fullname, Name, length
        $targetfiles = Get-ChildItem $env:FFToolsTarget -File | Select-Object fullname, Name, length
        $scount = ($sourcefiles | Measure-Object).count
        $tcount = ($targetfiles | Measure-Object).count

        if ($scount -eq $tcount) {
            [int]$max = $scount
            for ($i = 0; $i -lt $max; $i++) {
                if ($targetfiles[$i].Length -gt 0) {
                    if ($sourcefiles[$i].Length -lt $targetfiles[$i].Length) {
                        Remove-Item $targetfiles[$i].FullName -Force
                        ffmpeg -i $sourcefiles[$i].fullname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c copy $targetfiles[$i].FullName
                        Remove-Item $sourcefiles[$i].fullname -Force
                    }
                    else {
                        Move-Item $sourcefiles[$i].fullname $env:FFToolsTarget/recover -Force
                    }
                }
                else {
                    break
                }
            }
        }

        ##Move transcoded files into a processed folder so future file handling may proceed without issue
        $processedfiles = Get-ChildItem $env:FFToolsTarget -File | Select-Object fullname, Name, length
        $pcount = ($processedfiles | Measure-Object).count
        [int]$max = $pcount
        for ($i = 0; $i -lt $max; $i++) {
            if ($processedfiles[$i].Length -gt 0) {
                Move-Item $processedfiles[$i].fullname -Destination "$env:FFToolsTarget/processed"
            }
            else {
                break
            }
        }

        # Move transcoded files back into plex folders. This overwrites the original files
        Move-FileToPlexFolder -plexshowfolders $plexshowfolders -plexmoviefolders $plexmoviefolders -DataSource $DataSource
    }

    else {
        Write-Warning "Files in fftools folders preventing this function from running. Clear up this issue first"
    }

    #Remove recover files older than 14 days.
    Get-ChildItem -Path $env:FFToolsTarget/recover |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-14) } |
    Remove-Item
}