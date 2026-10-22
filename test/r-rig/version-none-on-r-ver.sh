#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "languageserver" R -q -e "library(languageserver)"
check "jsonlite" R -q -e "library(jsonlite)"

# Report result
reportResults
