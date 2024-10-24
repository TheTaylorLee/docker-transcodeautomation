# Changelog
- 1.0 Initial images released.
- 1.1.0 Convert plex name in variables to MEDIA.
- 1.1.1 Fixed update-processed media function so it properly calls ffprobe.
- 1.1.2 Fixed get-notprocessed to show days in the file age output.
- 2.0.0 Updated to handle one media file at a time, make the recover folder optional, and added env variables for various processing options.
- 2.1.0 Updated log output and updatedby sql entries to reflect new function names. Used for information and debugging output.
- 2.2.0 Remove MediaFunctions module unused private functions, and update get-childitem to use include instead of exclude on all functions.
- 2.3.0 Update transcode selections to not downmix 7.1 audio
- 2.4.0 Add the ability to specify custom ffmpeg options within reason of what will work with the current automation process. Option added to customize seperately for movies and shows. Fixed audio upmixing and downmixing
- 2.5.0 Added updatemetadata on first run functionality.
- 2.6.0 Update log output for more verbosity. Update certain logs with variables to ensure accuracy
- 2.7.0 Update lastwritetime on media moved to recover folder. This guarantees files older than BACKUPRETENTION period are't removed early.
- 2.7.1 Remove update-statistics output from logs
- 2.7.2 Added latest tag
- 2.8.0 Add Transcode time option
- 2.9.0 publish ghcr image
- 2.10.0 Add ci/cd actions workflow
- 2.10.1 Testing ci/cd workflow
- 2.10.2 Add handling for when $env:BACKUPPROCESSED is false. Sourcefile wasn't removed causing processing to halt.
- 2.11.0 Add StatisticsLive table so stats are updated every process loop and not only once a day.
- 2.11.1 Fix script not imported and missing environment variables
- 2.11.2 Update log output
- 2.12.0 Update Update-Statistics Mediafunction
- 2.13.0 Testing updated ci/cd workflow
- 2.13.1 Fix for missing variable in debug log filename that should of populated debug log dates.
- 2.13.1-2 rerun workflow
- 2.14.0 Copy pssqlite module directly into the global modules directory and don't include in build folder. This will reduce the image size and remove PSGallery as a failure point from ci/cd build processes.
- 2.14.1 Updating media functions to use environment variables for parameters. This will reduce the length of typing commands.
    - Reduced log retention to 14 days from 90
    - Improved performance of certain functions that are slowed by wsl volume performance.
- 2.15.0 Make CRF Variables optional
- 2.15.1 fix Get-Mediafunctions duplicated foreground color parameter for write-host.
- 2.16.0 Added handling to only transcode a file if enough free space exists prior to processing
- 2.17.0 Add psreadline options for better intellisense and History handling. Useful for included functions
- 2.17.1 Update get-missingyear so it doesn't truncate long paths
- 2.18.0 Add Get-EmptyFolder
- 2.18.1 Move write-output nested in the wrong script block
- 2.19.0 Add option to configure transcode delay
- 2.19.1 fix for issue [#25](https://github.com/TheTaylorLee/docker-transcodeautomation/issues/25)
- 2.20.0 Stop downgrading higher quality audio to aac. Use -c:a copy as the new default option
- 2.20.1 Fix for Issue [#29](https://github.com/TheTaylorLee/docker-transcodeautomation/issues/29)
- 2.20.2 Add handling so that move-mediafiletofolder doesn't process the else blocks unless a database entry exists. This should of been added during version 2.20.1
- 2.21.0 Feature Issue [#31](https://github.com/TheTaylorLee/docker-transcodeautomation/issues/31). Add integrity checks and run scheduled update-processed function.
- 2.21.1 Fix update-processed movie else loop conditions improperly configured.
- 2.22.0 Add UpdateProcessedLog Table Setup to Invoke-DBSetup function
- 2.23.0 Change log information charactors to a format that doesn't require escaping when using regex. The new strings will also provide color coding if using dozzle.
- 2.23.1 Skipped branch workflow in previous release. This version is simply to trigger the workflows.
- 2.23.2 Skipped branch workflow in previous release. This version is simply to trigger the workflows.
- 2.23.3 Update write-warnings and write-errors to use write-output
- 2.23.4 Split prod workflow up so that errored job reruns can be completed faster.
- 2.23.5 Fix workflow
- 2.23.6 Fix workflow
- 2.24.0 Change backup database frequency to only one week.
- 2.24.1 Update readme and remove legacy module functions
- 2.24.2 Failed to use a dev branch for 2.24.1 and workflows didn't run. Using 2.24.2 to trigger workflows and test for bugs.
- 2.25.0 Add the following to surpress verbose output, but still display stats. This will make logs easier to read by removing thousands of unneeded lines. (-hide_banner -loglevel error -stats)
- 2.25.1 Add the suppress output parameters to Invoke-Process<media/show> functions. Larger file sizes resulted in updating metadata only and those runs of ffmpeg were missing the parameters.
- 3.0.0 Deprecating Ubuntu Build and update alpine build
- 3.1.0 issues[#48](https://github.com/TheTaylorLee/docker-transcodeautomation/issues/48) fix using literalpath
- 3.1.1 issue [#29](https://github.com/TheTaylorLee/docker-transcodeautomation/issues/29) may have been misunderstood. There was a different issue or an additional issue. Now both issues are handled by ensuring filtering is occuring for movies and shows blocks and preventing those running when they shouldn't. The old fix will remain as a solution should the original considered exception occur.
- 3.1.2 fix move-filetomediafolder in optional media functions so parameters don't need supplied.