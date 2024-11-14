#!/usr/bin/env bash

RS_VERSION=${VERSION:-"stable"}
ALLOW_REINSTALL=${ALLOWREINSTALL:-"false"}
SINGLE_USER=${SINGLEUSER:-"true"}

RSTUDIO_DATA_DIR=${RSTUDIODATADIR:-"/usr/local/share/rocker-devcontainer-features/rstudio-server/data"}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

LIFECYCLE_SCRIPTS_DIR="/usr/local/share/rocker-devcontainer-features/rstudio-server/scripts"

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
    local tmp
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${escaped_separator}[0-9]+\+[0-9]+$"
        local version_list
        version_list="$(git ls-remote --tags "${repository}" | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g "${variable_name}"="$(echo "${version_list}" | head -n 1)"
        else
            tmp=${requested_version//+/\\+}
            set +e
            declare -g "${variable_name}"="$(echo "${version_list}" | grep -E -m 1 "^${tmp//./\\.}([\\.\\s]|$)")"
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
    local install_url
    local architecture
    local ubuntu_codename
    architecture="$(dpkg --print-architecture)"
    # Exported from /etc/os-release
    ubuntu_codename="${UBUNTU_CODENAME}"

    if [ "${ubuntu_codename}" = "noble" ]; then
        ubuntu_codename="jammy"
    fi

    mkdir -p /tmp/rstudio-server
    pushd /tmp/rstudio-server

    if [[ "${version}" == "stable" ]] || [[ "${version}" == "preview" ]] || [[ "${version}" == "daily" ]]; then
        install_url="https://rstudio.org/download/latest/${version}/server/${ubuntu_codename}/rstudio-server-latest-${architecture}.deb"
        echo "Download from ${install_url}"
        curl -fsLo "${deb_file}" "${install_url}" ||
            echo "(!) Version ${version} for ${ubuntu_codename} ${architecture} is not found"
    else
        curl -fsLo "${deb_file}" "https://download2.rstudio.org/server/${ubuntu_codename}/${architecture}/rstudio-server-${version/"+"/"-"}-${architecture}.deb" ||
            curl -fsLo "${deb_file}" "https://s3.amazonaws.com/rstudio-ide-build/server/${ubuntu_codename}/${architecture}/rstudio-server-${version/"+"/"-"}-${architecture}.deb" ||
            echo "(!) Version ${version} for ${ubuntu_codename} ${architecture} is not found"
    fi

    gdebi --non-interactive "${deb_file}"
    popd
    rm -rf /tmp/rstudio-server
}

set_single_user_mode() {
    mkdir -p "${RSTUDIO_DATA_DIR}"
    cat <<EOF >"${RSTUDIO_DATA_DIR}/dbconf.conf"
provider=sqlite
directory=$RSTUDIO_DATA_DIR
EOF

    chown -R "${USERNAME}":"${USERNAME}" "${RSTUDIO_DATA_DIR}"

    cat <<EOF >/etc/rstudio/rserver.conf
# https://docs.posit.co/ide/server-pro/access_and_security/server_permissions.html#running-without-permissions
server-user=$USERNAME
auth-none=1

server-data-dir=$RSTUDIO_DATA_DIR
database-config-file=$RSTUDIO_DATA_DIR/dbconf.conf
EOF
}

export DEBIAN_FRONTEND=noninteractive

if [ "${ALLOW_REINSTALL}" = "true" ] || [ ! -x "$(command -v rstudio-server)" ]; then
    check_packages curl ca-certificates gdebi-core
    check_r

    # Soft version matching
    # If RS_VERSION contains `daily` like `2023.09.0-daily+310`, the check will be skipped.
    if [[ "${RS_VERSION}" != "stable" ]] && [[ "${RS_VERSION}" != "preview" ]] && [[ "${RS_VERSION}" != *"daily"* ]]; then
        if [ ! -x "$(command -v git)" ]; then
            check_packages git
        fi
        find_version_from_git_tags RS_VERSION "https://github.com/rstudio/rstudio"
    fi

    # Install the RStudio Server
    echo "Downloading RStudio Server..."

    install_rstudio "${RS_VERSION}"
else
    echo "(!) RStudio Server is already installed. Skip installation..."
fi

if [ "${SINGLE_USER}" = "true" ]; then
    echo "Setting up RStudio Server for single user mode..."
    set_single_user_mode
fi

echo "Create symlinks for RStudio Server binaries..."
ln -fs /usr/lib/rstudio-server/bin/rstudio-server /usr/local/bin
ln -fs /usr/lib/rstudio-server/bin/rserver /usr/local/bin

# Set Lifecycle scripts
if [ -f oncreate.sh ]; then
    mkdir -p "${LIFECYCLE_SCRIPTS_DIR}"
    cp oncreate.sh "${LIFECYCLE_SCRIPTS_DIR}/oncreate.sh"
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
