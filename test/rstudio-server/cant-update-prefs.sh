#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
export prefs_json_path=~/.config/rstudio/rstudio-prefs.json
check "version" bash -c 'rstudio-server version'
check "rstudio prefs 1" bash -c "cat ${prefs_json_path} | grep initial_working_directory | grep /home/rstudio"
check "rstudio prefs 2" bash -c "cat ${prefs_json_path} | grep foo | grep bar"

# Report result
reportResults
