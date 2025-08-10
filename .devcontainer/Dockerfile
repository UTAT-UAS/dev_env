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
    htop bmon iotop neofetch tmux \
    bash-completion \
    iputils-ping net-tools usbutils \
    python3-vcstool \
    && apt autoremove -y \
    && apt clean -y

# Link python3 to python
RUN ln -sv /usr/bin/python3 /usr/bin/python

# Install core python packages
RUN python3 -m pip install \
    numpy \
    scipy \
    pillow \
    pandas \
    matplotlib \
    seaborn

# Install python packages needed for PX4, setuptool==64.0.4 required for px4_msgs to build
RUN python3 -m pip install \
    empy==3.3.4 \
    pyros-genmsg==0.5.8 \
    setuptools==64.0.3

# Install QGC and link to PATH
# Allows QGC to work without network_mode=host
RUN usermod -a -G dialout $USERNAME
RUN apt-get remove modemmanager -y
RUN apt -y install --no-install-recommends \
    gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl \
    libfuse2 libxcb-xinerama0 libxkbcommon-x11-0 libxcb-cursor-dev \
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
RUN git clone --branch v1.16.0 https://github.com/PX4/PX4-Autopilot.git --recursive && \
    bash ./PX4-Autopilot/Tools/setup/ubuntu.sh && \
    cd PX4-Autopilot && \
    DONT_RUN=1 make px4_sitl

# Install uXRCE-DDS agent and client
# Requires teh `sed` command to fix: https://github.com/eProsima/Micro-XRCE-DDS-Agent/issues/370
RUN git clone --branch v2.4.2 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git && \
    cd Micro-XRCE-DDS-Agent && \
    sed -i 's/_fastdds_tag 2\.12\.x/_fastdds_tag v2\.12\.2/' CMakeLists.txt && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j && \
    sudo make install && \
    sudo ldconfig /usr/local/lib/

# Back to root
USER root
WORKDIR /

# Install Mavros/Mavlink (binary installation)
RUN apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-mavros \
    ros-${ROS_DISTRO}-mavros-extras \
    ros-${ROS_DISTRO}-mavros-msgs

# geographiclib datsets installation
RUN wget https://raw.githubusercontent.com/mavlink/mavros/ros2/mavros/scripts/install_geographiclib_datasets.sh && \
    bash ./install_geographiclib_datasets.sh

# Computer vision Python packages

# https://pytorch.org/get-started/locally/
# Change (or remove) --index-url to use a different compute platform (make sure to use the correct cu/rocm version for you GPU)
# Note that the GPU versions take a lot more space ~4GB
# You will also have to enable gpu in docker-compose.yml (and have drivers on host machine)

RUN python3 -m pip install \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cpu
    # --index-url https://download.pytorch.org/whl/cu128
    # --index-url https://download.pytorch.org/whl/rocm6.3
RUN python3 -m pip install \
    opencv-python \
    ultralytics

# Place new packages here or ones not needed in any build dependencies
RUN apt-get install -y --no-install-recommends \
    x11-apps \
    dos2unix
# RUN python3 -m pip install --ignore-installed \
#     colorama \
#     pydot \
#     pygeodesy \
#     pyserial \
#     types-colorama \
#     flask-socketio \
#     flask_cors \
#     pykml

USER $USERNAME

# Append setup to .bashrc
RUN echo "" >> ~/.bashrc && \
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && \
    echo "source /home/uas/workspace/uas_ws/install/local_setup.bash" >> ~/.bashrc \
    echo "" >> ~/.bashrc
