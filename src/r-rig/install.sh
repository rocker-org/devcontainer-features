#!/usr/bin/env bash

R_VERSION=${VERSION:-"release"}
PAK_VERSION=${PAKVERSION:-"auto"}
VSCODE_R_SUPPORT=${VSCODERSUPPORT:-"minimal"}
INSTALL_DEVTOOLS=${INSTALLDEVTOOLS:-"false"}
INSTALL_RENV=${INSTALLRENV:-"false"}
INSTALL_RMARKDOWN=${INSTALLRMARKDOWN:-"false"}
ARF_VERSION=${ARFVERSION:-"none"}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

APT_PACKAGES=(curl ca-certificates)
R_PACKAGES=()

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

architecture="$(uname -m)"
if [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "aarch64" ]; then
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

# Allow latest as an alias of release for compatibility
if [ "${R_VERSION}" = "latest" ]; then
    R_VERSION="release"
fi

# Check options for installing packages
if [ "${VSCODE_R_SUPPORT}" = "minimal" ] || [ "${VSCODE_R_SUPPORT}" = "lsp" ] || [ "${VSCODE_R_SUPPORT}" = "languageserver" ] || [ "${VSCODE_R_SUPPORT}" = "full" ]; then
    # Required by the session watcher (sess) of vscode-R
    R_PACKAGES+=(processx later jsonlite rstudioapi)
fi

if [ "${VSCODE_R_SUPPORT}" = "lsp" ] || [ "${VSCODE_R_SUPPORT}" = "languageserver" ] || [ "${VSCODE_R_SUPPORT}" = "full" ]; then
    R_PACKAGES+=(languageserver)
fi

if [ "${VSCODE_R_SUPPORT}" = "full" ]; then
    R_PACKAGES+=(jgd)
fi

if [ "${INSTALL_DEVTOOLS}" = "true" ]; then
    R_PACKAGES+=(devtools)
fi

if [ "${INSTALL_RENV}" = "true" ]; then
    R_PACKAGES+=(renv)
fi

if [ "${INSTALL_RMARKDOWN}" = "true" ]; then
    R_PACKAGES+=(rmarkdown)
fi

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* 2>/dev/null | wc -l)" = "0" ]; then
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

check_xz() {
    if [ ! -x "$(command -v xz)" ]; then
        check_packages xz-utils
    fi
}

# Resolve a (partial) version to a full version using the git tags.
# Tags with a pre-release suffix (e.g. v0.7.0-alpha.1) are ignored.
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local escaped_separator=${separator//./\\.}
    local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${escaped_separator}[0-9]+$"
    local version_list
    requested_version="${requested_version#v}"
    version_list="$(git ls-remote --tags "${repository}" | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
        declare -g "${variable_name}"="$(echo "${version_list}" | head -n 1)"
    else
        set +e
        declare -g "${variable_name}"="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
        set -e
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" >/dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

check_glibc() {
    local required=$1
    local current
    current="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
    if [ -z "${current}" ]; then
        echo "(!) glibc is required, but this system does not seem to use glibc." >&2
        return 1
    fi
    if [ "$(printf '%s\n%s\n' "${required}" "${current}" | sort -V | head -n 1)" != "${required}" ]; then
        echo "(!) glibc ${required} or later is required, but glibc ${current} was found." >&2
        return 1
    fi
}

install_arf() {
    local tmp_dir=/tmp/arf
    local asset

    echo "Checking glibc version for arf..."
    if ! check_glibc 2.34; then
        echo "(!) arf requires glibc >= 2.34 (e.g. Debian 12+ or Ubuntu 22.04+). Set arfVersion to none or use a newer base image." >&2
        exit 1
    fi

    check_git
    check_xz
    find_version_from_git_tags ARF_VERSION "https://github.com/eitsupi/arf" "tags/v"
    asset="arf-console-${architecture}-unknown-linux-gnu.tar.xz"

    echo "Downloading arf ${ARF_VERSION}..."
    mkdir -p "${tmp_dir}"
    pushd "${tmp_dir}"
    curl -fsSLO "https://github.com/eitsupi/arf/releases/download/v${ARF_VERSION}/${asset}"
    curl -fsSLO "https://github.com/eitsupi/arf/releases/download/v${ARF_VERSION}/${asset}.sha256"
    sha256sum -c "${asset}.sha256"
    tar xJf "${asset}"
    install -m 0755 "arf-console-${architecture}-unknown-linux-gnu/arf" /usr/local/bin/arf
    popd
    rm -rf "${tmp_dir}"

    arf --version
}

install_rig() {
    local download_url="https://github.com/r-lib/rig/releases/download/latest/rig-linux-${architecture}-latest.tar.gz"
    curl -fsSL "${download_url}" | tar xz -C /usr/local
}

# rig cannot resolve a major-only version (e.g. 4), so resolve it here
resolve_major_r_version() {
    local major=$1
    local resolved
    # Versions listed by rig may not be resolvable on this platform, so check them from the newest
    for candidate in $(rig available --json --all 2>/dev/null | grep -oP '"version": "\K[0-9]+\.[0-9]+\.[0-9]+(?=")' | grep -E "^${major}\\." | sort -rV); do
        if rig resolve "${candidate}" >/dev/null 2>&1; then
            resolved="${candidate}"
            break
        fi
    done
    if [ -z "${resolved}" ]; then
        echo "(!) No R ${major}.x version is available." >&2
        exit 1
    fi
    echo "${resolved}"
}

install_pak() {
    local version=$1

    if [ "${version}" = "auto" ]; then
        if su "${USERNAME}" -c "R -s -e 'packageVersion(\"pak\")'" >/dev/null 2>&1; then
            echo "pak is already installed. Skip pak installation..."
            return
        else
            version="stable"
        fi
    fi

    echo "Installing pak ${version}..."
    # shellcheck disable=SC2016
    su "${USERNAME}" -c 'R -q -e "install.packages(\"pak\", repos = sprintf(\"https://r-lib.github.io/p/pak/'"${version}"'/%s/%s/%s\", .Platform\$pkgType, R.Version()\$os, R.Version()\$arch))"'
}

# Install R packages in two phases, so that the packages are installed
# into the user's library while the system requirements are installed by root.
install_r_packages() {
    local packages="$*"
    if [ -z "${packages}" ]; then
        return
    fi

    # Phase 1: Get the commands to install system requirements (as the user)
    rm -f /tmp/r-rig/sysreqs.sh
    cat <<"RSCRIPT" >/tmp/r-rig/sysreqs.R
pkgs <- unlist(strsplit(Sys.getenv("R_RIG_PACKAGES"), " "))
tryCatch(
  {
    sr <- pak::pkg_sysreqs(pkgs)
    writeLines(
      c(sr$pre_install, sr$install_scripts, sr$post_install),
      "/tmp/r-rig/sysreqs.sh"
    )
  },
  error = function(e) {
    message("Could not get the system requirements: ", conditionMessage(e))
  }
)
RSCRIPT
    chmod 644 /tmp/r-rig/sysreqs.R
    echo "Checking system requirements of the R packages..."
    su "${USERNAME}" -c "R_RIG_PACKAGES='${packages}' R -q -f /tmp/r-rig/sysreqs.R"

    # Phase 2: Install system requirements (as root)
    if [ -s /tmp/r-rig/sysreqs.sh ]; then
        echo "Installing system requirements..."
        cat /tmp/r-rig/sysreqs.sh
        apt_get_update
        bash -e /tmp/r-rig/sysreqs.sh
    else
        echo "No system requirements need to be installed."
    fi

    # Phase 3: Install R packages (as the user)
    cat <<"RSCRIPT" >/tmp/r-rig/install.R
pkgs <- unlist(strsplit(Sys.getenv("R_RIG_PACKAGES"), " "))
pak::pak(pkgs)
pak::cache_clean()
pak::meta_clean(force = TRUE)
RSCRIPT
    chmod 644 /tmp/r-rig/install.R
    su "${USERNAME}" -c "PKG_SYSREQS=false R_RIG_PACKAGES='${packages}' R -q -f /tmp/r-rig/install.R"
}

export DEBIAN_FRONTEND=noninteractive

# shellcheck disable=SC2048 disable=SC2086
check_packages ${APT_PACKAGES[*]}

# Install arf first, so that an unsupported environment fails fast
if [ "${ARF_VERSION}" != "none" ]; then
    install_arf
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
    if [[ "${R_VERSION}" =~ ^[0-9]+$ ]]; then
        R_VERSION="$(resolve_major_r_version "${R_VERSION}")"
        echo "R_VERSION=${R_VERSION}"
    fi
    echo "Downloading R ${R_VERSION}..."
    rig add "${R_VERSION}" --without-pak
fi

echo "Install R packages..."

# Should not add .gitconfig to the user's home directory
# https://github.com/r-lib/credentials/issues/25
if [ ! -f "${_REMOTE_USER_HOME}/.gitconfig" ]; then
    echo "There is no ${_REMOTE_USER_HOME}/.gitconfig file..."
    DELETE_GITCONFIG=true
fi

# Install the pak package
mkdir -p /tmp/r-rig
chmod 777 /tmp/r-rig
pushd /tmp/r-rig

install_pak "${PAK_VERSION}"

# shellcheck disable=SC2048 disable=SC2086
install_r_packages ${R_PACKAGES[*]}

popd
rm -rf /tmp/r-rig

# Should not add .gitconfig to the user's home directory
# https://github.com/r-lib/credentials/issues/25
if [ "${DELETE_GITCONFIG}" = "true" ] && [ -f "${_REMOTE_USER_HOME}/.gitconfig" ]; then
    echo "Remove ${_REMOTE_USER_HOME}/.gitconfig file..."
    rm -f "${_REMOTE_USER_HOME}/.gitconfig"
fi

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/rig
rm -rf /tmp/Rtmp*

echo "Done!"
