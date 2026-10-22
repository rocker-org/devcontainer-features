#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "library(xml2)" R -q -e 'library(xml2)'

# Report result
reportResults
