#!/usr/bin/env bash

set -e

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

set_radian_history
