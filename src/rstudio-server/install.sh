#!/usr/bin/env bash

VERSION=${VERSION:-"stable"}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

architecture="$(dpkg --print-architecture)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "arm64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

# Only supports Ubuntu
# shellcheck source=/dev/null
source /etc/os-release
if [ "${ID}" != "ubuntu" ]; then
    echo "(!) ${ID} is not supported"
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
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${escaped_separator}[0-9]+\\+[0-9]+$"
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

check_r() {
    if ! R --version >/dev/null 2>&1; then
        check_packages r-base
    fi
}

install_rstudio() {
    local version=$1
    local deb_file="rstudio-server.deb"
    local architecture
    architecture="$(dpkg --print-architecture)"

    mkdir -p /tmp/rstudio-server
    pushd /tmp/rstudio-server

    if [[ "${version}" == "stable" ]] || [[ "${version}" == "preview" ]] || [[ "${version}" == "daily" ]]; then
        curl -sLo "${deb_file}" "https://rstudio.org/download/latest/${version}/server/${UBUNTU_CODENAME}/rstudio-server-latest-${architecture}.deb"
    else
        curl -sLo "${deb_file}" "https://download2.rstudio.org/server/${UBUNTU_CODENAME}/${architecture}/rstudio-server-${VERSION/"+"/"-"}-${architecture}.deb" ||
            curl -sLo "${deb_file}" "https://s3.amazonaws.com/rstudio-ide-build/server/${UBUNTU_CODENAME}/${architecture}/rstudio-server-${VERSION/"+"/"-"}-${architecture}.deb" ||
            echo "(!) Version ${VERSION} for ${UBUNTU_CODENAME} ${architecture} is not found" && exit 1
    fi

    ln -fs /usr/lib/rstudio-server/bin/rstudio-server /usr/local/bin
    ln -fs /usr/lib/rstudio-server/bin/rserver /usr/local/bin

    gdebi "${deb_file}"
    popd
    rm -rf /tmp/rstudio-server
}

export DEBIAN_FRONTEND=noninteractive

check_packages curl ca-certificates gdebi-core
check_r

# Soft version matching
# If VERSION contains `daily` like `2023.09.0-daily+304`, the check will be skipped.
if [[ "${VERSION}" == "stable" ]] || [[ "${VERSION}" == "preview" ]] || [[ "${VERSION}" == "*daily*" ]]; then
    if [ ! -x "$(command -v git)" ]; then
        check_packages git
    fi
    find_version_from_git_tags VERSION "https://github.com/rstudio/rstudio"
fi

# Install the RStudio Server
echo "Downloading RStudio Server..."

install_rstudio "${VERSION}"

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
