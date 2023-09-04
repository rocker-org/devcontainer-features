#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
touch "${R_HISTFILE}"
check "cache dir permission" find /dc/r-history/*

# Report result
reportResults
