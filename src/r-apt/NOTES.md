<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platforms `debian`, `ubuntu` LTS.

To install arf (the `arfVersion` option), glibc >= 2.34 is required (e.g. Debian 12+ or Ubuntu 22.04+).

Note that this Feature only supports non-R images. If R is already installed, installation will be failed.

## R package installation

### Binary installation via apt

This feature will configure apt to install R and R packages.

Packages that can be installed via apt can be displayed with the following command.

```sh
apt-cache search "^r-.*" | sort
```

For example, the following command installs the dplyr package.

```sh
apt-get -y install --no-install-recommends r-cran-dplyr
```

Thanks to [r2u](https://eddelbuettel.github.io/r2u/), on Ubuntu,
all packages on CRAN and BioConductor can be installed via apt.

If you want to install R packages via apt during the container build phase (as opposed to installing R packages using the [`r-packages` Feature](https://github.com/rocker-org/devcontainer-features/tree/main/src/r-packages)),
you can use [the `ghcr.io/rocker-org/devcontainer-features/apt-packages` Feature](https://github.com/rocker-org/devcontainer-features/blob/main/src/apt-packages)
to do so.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-apt:latest": {},
    "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
        "packages": "r-cran-curl"
    }
},
"overrideFeatureInstallOrder": [
    "ghcr.io/rocker-org/devcontainer-features/r-apt"
]
```

`ghcr.io/rocker-org/devcontainer-features/apt-packages` is not guaranteed to install after this Feature,
so be sure to set up [the `overrideFeatureInstallOrder` property](https://containers.dev/implementors/features/#overrideFeatureInstallOrder).

When installing R packages via `r-cran-<package>` using the `apt-packages` Feature, R package name references must be lowercase. For example, the following snippet installs the kableExtra R package.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-apt:latest": {},
    "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
        "packages": "r-cran-kableextra"
    }
},
"overrideFeatureInstallOrder": [
    "ghcr.io/rocker-org/devcontainer-features/r-apt"
]
```

### Source installation via R

Packages that cannot be installed via apt must be installed using the R functions.

For more information, please check [the Rocker Project website](https://rocker-project.org/use/extending.html).


### Binary installation via R with bspm

If set the `installBspm` option to `true`, this Feature will install and set up
the [bspm R package](https://github.com/Enchufa2/bspm).

bspm provides functions to manage packages via the distribution's package manager.

Known limitation: bspm does not seem to work correctly on Debian.
(<https://github.com/rocker-org/devcontainer-features/pull/169#issuecomment-1665839740>)

## VS Code

The vscode-R 3.x extension uses the sess package as the session watcher.
The `vscodeRSupport` option installs the packages sess depends on (processx, later, jsonlite and rstudioapi),
the languageserver package (lsp), and the jgd package (full).
With the `r.plot.backend` setting `auto`, the plot viewer prefers jgd.

On Debian, the languageserver and jgd packages are not available via apt, so they are installed from source via R.

To use [arf](https://github.com/eitsupi/arf) as the R console in VS Code, set `arfVersion` and add the settings as follows.

```json
{
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/r-apt:1": {
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

## Migrating from 0.x

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
  install IRkernel (e.g. `r-cran-irkernel` via apt), then run `IRkernel::installspec()`.
- Python (`pip`) is no longer used.

## References

- [arf](https://github.com/eitsupi/arf)
- [vscode-R](https://github.com/REditorSupport/vscode-R)
- [Rocker Project](https://rocker-project.org)
