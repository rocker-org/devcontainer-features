<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platform `ubuntu:focal` and `ubuntu:jammy`.

`linux/arm64` platform supports are currently experimental and only available on daily builds for testing purposes.
([rstudio/rstudio#13340](https://github.com/rstudio/rstudio/issues/13340))

## Start RStudio Server

To run RStudio Server, the `rserver` command should be executed.

If we want to run RStudio Server automatically, for example,
we can set the `rserver` command to `postCreateCommand` as follows.

Since `rserver` uses the 8787 port by default, `"forwardPorts": [8787]` is also configured here.

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/rstudio-server": {}
    },
    "postCreateCommand": {
        "rstudio-start": "rserver"
    },
    "forwardPorts": [
        8787
    ]
}
```

## Available versions

`"stable"` and `"daily"` refer to the latest stable and daily builds
via [the redirect links](https://dailies.rstudio.com/links/).

You can also specify a version number, like `"2023.03"`, `"2023.03.2+454"`.
This pattern matches the highest numbered tag of <https://github.com/rstudio/rstudio>.

## R installation

If the `R` command is not available while this Feature's installation process,
`r-base` will be installed via `apt`.

`ghcr.io/rocker-org/devcontainer-features/r-apt` and `ghcr.io/rocker-org/devcontainer-features/r-rig` are
configured to be installed earlier than this Feature, so R can be installed first with these Features.

For example:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/rstudio-server": {},
        "ghcr.io/rocker-org/devcontainer-features/r-apt": {}
    }
}
```

## References

- [RStudio Server](https://posit.co/products/open-source/rstudio-server/)
- [RStudio Builds](https://dailies.rstudio.com/)
