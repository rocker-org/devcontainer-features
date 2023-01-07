#!/bin/sh

USERNAME=${USERNAME:-${_REMOTE_USER}}

set -e

if [ ! -x "$(command -v R)" ]; then
    echo "(!) Cannot run R. Please install R before installing this Feature."
    echo "    Skip installation..."
    exit 0
fi

install_renv() {
    if su "${USERNAME}" -c "R -s -e 'packageVersion(\"renv\")'" >/dev/null 2>&1; then
        echo "renv R package is already installed. Skip renv installation..."
    else
        echo "Install renv R package..."
        mkdir /tmp/renv-cache
        cd /tmp/renv-cache
        su "${USERNAME}" -c "R -s -e 'install.packages(\"renv\")'"
        cd ..
        rm -rf /tmp/renv-cache
        rm -rf /tmp/Rtmp*
    fi
}

export DEBIAN_FRONTEND=noninteractive

install_renv

echo "Done!"
