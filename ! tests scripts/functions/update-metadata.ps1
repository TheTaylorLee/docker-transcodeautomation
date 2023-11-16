function update-metadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Database
    )

    # Check that files in database exist, otherwise remove them.
    $query = "SELECT * FROM mediainfo"
    $files = Invoke-SqliteQuery -Query $query -DataSource $Database

    ForEach ($file in $files) {
        $fullname = $file.fullname
        if ((Test-Path $fullname) -eq $false) {
            $query = "UPDATE mediainfo SET fileexists = 'false' WHERE fullname = `"$fullname`""
            Invoke-SqliteQuery -Query $query -DataSource $Database
        }
    }
}