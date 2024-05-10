#!/usr/bin/env bash

Rscript -e \
    'pak::repo_add(@REPOS@);
    pak::local_install_deps("@ROOT@", dependencies = trimws(unlist(strsplit("@DEPS@", ","))))'
