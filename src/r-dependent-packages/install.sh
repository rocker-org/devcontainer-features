#!/usr/bin/env bash

WHEN=${WHEN:-"postCreate"}
PAK_VERSION=${PAKVERSION:-"auto"}
ROOT=${MANIFESTROOT:-"."}
ADDITIONAL_REPOSITORIES=${ADDITIONALREPOSITORIES:-""}
DEPENDENCIES=${DEPENDENTTYPES:-"all"}

USERNAME=${USERNAME:-${_REMOTE_USER}}

LIFECYCLE_SCRIPTS_DIR="/usr/local/share/rocker-devcontainer-features/r-dependent-packages/scripts"

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

check_r() {
    if [ ! -x "$(command -v R)" ]; then
        echo "(!) Cannot run R. Please install R before installing this Feature."
        echo "    Skip installation..."
        exit 0
    fi
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

export DEBIAN_FRONTEND=noninteractive

# Set Lifecycle scripts
mkdir -p "${LIFECYCLE_SCRIPTS_DIR}"

POSSIBLE_LIFECYCLE=("onCreate" "updateContent" "postCreate")
for lifecycle in "${POSSIBLE_LIFECYCLE[@]}"; do
    cp empty_script.sh "${LIFECYCLE_SCRIPTS_DIR}/${lifecycle,,}.sh"
done

# Enxure pak installed
check_r
install_pak "${PAK_VERSION}"

# Replace the target lifecycle script
echo "Set the lifecycle script for '${WHEN}'..."
target_script="${LIFECYCLE_SCRIPTS_DIR}/${WHEN,,}.sh"
sed \
    -e "s|@ROOT@|${ROOT}|" \
    -e "s|@REPOS@|${ADDITIONAL_REPOSITORIES}|" \
    -e "s|@DEPS@|${DEPENDENCIES}|" \
    lifecycle_script.sh >"${target_script}"
chmod +x "${target_script}"

echo "Done!"
