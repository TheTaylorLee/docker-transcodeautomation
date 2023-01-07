# Docker-TranscodeAutomation
An automated media transcoding solution.

- IT IS RECOMMEND TO FIRST TRANSCODE YOUR EXISTING MEDIA PRIOR TO USING THIS AUTOMATION. OTHERWISE YOU WILL RISK THE WORKFLOW OF THIS AUTOMATION USING MORE DISK SPACE THAN YOU HAVE AVAILABLE. THIS IS BECAUSE THE AUTOMATION CAN RESULT IN UP TO 2 COPIES OF A FILE WHILE BEING PROCESSED, AND 1 COPY OF A TRANSCODED VERSION. ADDITIONALLY TRANSCODED FILES ARE PLACED IN A RECOVER FOLDER FOR 14 DAYS IN CASE YOU NEED TO RECOVER THE ORIGINAL FILE.

- All transcoded media will have the following parameters applied. With differences in crf quality based on Shows vs Movies.
```
ffmpeg -i <input> -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf <21 or 23> -ac 6 -c:a aac -c:s copy -preset veryfast -stats_period 60 <output>
```
- All video, audio, and subtitles are mapped into the transcoded file
- Title and Description metadata is removed to so that data doesn't effect the media server of choice properly displaying the correct metadata
- The comment metadata is set to "transcoded". This ensures even if the mediadb is lost or filename changed, the file will not be transcoded again.
- Media will be transcoded using the x265 media format to an mkv container
- 6 channel aac audio is set
- If the transcoded file is larger than the original it will be excluded and the source file remuxed to only update metadata.

## Deploying the image
Docker Run command or Docker Compose can be used.
- [Docker Compose Example](https://github.com/TheTaylorLee/docker-transcodeautomation/blob/main/examples/docker-compose.yml)
- Docker Run Command
```
docker run -v /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data -v /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding -v /media:/media --name Docker-TranscodeAutomation -e PUID=1000 -e PGID=1000 -e TZ=Chicago/Illinois -e FFToolsSource=/docker-transcodeautomation/transcoding/ -e FFToolsTarget=/docker-transcodeautomation/transcoding/new/ -e plexmoviefolders=/media/test/movies, /media/test/movies02 -e plexshowfolders=/media/test/shows ttlee/docker-transcodeautomation:ubuntu22.04-v1.0
```

### Environment Variables
ENV Variable | Required | Description | Example
---------|----------|---------|---------
 PUID | No | User ID that had access to the volumes | PUID=1000
 GUID | No | Group ID that has access to the volumes | PGID=1000
 TZ | Yes | Sets the timezone of the container. Used for log and database entry times | TZ=Chicago/Illinois
PLEXMOVIEFOLDERS | yes | Top level movie directories. Multiple directories must be seperate by ", " and not be surrounded by quotes. | PLEXMOVIEFOLDERS=/media/test/movies, /media/test/movies02
PLEXSHOWFOLDERS | yes | #Top level show directories. Multiple directories must be seperate by ", " and not be surrounded by quotes. | PLEXSHOWFOLDERS=/media/test/shows

### Volumes

Docker Volume | Purpose | Example
---------|----------|---------
 Data | Logs, Database, and Database backups are stored here | /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data
 Transcoding | Transcoding of files occurs here. | /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding
 Media | Top volume containing media and show files | /media:/media

## Using included media functions
- This image comes with various PowerShell functions for managing the images transcode database.
- Enter docker exec for the container and use these commands to get more commands.
```powershell
pwsh
get-mediafunctions
```

- To get more help for any function
```Powershell
pwsh
help <function-name> -full
```

## Statistics
- /docker-transcodeautomation/data/MediaDB.sqlite volume file is a sqlite database containing logs and statistics
- Any sqlite viewer of choice can be leveraged if desired to view this data
- The following statistics are recorded

Statistic | Description
---------|----------
mediacount | total number of existing media files
oldsizeMB | old size of media that had been transcoded. regardless of if file still exists.
newsizeMB | new size of media that had been transcoded. regardless of if file still exists.
differenceMB | amount of space saved by transcoding the media. regardless of if file still exists.
percent | percent of new size as compared to old size of media. regardless of if file still exists.
existssumsizeMB | total size of existing media files
existsoldsizeMB | old size of media that had been transcoded. only if it still exists.
existsnewsizeMB | new size of media that had been transcoded. only if it still exists.
existsdifferenceMB | amount of space saved by transcoding the media. only if it still exists.
existspercent | percent of new size as compared to old size of media. only if file still exists.
added | date the table entry was added
updatedby | function that last updated the table entry. could prove useful if troubleshooting bad table updates.
growth30daysMB | this shows how much storage usage has increased in the past x days for existing media only
growth90daysMB | this shows how much storage usage has increased in the past x days for existing media only
growth180daysMB | this shows how much storage usage has increased in the past x days for existing media only
growth365daysMB | this shows how much storage usage has increased in the past x days for existing media only

## Troubleshooting
- Review the docker logs. You might have find there are issues with your pat variables, volumes, or files left over in transcoding directories due to interuptions.
- If the logs indicate that there are files leftover in the transcoding directory you must remove them so not extra files are in that directory. This will allow processing to resume.
- If a transcoded file is corrupted, you can recover a an original version of the file for 14 days from this mapped volume. /docker-transcodeautomation/transcoding/new/recover
- The transcoding process will retain logs in the mapped /docker-transcodeautomation/data volume.
- You might run into a scenario where you replace an already transcoded file and the new file doesn't transcode. This can be resolved with the update-processed media function. See the related section of the [README](#using-included-media-functions).
- If your media database becomes corrupted, use the backed up databases to restored a healthy copy. If this fails just delete the database and restart the container. This will build a new database sans historical statistics.