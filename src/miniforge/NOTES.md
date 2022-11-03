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

## Refferences

- [Conda](https://docs.conda.io)
- [Mamba](https://mamba.readthedocs.io)
- [Miniforge](https://github.com/conda-forge/miniforge)
