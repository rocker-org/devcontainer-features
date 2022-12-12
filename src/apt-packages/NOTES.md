<!-- markdownlint-disable MD041 -->

## How to specify packages?

Specify package names separated by commas in the `packages` option.

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

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-apt:0": {},
    "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
        "packages": "r-cran-curl"
    },
    "overrideFeatureInstallOrder": [
        "ghcr.io/rocker-org/devcontainer-features/r-apt"
    ]
}
```
