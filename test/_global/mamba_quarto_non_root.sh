#!/usr/bin/env bash

set -e

mamba install -y r-rmarkdown jupyterlab && mamba clean -yaf

source dev-container-features-test-lib

cat <<"EOF" >/tmp/knitr.qmd
---
title: Test
engine: knitr
---

```{r}
cat("Hello Quarto!")
```
EOF

cat <<"EOF" >/tmp/jupyter.qmd
---
title: Test
engine: jupyter
---

```{r}
cat("Hello Quarto!")
```
EOF

# Feature-specific tests
check "check rendering (knitr)" quarto render /tmp/knitr.qmd
check "check rendering (jupyter)" quarto render /tmp/jupyter.qmd
# Report result
reportResults
