FROM osrf/ros:humble-desktop-full

ARG DEBIAN_FRONTEND=noninteractive
ARG PIP_NO_CACHE_DIR=1

# Setup container user for consistency across systems
# Use a non-root user to eliminate inconsistency as well as emulate a normal linux system as much as much as possible
ARG USERNAME=uas
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Give user passwordless root privileges
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    passwd -d $USERNAME && \
    passwd -d root && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# System packages
RUN apt -y update --no-install-recommends \
    && yes | unminimize 2>&1

# Core packages
RUN apt -y install --no-install-recommends \
    build-essential apt-utils \
    python3 python3-dev python3-pip \
    git wget vim nano curl bzip2 tree less man-db \
    gnupg2 ca-certificates sudo \
    htop bmon iotop neofetch\
    && apt autoremove -y \
    && apt clean -y

# Link python3 to python
RUN ln -sv /usr/bin/python3 /usr/bin/python

# Install core python packages
RUN python3 -m pip install \
    numpy==2.2.6 \
    scipy==1.8.0 \
    pillow==9.0.1 \
    pandas==2.3.1 \
    matplotlib==3.5.1 \
    seaborn==0.13.2 \
    empy==3.3.4 \
    pyros-genmsg==0.5.8 \
    setuptools==59.6.0

# Install QGC and link to PATH
# Allows QGC to work without network_mode=host
RUN usermod -a -G dialout $USERNAME
RUN apt-get remove modemmanager -y
RUN apt -y install --no-install-recommends \
    gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl \
    libfuse2 \
    libxcb-xinerama0 libxkbcommon-x11-0 libxcb-cursor-dev \
    pipewire libspeechd2
RUN wget https://github.com/mavlink/qgroundcontrol/releases/download/v5.0.6/QGroundControl-x86_64.AppImage
# Custom launch script to launch appimages in containers
RUN echo "#!/usr/bin/env bash" >> /usr/bin/qgc
RUN echo "/QGroundControl-x86_64.AppImage --appimage-extract-and-run" >> /usr/bin/qgc
RUN chmod +x "/QGroundControl-x86_64.AppImage"
RUN chmod +x "/usr/bin/qgc"

# Do as USER
USER $USERNAME
WORKDIR /home/$USERNAME

# Install PX4
RUN git clone --branch v1.15.4 --depth 1 https://github.com/PX4/PX4-Autopilot.git && \
    cd PX4-Autopilot && \
    git checkout v1.15.4 && \
    make submodulesclean

RUN bash ./PX4-Autopilot/Tools/setup/ubuntu.sh

# Build gazebo
RUN cd ~/PX4-Autopilot && \
    make distclean && \
    DONT_RUN=1 make px4_sitl

# Back to root
USER root
WORKDIR /

# Install Mavros/Mavlink (binary installation)
RUN apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-mavros \
    ros-${ROS_DISTRO}-mavros-extras \
    ros-${ROS_DISTRO}-mavros-msgs

# This stopped working on 2025-01-07 on my machine, some sort of TLS issue or something, do manual install as workaround
RUN wget https://raw.githubusercontent.com/mavlink/mavros/ros2/mavros/scripts/install_geographiclib_datasets.sh && \
    bash ./install_geographiclib_datasets.sh

# Manual geographiclib datsets installation
# RUN wget -O egm96.tar.bz2 http://downloads.sourceforge.net/project/geographiclib/gravity-distrib/egm96.tar.bz2?use_mirror=autoselect && \
#     wget -O egm96-5.tar.bz2 http://downloads.sourceforge.net/project/geographiclib/geoids-distrib/egm96-5.tar.bz2?use_mirror=autoselect && \
#     wget -O emm2015.tar.bz2 http://downloads.sourceforge.net/project/geographiclib/magnetic-distrib/emm2015.tar.bz2?use_mirror=autoselect && \
#     tar -xvjf egm96.tar.bz2 && \
#     tar -xvjf egm96-5.tar.bz2 && \
#     tar -xvjf emm2015.tar.bz2 && \
#     sudo cp -r geoids /usr/share/GeographicLib && \
#     sudo cp -r gravity/ /usr/share/GeographicLib && \
#     sudo cp -r magnetic/ /usr/share/GeographicLib

# Computer vision python packages

# https://pytorch.org/get-started/locally/
# Change (or remove) --index-url to use a different compute platform, the GPU versions take a lot more space ~4GB
# You will also have to enable gpu in docker-compose.yml (and have drivers on host machine)
# Platforms successfully tested:
# CPU:  Yes
# CUDA: No
# ROCm: No

# Install old networkx first
# RUN python3 -m pip install \
#     networkx==3.0

RUN python3 -m pip install \
    torch torchvision torchaudio \
    # --index-url https://download.pytorch.org/whl/cpu
    --index-url https://download.pytorch.org/whl/cu128
    # --index-urlhttps://download.pytorch.org/whl/rocm6.3

# ultralytics needs requests but is not a pip dependency for some reason
RUN python3 -m pip install \
    opencv-python \
    ultralytics
#     requests

# For the drone-visualization webviewer (vite needs node v18 as minimum)
# RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
#     apt-get install -y --no-install-recommends nodejs

# Place new packages here or ones not needed in any build dependencies
# RUN apt-get install -y --no-install-recommends \
#     python3-vcstool \
#     x11-apps \
#     dos2unix \
#     graphviz \
#     ros-${ROS_DISTRO}-rosbridge-server \
#     python3-lxml \
#     bash-completion \
#     iputils-ping \
#     net-tools \
#     tmux
# RUN python3 -m pip install --ignore-installed \
#     colorama \
#     pydot \
#     pygeodesy \
#     pyserial \
#     types-colorama \
#     flask-socketio \
#     flask_cors \
#     pykml

# Install requests again because it doesn't get installed to user when installed earlier for some reason
# RUN python3 -m pip install \
#     requests

USER $USERNAME

# Append setup to .bashrc
RUN echo "" >> ~/.bashrc && \
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && \
    echo "source /home/uas/workspace/uas_ws/install/local_setup.bash" >> ~/.bashrc \
    echo "" >> ~/.bashrc
