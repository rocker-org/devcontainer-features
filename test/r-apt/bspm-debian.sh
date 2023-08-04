#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

R -q -e 'install.packages("curl")'

# Feature-specific tests
check "R" R -q -e "sessionInfo()"
check "R curl" R -q -e 'names(installed.packages()[, 3])' | grep curl

# Report result
reportResults
