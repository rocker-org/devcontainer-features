#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R" R -q -e "sessionInfo()"
for pkg in processx later jsonlite rstudioapi languageserver jgd devtools renv rmarkdown; do
    check "${pkg}" R -q -e "library(${pkg})"
    check "${pkg} is in a writable library" R -q -e "stopifnot(file.access(find.package('${pkg}'), 2) == 0)"
done
check "arf" arf --version
check "system requirements are not disabled" R -q -e 'stopifnot(Sys.getenv("PKG_SYSREQS") != "false")'

# Report result
reportResults
