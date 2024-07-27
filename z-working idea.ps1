# Considering a modification that allows renaming files and folders with imdb and tmdb ids for better matching in personal media apps, while also not losing existing statistics.
# This handles a limited scenario where the media db id is added only at the end of the file name and in curly brackets, so it is super subjective.
# Will require an environment variable to be applied specifically for handling this scenario as it is not a common scenario and should be run once only.
## In which case is this better handled with a media function script instead of bulding it into the regular process in which case a variable is not required?

#{Movie Title} ({Release Year}) {tmdb-{TmdbId}}

#lines 64, 106, 113
#invoke-mediamoviestoprocess
#
#inserted filename would need to be this with  " {tmdb-id}" trimmed when matching up
#movie name (2024) {tmdb-12345678}

$filename = "movie name (2024) {tmdb-1066262}.mkv"
$adjustedfilenamematch = $filename -replace " \{[a-zA-Z]+-\d+\}", ""
$adjustedfilenamematch

# adjusted filename variable would be used in lines 65, 106, and 113 of the above mentioned script for matching the file in the mediadb.sqlite database, and will update the entry.
# The adjusted filename variable doesn't need to handle scenarios of the filenames already within the database since they are filtered prior to the foreach loop.
## However if the folder path changes, then it will create a new entry in the database, which will result in lost statistics.
### So this is a run once scenario and would be for ongoing use cases.