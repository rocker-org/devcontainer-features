
# apt packages (apt-packages)

Installs packages via apt.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| packages | Comma separated list of packages to install. | string | - |
| upgradePackages | Upgrade apt packages? | boolean | false |

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

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/apt-packages/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
