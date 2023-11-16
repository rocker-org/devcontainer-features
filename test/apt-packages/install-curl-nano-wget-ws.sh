#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "curl" curl --version
check "nano" nano --version
check "wget" wget --version

# Report result
reportResults
