<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platforms `debian`, `ubuntu` LTS.

Note that this Feature only supports non-R images. If R is already installed, installation will be failed.

## R package installation

### Binary installation via apt

This feature will configure apt to install R and R packages.

Packages that can be installed via apt can be displayed with the following command.

```sh
apt-cache search "^r-.*" | sort
```

For example, the following command installs the `dplyr` package.

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

When installing R packages via `r-cran-<package>` using the `apt-packages` Feature, R package name references must be lowercase. For example, the following snippet installs the {kableExtra} R package.

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
the [`bspm` R package](https://github.com/Enchufa2/bspm).

`bspm` provides functions to manage packages via the distribution's package manager.

Known limitation: `bspm` does not seem to work correctly on Debian.
(<https://github.com/rocker-org/devcontainer-features/pull/169#issuecomment-1665839740>)

## Python package installation

This feature has some options to install Python packages such as `jupyterlab`.
When installing Python packages, if `python3 -m pip` is not available, it will install `python3-pip` via apt.

This feature set `PIP_BREAK_SYSTEM_PACKAGES=1` when installing Python packages.

## References

- [Rocker Project](https://rocker-project.org)
