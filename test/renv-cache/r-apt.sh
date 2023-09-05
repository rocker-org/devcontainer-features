#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

id "$(whoami)"
ls -l /renv

# Feature-specific tests
check "renv" R -q -e 'packageVersion("renv")'
check "renv::install" R -q -e 'renv::install("jsonlite")'
check "cache dir" find /renv/cache/*

id "$(whoami)"
ls -l /renv

# Report result
reportResults
