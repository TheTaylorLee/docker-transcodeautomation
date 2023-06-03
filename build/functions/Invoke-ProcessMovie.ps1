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

    ##Process files
    Start-TranscodeMovies -crf $env:MOVIESCRF

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
            # This is error handling in case free space on a drive runs out.
            if ($targetfiles[$i].Length -gt 0) {
                # If the source file is larger than the transcoded file
                if ($sourcefiles[$i].Length -lt $targetfiles[$i].Length) {
                    Remove-Item $targetfiles[$i].FullName -Force -Verbose
                    ffmpeg -i $sourcefiles[$i].fullname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c copy $targetfiles[$i].FullName
                    Remove-Item $sourcefiles[$i].fullname -Force -Verbose
                }
                # If the source file is smaller and backups are kept
                elseif ($env:BACKUPPROCESSED -eq 'true') {
                    Move-Item $sourcefiles[$i].fullname $env:FFToolsTarget/recover -Force -Verbose
                    (Get-ChildItem $env:FFToolsTarget/recover/($sourcefiles[$i]).name).lastwritetime = (Get-Date)
                }
                # If the source file is smaller and backups are not kept
                else {
                    Remove-Item $sourcefiles[$i].fullname -Force -Verbose
                }
            }
            else {
                Write-Output "error: Transcoded file shows a size of 0. Drive space might have run out or the file might not be able to transcode with given parameters. Processing will continue to fail until this is addressed."
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
            Move-Item $processedfiles[$i].fullname -Destination "$env:FFToolsTarget/processed" -Verbose
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