#!/usr/bin/env bash

RENV_PATHS_CACHE=${RENV_PATHS_CACHE:-"/renv/cache"}

set -e

fix_permissions() {
    local dir
    dir="${1}"

    if [ ! -w "${dir}" ]; then
        echo "Fixing permissions of '${dir}'..."
        sudo chown -R "$(id -u):$(id -g)" "${dir}"
        echo "Done!"
    else
        echo "Permissions of '${dir}' are OK!"
    fi
}

fix_permissions "${RENV_PATHS_CACHE}"
