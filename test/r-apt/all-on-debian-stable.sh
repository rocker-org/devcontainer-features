#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R" R -q -e "sessionInfo()"
for pkg in processx later jsonlite rstudioapi languageserver jgd devtools renv rmarkdown; do
    check "${pkg}" R -q -e "library(${pkg})"
done
check "rmarkdown pandoc" R -q -e 'rmarkdown::pandoc_version()'
check "arf" arf --version

# Report result
reportResults
