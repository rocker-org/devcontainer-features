# Dev Container Features by Rocker Project

This repository contains a _collection_ of Dev Container Features.

For a detailed explanation of Dev Container Features,
please check [the specification](https://containers.dev/implementors/features/) and
[the devcontainers' official Development Container Features repository](https://github.com/devcontainers/features).

This repository is based on the [the `devcontainers/features` repository](https://github.com/devcontainers/features),
and intended to make it easy to add Rocker Project related functionality.

## Contents

### [`apt-packages`](src/apt-packages/README.md)

Installs packages of the user's choice via apt.

A simple Feature that implements the functionality proposed in
[devcontainers/features#67](https://github.com/devcontainers/features/issues/67).

### [`miniforge`](src/miniforge/README.md)

Install [Conda](https://docs.conda.io) and [Mamba](https://mamba.readthedocs.io)
via [Miniforge](https://github.com/conda-forge/miniforge) installer.
[conda-forge](https://conda-forge.org/) set as the default (and only) channel.

Similar to
[`ghcr.io/devcontainers/features/conda`](https://github.com/devcontainers/features/blob/main/src/conda/README.md).

### [`pandoc`](src/pandoc/README.md)

Install [Pandoc](https://pandoc.org/).

### [`quarto-cli`](src/quarto-cli/README.md)

Install [the Quarto CLI](https://quarto.org/).

### [`r-apt`](src/r-apt/README.md)

Install the latest [R](https://www.r-project.org/) and R packages via apt.
When installing R packages via apt, dependencies are automatically installed as well, and it is very fast.

### [`r-history`](src/r-history/README.md)

A simple setup to preserve R terminal history across Dev Container instances.
Supports [Radian](https://github.com/randy3k/radian) and
[RStudio](https://posit.co/products/open-source/rstudio-server/)'s R console.

### [`r-packages`](src/r-packages/README.md)

Install R packages of the user's choice via [the `pak::pak()` function](https://pak.r-lib.org/reference/pak.html).

### [`r-rig`](src/r-rig/README.md)

Install a version of [R](https://www.r-project.org/) of your choice using [rig](https://github.com/r-lib/rig).
R packages must be installed via R functions.

### [`renv-cache`](src/renv-cache/README.md)

A simple setup to share [`renv`](https://rstudio.github.io/renv/) cache among multiple containers.

### [`rstudio-server`](src/rstudio-server/README.md)

Install [RStudio Server](https://posit.co/products/open-source/rstudio-server/).
