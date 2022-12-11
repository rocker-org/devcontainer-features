#!/usr/bin/env bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

cat <<"EOF" >/tmp/test.qmd
---
title: Test
engine: jupyter
---

```{python}
print("Hello Quarto!")
```
EOF

# Feature-specific tests
check "ensure i am user jovyan"  bash -c "whoami | grep 'jovyan'"
check "check rendering" quarto render /tmp/test.qmd

# Report result
reportResults
