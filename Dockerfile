# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# Modified by Taylor Lee to include additonal customizations under the MIT License.

# Docker image file that describes an Ubuntu20.04 image with PowerShell installed from Microsoft APT Repo
FROM ubuntu:22.04 AS installer-env

# Define Args for the needed to add the package
ARG PS_VERSION=7.3.0-preview.8
ARG PS_PACKAGE=powershell-preview_${PS_VERSION}-1.deb_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7-preview

RUN --mount=type=cache,target=/var/lib/apt \
    --mount=type=cache,target=/var/cache/apt \
    apt-get update \
    && apt-get install --no-install-recommends -y \
    # curl is required to grab the Linux package
    curl \
    # less is required for help in powershell
    less \
    # requied to setup the locale
    locales \
    # required for SSL
    ca-certificates \
    # Download the Linux package and save it
    && echo ${PS_PACKAGE_URL} \
    && curl -sSL ${PS_PACKAGE_URL} -o /tmp/powershell.deb

# Install the deb file in this image and make powershell available
FROM ubuntu:22.04 AS final-image

# # Define args needed to add the package
ARG PS_VERSION=7.3.0-preview.8
ARG PS_PACKAGE=powershell-preview_${PS_VERSION}-1.deb_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7-preview

# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Ubuntu-22.04 \
    # Set FFTools variables (Modified entry)
    FFToolsSource=/docker-transcodeautomation/transcoding/ \
    FFToolsTarget=/docker-transcodeautomation/transcoding/new/

# Install dependencies and clean up
RUN --mount=from=installer-env,target=/mnt/pwsh,source=/tmp \
    --mount=type=cache,target=/var/lib/apt \
    --mount=type=cache,target=/var/cache/apt \
    apt-get update \
    && apt-get install --no-install-recommends -y /mnt/pwsh/powershell.deb \
    && apt-get install --no-install-recommends -y \
    # less is required for help in powershell
    less \
    # requied to setup the locale
    locales \
    # required for SSL
    ca-certificates \
    gss-ntlmssp \
    libicu70 \
    libssl3 \
    libc6 \
    libgcc1 \
    libgssapi-krb5-2 \
    liblttng-ust1 \
    libstdc++6 \
    zlib1g \
    # Install ffmpeg (Modified entry)
    ffmpeg \
    # PowerShell remoting over SSH dependencies
    openssh-client \
    && apt-get dist-upgrade -y \
    && locale-gen $LANG && update-locale \
    && export POWERSHELL_TELEMETRY_OPTOUT=1 \
    # Give all user execute permissions and remove write permissions for others
    && chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    # Create the pwsh symbolic link that points to powershell
    && ln -sf ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    # Create the pwsh-preview symbolic link that points to powershell
    && ln -sf ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-preview \
    && pwsh \
    -NoLogo \
    -NoProfile \
    -Command " \
    \$ErrorActionPreference = 'Stop' ; \
    \$ProgressPreference = 'SilentlyContinue' ; \
    while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
    Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
    Start-Sleep -Seconds 6 ; \
    }" \
    # Install pssqlite module for use by manual functions. (Modified entry)
    && pwsh \
    -NoLogo \
    -NoProfile \
    -Command " \
    \$ErrorActionPreference = 'Stop' ; \
    \$ProgressPreference = 'SilentlyContinue' ; \
    Install-Module pssqlite -force -allowclobber"

# Copy in modules (Modified entry)
COPY build /docker-transcodeautomation
COPY modules/MediaFunctions /root/.local/share/powershell/Modules/MediaFunctions

# Use PowerShell as the default shell
# Use array to avoid Docker prepending /bin/sh -c
CMD [ "pwsh-preview", "-f", "/docker-transcodeautomation/Invoke-TranscodeAutomation.ps1" ]