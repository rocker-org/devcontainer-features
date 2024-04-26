#!/usr/bin/env bash

set -e

LATEST_VERSION="$(git ls-remote --tags https://github.com/conda-forge/miniforge | grep -oP "[0-9]+\\.[0-9]+.[0-9]+" | sort -V | tail -n 1)"

# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "conda" conda --version | grep "$LATEST_VERSION"
check "mamba" mamba --version
check "install packages" mamba install -y r-base && mamba clean -yaf
check "R" R --version

# Report result
reportResults
