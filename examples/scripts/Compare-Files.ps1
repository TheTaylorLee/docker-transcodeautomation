<#
    .SYNOPSIS
    Compares files in two directories and lists files with size differences exceeding a specified threshold.

    .DESCRIPTION
    This script compares files in two directories recursively and lists files with size differences exceeding a specified threshold in bytes. If no threshold is specified, a default value of 4096 bytes is used.

    .PARAMETER dir1
    The path to the first directory.

    .PARAMETER dir2
    The path to the second directory.

    .PARAMETER difbytes
    The size difference threshold in bytes. If not specified, defaults to 4096 bytes.

    .EXAMPLE
    compare-files -dir1 "C:\Path\To\First\Directory" -dir2 "C:\Path\To\Second\Directory"

    .EXAMPLE
    compare-files -dir1 "C:\Path\To\First\Directory" -dir2 "C:\Path\To\Second\Directory" -difbytes 8192
#>

function compare-files {
    param (
        [Parameter(Mandatory = $true)][string]$dir1,
        [Parameter(Mandatory = $true)][string]$dir2,
        [Parameter(Mandatory = $false)][int]$difbytes
    )

    function Get-FilesRecursively {
        param (
            [string]$directory
        )
        Get-ChildItem -Path $directory -Recurse -File
    }

    $filesDir1 = Get-FilesRecursively -directory $dir1
    $filesDir2 = Get-FilesRecursively -directory $dir2

    $filesDict1 = @{}
    $filesDict2 = @{}

    foreach ($file in $filesDir1) {
        $filesDict1[$file.Name] = $file.FullName
    }

    foreach ($file in $filesDir2) {
        $filesDict2[$file.Name] = $file.FullName
    }

    if ($null -eq $difbytes) {
        $difbytes = 4096
    }

    $results = foreach ($fileName in $filesDict1.Keys) {
        if ($filesDict2.ContainsKey($fileName)) {
            $file1 = Get-Item $filesDict1[$fileName]
            $file2 = Get-Item $filesDict2[$fileName]
            $sizeDifference = [math]::Abs($file1.Length - $file2.Length)
            if ($sizeDifference -gt $difbytes) {
                [PSCustomObject]@{
                    FileName         = $fileName
                    FullPath1        = $file1.FullName
                    FullPath2        = $file2.FullName
                    SizeDifferenceKB = [math]::Round($sizeDifference / 1024, 2)
                }
            }
        }
    }
    $results | Sort-Object filename
}