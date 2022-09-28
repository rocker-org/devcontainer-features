<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platforms `debian` and `ubuntu`(LTS).

## Install R

This feature uses [rig](https://github.com/r-lib/rig) to install [R](https://www.r-project.org/).

**Do not install this feature on R-installed images**, as rig does not manage R installed outside of rig.

## R package installation

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
    "remoteUser": "vscode",
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
