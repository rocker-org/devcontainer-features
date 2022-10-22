#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

check_packages() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

check_packages git ca-certificates
LATEST_VERSION="$(git ls-remote --tags https://github.com/jgm/pandoc | grep -oP "[0-9]+\\.[0-9]+(\\.[0-9])*" | sort -V | tail -n 1)"

# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "R" R -q -e "sessionInfo()"
check "pandoc" R -q -e 'rmarkdown::pandoc_version()' | grep "$LATEST_VERSION"

# Report result
reportResults
