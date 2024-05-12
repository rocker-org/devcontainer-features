
# R packages (via pak) (r-packages)

Installs R packages via the pak R package's function. R must be already installed.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-packages:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| packages | Comma separated list of packages to install to pass to the `pak::pak()` function. | string | - |
| pakVersion | Version of pak to install. By default, the stable version is installed if needed. | string | auto |
| additionalRepositories | String passed to the `pak::repo_add()` function. | string | - |
| installSystemRequirements | Install packages' system requirements if available via `pak::pak()`. Converted to the `PKG_SYSREQS` env var during the installation. | boolean | false |
| cranMirror | The CRAN mirror to use for installing packages. Converted to the `PKG_CRAN_MIRROR` env var if not empty. | string | - |
| notCran | The 'NOT_CRAN' environment variable that is referenced during the installation of this Feature. | boolean | false |

<!-- markdownlint-disable MD041 -->

## System Requirements

This Feature supports `linux/amd64` and `linux/arm64` platforms with R installed.

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

If many cases, we can use the `installSystemRequirements` option to install the system requirements
automatically by `pak::pak()`.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-apt:latest": {},
    "ghcr.io/rocker-org/devcontainer-features/r-packages:1": {
        "packages": "cli",
        "installSystemRequirements": true
    }
}
```

Or, for Debian and Ubuntu,
we can use [the `ghcr.io/rocker-org/devcontainer-features/apt-packages` Feature](https://github.com/rocker-org/devcontainer-features/blob/main/src/apt-packages)
to install apt packages before installing this Feature.

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

You can also specify packages on GitHub, etc.
For example, the following example installs a package from <https://github.com/r-lib/crayon>.

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-packages:1": {
        "packages": "github::r-lib/crayon"
    }
}
```

Please check [the `pak` documentation](https://pak.r-lib.org/dev/reference/pak_package_sources.html)
for information on how to specify individual package names.

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

## See also

- [r-dependent-packages Feature](../r-dependent-packages/README.md)
- [renv-cache Feature](../renv-cache/README.md)

## References

- [pak](https://pak.r-lib.org/)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/r-packages/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
