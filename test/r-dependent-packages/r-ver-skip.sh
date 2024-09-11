#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R pak package" bash -c "R -q -e 'names(installed.packages()[, 3])' | grep pak"

# Report result
reportResults
