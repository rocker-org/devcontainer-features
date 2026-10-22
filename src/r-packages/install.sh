#!/usr/bin/env bash

PACKAGES=${PACKAGES:-""}
PAK_VERSION=${PAKVERSION:-"auto"}
ADDITIONAL_REPOSITORIES=${ADDITIONALREPOSITORIES:-""}
CRAN_MIRROR=${CRANMIRROR:-""}
INSTALL_SYSREQS=${INSTALLSYSTEMREQUIREMENTS:-"true"}
NOT_CRAN_VALUE=${NOTCRAN:-"false"}

USERNAME=${USERNAME:-${_REMOTE_USER:-"automatic"}}

set -e

# Temporary directories to be removed on exit, even on failure
TEMP_DIRS=()

cleanup_temp_dirs() {
    if [ "${#TEMP_DIRS[@]}" -gt 0 ]; then
        rm -rf "${TEMP_DIRS[@]}"
    fi
}
trap cleanup_temp_dirs EXIT

if [ -z "${PACKAGES}" ]; then
    echo "No R packages specified. Skip installation..."
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

architecture="$(uname -m)"
if [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

if [ ! -x "$(command -v R)" ]; then
    echo "(!) Cannot run R. Please install R before installing this Feature."
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

# Quote a string for safe use inside a shell command
sq() {
    local s=${1//\'/\'\\\'\'}
    printf "'%s'" "${s}"
}

# Run an R script as the user.
# The environment variables are set explicitly in the command,
# because `su` may not preserve the environment.
# Usage: run_r_as_user <script> <packages> [<sysreqs file>]
run_r_as_user() {
    local script=$1
    local env_str
    env_str="PKG_SYSREQS=false NOT_CRAN=$(sq "${NOT_CRAN_VALUE}") R_PACKAGES_LIST=$(sq "$2") R_PACKAGES_REPOS_FILE=$(sq "${WORK_DIR}/repos.txt")"
    if [ -n "${CRAN_MIRROR}" ]; then
        env_str+=" PKG_CRAN_MIRROR=$(sq "${CRAN_MIRROR}")"
    fi
    if [ -n "${3:-}" ]; then
        env_str+=" R_PACKAGES_SYSREQS_FILE=$(sq "$3")"
    fi
    su "${USERNAME}" -c "${env_str} R -q -f $(sq "${script}")"
}

install_r_packages() {
    local packages=$1

    if [ -z "${packages}" ]; then
        return
    fi

    # The additional repositories (an R expression) are passed via a root-owned file
    printf '%s\n' "${ADDITIONAL_REPOSITORIES}" >"${WORK_DIR}/repos.txt"
    chmod 644 "${WORK_DIR}/repos.txt"

    if [ "${INSTALL_SYSREQS}" = "true" ]; then
        # Phase 1: Get the commands to install system requirements (as the user)
        # The user writes the commands into a user-owned temporary directory,
        # and root copies them to a root-owned file before running them.
        local user_tmp_dir
        user_tmp_dir="$(su "${USERNAME}" -c 'mktemp -d')"
        TEMP_DIRS+=("${user_tmp_dir}")
        cat <<"RSCRIPT" >"${WORK_DIR}/sysreqs.R"
repos <- paste(readLines(Sys.getenv("R_PACKAGES_REPOS_FILE")), collapse = "\n")
eval(parse(text = sprintf("pak::repo_add(%s)", repos)))
pkgs <- trimws(unlist(strsplit(Sys.getenv("R_PACKAGES_LIST"), ",")))
sr <- pak::pkg_sysreqs(pkgs)
writeLines(
  c(sr$pre_install, sr$install_scripts, sr$post_install),
  Sys.getenv("R_PACKAGES_SYSREQS_FILE")
)
RSCRIPT
        chmod 644 "${WORK_DIR}/sysreqs.R"
        echo "Checking system requirements of the R packages..."
        run_r_as_user "${WORK_DIR}/sysreqs.R" "${packages}" "${user_tmp_dir}/sysreqs.sh"

        rm -f "${WORK_DIR}/sysreqs.sh"
        if [ -f "${user_tmp_dir}/sysreqs.sh" ]; then
            install -m 600 "${user_tmp_dir}/sysreqs.sh" "${WORK_DIR}/sysreqs.sh"
        fi
        rm -rf "${user_tmp_dir}"

        # Phase 2: Install system requirements (as root, from the root-owned copy)
        if [ -s "${WORK_DIR}/sysreqs.sh" ]; then
            echo "Installing system requirements..."
            cat "${WORK_DIR}/sysreqs.sh"
            bash -e "${WORK_DIR}/sysreqs.sh"
        else
            echo "No system requirements need to be installed."
        fi
    fi

    # Phase 3: Install R packages (as the user)
    cat <<"RSCRIPT" >"${WORK_DIR}/install.R"
repos <- paste(readLines(Sys.getenv("R_PACKAGES_REPOS_FILE")), collapse = "\n")
eval(parse(text = sprintf("pak::repo_add(%s)", repos)))
pkgs <- trimws(unlist(strsplit(Sys.getenv("R_PACKAGES_LIST"), ",")))
pak::pak(pkgs)
pak::cache_clean()
pak::meta_clean(force = TRUE)
RSCRIPT
    chmod 644 "${WORK_DIR}/install.R"
    run_r_as_user "${WORK_DIR}/install.R" "${packages}"
}

export DEBIAN_FRONTEND=noninteractive

echo "Install R packages..."

# Root-owned work dir: the user can read and enter it, but cannot write to it
WORK_DIR="$(mktemp -d)"
TEMP_DIRS+=("${WORK_DIR}")
chmod 755 "${WORK_DIR}"
pushd "${WORK_DIR}" >/dev/null

if [ -n "${CRAN_MIRROR}" ]; then
    echo "Use '${CRAN_MIRROR}' as the CRAN mirror..."
fi

install_pak "${PAK_VERSION}"

install_r_packages "${PACKAGES}"

popd >/dev/null

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/Rtmp*

echo "Done!"
