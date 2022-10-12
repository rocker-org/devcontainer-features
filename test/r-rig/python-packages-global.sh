#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R" R -q -e "sessionInfo()"
check "radian" radian --version

# Report result
reportResults
