# Docker-TranscodeAutomation
An automated media transcoding solution with biased transcoding options. This solution is to be almost completely automated, retain statistics, and leave zero chance of a media file being transcoded twice. By using this container, you assume all risks. Be careful and begin by testing with a copy of only a few files for transcoding.

<div>
  <p align="Left">
    <a href="https://github.com/TheTaylorLee/docker-transcodeautomation">
      <img src="https://img.shields.io/github/stars/thetaylorlee?label=Github&logo=github">
    </a>
	  <a href="https://hub.docker.com/r/ttlee/docker-transcodeautomation">
	    <img src="https://img.shields.io/docker/v/ttlee/docker-transcodeautomation?label=Dockerhub&logo=docker">
	  </a>
    <a href="https://github.com/TheTaylorLee/docker-transcodeautomation/blob/master/LICENSE">
	    <img src="https://img.shields.io/github/license/thetaylorlee/docker-transcodeautomation">
	  </a>
  	<br />
	  <br />
    <a href="https://www.buymeacoffee.com/TheTaylorLee">
	    <img alt="Buy Me A Coffee" src="https://www.buymeacoffee.com/assets/img/custom_images/yellow_img.png" style="height: auto !important; width: auto !important;" />
	  </a>
  </p>
</div>

- When new media is added this process will only effect files 4 hours or older. This is so any other unrelated file handling processes have time to complete first.
- Once all media is transcoded the process sleeps for 4 hours before looking for new media to transcode. This is to reduce disk operations.
- This process will only process and transcode media in *.mp4 & *.mkv containers. All other files will be excluded.

## Parameters applied to transcoded media

- All transcoded media will have the following parameters applied. With crf quality configured by required env variables.
- All video, audio, and subtitles are mapped into the transcoded file.
- Title and Description metadata is removed so that data doesn't affect and leveraged media server will properly display the correct metadata
- The comment metadata is set to "transcoded". This ensures even if the database is lost or filename changed, the file will not be transcoded again.
- If the transcoded file is larger than the original it will be excluded and the source file remuxed to only update metadata.
```
ffmpeg -i <input> -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf <env:variable> -ac 8 -c:a aac -c:s copy -preset veryfast -stats_period 60 <output>
```

## Deploying the image
- Docker Compose Example
```yml
version: "3.8"
services:
  Docker-TranscodeAutomation:
    image: ttlee/docker-transcodeautomation:alpine3.1.4-lts
    container_name: Docker-TranscodeAutomation
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Chicago/Illinois
      - BACKUPPROCESSED=true
      - BACKUPRETENTION=14
      - MEDIAMOVIEFOLDERS=/media/test/movies, /media/test/movies02
      - MEDIASHOWFOLDERS=/media/test/shows
      - MOVIESCRF=21
      - SHOWSCRF=23
    volumes:
      - /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data
      - /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding
      - /media:/media
    restart: unless-stopped
```

### Environment Variables
- If setting BACKUPPROCESSED to true be careful. This can easily lead to filling up drive free space dependent on media processed during the BACKUPRETENTION period.

ENV Variable | Required | Description | Example
---------|----------|---------|---------
PUID | No | User ID that has access to the volumes | PUID=1000
GUID | No | Group ID that has access to the volumes | PGID=1000
TZ | No | Sets the timezone of the container. Used for log and database entry times | TZ=Chicago/Illinois
BACKUPPROCESSED | Yes | If set to true this will result in transcoded files being backed up for x days | BACKUPPROCESSED=false
BACKUPRETENTION | Yes | Number of days to retain a backup copy of transcoded media | BACKUPRETENTION=14
MEDIAMOVIEFOLDERS | Yes | Top level movie directories. Multiple directories must be seperate by ", " (colon and a trailing space) and not be surrounded by quotes. | MEDIAMOVIEFOLDERS=/media/test/movies, /media/test/movies02
MEDIASHOWFOLDERS | Yes | Top level show directories. Multiple directories must be seperate by ", "  (colon and a trailing space) and not be surrounded by quotes. | MEDIASHOWFOLDERS=/media/test/shows
MOVIESCRF | Yes | [Constant Rate Factor](https://trac.ffmpeg.org/wiki/Encode/H.265#:~:text=is%20not%20recommended.-,Constant%20Rate%20Factor%20(CRF),-Use%20this%20mode) for configuring trancode quality | MOVIESCRF=21
SHOWSCRF | Yes | [Constant Rate Factor](https://trac.ffmpeg.org/wiki/Encode/H.265#:~:text=is%20not%20recommended.-,Constant%20Rate%20Factor%20(CRF),-Use%20this%20mode) for configuring trancode quality | SHOWSCRF=23

### Volumes

Docker Volume | Purpose | Example
---------|----------|---------
Data | Logs, Database, and Database backups are stored here | /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data
Transcoding | Transcoding of files occurs here | /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding
Media | Top volume containing media files | /media:/media

## Using included media functions
- This image comes with various optional PowerShell functions for managing the transcode database.
```powershell
pwsh #Switch into pwsh from bash or sh first. Then the PowerShell functions can be used.
#Media Management Functions
Get-MissingYear        #Gets media missing the year of release in the name
Get-NotProcessed       #Get files not yet transcoded
Move-FileToMediaFolder #Move transcoded files back to media folders. TranscodeAutomation will handle this, but this can be useful in some scenarios
Update-Processed       #Updates transcoded files sql entries for replaced/upgraded files
Update-Statistics      #Updates and pulls transcoded media stats
```

- To get more help and info on these functions
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

### Example Using Grafana
Grafana can be leveraged to build a statistics dashboard for transcoded media.

#### Steps Required
- Add Grafana to your docker-compose file.
```yml
version: "3.8"
services:
  Docker-TranscodeAutomation:
    image: ttlee/docker-transcodeautomation:alpine3.1.4-lts
    container_name: Docker-TranscodeAutomation
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Chicago/Illinois
      - BACKUPPROCESSED=true
      - BACKUPRETENTION=14
      - MEDIAMOVIEFOLDERS=/media/test/movies, /media/test/movies02
      - MEDIASHOWFOLDERS=/media/test/shows
      - MOVIESCRF=21
      - SHOWSCRF=23
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
- You now have a dashboard for displaying statistics. If you haven't been running docker-transcodeautomation previously, no statistics will exist yet for the dashboard to display.
![Grafana Dashboard](https://raw.githubusercontent.com/TheTaylorLee/docker-transcodeautomation/master/examples/dashboard-grafana.png)

## Troubleshooting
- Review the docker logs. You might have found there are issues with your path variables, volumes, or files left over in transcoding directories due to interruptions.
- If the logs indicate that there are files leftover in the transcoding directory you must remove them so not extra files are in that directory. This will allow processing to resume.
- If a transcoded file is corrupted, you can recover an original version of the file for x days from this mapped volume. /docker-transcodeautomation/transcoding/new/recover
- The transcoding process will retain logs in the mapped /docker-transcodeautomation/data volume.
- You might run into a scenario where you replace an already transcoded file, and the new file doesn't transcode. This can be resolved with the update-processed media function. See the related section "Using Included Media functions"
- If your media database becomes corrupted, use the backed-up databases to restore a healthy copy. If this fails, just delete the database and restart the container. This will build a new database sans historical statistics.

# Changelog
- 1.0 Initial images released.
- 1.1.0 Convert plex name in variables to MEDIA.
- 1.1.1 Fixed update-processed media function so it properly calls ffprobe.
- 1.1.2 Fixed get-notprocessed to show days in the file age output.
- 2.0.0 Updated to handle one media file at a time, make the recover folder optional, and added env variables for various processing options.
- 2.1.0 Updated log output and updatedby sql entries to reflect new function names. Used for information and debugging output.
- 2.2.0 Remove MediaFunctions module unused private functions, and update get-childitem to use include instead of exclude on all functions.
- 2.3.0 Update transcode selections to not downmix 7.1 audio