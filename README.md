# Docker-TranscodeAutomation
An automated media transcoding solution. By using this container you assume all risks. Be careful and begin by testing with a copy of only a few files for transcoding.

<p align="Left">
<a href="https://hub.docker.com/r/ttlee/docker-transcodeautomation"><img src="https://img.shields.io/docker/v/ttlee/docker-transcodeautomation?logo=docker"></a>
</p>

- It is recommended to first transcode your existing media prior to using this container. Otherwise, you will risk the workflow of this automation using more disk space than would be desired. That is because the automation will result in up to 2 copies of a file and a transcoded copy while processing the media directories. When complete there will be only the transcoded copy of the media and a backup copy of the original file that is removed after a 14-day period.
- Media first transcoded will need to contain a metadata comment of transcoded to avoid this process picking up the file for transcoding.
- For this reason, I suggest using a script like this [script](https://github.com/TheTaylorLee/docker-transcodeautomation/blob/main/scripts/invoke-transcoderecursive.ps1)
- Once all media is transcoded the process sleeps for 2 hours before looking for new media to transcode.
- Any non-media file that is not in these excluded extensions should not be saved in your media directories. ".txt", ".srt", ".md", ".jpg", ".jpeg", ".bat", ".png", ".idx", ".sub", ".SQLite"

## Parameters applied to transcoded media

- All transcoded media will have the following parameters applied. With differences in crf quality based on Shows vs Movies.
```
ffmpeg -i <input> -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf <21 or 23> -ac 6 -c:a aac -c:s copy -preset veryfast -stats_period 60 <output>
```
- All video, audio, and subtitles are mapped into the transcoded file
- Title and Description metadata is removed so that data doesn't affect the media server of choice properly displaying the correct metadata
- The comment metadata is set to "transcoded". This ensures even if the mediadb is lost or filename changed, the file will not be transcoded again.
- Media will be transcoded using the x265 media format to an mkv container
- 6 channel aac audio is set
- If the transcoded file is larger than the original it will be excluded and the source file remuxed to only update metadata.

## Deploying the image
- Docker Compose Example
```
version: "3.8"
services:
  Docker-TranscodeAutomation:
    image: ttlee/docker-transcodeautomation:ubuntu22.04-v1.1.0
    container_name: Docker-TranscodeAutomation
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Chicago/Illinois
      - MEDIAMOVIEFOLDERS=/media/test/movies, /media/test/movies02
      - MEDIASHOWFOLDERS=/media/test/shows
    volumes:
      - /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data
      - /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding
      - /media:/media
    restart: unless-stopped
```
- Docker Run Example
```
docker run -v /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data -v /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding -v /media:/media --name Docker-TranscodeAutomation -e PUID=1000 -e PGID=1000 -e TZ=Chicago/Illinois -e MEDIAMOVIEFOLDERS=/media/test/movies, /media/test/movies02 -e MEDIASHOWFOLDERS=/media/test/shows ttlee/docker-transcodeautomation:ubuntu22.04-v1.0
```

### Environment Variables
ENV Variable | Required | Description | Example
---------|----------|---------|---------
 PUID | No | User ID that had access to the volumes | PUID=1000
 GUID | No | Group ID that has access to the volumes | PGID=1000
 TZ | Yes | Sets the timezone of the container. Used for log and database entry times | TZ=Chicago/Illinois
MEDIAMOVIEFOLDERS | yes | Top level movie directories. Multiple directories must be seperate by ", " and not be surrounded by quotes. | MEDIAMOVIEFOLDERS=/media/test/movies, /media/test/movies02
MEDIASHOWFOLDERS | yes | Top level show directories. Multiple directories must be seperate by ", " and not be surrounded by quotes. | MEDIASHOWFOLDERS=/media/test/shows

### Volumes

Docker Volume | Purpose | Example
---------|----------|---------
Data | Logs, Database, and Database backups are stored here | /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data
Transcoding | Transcoding of files occurs here. | /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding
Media | Top volume containing media files | /media:/media

## Using included media functions
- This image comes with various PowerShell functions for managing the transcode database.
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
- /docker-transcodeautomation/data/MediaDB.sqlite volume file is a sqlite database containing media data and statistics
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
- Review the docker logs. You might have found there are issues with your path variables, volumes, or files left over in transcoding directories due to interruptions.
- If the logs indicate that there are files leftover in the transcoding directory you must remove them so not extra files are in that directory. This will allow processing to resume.
- If a transcoded file is corrupted, you can recover an original version of the file for 14 days from this mapped volume. /docker-transcodeautomation/transcoding/new/recover
- The transcoding process will retain logs in the mapped /docker-transcodeautomation/data volume.
- You might run into a scenario where you replace an already transcoded file and the new file doesn't transcode. This can be resolved with the update-processed media function. See the related section of the [README](#using-included-media-functions).
- If your media database becomes corrupted, use the backed-up databases to restore a healthy copy. If this fails, just delete the database and restart the container. This will build a new database sans historical statistics.

## Using Grafana
Grafana can be leveraged to build a statistics dashboard for transcoded media.


### Steps Required
- Add Grafana to your docker-compose file. Look at container readme for an idea on the various environment variable.
```yml
version: "3.8"
services:
  Docker-TranscodeAutomation:
    image: ttlee/docker-transcodeautomation:alpine3.1.4-lts-v1.1.1
    container_name: Docker-TranscodeAutomation
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Chicago/Illinois
      - MEDIAMOVIEFOLDERS=/media/test/movies, /media/test/movies02
      - MEDIASHOWFOLDERS=/media/test/shows
    volumes:
      - /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data
      - /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding
      - /media:/media
    restart: unless-stopped
  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    privileged: true
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Chicago/Illinois
    ports:
      - "3000:3000"
    volumes:
      - /home/user/docker/appdata/grafana-data:/var/lib/grafana
      - /home/user/docker/appdata/docker-transcodeautomation/data/MediaDB.SQLite:/mydb/MediaDB.SQLite
```
- Navigate to Grafana http://localhost:3000
- In Configuration > Data Sources > Plugins, install the SQLite plugin
- In Datasources add a new sqlite datasource with the path /mydb/MediaDB.SQLite (Leave the other options untouched)
- Go to Dashboards > Import, [paste the json from here](https://raw.githubusercontent.com/TheTaylorLee/docker-transcodeautomation/master/examples/grafana-dashboard.json), and then click import
- You know have a dashboard for displaying statistics. If you haven't been running docker-transcodeautomation previously, no statistics will exist yet for the dashboard to display.
![Grafana Dashboard](https://raw.githubusercontent.com/TheTaylorLee/docker-transcodeautomation/master/examples/dashboard-grafana.png)