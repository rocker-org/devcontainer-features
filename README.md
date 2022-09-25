# Dev Container Features (for R)

This repository contains a _collection_ of devcontainer features.

For a detailed explanation of devcontainer features,
please check [the devcontainers' official devcontainer features repository](https://github.com/devcontainers/features).

This repository is intended to make it easy to add R-related functionality on top of the Debian base containers.

Heavily under development.

## Contents

### [`quarto-cli`](src/quarto-cli/README.md)

Install [the quarto cli](https://quarto.org/).

Currently the arm64 platform is not supported.

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/quarto-cli:0": {
            "version": "latest"
        }
    }
}
```

### [`r-rig`](src/r-rig/README.md)

Install a version of [R](https://www.r-project.org/) of your choice using [rig](https://github.com/r-lib/rig).

There are also options to install some R packages,
but be aware that R packages are source-installed and will take longer to build (except for amd64 Ubuntu).

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
            "ghcr.io/rocker-org/devcontainer-features/r-rig:0": {
                "version": "latest"
            }
    }
}
```
