# Docker-TranscodeAutomation
An automated media transcoding solution. This solution is to be almost completely automated and retains statistics. By using this container, you assume all risks. Be careful and begin by testing with a copy of only a few files for transcoding.

<div>
  <p align="Left">
    <a href="https://img.shields.io/github/workflow/status/thetaylorlee/docker-transcodeautomation/.github/workflows/prod-amd64.yml?branch=master">
      <img src="https://img.shields.io/github/actions/workflow/status/TheTaylorLee/docker-transcodeautomation/prod-amd64.yml?branch=master&label=Prod%20Workflow&logo=Github">
    </a>
    <a href="https://github.com/TheTaylorLee/docker-transcodeautomation/issues?q=is%3Aopen+is%3Aissue">
      <img src ="https://img.shields.io/github/issues-raw/thetaylorlee/docker-transcodeautomation">
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

## Transcoding Process and Options
- This solution comes with preset transcoding options, but if you wish to use your own options, skip to Option 2.
- The comment metadata is set to `transcoded`. This ensures even if the database is lost or filename changed, the file will not be transcoded again.
- If the transcoded file is larger than the original it will be excluded and the source file remuxed to only update metadata while keeping all media, video, and audio streams.
- This process will only process and transcode media in `*.mp4 & *.mkv` containers. All other files will be excluded.
- I highly recommend testing with copy of a few media files first.

### Option 1
- All transcoded media will have the below parameters applied.
- All video, audio, and subtitle streams are mapped into transcoded files.
- Title and Description metadata is removed so that proper metadata is presented in certain 3rd party media servers.
- CRF quality defaults to 21 for movies and 23 for shows.
- You can customize the [Constant Rate Factor](https://trac.ffmpeg.org/wiki/Encode/H.265#:~:text=is%20not%20recommended.-,Constant%20Rate%20Factor%20(CRF),-Use%20this%20mode) using the environment variables with option 1. See the environment variables section of the readme.
```powershell
ffmpeg -i <input> -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="transcoded" -c:v libx265 -crf <env:variable> -c:a copy -c:s copy -preset veryfast -stats_period 60 <output>
```

### Option 2
- Option 2 allows for customizing the majority of the applied ffmpeg parameters.
- You can apply the custom options by saving the below command to files in the mapped data volume `/docker-transcodeautomation/data`. Use one file for Shows and another for Movies.
  - `showscustomoptions.ps1`
  - `moviescustomoptions.ps1`
- You may replace the `{Custom Options Here}` text with any custom Options you want to use. Be sure to remove the brackets.
- All other options must be left alone or the transcode automation process will not work as intended. This is because of the way ffprobe handles media with the transcoded comment.
- Example Options: `-metadata title="" -metadata description="" -map 0:v:0? -map 0:a? -map 0:s? -c:v libx265 -crf 23 -c:a aac -c:s copy -preset veryfast`
```powershell
ffmpeg -i $video -metadata COMMENT="transcoded" {Custom Options Here} -stats_period 60 "$env:FFToolsTarget$video"
```

## Deploying the image
### Compose Example
```yml
version: "3.8"
services:
  Docker-TranscodeAutomation:
    image: ghcr.io/thetaylorlee/docker-transcodeautomation:latest
    container_name: Docker-TranscodeAutomation
    environment:
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
    network_mode: none
    restart: unless-stopped
```

### Environment Variables
#### Required Variables
ENV Variable |  Description | Example
---------|---------|---------
BACKUPPROCESSED | If set to true this will result in transcoded files being backed up for x days | BACKUPPROCESSED=false
BACKUPRETENTION | Number of days to retain a backup copy of transcoded media | BACKUPRETENTION=14
MEDIAMOVIEFOLDERS | Top level movie directories. Multiple directories must be seperate by ", " (Comma and a trailing space) and not be surrounded by quotes. | MEDIAMOVIEFOLDERS=/media/test/movies, /media/test/movies02
MEDIASHOWFOLDERS | Top level show directories. Multiple directories must be seperate by ", "  (Comma and a trailing space) and not be surrounded by quotes. | MEDIASHOWFOLDERS=/media/test/shows


#### Optional Variables
ENV Variable | Description | Example
---------|---------|--------
ENDTIMEUTC | End of timeframe that transcoding is allowed in UTC 24 hour format | ENDTIMEUTC=02:00
MINAGE | Minimum age in hours of a file before it's processed | MINAGE=1.5
MOVIESCRF | [Constant Rate Factor](https://trac.ffmpeg.org/wiki/Encode/H.265#:~:text=is%20not%20recommended.-,Constant%20Rate%20Factor%20(CRF),-Use%20this%20mode) for configuring trancode quality | MOVIESCRF=21
PROCDELAY | Time delay in hours between processing files | PROCDELAY=4
SHOWSCRF | [Constant Rate Factor](https://trac.ffmpeg.org/wiki/Encode/H.265#:~:text=is%20not%20recommended.-,Constant%20Rate%20Factor%20(CRF),-Use%20this%20mode) for configuring trancode quality | SHOWSCRF=23
STARTTIMEUTC | Beginning of timeframe that transcoding is allowed in UTC 24 hour format | STARTTIMEUTC=17:00
UPDATEMETADATA | If true, existing media will have metadata updated only | UPDATEMETADATA=true

#### Variable Notes
- If setting `BACKUPPROCESSED` to true be careful. This can easily lead to filling up drive free space dependent on media processed during the `BACKUPRETENTION` period.
- `UPDATEMETADATA` can be used to have the comment 'transcoded' added to media that has been transcoded in the past. This will prevent that media being processed and is recommend to avoid undesired quality loss.
  - After metadata has been updated remove this variable and restart the container.
- If `ENDTIMEUTC` is an earlier time than `STARTTIMEUTC`, then it will be treated as next day. For example 18:30 UTC start time with an end time of 03:00 UTC, the end time will stop processing new transcodes the next day for the given UTC Datetime.
- `PROCDELAY` and `MINAGE` defaults are 4 hours. `PROCDELAY` will respect UTC time windows. It is recommended to maintain a larger processing delay to limit excessive disk reads.


### Volumes

Docker Volume | Purpose | Example
---------|----------|---------
Data | Config Files, Database, Database backups and logs, are stored here | /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data
Transcoding | Transcoding of files occurs here | /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding
Media | Top volume containing media files | /media:/media

### Builds and Tags
Build | Architecture | Updated
---------|----------|---------
Alpine3.14-lts | amd64 | yes
Ubuntu22.04-lts | amd64 | yes

Tags | Description
---------|----------
`build`-`Architecture`-develop | Most recent dev image for for any build & architecture
`build`-`Architecture`-develop-`version` | Versioned dev image for for any build & architecture
`build`-`Architecture`-`version` | Versioned image for any build & architecture
`build`-`Architecture` | Latest image for any build & architecture
latest | Latest alpine amd64 image

## Using included media functions
- This image comes with various optional PowerShell functions for managing the transcode database.
- Use `docker exec -i Docker-TranscodeAutomation /usr/bin/pwsh` to get an interactive shell
```powershell
#Media Management Functions
Get-EmptyFolder        #Gets empty directories that can be cleaned up.
Get-MissingYear        #Gets media missing the year of release in the name
Get-NotProcessed       #Get files not yet transcoded
Move-FileToMediaFolder #Move transcoded files back to media folders. TranscodeAutomation will handle this, but this can be useful in some scenarios
Update-Processed       #Updates transcoded files sql entries for replaced/upgraded files
Update-Statistics      #Updates and pulls transcoded media stats
```

## Using Windows Docker Desktop
- It's possible to run this image on a Windows 10+ desktop using Windows Subsystem for Linux and Docker Desktop
- Transcode performance is about 40% worse in my testing with wsl. I would only recommend this container using a linux host. I observe near native transcode performance using docker-transcodeautomation on a native linux host.
- [Check out the example provided here for guidance](https://github.com/TheTaylorLee/docker-transcodeautomation/tree/master/examples/wsl)

## Statistics
- `/docker-transcodeautomation/data/MediaDB.sqlite` volume file is a sqlite database containing media data and statistics
- Any sqlite viewer of choice can be leveraged if desired to view this data
- [Here is an example using Grafana](https://github.com/TheTaylorLee/docker-transcodeautomation/tree/master/examples/grafana)

## Troubleshooting
- [Check out the Troubleshooting Discussion Topics](https://github.com/TheTaylorLee/docker-transcodeautomation/discussions/categories/troubleshooting-help)
