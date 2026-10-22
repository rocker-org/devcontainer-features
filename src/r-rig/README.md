
# R (via rig) (r-rig)

Installs R (via rig), some R packages, and needed system dependencies. Optionally installs the arf R console. Note: May require source code compilation for R packages.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-rig:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of R, if not the latest release version. | string | release |
| pakVersion | Version of pak to install. By default, the stable version is installed if needed. | string | auto |
| vscodeRSupport | Install R packages to make vscode-R work. minimal means the packages required by the session watcher of vscode-R (processx, later, jsonlite and rstudioapi), lsp means minimal plus the languageserver package, full means lsp plus the jgd package (the graphics device for the vscode-R plot viewer). | string | minimal |
| installDevTools | Install the devtools R package. | boolean | false |
| installREnv | Install the renv R package. | boolean | false |
| installRMarkdown | Install the rmarkdown R package. It is required for R Markdown or Quarto documentation. Note that this feature does not install pandoc, use the pandoc Feature. | boolean | false |
| arfVersion | Install arf (R console, https://github.com/eitsupi/arf) from GitHub releases. latest means the latest stable release, or specify a version like `0.6.0`. Requires glibc >= 2.34. | string | none |

## Customizations

### VS Code Extensions

- `REditorSupport.r`

<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platforms `debian` and `ubuntu` (LTS).

This feature installs system requirements via `apt`, so it only supports Debian-based distributions.
To install arf (the `arfVersion` option), glibc >= 2.34 is required (e.g. Debian 12+ or Ubuntu 22.04+).

## Install R

This feature uses [rig](https://github.com/r-lib/rig) to install [R](https://www.r-project.org/).

The `version` option accepts `release` (`latest` is an alias), `devel`, a minor version such as `4.4`,
a full version such as `4.4.1`, or a major version such as `4`
(the latest version of the given major version is installed).

Note that rig does not manage R installed outside of rig.
If R is already installed and `"version": "none"` is set, rig will not be installed.

## R package installation

The R packages are installed with [the pak package](https://pak.r-lib.org/) into the user's library
by the non-root user (the `remoteUser` or the automatically detected user),
so that they can be updated from R inside the container.

### Binary installation from Posit Public Package Manager

rig configures [Posit Public Package Manager](https://p3m.dev) (P3M) as the package repository.
Binary packages are used where P3M provides them (e.g. Ubuntu 24.04 or later on amd64 and arm64, and Ubuntu 20.04, 22.04 and Debian on amd64).
Otherwise, the R packages are installed from source, which takes longer to build.
Please check the P3M website for the current list of supported platforms.

For more information, please check [the Rocker Project website](https://rocker-project.org/use/extending.html).

The options that install R packages are not guaranteed to work with every R version.
Recent versions of many packages require newer R (e.g. many tidyverse and r-lib packages require R >= 4.1),
so installation may fail on old R versions.

If you want to install more R packages during the container build phase,
you can use [the `ghcr.io/rocker-org/devcontainer-features/r-packages` Feature](https://github.com/rocker-org/devcontainer-features/blob/main/src/r-packages).

## System requirements

At build time, this feature installs the system requirements of the R packages in two phases.
First, the non-root user runs `pak::pkg_sysreqs()` to get the commands to install the system requirements.
Then root runs the commands (using `apt`).
Finally, the non-root user installs the R packages with `PKG_SYSREQS=false`.
This does not depend on `sudo` being available at build time.

At runtime, pak installs the system requirements automatically when R packages are installed
as root or by a user who can use `sudo` without a password.
To disable this, set `PKG_SYSREQS` to `false` in `remoteEnv` or `containerEnv`.

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/r-rig:2": {}
    },
    "remoteEnv": {
        "PKG_SYSREQS": "false"
    }
}
```

> [!WARNING]
> The rmarkdown package declares pandoc as a system requirement.
> If pandoc is not installed as a dpkg package (e.g. pandoc bundled with Quarto, or the one in the rocker images),
> an old pandoc may be installed via `apt`.
> To avoid this, use the pandoc Feature, `ghcr.io/rocker-org/devcontainer-features/pandoc`.
> This feature is installed after it, so pak detects the installed pandoc.

## VS Code

The vscode-R 3.x extension uses the sess package as the session watcher.
The `vscodeRSupport` option installs the packages sess depends on (processx, later, jsonlite and rstudioapi),
the languageserver package (lsp), and the jgd package (full).
With the `r.plot.backend` setting `auto`, the plot viewer prefers jgd.

To use [arf](https://github.com/eitsupi/arf) as the R console in VS Code, set `arfVersion` and add the settings as follows.

```json
{
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/r-rig:2": {
            "arfVersion": "latest"
        }
    },
    "customizations": {
        "vscode": {
            "settings": {
                "r.consolePath": "arf",
                "r.bracketedPaste": true
            }
        }
    }
}
```

## Migrating from v1

- `installRadian`: removed. Use `arfVersion` to install arf instead.
  Existing radian command history can be imported into [arf](https://github.com/eitsupi/arf).
  Re-importing is safe because duplicates are skipped.
  If the history was kept with the `ghcr.io/rocker-org/devcontainer-features/r-history` Feature, pass the file explicitly.

  ```sh
  # Preview (dry run)
  arf history import --from radian --dry-run
  # Import from radian (default: ~/.radian_history)
  arf history import --from radian
  # Import from the history file kept by the r-history Feature
  arf history import --from radian --file /dc/r-history/.radian_history
  ```
- `vscodeRSupport`: full installs jgd instead of httpgd. minimal installs processx, later, jsonlite and rstudioapi instead of jsonlite and rlang.
- `installVscDebugger`: removed. There is no replacement in this feature, install it manually if needed.
- `installJupyterlab`: removed. Use a Python Feature and `pip install jupyterlab`,
  and the r-packages Feature to install IRkernel, then run `IRkernel::installspec()`.
- `pandocVersion`: removed. Use the pandoc Feature, `ghcr.io/rocker-org/devcontainer-features/pandoc`.
- System requirements are now enabled (v1 set `PKG_SYSREQS=false`).
- Python (`pip`) is no longer used.

## References

- [rig](https://github.com/r-lib/rig)
- [pak](https://pak.r-lib.org)
- [arf](https://github.com/eitsupi/arf)
- [vscode-R](https://github.com/REditorSupport/vscode-R)
- [Rocker Project](https://rocker-project.org)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/r-rig/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
