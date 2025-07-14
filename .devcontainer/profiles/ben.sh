#!/usr/bin/env bash

# Personal aliases
echo "set -o vi
alias svi='sudo vim'
stty -ixon
export VISUAL=vim
export EDITOR=vim" >> ~/.bashrc

# Force certain environment vars for attatching using local terminal
echo "" >> ~/.bashrc
echo "export SHELL=/bin/bash" >> ~/.bashrc
echo "export TERM=xterm-256color" >> ~/.bashrc

# zellij installation
mkdir -p .devcontainer/bin
cd .devcontainer/bin
wget https://github.com/zellij-org/zellij/releases/download/v0.40.1/zellij-x86_64-unknown-linux-musl.tar.gz --no-clobber
tar -xvf zellij-x86_64-unknown-linux-musl.tar.gz
chmod +x zellij
echo "" >> ~/.bashrc
echo "export PATH=\$PATH:$(pwd)" >> ~/.bashrc
