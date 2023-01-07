<!-- markdownlint-disable MD041 -->

## System Requirements

R must already be installed.

If R cannot be run or the `renv` R package is already installed,
the installation script of this Feature does nothing.

If you want to install a specific version of `renv`,
please use [the `ghcr.io/rocker-org/devcontainer-features/r-packages` Feature](https://github.com/rocker-org/devcontainer-features/tree/main/src/r-packages).

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/renv-cache:latest": {},
    "ghcr.io/rocker-org/devcontainer-features/r-packages:1": {
        "packages": "github::rstudio/renv"
    }
}
```

## Cache directory and cache volume

The cache directory in the container is set to `/renv/cache`.

This directory is stored in a volume named `devcontainer-renv-cache`
and is shared among multiple containers.

## References

- [renv](https://rstudio.github.io/renv/)
- [Volumes | Docker Documentation](https://docs.docker.com/storage/volumes/)
