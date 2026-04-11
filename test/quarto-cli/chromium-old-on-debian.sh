#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

cat <<"EOF" >/tmp/test.qmd
---
title: Test
format:
  gfm:
    mermaid-format: png
---

```{mermaid}
flowchart LR
  A[Hard edge] --> B(Round edge)
  B --> C{Decision}
  C --> D[Result one]
  C --> E[Result two]
```
EOF

# Feature-specific tests
check "check rendering" quarto render /tmp/test.qmd

# Report result
reportResults
