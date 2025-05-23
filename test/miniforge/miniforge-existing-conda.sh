#!/usr/bin/env bash

set -e

# shellcheck source=/dev/null
source dev-container-features-test-lib

# Check that conda is installed
check "conda" conda --version

# Report result
reportResults
