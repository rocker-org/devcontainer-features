#!/usr/bin/env bash

PACKAGES=${PACKAGES:-""}
PAK_VERSION=${PAKVERSION:-"auto"}
ADDITIONAL_REPOSITORIES=${ADDITIONALREPOSITORIES:-""}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

R_PACKAGES=("${PACKAGES//,/ }")

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ -z "${PACKAGES}" ]; then
    echo "No R packages specified. Skip installation..."
    exit 0
fi

install_pak() {
    local version=$1

    if [ "${version}" = "auto" ]; then
        if su "${USERNAME}" -c "R -q -e 'names(installed.packages()[, 3])'" | grep "pak" >/dev/null 2>&1; then
            echo "pak is already installed. Skip pak installation..."
            return
        else
            version="devel"
        fi
    fi

    echo "Installing pak ${version}..."
    # shellcheck disable=SC2016
    su "${USERNAME}" -c 'R -q -e "install.packages(\"pak\", repos = sprintf(\"https://r-lib.github.io/p/pak/'"${version}"'/%s/%s/%s\", .Platform\$pkgType, R.Version()\$os, R.Version()\$arch))"'
}

install_r_packages() {
    local packages="$*"
    if [ -n "${packages}" ]; then
        su "${USERNAME}" -c "R -q -e \"pak::repo_add(${ADDITIONAL_REPOSITORIES}); pak::pak(unlist(strsplit('${packages}', ' ')))\""
    fi
}

export DEBIAN_FRONTEND=noninteractive


echo "Install R packages..."
mkdir /tmp/r-packages
pushd /tmp/r-packages

install_pak "${PAK_VERSION}"
# shellcheck disable=SC2048 disable=SC2086
install_r_packages ${R_PACKAGES[*]}

popd
rm -rf /tmp/r-packages

echo "Done!"
