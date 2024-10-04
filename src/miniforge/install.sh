#!/usr/bin/env bash

VERSION=${VERSION:-"latest"}
VARIANT=${VARIANT:-"Miniforge3"}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}
CONDA_DIR="/opt/conda"

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

if conda --version &>/dev/null; then
    echo "(!) conda is already installed - exiting."
    exit 0
fi

if mamba --version &>/dev/null; then
    echo "(!) mamba is already installed - exiting."
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Check the platform
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

check_git() {
    if [ ! -x "$(command -v git)" ]; then
        check_packages git
    fi
}

find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/"}
    local separator=${4:-"."}
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part="${escaped_separator}[0-9]+-[0-9]+"
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list
        check_git
        check_packages ca-certificates
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

install_miniforge() {
    local variant=$1
    local version=$2
    local conda_dir=$3
    local download_url
    download_url="https://github.com/conda-forge/miniforge/releases/download/${version}/${variant}-${version}-Linux-$(uname -m).sh"

    check_packages curl ca-certificates
    mkdir -p /tmp/miniforge
    pushd /tmp/miniforge
    curl -sLo miniforge.sh "${download_url}"
    chmod +x miniforge.sh
    /bin/bash miniforge.sh -b -p "${conda_dir}"
    popd
    rm -rf /tmp/miniforge
    "${conda_dir}/bin/conda" clean -yaf
}

export DEBIAN_FRONTEND=noninteractive

if ! grep -e "^conda:" "/etc/group" >/dev/null 2>&1; then
    groupadd -r conda
fi
usermod -a -G conda "${USERNAME}"

check_packages curl ca-certificates

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" >/etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Soft version matching
find_version_from_git_tags VERSION "https://github.com/conda-forge/miniforge"

# Install the miniforge
echo "Downloading ${VARIANT} ${VERSION}..."
install_miniforge "${VARIANT}" "${VERSION}" "${CONDA_DIR}"

CONDA_SCRIPT="${CONDA_DIR}/etc/profile.d/conda.sh"
# shellcheck source=/dev/null
source "${CONDA_SCRIPT}"
conda config --set env_prompt '({name})'

echo "source ${CONDA_SCRIPT}" >>"/root/.bashrc"
if [ "${USERNAME}" != "root" ]; then
    echo "source ${CONDA_SCRIPT}" >>"/home/${USERNAME}/.bashrc"
    chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.bashrc"
fi

chown -R "${USERNAME}:conda" "${CONDA_DIR}"
chmod -R g+r+w "${CONDA_DIR}"
find "${CONDA_DIR}" -type d -print0 | xargs -n 1 -0 chmod g+s

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
