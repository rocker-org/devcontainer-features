#!/usr/bin/env bash

set -e

# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "Pandoc" pandoc --version | grep 2.17.1.1

# Report result
reportResults
