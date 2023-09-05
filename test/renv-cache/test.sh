#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests

id "$(whoami)"
ls -l /renv

# Report result
reportResults
