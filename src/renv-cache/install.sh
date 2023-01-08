#!/bin/sh

RENV_PATHS_CACHE=${RENV_PATHS_CACHE:-"/renv/cache"}

USERNAME=${USERNAME:-${_REMOTE_USER}}

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

check_r() {
    if [ ! -x "$(command -v R)" ]; then
        echo "(!) Cannot run R. Please install R before installing this Feature."
        echo "    Skip installation..."
        exit 0
    fi
}

install_renv() {
    if su "$1" -c "R -s -e 'packageVersion(\"renv\")'" >/dev/null 2>&1; then
        echo "renv R package is already installed. Skip renv installation..."
    else
        echo "Install renv R package..."
        mkdir /tmp/renv-cache
        cd /tmp/renv-cache
        su "$1" -c "R -s -e 'install.packages(\"renv\")'"
        cd ..
        rm -rf /tmp/renv-cache
        rm -rf /tmp/Rtmp*
    fi
}

export DEBIAN_FRONTEND=noninteractive

create_cache_dir "${RENV_PATHS_CACHE}" "${USERNAME}"
check_r
install_renv "${USERNAME}"

echo "Done!"
