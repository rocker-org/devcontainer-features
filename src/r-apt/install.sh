#!/usr/bin/env bash

VSCODE_R_SUPPORT=${VSCODERSUPPORT:-"minimal"}
INSTALL_DEVTOOLS=${INSTALLDEVTOOLS:-"false"}
INSTALL_RMARKDOWN=${INSTALLRMARKDOWN:-"false"}
INSTALL_JUPYTERLAB=${INSTALLJUPYTERLAB:-"false"}
INSTALL_RADIAN=${INSTALLRADIAN:-"false"}
INSTALL_VSCDEBUGGER=${INSTALLVSCDEBUGGER:-"false"}

USERNAME=${USERNAME:-"automatic"}

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
if [ "${architecture}" != "amd64" ]; then
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

# Check options for installing packages
if [ "${VSCODE_R_SUPPORT}" = "minimal" ]; then
    APT_PACKAGES+=(r-cran-jsonlite r-cran-rlang)
elif [ "${VSCODE_R_SUPPORT}" = "lsp" ] || [ "${VSCODE_R_SUPPORT}" = "languageserver" ]; then
    APT_PACKAGES+=(r-cran-languageserver)
elif [ "${VSCODE_R_SUPPORT}" = "full" ]; then
    APT_PACKAGES+=(r-cran-languageserver r-cran-httpgd)
fi

if [ "${INSTALL_DEVTOOLS}" = "true" ]; then
    APT_PACKAGES+=(r-cran-devtools)
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

# shellcheck source=/dev/null
source /etc/os-release

if grep -q "Ubuntu" </etc/os-release; then
    check_packages curl ca-certificates
    curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
    echo "deb [arch=amd64] https://cloud.r-project.org/bin/linux/ubuntu ${UBUNTU_CODENAME}-cran40/" >/etc/apt/sources.list.d/cran-ubuntu.list
    curl -fsSL https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc | tee -a /etc/apt/trusted.gpg.d/cranapt_key.asc
    echo "deb [arch=amd64] https://r2u.stat.illinois.edu/ubuntu ${UBUNTU_CODENAME} main" >/etc/apt/sources.list.d/cranapt.list
elif grep -q "Debian" </etc/os-release; then
    check_packages gnupg2
    apt-key adv --keyserver keyserver.ubuntu.com --recv-key "95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7"
    echo "deb http://cloud.r-project.org/bin/linux/debian ${VERSION_CODENAME}-cran40/" >>/etc/apt/sources.list
fi

apt-get update -y
# shellcheck disable=SC2048 disable=SC2086
check_packages ${APT_PACKAGES[*]}
# shellcheck disable=SC2048 disable=SC2086
install_pip_packages ${PIP_PACKAGES[*]}

if [ "${INSTALL_VSCDEBUGGER}" = "true" ]; then
    check_packages git make r-base-dev r-cran-remotes r-cran-r6 r-cran-jsonlite
    R -q -e "remotes::install_github('ManuelHentschel/vscDebugger@$(git ls-remote --tags https://github.com/ManuelHentschel/vscDebugger | grep -oP "v[0-9]+\\.[0-9]+\\.[0-9]+" | sort -V | tail -n 1)')"
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

echo "Done!"
