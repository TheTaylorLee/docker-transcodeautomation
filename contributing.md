## Contributing

**Contribution Guidelines**

- An issue should be opened prior to any work being done. Use one of the existing templates.
- Create a  branch off of the main branch. Name the branch sensibly regarding the changes made or the version it would update the release to.
- Update the changelog with the new version number and a description of changes. See the "Version Guidelines" section of this document.
- Update the version file with the new semantic version.

**Pull Request**

- Once the changes are ready for testing a pull request may be submitted to the repository.
- The pull request should use the name format outlined below in the "Pull Request Format" section of this document.
- Code will be reviewed and once approved workflows will run to create dev docker images.
- Dev images should be tested by the individual submitting the changes and might be reviewed by @TheTaylorLee
- Once Dev Images have been tested and approved, the pull request will be merged to the main branch and workflows will create new production images.

#### Pull Request format
- Type: Description

- ALLOWED type VALUES:

    Type | Description
    ---------|----------
    build | A change to the overall structure of a module
    ci | changes to CI/CD
    docs | Documentation Changes
    feat | A new feature
    fix | A bug fix
    func | New function
    note | If the commit doesn't fall into other categories, this allows for a free hand description
    rel | New module release versions
    test | Testing changes

**Version Guidelines**
MAJOR.MINOR.REVISION

MAJOR: Adding multiple new functions or major refactoring of a module \
MINOR: Adding or updating few functions that don't result in functional changes to a module \
REVISION: is usually a fix for a previous minor release (no new functionality).
