<#
.SYNOPSIS
Updates the last index in the ImmutableIndex table and returns a new comment string.

.DESCRIPTION
The Update-LastIndex function retrieves the current last index from the ImmutableIndex table in the specified SQLite database, increments it, formats it as a 10-digit string, and updates the table with the new index. It then returns a new comment string based on the updated index.

.PARAMETER DataSource
The path to the SQLite database file.

.OUTPUTS
[pscustomobject]
Returns a custom object with the following property:
- newcomment: The new comment string based on the updated index.

.EXAMPLE
$result = Update-LastIndex -DataSource $datasource
$result.newcomment
dta-0000000001
#>

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