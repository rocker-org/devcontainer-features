<!-- markdownlint-disable MD041 -->

## System Requirements

Please use this with an R-installed image (e.g. [`ghcr.io/rocker-org/devcontainer/r-ver`](https://rocker-project.org/images/devcontainer/images.html))
or this should be installed after installing Features that installs R
(e.g. [`ghcr.io/rocker-org/devcontainer-features/r-apt`](https://github.com/rocker-org/devcontainer-features/tree/main/src/r-apt),
[`ghcr.io/rocker-org/devcontainer-features/r-rig`](https://github.com/rocker-org/devcontainer-features/tree/main/src/r-rig)).

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/r-rig:1": {},
    "ghcr.io/rocker-org/devcontainer-features/r-dependent-packages:latest": {}
}
```

## DESCRIPTION file format

This feature installs packages listed in the manifest file named `DESCRIPTION`.
If you are new to the `DESCRIPTION` file, please refer to the
[`usethis::use_description()`](https://usethis.r-lib.org/reference/use_description.html) function's reference.

Here is an minimal example of the `DESCRIPTION` file.
At least, the `Package` and `Version` fields are required.
The `Imports` field is a list of packages that will be installed.

```dcf
Package: foo
Version: 0.0.0.9000
Imports:
    cli,
    rlang
```

### Additional fields

When developing an R package, we may want to specify dependencies that are only needed during development
in the `DESCRIPTION` file. In such cases, we can use any field name starting with `Config`,
and generally specify multiple fields prefixed with `Config/Needs` as follows:

```dcf
Package: foo
Version: 0.0.0.9000
Suggests:
    cli
Config/Needs/website:
    curl
Config/Needs/dev:
    crayon
```

If we want use such fields to install dependencies, we can specify the `dependencyTypes` field of
this Feature like this:

```json
"ghcr.io/rocker-org/devcontainer-features/r-dependent-packages:latest": {
    "dependencyTypes": "all,Config/Needs/website,Config/Needs/dev"
}
```

## Environment variables

Enviroment variables listed in [the `containerEnv` field](https://containers.dev/implementors/json_reference/#general-properties)
are used in the package installation process.
See [the reference of the `pak` package](https://pak.r-lib.org/reference/pak-config.html) for options for `pak`.

```json
"containerEnv": {
    "NOT_CRAN": "true",
    "PKG_CRAN_MIRROR": "https://cloud.r-project.org/"
}
```

## Cache directory and cache volume

The package cache directory in the container is set to `/pak/cache`.

This directory is stored in a volume named `devcontainer-pak-cache`
and is shared among multiple containers.

## See also

- [r-packages Feature](../r-packages/README.md)
- [renv-cache Feature](../renv-cache/README.md)

## References

- [pak](https://pak.r-lib.org/)
