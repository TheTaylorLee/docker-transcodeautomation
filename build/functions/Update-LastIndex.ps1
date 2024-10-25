function Update-LastIndex {
    param (
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    # Get new index
    $Query = "SELECT * from ImmutableIndex"
    [int]$lastindex = (Invoke-SqliteQuery -Query $Query -DataSource $DataSource).lastindex
    [int]$newindex = $lastindex + 1
    [string]$formattedindex = "{0:D10}" -f $newindex
    [string]$newcomment = "dta-" + $formattedindex

    # Update database with last used index
    $Query = "UPDATE ImmutableIndex SET lastindex = '$formattedindex'"
    Invoke-SqliteQuery -Query $Query -DataSource $DataSource

    [pscustomobject]@{
        newcomment = $newcomment
    }
}