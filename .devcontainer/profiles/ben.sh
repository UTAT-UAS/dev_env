#!/usr/bin/env bash

# Custom SDL config
echo '#!/usr/bin/env bash' | sudo tee /usr/bin/qgc > /dev/null
echo 'SDL_GAMECONTROLLERCONFIG="0300000009120000544f000011010000,OpenTX Radiomaster Pocket Joystick,a:b0,b:b1,x:b3,y:b4,back:b10,guide:b12,start:b11,leftstick:b13,rightstick:b14,leftshoulder:b6,rightshoulder:b7,leftx:a0,lefty:a1,rightx:a3,righty:a2,lefttrigger:a4,righttrigger:a5,platform:Linux" /QGroundControl-x86_64.AppImage --appimage-extract-and-run' | sudo tee -a /usr/bin/qgc > /dev/null

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
wget https://github.com/zellij-org/zellij/releases/download/v0.42.2/zellij-x86_64-unknown-linux-musl.tar.gz --no-clobber
tar -xvf zellij-x86_64-unknown-linux-musl.tar.gz
chmod +x zellij
echo "" >> ~/.bashrc
echo "export PATH=\$PATH:$(pwd)" >> ~/.bashrc
