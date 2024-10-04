
# Conda, Mamba (Miniforge) (miniforge)

Installs Conda and Mamba package manager and Python3. conda-forge set as the default (and only) channel.

## Example Usage

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/miniforge:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Miniforge. | string | latest |
| variant | Select install CPython (3) or PyPy (-pypy3). | string | Miniforge3 |

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

This Feature is similar to [`ghcr.io/devcontainers/features/conda`](https://github.com/devcontainers/features/tree/main/src/conda),
but differs in options and arm64 platform support.

## Mambaforge or micormamba?

[The `ghcr.io/mamba-org/devcontainer-features/micromamba` Feature](https://github.com/mamba-org/devcontainer-features/tree/main/src/micromamba)
installs only [micromamba](https://mamba.readthedocs.io/en/latest/user_guide/micromamba.html), a single binary command line tool.
micromamba is lightweight, so installation is quick.

If you do not need Conda, Mamba (which exist on top of Python) or Python by default, the micromamba Feature may be a better choice.

## Release notes

### 2.0.0

- Change the default value of `variant` from `"Mambaforge"` to `"Miniforge3"`,
  sinse as of 2024-07-21, `Mambaforge` is deprecated.
  See the official announcement:
  [Sunsetting Mambaforge](https://conda-forge.org/news/2024/07/29/sunsetting-mambaforge/)

## References

- [Conda](https://docs.conda.io)
- [Mamba](https://mamba.readthedocs.io)
- [Miniforge](https://github.com/conda-forge/miniforge)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rocker-org/devcontainer-features/blob/main/src/miniforge/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
