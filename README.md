# Docker-TranscodeAutomation
An automated media transcoding solution.

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

### Environment Variables

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

## Troubleshooting
- Review the docker logs. You might have find there are issues with your pat variables, volumes, or files left over in transcoding directories due to interuptions.
- The transcoding process will retain logs in the mapped /docker-transcodeautomation/data volume.
- You might run into a scenario where you replace an already transcoded file and the new file doesn't transcode. This can be resolved with the update-processed media function. See the related section of the [README](#using-included-media-functions).