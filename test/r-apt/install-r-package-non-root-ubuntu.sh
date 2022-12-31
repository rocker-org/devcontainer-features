#!/usr/bin/env bash

set -e

packages="jsonlite rlang"
R -q -e "pak::pak(unlist(strsplit('${packages}', ' ')))"

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "ensure i am user vscode"  bash -c "whoami | grep 'vscode'"
check "R" R -q -e "sessionInfo()"
check "jsonlite" R -q -e 'names(installed.packages()[, 3])' | grep jsonlite
check "rlang" R -q -e 'names(installed.packages()[, 3])' | grep rlang

# Report result
reportResults
