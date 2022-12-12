#!/usr/bin/env bash

PACKAGES=${PACKAGES:-""}
UPGRADE_PACKAGES=${UPGRADEPACKAGES:-"false"}

APT_PACKAGES=("${PACKAGES//,/ }")

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

export DEBIAN_FRONTEND=noninteractive

# shellcheck disable=SC2048 disable=SC2086
check_packages ${APT_PACKAGES[*]}

if [ "${UPGRADE_PACKAGES}" = "true" ]; then
    apt_get_update
    apt-get -y upgrade --no-install-recommends
    apt-get autoremove -y
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
