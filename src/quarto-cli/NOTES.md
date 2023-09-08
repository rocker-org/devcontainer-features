<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platform `debian` and `ubuntu`.

`linux/arm64` platform only supports version 1.3 or later.

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
    "postCreateCommand": "python3 -m pip install jupyter"
}
```

## Install Chromium

Chromium may be required to render documents containing [diagrams code blocks](https://quarto.org/docs/authoring/diagrams.html)
such as `{mermaid}` and `{dot}` into non-HTML formats.

To do this in a Docker container, besides specifying the `installChromium` option of this Feature,
you also need to install Chromium itself.
For Debian, this can be done with `devcontainer.json` as follows
using the `ghcr.io/rocker-org/devcontainer-features/apt-packages` Feature.

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:debian",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/quarto-cli:1": {
            "installChromium": true
        },
        "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
            "packages": "chromium"
        }
    }
}
```

Unfortunately, this does not work for Ubuntu because it is not possible to install chromium via apt.

On Ubuntu, we need to install missing dependencies by either. For example:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/quarto-cli:1": {
            "installChromium": true
        },
        "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
            "packages": "libgtk-3-dev,libnotify-dev,libgconf-2-4,libnss3,libxss1,libasound2"
        }
    }
}
```

The package list came from the Puppeteer for WSL. <https://pptr.dev/troubleshooting#running-puppeteer-on-wsl-windows-subsystem-for-linux>

See also: <https://pptr.dev/troubleshooting#running-puppeteer-in-docker>

## Available versions

`"latest"` and `"prerelease"` refer to the release and pre-release versions
listed in [the Quarto CLI's download page](https://quarto.org/docs/download).

You can also specify a version number, like `"1"`, `"1.2"`, `"1.0.38"`.

`"1"` matches the highest numbered tag has pattern `1.Y.Z` in
[the Quarto CLI GitHub repository](https://github.com/quarto-dev/quarto-cli).

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:debian",
    "features": {
        "ghcr.io/rocker-org/devcontainer-features/quarto-cli:latest": {
            "version": "1"
        }
    }
}
```

## References

- [Quarto](https://quarto.org)
