# syntax=docker/dockerfile:1.4

FROM rocker/r-ver:latest

RUN useradd -s /bin/bash -m rstudio \
    && usermod -a -G staff rstudio

USER rstudio
RUN <<EOF
mkdir -p ~/.config/rstudio
cat <<EOF2 >~/.config/rstudio/rstudio-prefs.json
{
  "initial_working_directory": "/home/rstudio",
  "foo": "bar"
}
EOF2
EOF
