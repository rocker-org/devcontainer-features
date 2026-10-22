#!/usr/bin/env bash

USE_TESTING=${USETESTING:-"true"}
VSCODE_R_SUPPORT=${VSCODERSUPPORT:-"minimal"}
INSTALL_DEVTOOLS=${INSTALLDEVTOOLS:-"false"}
INSTALL_RENV=${INSTALLRENV:-"false"}
INSTALL_RMARKDOWN=${INSTALLRMARKDOWN:-"false"}
INSTALL_BSPM=${INSTALLBSPM:-"false"}
ARF_VERSION=${ARFVERSION:-"none"}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}
R_LIBRARY_PATH="/usr/local/lib/R/site-library"

APT_PACKAGES=(r-base)

set -e

# Temporary directories to be removed on exit, even on failure
TEMP_DIRS=()

cleanup_temp_dirs() {
    if [ "${#TEMP_DIRS[@]}" -gt 0 ]; then
        rm -rf "${TEMP_DIRS[@]}"
    fi
}
trap cleanup_temp_dirs EXIT

if R --version >/dev/null 2>&1 && dpkg -s r-base >/dev/null 2>&1; then
    echo "(!) R has already been installed via a non-apt method."
    echo "    This script is designed only for non-R Debian and Ubuntu."
    exit 1
fi

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

# Check options for installing packages
if [ "${VSCODE_R_SUPPORT}" = "minimal" ] || [ "${VSCODE_R_SUPPORT}" = "lsp" ] || [ "${VSCODE_R_SUPPORT}" = "languageserver" ] || [ "${VSCODE_R_SUPPORT}" = "full" ]; then
    # Required by the session watcher (sess) of vscode-R
    APT_PACKAGES+=(r-cran-processx r-cran-later r-cran-jsonlite r-cran-rstudioapi)
fi

if [ "${VSCODE_R_SUPPORT}" = "lsp" ] || [ "${VSCODE_R_SUPPORT}" = "languageserver" ] || [ "${VSCODE_R_SUPPORT}" = "full" ]; then
    APT_PACKAGES+=(r-cran-languageserver)
    install_languageserver="true"
fi

if [ "${VSCODE_R_SUPPORT}" = "full" ]; then
    APT_PACKAGES+=(r-cran-jgd)
    install_jgd="true"
fi

if [ "${INSTALL_DEVTOOLS}" = "true" ]; then
    APT_PACKAGES+=(r-cran-devtools)
fi

if [ "${INSTALL_RENV}" = "true" ]; then
    APT_PACKAGES+=(r-cran-renv)
fi

if [ "${INSTALL_RMARKDOWN}" = "true" ]; then
    APT_PACKAGES+=(r-cran-rmarkdown)
fi

if [ "${INSTALL_BSPM}" = "true" ]; then
    APT_PACKAGES+=(make sudo python3-apt python3-gi)
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
    local tmp_dir
    local asset
    local arf_arch
    arf_arch="$(uname -m)"
    tmp_dir="$(mktemp -d)"
    TEMP_DIRS+=("${tmp_dir}")

    echo "Checking glibc version for arf..."
    if ! check_glibc 2.34; then
        echo "(!) arf requires glibc >= 2.34 (e.g. Debian 12+ or Ubuntu 22.04+). Set arfVersion to none or use a newer base image." >&2
        exit 1
    fi

    check_git
    check_xz
    find_version_from_git_tags ARF_VERSION "https://github.com/eitsupi/arf" "tags/v"
    asset="arf-console-${arf_arch}-unknown-linux-gnu.tar.xz"

    echo "Downloading arf ${ARF_VERSION}..."
    pushd "${tmp_dir}"
    curl -fsSLO "https://github.com/eitsupi/arf/releases/download/v${ARF_VERSION}/${asset}"
    curl -fsSLO "https://github.com/eitsupi/arf/releases/download/v${ARF_VERSION}/${asset}.sha256"
    sha256sum -c "${asset}.sha256"
    tar xJf "${asset}"
    install -m 0755 "arf-console-${arf_arch}-unknown-linux-gnu/arf" /usr/local/bin/arf
    popd
    rm -rf "${tmp_dir}"

    arf --version
}

export DEBIAN_FRONTEND=noninteractive

if ! grep -e "^staff:" "/etc/group" >/dev/null 2>&1; then
    groupadd -r staff
fi
usermod -a -G staff "${USERNAME}"

check_packages curl ca-certificates

# Install arf first, so that an unsupported environment fails fast
if [ "${ARF_VERSION}" != "none" ]; then
    install_arf
fi

# shellcheck source=/dev/null
source /etc/os-release
if [ "${ID}" = "ubuntu" ]; then
    echo "Set up for Ubuntu..."
    curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc >/dev/null
    echo "deb https://cloud.r-project.org/bin/linux/ubuntu ${UBUNTU_CODENAME}-cran40/" >/etc/apt/sources.list.d/cran-ubuntu.list
    echo "Set up r2u..."
    curl -fsSL https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc | tee -a /etc/apt/trusted.gpg.d/cranapt_key.asc >/dev/null
    echo "deb https://r2u.stat.illinois.edu/ubuntu ${UBUNTU_CODENAME} main" >/etc/apt/sources.list.d/cranapt.list
    # Pinning
    cat <<EOF >"/etc/apt/preferences.d/99cranapt"
Package: *
Pin: release o=CRAN-Apt Project
Pin: release l=CRAN-Apt Packages
Pin-Priority: 700
EOF
elif [ "${ID}" = "debian" ]; then
    if [ "${USE_TESTING}" = "true" ]; then
        echo "Set up Debian testing..."
        echo "deb http://http.debian.net/debian testing main" >/etc/apt/sources.list.d/debian-testing.list
        echo "deb http://http.debian.net/debian-security testing-security main" >>/etc/apt/sources.list.d/debian-testing.list
        echo "deb http://http.debian.net/debian unstable main" >/etc/apt/sources.list.d/debian-unstable.list
    else
        echo "Set up for Debian ${VERSION_CODENAME}..."
        curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x95c0faf38db3ccad0c080a7bdc78b2ddeabc47b7" | tee -a /etc/apt/trusted.gpg.d/cran_debian_key.asc >/dev/null
        echo "deb http://cloud.r-project.org/bin/linux/debian ${VERSION_CODENAME}-cran40/" >/etc/apt/sources.list.d/cran-debian.list
    fi
    # On Debian, languageserver and jgd are not available via apt,
    # and renv is not available unless Debian testing is used
    if [ "${USE_TESTING}" != "true" ]; then
        # shellcheck disable=SC2206
        APT_PACKAGES=(${APT_PACKAGES[@]/r-cran-renv})
    fi
    # shellcheck disable=SC2206
    APT_PACKAGES=(${APT_PACKAGES[@]/r-cran-languageserver})
    # shellcheck disable=SC2206
    APT_PACKAGES=(${APT_PACKAGES[@]/r-cran-jgd})
else
    echo "(!) Unsupported distribution: ${ID}"
    echo "    This script is designed only for Debian and Ubuntu."
    exit 1
fi

apt-get update -y
# shellcheck disable=SC2048 disable=SC2086
check_packages ${APT_PACKAGES[*]}

chown root:staff "${R_LIBRARY_PATH}"
chmod g+ws "${R_LIBRARY_PATH}"

# Install pak
R -q -e "install.packages(\"pak\", repos = sprintf(\"https://r-lib.github.io/p/pak/stable/%s/%s/%s\", .Platform\$pkgType, R.Version()\$os, R.Version()\$arch))"

if [ "${ID}" = "debian" ] && [ "${install_languageserver}" = "true" ]; then
    check_packages \
        gcc \
        make \
        r-cran-callr \
        r-cran-fs \
        r-cran-jsonlite \
        r-cran-codetools \
        r-cran-crayon \
        r-cran-desc \
        r-cran-remotes \
        r-cran-withr \
        r-cran-digest \
        r-cran-glue \
        r-cran-knitr \
        r-cran-lazyeval \
        r-cran-xml2 \
        r-cran-roxygen2 \
        r-cran-stringi \
        r-cran-stringi \
        r-cran-magrittr \
        r-cran-purrr \
        r-cran-r.cache \
        r-cran-rematch2 \
        r-cran-rlang \
        r-cran-rprojroot \
        r-cran-tibble
    R -q -e 'install.packages("languageserver")'
fi

if [ "${ID}" = "debian" ] && [ "${install_jgd}" = "true" ]; then
    check_packages gcc make r-base-dev
    R -q -e 'install.packages("jgd")'
fi

if [ "${ID}" = "debian" ] && [ "${USE_TESTING}" != "true" ] && [ "${INSTALL_RENV}" = "true" ]; then
    R -q -e 'install.packages("renv")'
fi

if [ "${INSTALL_BSPM}" = "true" ]; then
    R -q -e 'install.packages("bspm")'
    echo "options(bspm.sudo = TRUE)" >>/etc/R/Rprofile.site
    echo "bspm::enable()" >>/etc/R/Rprofile.site
fi

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/Rtmp*
R -q -e 'pak::cache_clean()'

echo "Done!"
