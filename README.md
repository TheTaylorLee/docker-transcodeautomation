# Docker-TranscodeAutomation
An automated media transcoding solution with statistics. **By using this container, you assume all risks, and it is recommended to maintain backups.** For a better understanding of this containers function and workflow see this [diagram](https://github.com/TheTaylorLee/docker-transcodeautomation/blob/master/examples/workflowdiagram/Docker-TranscodeAutomation.png).

<div>
  <p align="Left">
      <a href="https://github.com/TheTaylorLee/docker-transcodeautomation/actions/workflows/prod-alpine-amd64.yml">
      <img src="https://github.com/TheTaylorLee/docker-transcodeautomation/actions/workflows/prod-alpine-amd64.yml/badge.svg">
    </a>
    <a href="https://github.com/TheTaylorLee/docker-transcodeautomation/issues?q=is%3Aopen+is%3Aissue">
      <img src ="https://img.shields.io/github/issues-raw/thetaylorlee/docker-transcodeautomation">
    </a>
    <a href="https://github.com/TheTaylorLee/docker-transcodeautomation/blob/master/LICENSE">
	    <img src="https://img.shields.io/github/license/thetaylorlee/docker-transcodeautomation">
	  </a>
  </p>
</div>

## Transcoding Process and Options
- This solution comes with preset transcoding options, but if you wish to use your own options, skip to Option 2.
- The comment metadata is set to an immutable index. This ensures even if the database is lost or filename changed, the file will not be transcoded again.
- If the transcoded file is larger than the original it will be excluded and the source file remuxed to only update metadata while keeping all media, video, and audio streams.
- This process will only process and transcode media in `*.mp4 & *.mkv` containers. All other files will be excluded.

### Option 1
- All transcoded media will be analyzed and parameters dynamically applied from [Build-TranscodeParams](https://github.com/TheTaylorLee/docker-transcodeautomation/blob/main/build/functions/Build-TranscodeParams.ps1).
- All video, audio, and subtitle streams are mapped into transcoded files.
- Title and Description metadata is removed so that proper metadata is presented in certain 3rd party media servers.
- Additional parameters are applied to match with the source file, such as colorspace, luminance, and other x265 parameters.
- CRF quality defaults to 21 for movies and 23 for shows.
- You can customize the [Constant Rate Factor](https://trac.ffmpeg.org/wiki/Encode/H.265#:~:text=is%20not%20recommended.-,Constant%20Rate%20Factor%20(CRF),-Use%20this%20mode) using the environment variables with option 1. See the environment variables section of the readme.

### Option 2
- Option 2 allows for customizing the majority of the applied ffmpeg parameters.
- You can apply the custom options by saving the below command to files in the mapped data volume `/docker-transcodeautomation/data`. Use one file for Shows and another for Movies.
  - `showscustomoptions.ps1`
  - `moviescustomoptions.ps1`
- You may replace the `{Custom Options Here}` text with any custom Options you want to use. Be sure to remove the brackets.
- All other options must be left alone and the $comment variable must be retained, or the transcode automation process will not work as intended. This is because of the way immutable file indexing is considered.
- Example Options: `-metadata title="" -metadata description="" -map 0:v:0? -map 0:a? -map 0:s? -c:v libx265 -crf 23 -c:a aac -c:s copy -preset veryfast`
```powershell
$comment = (Update-Lastindex -DataSource $datasource).newcomment
ffmpeg -i $video -metadata COMMENT="$comment" {Custom Options Here} -stats_period 60 "$env:FFToolsTarget$video"
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
    cap_add:
      - SYS_NICE # Allows ffmpeg to set cpu affinity and allocate memory
    restart: unless-stopped
```

### Environment Variables
#### Required Variables
ENV Variable |  Description | Example
---------|---------|---------
BACKUPPROCESSED | If set to true this will result in transcoded files being backed up for x days | false
BACKUPRETENTION | Number of days to retain a backup copy of transcoded media | 14
MEDIAMOVIEFOLDERS | Top level movie directories. Multiple directories must be seperated by ", " (Comma and a trailing space) and not be surrounded by quotes. | /media/test/movies, /media/test/movies02
MEDIASHOWFOLDERS | Top level show directories. Multiple directories must be seperated by ", "  (Comma and a trailing space) and not be surrounded by quotes. | /media/test/shows


#### Optional Variables
ENV Variable | Description | Example
---------|---------|--------
ENDTIMEUTC | End of timeframe that transcoding is allowed in UTC 24 hour format | 02:00
MINAGE | Minimum age in hours of a file before it's processed | 1.5
MOVIESCRF | [Constant Rate Factor](https://trac.ffmpeg.org/wiki/Encode/H.265#:~:text=is%20not%20recommended.-,Constant%20Rate%20Factor%20(CRF),-Use%20this%20mode) for configuring trancode quality | 21
PROCDELAY | Time delay in hours between processing files | 4
SHOWSCRF | [Constant Rate Factor](https://trac.ffmpeg.org/wiki/Encode/H.265#:~:text=is%20not%20recommended.-,Constant%20Rate%20Factor%20(CRF),-Use%20this%20mode) for configuring trancode quality | 23
STARTTIMEUTC | Beginning of timeframe that transcoding is allowed in UTC 24 hour format | 17:00
SKIPAV1 | Skip processing files that are av1 encoded | true
SKIPHEVC | Skip processing files that are x265/hevc encoded | false
SKIPKBPSBITRATEMIN | Skip files below a minimum bitrate in kbps | 1000
SKIPMINUTESMIN | Skip files below a minimum legnth in minutes | 30
SKIPDOVI | Skip files containing Dolby Vision metadata | true
SKIPHDR | Skip files containing HDR metadata | false
UPDATEMETADATA | If true, existing media will have metadata updated only | true

#### Variable Notes
- If setting `BACKUPPROCESSED` to true be careful. This can easily lead to filling up drive free space dependent on media processed during the `BACKUPRETENTION` period.
- `UPDATEMETADATA` can be used to index existing media. Useful if existing media was previously transcoded. After metadata has been updated remove this variable and restart the container.
- If `ENDTIMEUTC` is an earlier time than `STARTTIMEUTC`, then it will be treated as next day. For example 18:30 UTC start time with an end time of 03:00 UTC, the end time will stop processing new transcodes the next day for the given UTC Datetime.
- `PROCDELAY` and `MINAGE` defaults are 4 hours. `PROCDELAY` will respect UTC time windows. It is recommended to maintain a larger processing delay to limit excessive disk reads.


### Volumes

Docker Volume | Purpose | Example
---------|----------|---------
Data | Config Files, Database, Database backups and logs, are stored here | /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data
Transcoding | Transcoding of files occurs here | /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding
Media | Top volume containing media files | /media:/media

### Builds and Tags
Build | Architecture | Maintained
---------|----------|---------
Alpine3.14-lts | amd64 | no
Alpine3.17 | amd64 | yes
Ubuntu22.04-lts | amd64 | no

Tags | Description
---------|----------
`build`-`Architecture`-develop | Most recent dev image for for any build & architecture
`build`-`Architecture`-develop-`version` | Versioned dev image for for any build & architecture
`build`-`Architecture`-`version` | Versioned image for any build & architecture
[latest](https://github.com/TheTaylorLee/docker-transcodeautomation/pkgs/container/docker-transcodeautomation) | There is no longer a latest docker-transcodeautomation build. Breaking changes have dictated requiring version pinning.

## Using included media functions
- This image comes with various optional PowerShell functions i've added for retrieving useful info. They are not necessary to use.
- `docker exec -i Docker-TranscodeAutomation /usr/bin/pwsh` to get an interactive shell
```powershell
#Media Management Functions
Get-EmptyFolder        #Gets empty directories that can be cleaned up.
Get-MissingYear        #Gets media missing the year of release in the name
Get-NotProcessed       #Get files not yet transcoded
Move-FileToMediaFolder #Move transcoded files back to media folders. TranscodeAutomation will handle this, but this can be useful to handle failed moves sooner.
```

## Statistics
- `/docker-transcodeautomation/data/MediaDB.sqlite` volume file is a sqlite database containing media data and statistics
- Any sqlite viewer of choice can be leveraged if desired to view this data
- [Here is an example using Grafana](https://github.com/TheTaylorLee/docker-transcodeautomation/tree/master/examples/grafana)

## Additional Notes
- If a file is is replaced by another file of the same name, and the old file is deleted, statistics cannot update sooner than (25 hours + PROCDELAY + MINAGE). This ensures statistics are not lost in rare circumstances. Becuase of this the container must run at a minimum that long without restart prior to a replaced files database entry being updated.
- Docker logs should provide hints to the root of an issue and relevant snippets need to be included in opened issues.
- If the logs indicate that there are files leftover in the transcoding directory you must remove them. This is a safety feature that allows for addressing reasons for failed transcodes before continuing.
- If your media database becomes corrupted, use the backed-up databases to restore a healthy copy.
  - /docker-transcodeautomation/data/MediaDB.SQLite #database location
  - /docker-transcodeautomation/data/Backups #BackupsLocation
- If wanting to add media to an existing watched directory but not actually transcode it; remux it with comment of dta-remuxed.
  ```bash
  # replace $oldname and $name with filepaths
  ffmpeg -hide_banner -loglevel error -stats -i $oldname -map 0:v:0? -map 0:a? -map 0:s? -metadata title="" -metadata description="" -metadata COMMENT="dta-remuxed" -c copy -stats_period 60 $name
  ```
