## Updatemetadata may be used during initial adoption of this container and is used when migrating from an earlier version to 4.1.0+ versions.
- Compare-Files, Get-Failed, and Repair-Files
- These are scripts to inspect files modified using the updatemetadata process.
    - If used these scripts provide a method to check and confirm the integrity of many changed files.
    - If starting with or migrating a large amount of media files, it is recommended to confirm the integrity using these scripts or by another method.
- These scripts expect a backup exists to compare modified files against.

## A script for setting metadata of an already transcoded HDR file to a state where it can be used for testing by this container.
- Initialize-HDRFile