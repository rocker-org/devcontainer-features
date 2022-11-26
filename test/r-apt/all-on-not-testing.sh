#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "R" R -q -e "sessionInfo()"
check "languageserver" R -q -e 'names(installed.packages()[, 3])' | grep languageserver
check "httpgd" R -q -e 'names(installed.packages()[, 3])' | grep httpgd
check "devtools" R -q -e 'names(installed.packages()[, 3])' | grep devtools
check "vscDebugger" R -q -e 'names(installed.packages()[, 3])' | grep vscDebugger
check "renv" R -q -e 'names(installed.packages()[, 3])' | grep renv
check "rmarkdown" R -q -e 'rmarkdown::pandoc_version()'
check "jupyter" jupyter kernelspec list | grep jupyter/kernels/ir
check "radian" radian --version

# Report result
reportResults
