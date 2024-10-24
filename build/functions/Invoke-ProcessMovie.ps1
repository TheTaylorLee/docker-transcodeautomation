function invoke-processmovie {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$MEDIAshowfolders,
        [Parameter(Mandatory = $true)][string[]]$MEDIAmoviefolders,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "info: Invoke-ProcessMovie Start"

    if ($null -eq $env:MOVIESCRF) {
        $env:MOVIESCRF = "21"
    }

    # Get an index number for the transcoded files
    $comment = (Update-Lastindex -DataSource $datasource).newcomment

    ##Process files
    Start-TranscodeMovies -crf $env:MOVIESCRF -comment $comment

    ##Compare processed files to the original files.
    ##Source files will be moved into a recover folder in case transcode failed.
    ##If source files is smaller it's metadata will be cleaned up and the transcoded file removed.
    ##If target files has a length of 0 ffmpeg failed and processing aborts. This avoids transcode failures overwriting good files
    $sourcefiles = Get-ChildItem -LiteralPath $env:FFToolsSource -File | Select-Object fullname, Name, length
    $targetfiles = Get-ChildItem -LiteralPath $env:FFToolsTarget -File | Select-Object fullname, Name, length
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
                    Remove-Item -LiteralPath $targetfiles[$i].FullName -Force -Verbose
                    ffmpeg -hide_banner -loglevel error -stats -i $sourcefiles[$i].fullname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT=`"$comment`" -c copy $targetfiles[$i].FullName
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
            else {
                Write-Output "error: Transcoded file shows a size of 0. Drive space might have run out or the file might not be able to transcode with given parameters. Processing will continue to fail until this is addressed."
                break
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
        else {
            break
        }
    }

    # Move transcoded files back into MEDIA folders. This overwrites the original files
    Move-FileToMEDIAFolder -MEDIAshowfolders $MEDIAshowfolders -MEDIAmoviefolders $MEDIAmoviefolders -DataSource $DataSource

    #Used in debug logs
    Write-Output "info: Invoke-ProcessMovie End"
}