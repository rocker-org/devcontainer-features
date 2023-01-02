#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R curl package" R -q -e 'names(installed.packages()[, 3])' | grep curl
check "R R6 package" R -q -e 'names(installed.packages()[, 3])' | grep R6

# Report result
reportResults
