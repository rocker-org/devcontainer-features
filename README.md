# Dev Container Features (for R)

This repository contains a _collection_ of Dev Container Features.

For a detailed explanation of Dev Container Features,
please check [the specification](https://containers.dev/implementors/features/) and
[the devcontainers' official Development Container Features repository](https://github.com/devcontainers/features).

This repository is based on the [the `devcontainers/features` repository](https://github.com/devcontainers/features),
and intended to make it easy to add R-related functionality on top of the Debian base containers.

## Contents

### [`pandoc`](src/pandoc/README.md)

Install [Pandoc](https://pandoc.org/).

### [`quarto-cli`](src/quarto-cli/README.md)

Install [the Quarto CLI](https://quarto.org/).

### [`r-apt`](src/r-apt/README.md)

Install the latest [R](https://www.r-project.org/) and R packages via apt.
When installing R packages via apt, dependencies are automatically installed as well, and it is very fast.

### [`r-rig`](src/r-rig/README.md)

Install a version of [R](https://www.r-project.org/) of your choice using [rig](https://github.com/r-lib/rig).
R packages must be installed via R functions.
