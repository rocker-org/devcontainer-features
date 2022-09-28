<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` platform `debian` and `ubuntu`.

## Execution Engine

This feature will not install execution engines such as `jupyter` or `knitr`,
so if you wish to use them, please install them separately.

For example, set `postCreateCommand` to install jupyter on `mcr.microsoft.com/devcontainers/python`:

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
