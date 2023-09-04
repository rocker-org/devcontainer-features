#!/bin/sh

USERNAME=${USERNAME:-${_REMOTE_USER}}

LIFECYCLE_SCRIPTS_DIR="/usr/local/share/rocker-devcontainer-features/r-history/scripts"

set -e

create_cache_dir() {
    if [ -d "$1" ]; then
        echo "Cache directory $1 already exists. Skip creation..."
    else
        echo "Create cache directory $1..."
        mkdir -p "$1"
    fi

    if [ -z "$2" ]; then
        echo "No username provided. Skip chown..."
    else
        echo "Change owner of $1 to $2..."
        chown -R "$2:$2" "$1"
    fi
}

export DEBIAN_FRONTEND=noninteractive

create_cache_dir "/dc/r-history" "${USERNAME}"

# Set Lifecycle scripts
if [ -f oncreate.sh ]; then
    mkdir -p "${LIFECYCLE_SCRIPTS_DIR}"
    cp oncreate.sh "${LIFECYCLE_SCRIPTS_DIR}/oncreate.sh"
fi

echo "Done!"
