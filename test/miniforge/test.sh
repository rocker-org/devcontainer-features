#!/usr/bin/env bash

set -e

# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "conda" conda --version
check "mamba" mamba --version
check "install packages" mamba install -y r-base && mamba clean -yaf
check "R" R --version

# Report result
reportResults
