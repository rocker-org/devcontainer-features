#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature-specific tests
check "version" bash -c 'rstudio-server version'
check "rstudio prefs" bash -c "cat ~/.config/rstudio/rstudio-prefs.json"

# Report result
reportResults
