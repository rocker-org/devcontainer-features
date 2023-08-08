#!/bin/bash

## This is adapted from the script used in https://github.com/rocker-org/rocker-versioned2

## Download and install RStudio server & dependencies uses.
##
## In order of preference, first argument of the script, the RSTUDIO_VERSION variable.
## ex. stable, preview, daily, 1.3.959, 2021.09.1+372, 2021.09.1-372, 2022.06.0-daily+11

set -e

RSTUDIO_VERSION=${1:-${RSTUDIO_VERSION:-"stable"}}
DEFAULT_USER=${DEFAULT_USER:-"rstudio"}

# shellcheck source=/dev/null
source /etc/os-release

ARCH=$(dpkg --print-architecture)

## Download RStudio Server for Ubuntu 18+
DOWNLOAD_FILE=rstudio-server.deb

if [ "$RSTUDIO_VERSION" = "latest" ]; then
    RSTUDIO_VERSION="stable"
fi

# if [ "$UBUNTU_CODENAME" = "focal" ]; then
#     UBUNTU_CODENAME="bionic"
# fi

if [ "$RSTUDIO_VERSION" = "stable" ] || [ "$RSTUDIO_VERSION" = "preview" ] || [ "$RSTUDIO_VERSION" = "daily" ]; then
    # if [ "$UBUNTU_CODENAME" = "bionic" ]; then
    #     UBUNTU_CODENAME="focal"
    # fi
    wget "https://rstudio.org/download/latest/${RSTUDIO_VERSION}/server/${UBUNTU_CODENAME}/rstudio-server-latest-${ARCH}.deb" -O "$DOWNLOAD_FILE"
else
    wget "https://download2.rstudio.org/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-${RSTUDIO_VERSION/"+"/"-"}-${ARCH}.deb" -O "$DOWNLOAD_FILE" ||
        wget "https://s3.amazonaws.com/rstudio-ide-build/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-${RSTUDIO_VERSION/"+"/"-"}-${ARCH}.deb" -O "$DOWNLOAD_FILE"
fi

dpkg -i "$DOWNLOAD_FILE"
rm "$DOWNLOAD_FILE"

ln -fs /usr/lib/rstudio-server/bin/rstudio-server /usr/local/bin
ln -fs /usr/lib/rstudio-server/bin/rserver /usr/local/bin

# https://github.com/rocker-org/rocker-versioned2/issues/137
rm -f /var/lib/rstudio-server/secure-cookie-key

## RStudio wants an /etc/R, will populate from $R_HOME/etc
mkdir -p /etc/R

## Make RStudio compatible with case when R is built from source
## (and thus is at /usr/local/bin/R), because RStudio doesn't obey
## path if a user apt-get installs a package
R_BIN=$(which R)
echo "rsession-which-r=${R_BIN}" >/etc/rstudio/rserver.conf
## use more robust file locking to avoid errors when using shared volumes:
echo "lock-type=advisory" >/etc/rstudio/file-locks

## Prepare optional configuration file to disable authentication
## To de-activate authentication, `disable_auth_rserver.conf` script
## will just need to be overwrite /etc/rstudio/rserver.conf.
## This is triggered by an env var in the user config
cp /etc/rstudio/rserver.conf /etc/rstudio/disable_auth_rserver.conf
echo "auth-none=1" >>/etc/rstudio/disable_auth_rserver.conf

# If CUDA enabled, make sure RStudio knows (config_cuda_R.sh handles this anyway)
if [ -n "$CUDA_HOME" ]; then
    sed -i '/^rsession-ld-library-path/d' /etc/rstudio/rserver.conf
    echo "rsession-ld-library-path=$LD_LIBRARY_PATH" >>/etc/rstudio/rserver.conf
fi

# Log to stderr
cat <<EOF >/etc/rstudio/logging.conf
[*]
log-level=debug
logger-type=syslog
EOF

# set up default user
bash ./rocker_scripts/default_user.sh "${DEFAULT_USER}"

# Clean up
rm -rf /var/lib/apt/lists/*

# Check the RStudio Server
echo -e "Check the RStudio Server version...\n"

rstudio-server version

echo -e "\nInstall RStudio Server, done!"
