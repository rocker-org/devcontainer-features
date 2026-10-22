#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "arf version" bash -c "arf --version | grep 0.6.0"
check "R" R -q -e "sessionInfo()"

# Report result
reportResults
