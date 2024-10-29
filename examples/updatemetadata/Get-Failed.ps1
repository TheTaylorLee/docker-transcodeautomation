<#
    .DESCRIPTION
    This function searches for .mp4 and .mkv files within a specified directory and its subdirectories.
    It uses ffprobe to check the metadata of each file and identifies files that do not have a comment tag starting with "dta-*".

    .PARAMETER directory
    The directory parent directory to inspect files in.

    .EXAMPLE
    get-failed -directory "C:\Videos"

    .NOTES
    Requires ffprobe to be installed and available in PATH.
#>

function get-failed {

    param (
        [Parameter(Mandatory = $true)][string]$directory
    )

    $files = Get-ChildItem -LiteralPath $directory -Include "*.mp4", "*.mkv" -Recurse
    foreach ($file in $files) {
        $fullname = $file.fullname
        $Probe = ffprobe -loglevel 0 -print_format json -show_format $fullname
        $convert = $Probe | ConvertFrom-Json
        $filecomment = $convert.format.tags.comment

        $results = if ($filecomment -notlike "dta-*") {
            [PSCustomObject]@{
                Filename = $file.name
                Fullname = $fullname
            }
        }
        $results | Sort-Object fullname
    }
}