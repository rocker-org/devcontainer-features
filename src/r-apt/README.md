
# R (via apt) (r-apt)

Installs the latest R, some R packages, and needed dependencies. Note: May require source code compilation for some R packages.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-apt:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| vscodeRSupport | Install R packages to make vscode-R work. lsp means the `languageserver` package, full means lsp plus the `httpgd` package. | string | minimal |
| installDevTools | Install the `devtools` R package. | boolean | false |
| installREnv | Install the `renv` R package. | boolean | false |
| installRMarkdown | Install the `rmarkdown` R package. It is required for R Markdown or Quarto documentation. | boolean | false |
| installJupyterlab | Install and setup JupyterLab (via `python3 -m pip`). JupyterLab is a web-based interactive development environment for notebooks. | boolean | false |
| installRadian | Install radian (via `python3 -m pip`). radian is an R console with multiline editing and rich syntax highlight. | boolean | false |
| installVscDebugger | Install the `vscDebugger` R package from the GitHub repo. It is required for the VSCode-R-Debugger. | boolean | false |
| useTesting | For Debian, install packages from Debian testing. If false, the R package installed by apt may be out of date. | boolean | true |

## Customizations

### VS Code Extensions

- `REditorSupport.r`

<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` platform `debian`, `ubuntu:focal` and `ubuntu:jammy`.

If the `useTesting` is `true`, `linux/arm64` platform `debian` also supported.

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

If you want to install R packages via apt during the container build phase,
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

### Source installation via R

Packages that cannot be installed via apt must be installed using the R functions.

For more information, please check [the Rocker Project website](https://rocker-project.org/use/extending.html).

## Python package installation

This feature has some options to install Python packages such as `jupyterlab`.
When installing Python packages, if `python3 -m pip` is not available, it will install `python3-pip` via apt.

This feature set `PIP_BREAK_SYSTEM_PACKAGES=1` when installing Python packages.

## References

- [Rocker Project](https://rocker-project.org)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/r-apt/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
