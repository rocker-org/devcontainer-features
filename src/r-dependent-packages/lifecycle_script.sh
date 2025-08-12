#!/usr/bin/env bash

PKG_PACKAGE_CACHE_DIR=${PKG_PACKAGE_CACHE_DIR:-"/pak/cache"}

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

fix_permissions "${PKG_PACKAGE_CACHE_DIR}"

echo "The manifest DESCRIPTION file was set to '@ROOT@/DESCRIPTION'"
echo "Install dependent R packages..."

R -q -e \
    'pak::repo_add(@REPOS@); pak::local_install_deps("@ROOT@", dependencies = trimws(unlist(strsplit("@DEPS@", ","))))'

echo "Done!"
