#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "rmarkdown" R -q -e "library(rmarkdown)"
check "pandoc is available" R -q -e 'stopifnot(rmarkdown::pandoc_available())'
check "pandoc is not the old one provided by apt" R -q -e 'stopifnot(rmarkdown::pandoc_version() >= "3.0")'

# Report result
reportResults
