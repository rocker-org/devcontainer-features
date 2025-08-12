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