function Move-FileToMEDIAFolder {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)][string[]]$MEDIAshowfolders,
        [Parameter(Mandatory = $true)][string[]]$MEDIAmoviefolders,
        [Parameter(Mandatory = $true)][string]$DataSource
    )

    #Used in debug logs
    Write-Output "[+] Move-FileToMEDIAFolder Start"

    #Generate list of existing files for moving new files in their place
    ##Delete old comparison file and make a new one
    [psobject]$MEDIAmoviefiles = foreach ($MEDIAmoviefolder in $MEDIAmoviefolders) {
        Get-ChildItem $MEDIAmoviefolder -r -File -Include "*.mkv", "*.mp4" |
        Select-Object name, fullname, directory, @{ Name = "OldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
    }
    [psobject]$MEDIAshowfiles = foreach ($MEDIAshowfolder in $MEDIAshowfolders) {
        Get-ChildItem $MEDIAshowfolder -r -File -Include "*.mkv", "*.mp4" |
        Select-Object name, fullname, directory, @{ Name = "OldsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }
    }

    #Get a list of files in process folder
    $processeddir = "$env:FFToolsTarget" + "processed"
    [psobject]$filestomove = Get-ChildItem $processeddir -r -File -Include "*.mkv", "*.mp4" | Select-Object name, fullname, directory, @{ Name = "NewsizeMB"; Expression = { [math]::round(($_.length / 1mb), 2) } }

    #Move processed movie files
    try {
        foreach ($file in $filestomove) {
            #move the file
            $destination = $MEDIAmoviefiles | Where-Object { $_.name -eq $file.name }
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue -Verbose

                # log stats and changes to database
                $TableName = 'Movies'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $destination.OldsizeMB
                $fullname = $destination.fullname
                $query = "Update $TableName SET comment = 'transcoded', modified = `"$modified`", updatedby = 'Move-FileToMEDIAFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
                Invoke-SqliteQuery -DataSource $DataSource -Query $query
            }
        }
    }
    catch {
        $_
    }

    #Move processed show files
    try {
        foreach ($file in $filestomove) {
            #move the file
            $destination = $MEDIAshowfiles | Where-Object { $_.name -eq $file.name }
            if (Test-Path $destination.fullname -ErrorAction SilentlyContinue) {
                Move-Item $file.fullname $destination.fullname -Force -Confirm:$false -ErrorAction SilentlyContinue -Verbose

                # log stats and changes to database
                $TableName = 'Shows'
                $modified = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $newsizeMB = $file.newsizeMB
                $oldsizeMB = $destination.OldsizeMB
                $fullname = $destination.fullname
                $query = "Update $TableName SET comment = 'transcoded', modified = `"$modified`", updatedby = 'Move-FileToMEDIAFolder', filesizeMB = `"$newsizeMB`", newsizeMB = `"$newsizeMB`", oldsizeMB = `"$oldsizeMB`" WHERE fullname = `"$fullname`""
                Invoke-SqliteQuery -DataSource $DataSource -Query $query
            }
        }
    }
    catch {
        $_
    }

    #Used in debug logs
    Write-Output "[+] Move-FileToMEDIAFolder End"
}
