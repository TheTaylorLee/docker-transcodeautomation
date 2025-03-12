<#
.SYNOPSIS
Processes and transcodes show files, compares the processed files to the original files, and handles file movements and metadata updates.

.DESCRIPTION
The Invoke-Processshow function processes and transcodes show files from specified source folders. It compares the processed files to the original files, handles error cases, updates metadata, and moves files to appropriate folders. The function ensures that transcoded files are correctly handled and moved back to their respective media folders.

.PARAMETER MEDIAshowfolders
An array of strings specifying the folders containing TV show media files.

.PARAMETER MEDIAmoviefolders
An array of strings specifying the folders containing movie media files.

.PARAMETER DataSource
A string specifying the data source for the media files.

.EXAMPLE
invoke-processshow -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $DataSource
#>

function invoke-processshow {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$MEDIAshowfolders,
        [Parameter(Mandatory = $true)][string[]]$MEDIAmoviefolders,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "info: Invoke-ProcessShow Start"

    if ($null -eq $env:SHOWSCRF) {
        $env:SHOWSCRF = "23"
    }

    # Get an index number for the transcoded files
    $commentbuilder = (Get-ChildItem -LiteralPath $env:FFToolsSource -File).name
    $comment = $commentbuilder | ForEach-Object {
        if ($_ -match 'dta-\d{10}') {
            $matches[0]
        }
    }

    ##Process files
    Start-TranscodeShows -crf $env:SHOWSCRF -comment $comment -DataSource $DataSource

    ##Compare processed files to the original files.
    ##Source files will be moved into a recover folder in case transcode failed.
    ##If source files is smaller it's metadata will be cleaned up and the transcoded file removed.
    ##If target files has a length of 0 ffmpeg failed and processing aborts. This avoids transcode failures overwriting good files
    $sourcefiles = Get-ChildItem -LiteralPath $env:FFToolsSource -File | Select-Object fullname, Name, length
    $targetfiles = Get-ChildItem -LiteralPath $env:FFToolsTarget -File -ErrorAction SilentlyContinue | Select-Object fullname, Name, length
    $scount = ($sourcefiles | Measure-Object).count
    $tcount = ($targetfiles | Measure-Object).count

    if ($scount -eq $tcount) {
        [int]$max = $scount
        for ($i = 0; $i -lt $max; $i++) {
            # This is error handling in case free space on a drive runs out.
            if ($targetfiles[$i].Length -gt 0) {
                # If the source file is smaller than the transcoded file
                if ($sourcefiles[$i].Length -lt $targetfiles[$i].Length) {
                    Write-Output "info: Transcoded file was larger. Removing the transcoded file and updating metadata only on source file."

                    $tablename = "shows"
                    $reason = "Transcoded File Was Larger"
                    $query = "Update $tableName SET transcodeskipreason = `"$reason`" WHERE comment = `"$comment`""
                    Invoke-SqliteQuery -DataSource $DataSource -Query $query

                    Remove-Item -LiteralPath $targetfiles[$i].FullName -Force -Verbose
                    ffmpeg -hide_banner -loglevel error -stats -i $sourcefiles[$i].fullname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$comment -c copy $targetfiles[$i].FullName
                    Remove-Item -LiteralPath $sourcefiles[$i].fullname -Force -Verbose
                }
                # If the source file is larger and backups are kept
                elseif ($env:BACKUPPROCESSED -eq 'true') {
                    Move-Item -LiteralPath $sourcefiles[$i].fullname $env:FFToolsTarget/recover -Force -Verbose
                    (Get-ChildItem -LiteralPath $env:FFToolsTarget/recover/($sourcefiles[$i]).name).lastwritetime = (Get-Date)
                }
                # If the source file is larger and backups are not kept
                else {
                    Remove-Item -LiteralPath $sourcefiles[$i].fullname -Force -Verbose
                }
            }
            # If the target file doesn't exists because it was skipped by Skip-Analysis
            elseif (Test-Path /docker-transcodeautomation/data/logs/skipcheck/$comment) {
                $targetfile = $env:FFToolsTarget + $sourcefiles[$i].name
                ffmpeg -hide_banner -loglevel error -stats -i $sourcefiles[$i].fullname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=$comment -c copy $targetfile
                Remove-Item -LiteralPath $sourcefiles[$i].fullname -Force -Verbose
            }
            else {
                Write-Output "error: Transcoded file shows a size of 0 or doesn't exist. Drive space might have run out or the file might not be able to transcode with given parameters. Processing will continue to fail until this is addressed."
            }
        }
    }

    ##Move transcoded files into a processed folder so future file handling may proceed without issue
    $processedfiles = Get-ChildItem -LiteralPath $env:FFToolsTarget -File | Select-Object fullname, Name, length
    $pcount = ($processedfiles | Measure-Object).count
    [int]$max = $pcount
    for ($i = 0; $i -lt $max; $i++) {
        if ($processedfiles[$i].Length -gt 0) {
            Move-Item -LiteralPath $processedfiles[$i].fullname -Destination "$env:FFToolsTarget/processed" -Verbose
        }
    }

    # Move transcoded files back into MEDIA folders. This overwrites the original files
    Move-FileToMEDIAFolder -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $DataSource

    #Used in debug logs
    Write-Output "info: Invoke-ProcessShow End"
}