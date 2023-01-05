

# R (via rig) (r-rig)

Installs R, some R packages, and needed dependencies. Note: May require source code compilation for R packages.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-rig:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of R, if not the latest release version. | string | release |
| pakVersion | Version of pak to install. By default, the devel version is installed if needed. | string | auto |
| vscodeRSupport | Install R packages to make vscode-R work. lsp means the `languageserver` package, full means lsp plus the `httpgd` package. | string | minimal |
| installDevTools | Install the `devtools` R package. | boolean | false |
| installREnv | Install the `renv` R package. | boolean | false |
| installRMarkdown | Install the `rmarkdown` R package. It is required for R Markdown or Quarto documentation. | boolean | false |
| installJupyterlab | Install and setup JupyterLab (via `python3 -m pip`). JupyterLab is a web-based interactive development environment for notebooks. | boolean | false |
| installRadian | Install radian (via `python3 -m pip`). radian is an R console with multiline editing and rich syntax highlight. | boolean | false |
| installVscDebugger | Install the `vscDebugger` R package from the GitHub repo. It is required for the VSCode-R-Debugger. | boolean | false |
| pandocVersion | Select version of Pandoc. By default, the latest version is installed if needed. | string | auto |

<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platforms `debian` and `ubuntu` (LTS).

## Install R

This feature uses [rig](https://github.com/r-lib/rig) to install [R](https://www.r-project.org/).

Note that rig does not manage R installed outside of rig.
If R is already installed and `"version": "none"` is set, rig will not be installed.

## R package installation

### Binary installation from RSPM

On `ubuntu` on `linux/amd64` platforms, When you try to install the R package,
it installs binaries from RStudio Public Package Manager.
For other distributions or platforms, the R packages are installed from source, which takes longer to build.

For more information, please check [the Rocker Project website](https://rocker-project.org/use/extending.html).

### Install R packages via `pak`

By default, this feature installs [the `pak` package](https://pak.r-lib.org/),
which is useful for installing the R packages.

The `pak` package has the ability to install system libraries in certain distributions, but is turned off by default.
To enable this ability, set the `PKG_SYSREQS` environment variable to `true`.

You can configure this in `remoteEnv` in `devcontainer.json` as like follows.

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/r-rig:latest": {}
    },
    "remoteEnv": {
        "PKG_SYSREQS": "true"
    }
}
```

When installing R package via `pak` as follows, `apt-get install` commands are also executed.

```sh
$ R -q -e 'pak::pak("curl")'
> pak::pak("curl")
✔ Loading metadata database ... done
 
ℹ No downloads are needed
ℹ Installing system requirements
ℹ Executing `sudo sh -c apt-get install -y libcurl4-openssl-dev`
ℹ Executing `sudo sh -c apt-get install -y libssl-dev`
✔ 1 pkg: kept 1 [11.8s]
```

## Python package installation

This feature has some options to install Python packages such as `jupyterlab`.
When installing Python packages, if `python3 -m pip` is not available, it will install `python3-pip` via apt.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/r-rig/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
