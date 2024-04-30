<!-- markdownlint-disable MD041 -->

## How to specify packages?

Specify package names separated by commas in the `packages` option.

The following example installs `curl` and `nano`.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
        "packages": "curl,nano"
    }
}
```

### Specifiying R packages

When installing R packages via `r-cran-<package>`, note that R package name references must be lowercase. For example, the following example installs the {kableExtra} R package.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
        "packages": "r-cran-kableextra"
    }
}
```

## Installation order

Specify the installation order of Features
by [the `overrideFeatureInstallOrder` property](https://containers.dev/implementors/features/#overrideFeatureInstallOrder).

The following example installs the `r-cran-curl` package after the `r-apt` Feature is installed.

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