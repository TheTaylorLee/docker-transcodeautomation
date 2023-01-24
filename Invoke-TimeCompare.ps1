#Created time compare function to handle when endtime is am of next day
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

<#
    #supplied env variables from compose file or docker run
    #if no time is provide populate it
    $env:STARTTIMEUTC = "9:00"
    $env:ENDTIMEUTC = "7:00"
    if ($null -eq $env:STARTTIMEUTC) {
        $env:STARTTIMEUTC = "00:00"
        $env:ENDTIMEUTC = "23:59"
    }


    if (Invoke-Timecompare -STARTTIMEUTC $env:STARTTIMEUTC -ENDTIMEUTC $env:ENDTIMEUTC) {
        Write-Output "Transcoding Started"
    }
    else {
        Write-Output "Outside transcode time window will reprocess later"
    }
#>

# Need to test in a build
# Need to ensure the time in the container is utc
# Should remove the TX env variable if not already done so