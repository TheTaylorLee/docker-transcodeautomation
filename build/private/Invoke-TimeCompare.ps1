#Created time compare function to handle when endtime is morning of of next day
function Invoke-TimeCompare {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]$STARTTIMEUTC,
        [Parameter(Mandatory = $true)]$ENDTIMEUTC
    )

    $startime = Get-Date -Date $STARTTIMEUTC
    $endtime = Get-Date -Date $ENDTIMEUTC
    $currentime = Get-Date

    if ($ENDTIMEUTC -lt $STARTTIMEUTC) {
        $modifiedendtime = $endtime.AddDays(1)
        [System.Boolean]$comparetime = ($startime -lt $currentime -and $modifiedendtime -gt $currentime)
    }
    else {
        [System.Boolean]$comparetime = ($startime -lt $currentime -and $endtime -gt $currentime)
    }

    $comparetime
}