#!/usr/bin/env bash

PACKAGES=${PACKAGES:-""}
PAK_VERSION=${PAKVERSION:-"auto"}
ADDITIONAL_REPOSITORIES=${ADDITIONALREPOSITORIES:-""}
INSTALL_SYS_REQS=${INSTALLSYSTEMREQUIREMENTS:-"false"}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

R_PACKAGES=("${PACKAGES//,/ }")

set -e

if [ -z "${PACKAGES}" ]; then
    echo "No R packages specified. Skip installation..."
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

architecture="$(uname -m)"
if [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

if [ ! -x "$(command -v R)" ]; then
    echo "Cannot run R. Please install R before installing this Feature."
    exit 1
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" >/dev/null 2>&1; then
    USERNAME=root
fi

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

install_pak() {
    local version=$1

    if [ "${version}" = "auto" ]; then
        if su "${USERNAME}" -c "R -s -e 'packageVersion(\"pak\")'" >/dev/null 2>&1; then
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

install_r_package_system_requirements() {
    local packages="$*"
    local is_apt="false"

    # shellcheck source=/dev/null
    source /etc/os-release
    if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
        is_apt="true"
    fi

    if R -s -e "pak::repo_add(${ADDITIONAL_REPOSITORIES}); pak::pkg_system_requirements('${packages}')" >/dev/null 2>&1; then
        if [ -z "$(R -s -e "pak::repo_add(${ADDITIONAL_REPOSITORIES}); cat(pak::pkg_system_requirements('${packages}'))")" ]; then
            echo "There are no system requirements to install for the specified R packages."
            return
        fi
        if [ "${is_apt}" = "true" ]; then
            apt_get_update
        fi
        echo "Install system requirements for the R packages..."
        R -q -e "pak::repo_add(${ADDITIONAL_REPOSITORIES}); pak::pkg_system_requirements('${packages}', execute = TRUE, sudo = FALSE)"
        if [ "${is_apt}" = "true" ]; then
            # Clean up
            rm -rf /var/lib/apt/lists/*
        fi
    else
        echo "(!) This distribution is not supported by 'pak::pkg_system_requirements()'."
    fi
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
if [ "${INSTALL_SYS_REQS}" = "true" ]; then
    # shellcheck disable=SC2048 disable=SC2086
    install_r_package_system_requirements ${R_PACKAGES[*]}
fi
# shellcheck disable=SC2048 disable=SC2086
install_r_packages ${R_PACKAGES[*]}

popd
rm -rf /tmp/r-packages
rm -rf /tmp/Rtmp*

echo "Done!"
