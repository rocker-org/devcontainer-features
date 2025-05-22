#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "version"  bash -c "quarto --version | grep '1.0.38'"

# Report result
reportResults
