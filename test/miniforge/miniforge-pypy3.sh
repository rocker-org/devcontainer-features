#!/usr/bin/env bash

set -e

# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "conda" bash -c 'conda --version | grep "24.7.1"'

# Report result
reportResults
