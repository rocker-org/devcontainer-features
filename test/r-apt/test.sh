#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "version" R -q -e "sessionInfo()"

# Check package installation via R function
R -q -e 'install.packages("glue")'

# Report result
reportResults
