$test = Invoke-SqliteQuery -DataSource .\metadata.db -Query 'select * from mediainfo'
($test[0].ffprobedata | ConvertFrom-Json).streams