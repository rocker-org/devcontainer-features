#!/usr/bin/env bash

R_VERSION=${VERSION:-"release"}
VSCODE_R_SUPPORT=${VSCODERSUPPORT:-"minimal"}
INSTALL_DEVTOOLS=${INSTALLDEVTOOLS:-"false"}
INSTALL_RMARKDOWN=${INSTALLRMARKDOWN:-"false"}
INSTALL_JUPYTERLAB=${INSTALLJUPYTERLAB:-"false"}
INSTALL_RADIAN=${INSTALLRADIAN:-"false"}
INSTALL_VSCDEBUGGER=${INSTALLVSCDEBUGGER:-"false"}
PANDOC_VERSION=${PANDOCVERSION:-"auto"}

USERNAME=${USERNAME:-"automatic"}

APT_PACKAGES=(curl ca-certificates)
PIP_PACKAGES=()
R_PACKAGES=()

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

architecture="$(dpkg --print-architecture)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "arm64" ]; then
    echo "(!) Architecture $architecture unsupported"
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
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} >/dev/null 2>&1; then
    USERNAME=root
fi

# Allow latest as an alias of release for compatibility
if [ "${R_VERSION}" = "latest" ]; then
    R_VERSION="release"
fi

# Check options for installing packages
if [ "${VSCODE_R_SUPPORT}" = "minimal" ]; then
    R_PACKAGES+=(jsonlite rlang)
elif [ "${VSCODE_R_SUPPORT}" = "lsp" ] || [ "${VSCODE_R_SUPPORT}" = "languageserver" ]; then
    R_PACKAGES+=(languageserver)
    APT_PACKAGES+=(libxml2-dev libicu-dev)
elif [ "${VSCODE_R_SUPPORT}" = "full" ]; then
    R_PACKAGES+=(languageserver httpgd)
    APT_PACKAGES+=(libxml2-dev libicu-dev libcairo2-dev libfontconfig1-dev libfreetype6-dev libpng-dev)
fi

if [ "${INSTALL_DEVTOOLS}" = "true" ]; then
    APT_PACKAGES+=( \
        make \
        libgit2-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libssl-dev \
        libfontconfig1-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libfreetype6-dev \
        libpng-dev \
        libtiff-dev \
        libjpeg-dev \
        libicu-dev \
        zlib1g-dev \
    )
    R_PACKAGES+=(devtools)
    if [ "${PANDOC_VERSION}" = "auto" ] && [ ! -x "$(command -v pandoc)" ]; then
        PANDOC_VERSION="latest"
    fi
fi

if [ "${INSTALL_RMARKDOWN}" = "true" ]; then
    APT_PACKAGES+=(make libicu-dev)
    R_PACKAGES+=(rmarkdown)
    if [ "${PANDOC_VERSION}" = "auto" ] && [ ! -x "$(command -v pandoc)" ]; then
        PANDOC_VERSION="latest"
    fi
fi

if [ "${INSTALL_RADIAN}" = "true" ]; then
    PIP_PACKAGES+=(radian)
fi

if [ "${INSTALL_JUPYTERLAB}" = "true" ]; then
    APT_PACKAGES+=(libzmq3-dev)
    PIP_PACKAGES+=(jupyterlab)
    R_PACKAGES+=(IRkernel)
fi

if [ "${PANDOC_VERSION}" = "os-provided" ]; then
    APT_PACKAGES+=(pandoc)
    PANDOC_VERSION="none"
fi

if [ "${PANDOC_VERSION}" = "auto" ]; then
    PANDOC_VERSION="none"
fi

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)*?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list
        version_list="$(git ls-remote --tags "${repository}" | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g "${variable_name}"="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g "${variable_name}"="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" >/dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

find_version_from_json() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local json_url=$2
    local prefix=${3:-""}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list
        version_list="$(curl -sL ${json_url} | tr '"' '\n' | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g "${variable_name}"="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g "${variable_name}"="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" >/dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

install_rig() {
    local download_url
    if [ "$architecture" = "amd64" ]; then
        download_url="https://github.com/r-lib/rig/releases/download/latest/rig-linux-latest.tar.gz"
    elif [ "$architecture" = "arm64" ]; then
        download_url="https://github.com/r-lib/rig/releases/download/latest/rig-linux-arm64-latest.tar.gz"
    fi
    curl -sL "${download_url}" | tar xz -C /usr/local
}

install_pandoc() {
    local version=$1
    local deb_file="pandoc.deb"
    local architecture
    local download_url
    architecture="$(dpkg --print-architecture)"
    download_url="https://github.com/jgm/pandoc/releases/download/${version}/pandoc-${version}-1-${architecture}.deb"

    mkdir -p /tmp/pandoc
    pushd /tmp/pandoc
    curl -sLo "${deb_file}" "${download_url}"
    dpkg -i "${deb_file}"
    popd
    rm -rf /tmp/pandoc
}

install_r_packages() {
    packages="$*"
    if [ -n "${packages}" ]; then
        su ${USERNAME} -c "R -q -e \"pak::pak(unlist(strsplit('${packages}', ' ')))\""
    fi
}

check_pip() {
    if ! python3 -m pip --help >/dev/null 2>&1; then
        check_packages python3-pip
    fi
}

install_pip_packages() {
    packages="$*"
    if [ -n "${packages}" ]; then
        check_pip
        su ${USERNAME} -c "python3 -m pip install --user --upgrade --no-cache-dir --no-warn-script-location ${packages}"
    fi
}

export DEBIAN_FRONTEND=noninteractive

# Clean up
rm -rf /var/lib/apt/lists/*

if [ ! -x "$(command -v git)" ]; then
    APT_PACKAGES+=(git)
fi

if [ "${INSTALL_VSCDEBUGGER}" = "true" ]; then
    R_PACKAGES+=("ManuelHentschel/vscDebugger@$(git ls-remote --tags https://github.com/ManuelHentschel/vscDebugger | grep -oP "v[0-9]+\\.[0-9]+\\.[0-9]+" | tail -n 1)")
fi

# shellcheck disable=SC2048 disable=SC2086
check_packages ${APT_PACKAGES[*]}
# shellcheck disable=SC2048 disable=SC2086
install_pip_packages ${PIP_PACKAGES[*]}

# Install pandoc if needed
if [ "${PANDOC_VERSION}" = "latest" ]; then
    PANDOC_VERSION=$(git ls-remote --tags https://github.com/jgm/pandoc | grep -oP "\\K[0-9]+\.[0-9]+(\.[0-9]+)*" | sort -rV | head -n 1)
elif [ "${PANDOC_VERSION}" != "none" ]; then
    find_version_from_git_tags PANDOC_VERSION "https://github.com/jgm/pandoc" "tags/" "." "true"
fi

if [ "${PANDOC_VERSION}" != "none" ]; then
    echo "Downloading pandoc ${PANDOC_VERSION}..."
    install_pandoc "${PANDOC_VERSION}"
fi

# Soft version matching
# https://github.com/r-lib/rig/issues/101
if [ "${R_VERSION}" != "release" ] && [ "${R_VERSION}" != "devel" ] && [ "${R_VERSION}" != "none" ]; then
    if [ "${architecture}" = "amd64" ]; then
        find_version_from_json R_VERSION "https://cdn.rstudio.com/r/versions.json"
    elif [ "${architecture}" = "arm64" ]; then
        find_version_from_git_tags R_VERSION "https://github.com/r-hub/R"
    fi
fi

# Install rig
if [ "${R_VERSION}" = "none" ] && [ -x "$(command -v R)" ]; then
    echo "R is already installed. Skipping rig installation"
else
    echo "Downloading rig..."
    install_rig
fi

if [ "${R_VERSION}" = "none" ] && [ ! -x "$(command -v R)" ]; then
    echo "Skipping R and R packages installation"
    # Clean up
    rm -rf /tmp/rig
    rm -rf /var/lib/apt/lists/*
    exit 0
fi

if [ "${R_VERSION}" = "none" ]; then
    echo "Skipping R installation"
else
    echo "Downloading R ${R_VERSION}..."
    rig add "${R_VERSION}" --without-pak --without-sysreqs
fi

echo "Install R packages..."
# Install the pak package
# shellcheck disable=SC2016
su ${USERNAME} -c 'R -q -e "install.packages(\"pak\", repos = sprintf(\"https://r-lib.github.io/p/pak/devel/%s/%s/%s\", .Platform\$pkgType, R.Version()\$os, R.Version()\$arch))"'
# shellcheck disable=SC2048 disable=SC2086
install_r_packages ${R_PACKAGES[*]}

# Set up IRkernel
if [ "${INSTALL_JUPYTERLAB}" = "true" ]; then
    echo "Register IRkernel..."
    # shellcheck disable=SC2016
    su ${USERNAME} -c 'export PATH="/home/'${USERNAME}'/.local/bin:/root/.local/bin:${PATH}"; R -q -e "IRkernel::installspec()"'
fi

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/rig
rm -rf /tmp/Rtmp*

echo "Done!"
