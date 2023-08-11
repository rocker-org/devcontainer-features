#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R version" bash -c 'R --version | grep 4.3.0'
check "version" bash -c 'rstudio-server version'

# Report result
reportResults
