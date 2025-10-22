#!/usr/bin/env bash

# We install these packages outside of the container build step because these commands pollute the /home/uas directory.
# Devcontainers are chowned to the host user and their group in order to allow seamless access to the mounted workspace.
# If the ~/ is large then this process to take an eternity
# You could put these all in the Dockerfile and set `updateRemoteUserUID` to false you only ever wanted it to work for userid 1000

export PIP_NO_CACHE_DIR=1
cd ~/

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# pnpm
wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -

# Manually source cargo and pnpm
. "$HOME/.cargo/env"
export PNPM_HOME="/home/uas/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Set store dir explicitly, otherwise pnpm seems to use current dir for store?
pnpm config set store-dir ~/.local/share/pnpm/store

# Computer vision Python packages

# https://pytorch.org/get-started/locally/
# Change (or remove) --index-url to use a different compute platform (make sure to use the correct cu/rocm version for you GPU)
# Note that the GPU versions take a lot more space ~4GB
# You will also have to enable gpu in docker-compose.yml (and have drivers on host machine)
# We probably shouldn't be using pip or sudo pip but it works so...
python3 -m pip install \
    torch==2.8.0 torchvision==0.23.0 \
    --index-url https://download.pytorch.org/whl/cpu
    # --index-url https://download.pytorch.org/whl/cu128
    # --index-url https://download.pytorch.org/whl/rocm6.3
# Install ultralytics
python3 -m pip install \
    ultralytics==8.3.217
# Uninstall numpy for apt managed (for opencv), and remove opencv to use the one we built
python3 -m pip uninstall -y numpy
python3 -m pip uninstall -y opencv-python
