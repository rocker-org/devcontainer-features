#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "whoami" bash -c "[ \"\$(whoami)\" = vscode ]"
check "languageserver" R -q -e "library(languageserver)"
check "languageserver is in the user library" R -q -e 'stopifnot(startsWith(normalizePath(find.package("languageserver")), "/home/vscode"))'
check "pak is in the user library" R -q -e 'stopifnot(startsWith(normalizePath(find.package("pak")), "/home/vscode"))'

# Report result
reportResults
