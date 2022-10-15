<!-- markdownlint-disable MD041 -->

## Supported platforms

`linux/amd64` platforms `debian` and `ubuntu:focal`, `ubuntu:jammy`.

## R package installation

### Binary installation with apt

This feature will configure apt to install R and R packages.

Packages that can be installed with apt can be displayed with the following command.

```sh
apt-cache search "^r-.*" | sort
```

For example, the following command installs the `dplyr` package.

```sh
apt-get -y install --no-install-recommends r-cran-dplyr
```

For more information, please check [the Rocker Project website](https://rocker-project.org/use/extending.html).

## Python package installation

This feature has some options to install Python packages such as `jupyterlab`.
When installing Python packages, if `python3 -m pip` is not available, it will install `python3-pip` via apt.
