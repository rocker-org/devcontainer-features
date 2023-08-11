#!/usr/bin/env bash

set -e

set_rstudio_prefs() {
    local cur_dir
    local prefs_path

    cur_dir="$(pwd)"
    config_dir=~/.config/rstudio
    prefs_path="${config_dir}/rstudio-prefs.json"

    if [ ! -f "${prefs_path}" ]; then
        mkdir -p "${config_dir}"
        echo "Setting RStudio preferences..."
        cat <<EOF >"${prefs_path}"
{
    "initial_working_directory": "${cur_dir}"
}
EOF
        echo "Done!"
    fi
}

set_rstudio_prefs
