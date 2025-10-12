#!/usr/bin/env bash

# Post create setup script, non-essential aliases and packages to keep Dockerfile clean

## Append utility aliases

cat .devcontainer/bashrc_aliases >> ~/.bashrc

## Create the colcon workspace directory

mkdir -p uas_ws/src

## Create custom setup script in .devcontainer/profiles
## Then create .user file in .devcontainer with only the name of the script in it

USER_PROFILE=$(cat .devcontainer/.user 2>/dev/null)

if [[ -n $USER_PROFILE ]]; then
    .devcontainer/profiles/"$USER_PROFILE"
fi
