#!/usr/bin/env bash

USE_TESTING=${USETESTING:-"true"}
VSCODE_R_SUPPORT=${VSCODERSUPPORT:-"minimal"}
INSTALL_DEVTOOLS=${INSTALLDEVTOOLS:-"false"}
INSTALL_RENV=${INSTALLRENV:-"false"}
INSTALL_RMARKDOWN=${INSTALLRMARKDOWN:-"false"}
INSTALL_JUPYTERLAB=${INSTALLJUPYTERLAB:-"false"}
INSTALL_RADIAN=${INSTALLRADIAN:-"false"}
INSTALL_VSCDEBUGGER=${INSTALLVSCDEBUGGER:-"false"}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}
R_LIBRARY_PATH="/usr/local/lib/R/site-library"

APT_PACKAGES=(r-base)
PIP_PACKAGES=()

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

# Only debian testing supports arm64
# shellcheck source=/dev/null
source /etc/os-release
if [ "${ID}" = "ubuntu" ] && [ "${architecture}" != "amd64" ]; then
    echo "(!) Ubuntu $architecture unsupported"
    exit 1
fi
if [ "${ID}" = "debian" ] && [ "${architecture}" != "amd64" ] && [ "${USE_TESTING}" != "true" ]; then
    echo "(!) To use Debian $architecture, please set useTesting option to true"
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

# Check options for installing packages
if [ "${VSCODE_R_SUPPORT}" = "minimal" ]; then
    APT_PACKAGES+=(r-cran-jsonlite r-cran-rlang)
elif [ "${VSCODE_R_SUPPORT}" = "lsp" ] || [ "${VSCODE_R_SUPPORT}" = "languageserver" ]; then
    APT_PACKAGES+=(r-cran-languageserver)
    install_languageserver="true"
elif [ "${VSCODE_R_SUPPORT}" = "full" ]; then
    APT_PACKAGES+=(r-cran-languageserver r-cran-httpgd)
    install_languageserver="true"
    install_httpgd="true"
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

if [ "${INSTALL_RADIAN}" = "true" ]; then
    PIP_PACKAGES+=(radian)
fi

if [ "${INSTALL_JUPYTERLAB}" = "true" ]; then
    APT_PACKAGES+=(r-cran-irkernel)
    PIP_PACKAGES+=(jupyterlab)
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

check_pip() {
    if ! python3 -m pip --help >/dev/null 2>&1; then
        check_packages python3-pip python3-dev
    fi
}

install_pip_packages() {
    packages="$*"
    if [ -n "${packages}" ]; then
        check_pip
        # shellcheck disable=SC2086
        python3 -m pip install --upgrade --no-cache-dir --no-warn-script-location ${packages}
    fi
}

export DEBIAN_FRONTEND=noninteractive

if ! grep -e "^staff:" "/etc/group" >/dev/null 2>&1; then
    groupadd -r staff
fi
usermod -a -G staff "${USERNAME}"

check_packages curl ca-certificates

if [ "${ID}" = "ubuntu" ]; then
    echo "Set up for Ubuntu..."
    curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc >/dev/null
    echo "deb [arch=amd64] https://cloud.r-project.org/bin/linux/ubuntu ${UBUNTU_CODENAME}-cran40/" >/etc/apt/sources.list.d/cran-ubuntu.list
    echo "Set up r2u..."
    curl -fsSL https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc | tee -a /etc/apt/trusted.gpg.d/cranapt_key.asc >/dev/null
    echo "deb [arch=amd64] https://r2u.stat.illinois.edu/ubuntu ${UBUNTU_CODENAME} main" >/etc/apt/sources.list.d/cranapt.list
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
        echo "deb http://http.debian.net/debian unstable main" >/etc/apt/sources.list.d/debian-unstable.list
        echo 'APT::Default-Release "testing";' >/etc/apt/apt.conf.d/default
    else
        echo "Set up for Debian ${VERSION_CODENAME}..."
        curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x95c0faf38db3ccad0c080a7bdc78b2ddeabc47b7" | tee -a /etc/apt/trusted.gpg.d/cran_debian_key.asc >/dev/null
        echo "deb [arch=amd64] http://cloud.r-project.org/bin/linux/debian ${VERSION_CODENAME}-cran40/" >/etc/apt/sources.list.d/cran-debian.list
    fi
    # On Debian, renv, languageserver and httpgd are not available via apt
    # shellcheck disable=SC2206
    APT_PACKAGES=(${APT_PACKAGES[@]/r-cran-renv})
    # shellcheck disable=SC2206
    APT_PACKAGES=(${APT_PACKAGES[@]/r-cran-languageserver})
    # shellcheck disable=SC2206
    APT_PACKAGES=(${APT_PACKAGES[@]/r-cran-httpgd})
fi

apt-get update -y
# shellcheck disable=SC2048 disable=SC2086
check_packages ${APT_PACKAGES[*]}

chown root:staff "${R_LIBRARY_PATH}"
chmod g+ws "${R_LIBRARY_PATH}"

# shellcheck disable=SC2048 disable=SC2086
install_pip_packages ${PIP_PACKAGES[*]}

# Install pak
R -q -e "install.packages(\"pak\", repos = sprintf(\"https://r-lib.github.io/p/pak/devel/%s/%s/%s\", .Platform\$pkgType, R.Version()\$os, R.Version()\$arch))"

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

if [ "${ID}" = "debian" ] && [ "${install_httpgd}" = "true" ]; then
    check_packages \
        g++ make r-cran-later r-cran-systemfonts r-cran-bh \
        libxml2-dev libicu-dev libcairo2-dev libfontconfig1-dev libfreetype6-dev libpng-dev
    R -q -e 'install.packages("httpgd")'
fi

if [ "${ID}" = "debian" ] && [ "${INSTALL_RENV}" = "true" ]; then
    R -q -e 'install.packages("renv")'
fi

if [ "${INSTALL_VSCDEBUGGER}" = "true" ]; then
    check_packages git make r-base-dev r-cran-r6 r-cran-jsonlite
    R -q -e "pak::pkg_install('ManuelHentschel/vscDebugger@$(git ls-remote --tags https://github.com/ManuelHentschel/vscDebugger | grep -oP "v[0-9]+\\.[0-9]+\\.[0-9]+" | sort -V | tail -n 1)')"
fi

# Set up IRkernel
if [ "${INSTALL_JUPYTERLAB}" = "true" ]; then
    echo "Register IRkernel..."
    # shellcheck disable=SC2016
    su ${USERNAME} -c 'export PATH="/home/'${USERNAME}'/.local/bin:/root/.local/bin:${PATH}"; R -q -e "IRkernel::installspec()"'
fi

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/Rtmp*
R -q -e 'pak::cache_clean()'

echo "Done!"
