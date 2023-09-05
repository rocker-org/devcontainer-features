#!/usr/bin/env bash

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

set_renviron() {
    local renviron_file

    if [ -n "${R_ENVIRON}" ]; then
        renviron_file="${R_ENVIRON}"
    else
        renviron_file="${HOME}/.Renviron"
    fi

    echo "Updating '${renviron_file}'..."
    echo "R_HISTFILE=${R_HISTFILE}" >>"${renviron_file}"
    echo "Done!"
}

set_radian_history() {
    local radian_profile_dir

    if [ -n "${XDG_CONFIG_HOME}" ]; then
        radian_profile_dir="${XDG_CONFIG_HOME}/radian"
    else
        radian_profile_dir="${HOME}/.config/radian"
    fi

    mkdir -p "${radian_profile_dir}"

    echo "Updating '${radian_profile_dir}/profile'..."
    echo 'options(radian.global_history_file = "/dc/r-history/.radian_history")' >>"${radian_profile_dir}/profile"
    echo "Done!"
}

fix_permissions "/dc/r-history"
set_renviron
set_radian_history
