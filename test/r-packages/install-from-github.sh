#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R crayon package" R -q -e 'names(installed.packages()[, 3])' | grep crayon

# Report result
reportResults
