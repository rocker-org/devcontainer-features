
# Quarto CLI (quarto-cli)

Installs the Quarto CLI. Auto-detects latest version.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/quarto-cli:1": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of the Quarto CLI, if not latest. | string | latest |
| installTinyTex | Install TinyTeX by using the `quarto tools install tinytex` command. Works only with version 1.2 or later. | boolean | - |

<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` platform `debian` and `ubuntu`.

## Execution Engine

This feature will not install execution engines such as `jupyter` or `knitr`,
so if you wish to use them, please install them separately.

For example, set `postCreateCommand` to install `jupyter` on `mcr.microsoft.com/devcontainers/python`:

```json
{
    "image": "mcr.microsoft.com/devcontainers/python:3",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/quarto-cli:latest": {}
    },
    "remoteUser": "vscode",
    "postCreateCommand": "python3 -m pip install jupyter"
}
```

## Available versions

`"latest"` and `"prerelease"` refer to the release and pre-release versions
listed in [the quarto-cli's download page](https://quarto.org/docs/download).

You can also specify a version number, like `"1"`, `"1.2"`, `"1.0.38"`.

`"1"` matches the highest numbered tag has pattern `1.Y.Z` in
[the quarto-cli GitHub repository](https://github.com/quarto-dev/quarto-cli).

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:debian",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/quarto-cli:latest": {
            "version": "1"
        }
    },
    "remoteUser": "vscode"
}
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/quarto-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
