<!-- markdownlint-disable MD041 -->

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
