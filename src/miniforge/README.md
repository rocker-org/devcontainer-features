
# Conda, Mamba (Miniforge) (miniforge)

Installs Conda and Mamba package manager and Python3. conda-forge set as the default (and only) channel.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/miniforge:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Miniforge. | string | latest |
| variant | Select Conda only (Miniforge) or Conda plus Mamba (Mambaforge), and install CPython (non-suffixed) or PyPy (-pypy3). | string | Mambaforge |

<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` and `linux/arm64` platforms `debian` and `ubuntu`.

## Install packages from conda-forge

We can install packages from [conda-forge](https://conda-forge.org) using `conda` or `mamba`.
For example, install specific version of Pytnon as follows:

```sh
mamba install -y python=3.7
```

## Conda or Miniforge?

- This Feature is similar to [`ghcr.io/devcontainers/features/conda`](https://github.com/devcontainers/features/tree/main/src/conda),
  but differs in options and arm64 platform support.

## References

- [Conda](https://docs.conda.io)
- [Mamba](https://mamba.readthedocs.io)
- [Miniforge](https://github.com/conda-forge/miniforge)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/miniforge/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
