#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "version" bash -c 'rstudio-server version'
check "rstudio prefs" bash -c "cat ~/.config/rstudio/rstudio-prefs.json | grep $(pwd)"

# Report result
reportResults
