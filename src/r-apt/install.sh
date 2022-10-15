#!/usr/bin/env bash

USERNAME=${USERNAME:-"automatic"}

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

export DEBIAN_FRONTEND=noninteractive

if grep -q "Ubuntu" </etc/os-release; then
    # shellcheck source=/dev/null
    source /etc/os-release
    check_packages wget
    wget -q -O- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
    echo "deb [arch=amd64] https://cloud.r-project.org/bin/linux/ubuntu ${UBUNTU_CODENAME}-cran40/" >/etc/apt/sources.list.d/cran-ubuntu.list
    wget -q -O- https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc | tee -a /etc/apt/trusted.gpg.d/cranapt_key.asc
    echo "deb [arch=amd64] https://dirk.eddelbuettel.com/cranapt ${UBUNTU_CODENAME} main" >/etc/apt/sources.list.d/cranapt.list
elif grep -q "Debian" </etc/os-release; then
    # shellcheck source=/dev/null
    source /etc/os-release
    check_packages gnupg2
    apt-key adv --keyserver keyserver.ubuntu.com --recv-key "95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7"
    echo "deb http://cloud.r-project.org/bin/linux/debian ${VERSION_CODENAME}-cran40/" >>/etc/apt/sources.list
fi

apt-get update -y
apt install --no-install-recommends r-base

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
