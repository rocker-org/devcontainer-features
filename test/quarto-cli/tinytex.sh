#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

cat <<"EOF" >/tmp/test.qmd
---
title: Test
format:
    pdf: default
---

Hello Quarto!
EOF

# Feature-specific tests
check "check rendering" quarto render /tmp/test.qmd

# Report result
reportResults
