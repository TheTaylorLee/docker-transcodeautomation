function get-metadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        [Parameter(Mandatory = $true)]
        [string]$Database
    )

    begin {
        # check if the database exists
        if (Test-Path $Database) {
            #continue
        }
        else {
            $query = "CREATE TABLE mediainfo (fullname TEXT, filesizeMB INT, ffprobedata TEXT, fileexists boolean)"
            Invoke-SqliteQuery -Query $query -DataSource $Database
        }

        # Check that mediainfo table exists and create it if it doesn't
        $query = "CREATE TABLE IF NOT EXISTS mediainfo (fullname TEXT, filesizeMB INT, ffprobedata blob fileexists boolean)"
        Invoke-SqliteQuery -Query $query -DataSource $Database
    }

    process {
        # get all files in the directory
        $files = Get-ChildItem $Directory -Recurse -File -Include "*.mkv", "*.mp4"
        # loop through each file
        foreach ($file in $files) {
            # set variable
            $fullname = $file.FullName

            # check if the file is already in the database
            $query = "SELECT * FROM mediainfo WHERE fullname = `"$fullname`""
            $exists = Invoke-SqliteQuery -Query $query -DataSource $Database

            # convert file length to MB
            $filelength = [math]::Round($file.Length / 1MB, 2)

            # Handle different file sizes
            if ($null -ne $exists) {
                $query = "SELECT filesizeMB FROM mediainfo WHERE fullname = `"$fullname`""
                $size = Invoke-SqliteQuery -Query $query -DataSource $Database
                # if the file size is the same, skip the file
                if ($size -eq $filelength) {
                    #continue
                }
                # else overwrite the table entry with the new data
                else {
                    $ffprobe = ffprobe -v quiet -print_format json -show_format -show_streams $fullname
                    # write the data to the database
                    $query = "UPDATE mediainfo SET filesizeMB = `"$filelength`", ffprobedata = `"$ffprobe`", fileexists = 'true' WHERE fullname = `"$fullname`""

                }

            }

            else {
                # if the file is not in the database insert it
                $ffprobe = ffprobe -v quiet -print_format json -show_format -show_streams $fullname
                $query = "INSERT INTO mediainfo (fullname, filesizeMB, ffprobedata, fileexists) VALUES (@fullname, @filesizeMB, @ffprobedata, @fileexists)"
                Invoke-SqliteQuery -ErrorAction Inquire -DataSource $Database -Query $query -SqlParameters @{
                    fullname    = "$fullname"
                    filesizeMB  = "$filelength"
                    ffprobedata = "$ffprobe"
                    fileexists  = "true"
                }
            }
        }
    }
    end {
        update-metadata -Database $Database
    }
}