$test = Invoke-SqliteQuery -DataSource .\metadata.sqlite -Query 'select * from mediainfo'
($test[0].ffprobedata | ConvertFrom-Json).streams