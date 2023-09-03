#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
export prefs_json_path=~/.config/rstudio/rstudio-prefs.json
check "version" bash -c 'rstudio-server version'
check "rstudio prefs 1" bash -c "jq -r '.initial_working_directory' ${prefs_json_path} | grep /home/rstudio"
check "rstudio prefs 2" bash -c "jq -r '.foo' ${prefs_json_path} | grep bar"

# Report result
reportResults
