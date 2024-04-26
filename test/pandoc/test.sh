#!/usr/bin/env bash

set -e

LATEST_VERSION="$(git ls-remote --tags https://github.com/jgm/pandoc | grep -oP "[0-9]+\\.[0-9]+(\\.[0-9]+)*" | sort -V | tail -n 1)"

# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "Pandoc" pandoc --version | grep "$LATEST_VERSION"

# Report result
reportResults
