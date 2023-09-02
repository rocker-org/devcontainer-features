
# RStudio Server (rstudio-server)

Installs the RStudio Server, enables to run the RStudio IDE on the browser.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/rstudio-server:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of the RStudio Server, if not stable. | string | stable |
| allowReinstall | Reinstall in case RStudio Server is already installed. | boolean | true |
| singleUser | If `true`, configures as the single user mode. | boolean | true |

<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platform `ubuntu:focal` and `ubuntu:jammy`.

`linux/arm64` platform supports are currently experimental and only available on daily builds for testing purposes.
([rstudio/rstudio#13340](https://github.com/rstudio/rstudio/issues/13340))

## Start RStudio Server

To run RStudio Server, the `rserver` command should be executed.

If we want to run RStudio Server automatically, for example,
we can set the `rserver` command to `postAttachCommand` as follows.

Since `rserver` uses the 8787 port by default, `"forwardPorts": [8787]` is also configured here.

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/rstudio-server": {}
    },
    "postAttachCommand": {
        "rstudio-start": "rserver"
    },
    "forwardPorts": [
        8787
    ]
}
```

## RStudio's initial working directory

This Feature sets `onCreateCommand`, and the `onCreateCommand` sets `initial_working_directory`
to file `rstudio-prefs.json` immediately after container creation.

If `rstudio-prefs.json` already exists when the container is created,
the `jq` command must be installed to update `rstudio-prefs.json`.

For example, we can install `jq` with the
[`ghcr.io/rocker-org/devcontainer-features/apt-packages`](https://github.com/rocker-org/devcontainer-features/tree/main/src/apt-packages)
Feature as follows:

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
        "packages": "jq"
    },
    "ghcr.io/rocker-org/devcontainer-features/rstudio-server": {}
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


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/rstudio-server/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
