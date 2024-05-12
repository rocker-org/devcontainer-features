#!/usr/bin/env bash

set -e

echo "Install dependent R packages..."

R -q -e \
    'pak::repo_add(@REPOS@);
    pak::local_install_deps("@ROOT@", dependencies = trimws(unlist(strsplit("@DEPS@", ","))))'

echo "Done!"
