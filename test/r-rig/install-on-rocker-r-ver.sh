#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R" R --version | grep 4.0.5
check "pandoc" R -q -e 'rmarkdown::pandoc_version()'

# Report result
reportResults
