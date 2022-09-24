#!/usr/bin/env bash

CLI_VERSION=${VERSION:-"latest"}

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Check the platform
# https://github.com/quarto-dev/quarto-cli/issues/190
architecture="$(dpkg --print-architecture)"
if [ "${architecture}" != "amd64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

apt_get_update() {
    echo "Running apt-get update..."
    apt-get update -y
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
            last_part="(${escaped_separator}[0-9]+)?"
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

install() {
    local deb_file="quarto.deb"
    local architecture
    local download_url
    architecture="$(dpkg --print-architecture)"
    if [ "${CLI_VERSION}" = "latest" ] || [ "${CLI_VERSION}" = "release" ] ; then
        download_url=$(curl -sL https://quarto.org/docs/download/_download.json | grep -oP "(?<=\"download_url\":\s\")https.*${architecture}\.deb")
    elif [ "${CLI_VERSION}" = "prerelease" ]; then
        download_url=$(curl -sL https://quarto.org/docs/download/_prerelease.json | grep -oP "(?<=\"download_url\":\s\")https.*${architecture}\.deb")
    else
        download_url="https://github.com/quarto-dev/quarto-cli/releases/download/v${CLI_VERSION}/quarto-${CLI_VERSION}-linux-${architecture}.deb"
    fi

    mkdir -p /tmp/quarto
    pushd /tmp/quarto
    curl -sLo "${deb_file}" "${download_url}"
    dpkg -i "${deb_file}"
    popd
    rm -rf /tmp/quarto
}

export DEBIAN_FRONTEND=noninteractive

check_packages curl ca-certificates

# Soft version matching
if [ "${CLI_VERSION}" != "latest" ] && [ "${CLI_VERSION}" != "release" ] && [ "${CLI_VERSION}" != "prerelease" ]; then
    find_version_from_git_tags CLI_VERSION "https://github.com/quarto-dev/quarto-cli"
fi

# Install the Quarto CLI
echo "Downloading Quarto CLI..."

install

echo "Done!"
