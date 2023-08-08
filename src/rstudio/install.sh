#!/usr/bin/env bash

set -e

export DEBIAN_FRONTEND=noninteractive
export DEFAULT_USER=${_REMOTE_USER}
export RSTUDIO_VERSION=$RSTUDIOVERSION
export PASSWORD=${PASSWORD:-$DEFAULT_USER}

bash ./rocker_scripts/install_rstudio.sh

# create the directories and configurations
mkdir /tmp/rstudio-server-data
mkdir /tmp/db-conf

cat <<EOF> /tmp/db-conf/db.conf
provider=sqlite
directory=/tmp/db-conf
EOF

chown -R ${DEFAULT_USER}:${DEFAULT_USER} /tmp/rstudio-server-data
chown -R ${DEFAULT_USER}:${DEFAULT_USER} /tmp/db-conf
