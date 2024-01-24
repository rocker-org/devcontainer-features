#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "cache dir permission" bash -c "test -w /renv/cache/"

# Report result
reportResults
