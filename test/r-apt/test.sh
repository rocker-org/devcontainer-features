#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "version" R -q -e "sessionInfo()"

# Check package installation via R function
R -q -e 'install.packages("R6")'
check "R6" R -q -e 'names(installed.packages()[, 3])' | grep R6

# Report result
reportResults
