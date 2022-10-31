
# Conda, Mamba (Miniforge) (miniforge)

Installs Conda and Mamba package manager. conda-forge set as the default (and only) channel.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/miniforge:0": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Miniforge. | string | latest |
| variant | Select Conda only (Miniforge) or Conda plus Mamba (Mambaforge), and support CPython (non-suffixed) or PyPy (-pypy3). | string | Mambaforge |

<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platforms `debian` and `ubuntu`.

## Refferences

- [Conda](https://docs.conda.io)
- [Mamba](https://mamba.readthedocs.io)
- [Miniforge](https://github.com/conda-forge/miniforge)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/miniforge/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
