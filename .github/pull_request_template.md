The pull request checklist must be reviewed and completed prior to completing a pull request. This is to ensure stable production images and avoid overwrites of ghcr version tags.

# Pull Request Checklist
- [ ] Reviewed the [Contributing Guidelines](https://github.com/TheTaylorLee/docker-transcodeautomation/blob/master/contributing.md)
- [ ] Update changelog.md
- [ ] Update version with new semver
- [ ] Build dev images and test changes
    - [ ] Rename a file and ensure the database entry updates paths & retains statistics.
    - [ ] Delete a file. The associated table entry should mark fileexists false and not modify the comment.
        - [ ] Update-Processed once run should mark the comment NULL
    - [ ] Replace a file with a file of the same name, but the comment should not match dta-*. The table entry should remain unchanged.
        - [ ] Update-Processed when run should null the comment of the db entry.
        - [ ] Next run the table entry should be renamed and NULL fields should have data. Ensure entries are accurate.
    - [ ] Add a new unique file and see that a table entry is created and the file is transcoded
    - [ ] Move a file to a new parent directory provided to MEDIA(MOVIE/SHOWS)FOLDERS environment variable. Statistics should be preserved.
- [ ] If this is a new major release with breaking changes, a github release must first be created.