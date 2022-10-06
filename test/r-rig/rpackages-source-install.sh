#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R" R -q -e "sessionInfo()"
check "rmarkdown" R -q -e 'rmarkdown::pandoc_version()'
check "languageserver" R -q -e 'names(installed.packages()[, 3])' | grep languageserver
check "httpgd" R -q -e 'names(installed.packages()[, 3])' | grep httpgd

# Report result
reportResults
