#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "version" bash -c 'rstudio-server version | grep 2023.03.2+454'

# Report result
reportResults
