<!-- markdownlint-disable MD041 -->

## System Requirements

This Feature supports `linux/amd64` and `linux/arm64` platforms with R installed.

This Feature does not install R.
Please use this with an R-installed image (e.g. [`ghcr.io/rocker-org/devcontainer/r-ver`](https://rocker-project.org/images/devcontainer/images.html))
or this should be installed after installing Features that installs R
(e.g. [`ghcr.io/rocker-org/devcontainer-features/r-apt`](https://github.com/rocker-org/devcontainer-features/tree/main/src/r-apt),
[`ghcr.io/rocker-org/devcontainer-features/r-rig`](https://github.com/rocker-org/devcontainer-features/tree/main/src/r-rig)).

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-rig:1": {},
    "ghcr.io/rocker-org/devcontainer-features/r-packages:1": {
        "packages": "rlang"
    }
}
```

Note that source installation of the R packages may require the installation of
additional build tools and system packages.

For Debian and Ubuntu, we can use the `ghcr.io/rocker-org/devcontainer-features/apt-packages` Feature
to install apt packages prior to installing this Feature.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-apt:latest": {},
    "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
        "packages": "make,gcc,g++"
    },
    "ghcr.io/rocker-org/devcontainer-features/r-packages:1": {
        "packages": "cli"
    }
}
```

## How to specify packages?

Specify package names separated by commas in the `packages` option.

The following example installs `cli` and `rlang`.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-packages:1": {
        "packages": "cli,rlang"
    }
}
```

## How to add other repositories?

Repositories can be set up as a string in R's named vector format.

For example, the following example runs as `pak::repo_add(rhub = 'https://r-hub.r-universe.dev', jeroen = 'https://jeroen.r-universe.dev'); pak::pak("rversions")`.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-packages:1": {
        "packages": "rversions",
        "additionalRepositories": "rhub = 'https://r-hub.r-universe.dev', jeroen = 'https://jeroen.r-universe.dev'"
    }
}
```

## References

- [pak](https://pak.r-lib.org/)
