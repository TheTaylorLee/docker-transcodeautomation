<#
.SYNOPSIS
Repairs a media file by updating its metadata and optionally keeps a backup of the original file. Should be run against the backup file if the file modified by updatemetadata is corrupted and needs replaced.

.PARAMETER file
The full path to the backup copy of the corrupted media file.

.PARAMETER indexcomment
The comment to be added to the metadata of the file. This is the matching index comment from the mediadb.sqlite database.

.PARAMETER keepbackup
A boolean flag indicating whether to keep the backup of the original file. If set to $false, the backup file will be removed after the repair process. Default is $true.

.EXAMPLE
Repair-File -file "C:\Videos\example.mp4" -indexcomment "dta-0000005812" -keepbackup $true

This example repairs the file "example.mp4", adds the comment "Repaired file" to its metadata, and keeps a backup of the original file.

.EXAMPLE
Repair-File -file "C:\Videos\example.mp4" -indexcomment "dta-0000005812"

This example repairs the file "example.mp4", adds the comment "Repaired file" to its metadata, and removes the backup of the original file.

.NOTES
Requires ffmpeg to be installed and available in the system's PATH.
#>

function Repair-File {
    param (
        [Parameter(Mandatory = $true)][string]$file,
        [Parameter(Mandatory = $true)][string]$indexcomment,
        [Parameter(Mandatory = $false)][Boolean]$keepbackup
    )

    $oldname = $file + ".bak"
    Rename-Item $file $oldname
    ffmpeg -hide_banner -loglevel error -stats -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="$indexcomment" -c copy -stats_period 60 $file
    if ($keepbackup -eq $false) {
        Remove-Item $oldname
    }
}