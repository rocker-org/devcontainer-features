#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R cli package" bash -c "R -q -e 'names(installed.packages()[, 3])' | grep cli"
check "R rlang package" bash -c "R -q -e 'names(installed.packages()[, 3])' | grep curl"
check "R rlang package" bash -c "R -q -e 'names(installed.packages()[, 3])' | grep crayon"

# Report result
reportResults
