FROM osrf/ros:humble-desktop-full@sha256:ddfee4353aa16235a8f87b00815d9f8c611cf42f1fb6a90e113e573bc466f9f1

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
RUN apt -y install \
    python3-numpy \
    python3-scipy \
    python3-pillow \
    python3-pandas \
    python3-matplotlib \
    python3-seaborn

# Install PX4 and ROS python packages
RUN apt -y install \
    python3-empy \
    python3-genpy \
    python3-setuptools

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
# Requires the `sed` command to fix: https://github.com/eProsima/Micro-XRCE-DDS-Agent/issues/370
RUN git clone --branch v2.4.2 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git && \
    cd Micro-XRCE-DDS-Agent && \
    sed -i 's/_fastdds_tag 2\.12\.x/_fastdds_tag v2\.12\.2/' CMakeLists.txt && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    sudo make install && \
    sudo ldconfig /usr/local/lib/

# Build OpenCV with gstreamer support (needed for gazebo camera plugin video capture)
# https://medium.com/@erencanbulut/step-by-step-build-opencv-with-gstreamer-on-jetson-orin-nano-ubuntu-22-04-08edfb373c78
# TODO build with numpy v2.x.x
RUN sudo apt install -y \
    build-essential cmake git pkg-config \
    libjpeg-dev libtiff-dev libpng-dev \
    libavcodec-dev libavformat-dev libswscale-dev \
    libv4l-dev libxvidcore-dev libx264-dev \
    libgtk-3-dev libatlas-base-dev gfortran \
    python3-dev python3-numpy \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
RUN git clone --branch 4.12.0 --depth 1 https://github.com/opencv/opencv.git && \
    git clone --branch 4.12.0 --depth 1 https://github.com/opencv/opencv_contrib.git
RUN cd ~/opencv && \
    mkdir build && \
    cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D WITH_GSTREAMER=ON \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
    -D BUILD_opencv_python2=OFF \
    -D BUILD_opencv_python3=ON \
    -D PYTHON_VERSION=310 \
    -D PYTHON3_EXECUTABLE=$(which python3) \
    -D BUILD_EXAMPLES=OFF .. && \
    make -j$(nproc) && \
    sudo make install && \
    sudo ldconfig

RUN sudo pip install meson
RUN git clone --depth 1 -b 1.26 https://gitlab.freedesktop.org/gstreamer/gstreamer.git
RUN cd gstreamer && \
    meson setup builddir -Dgpl=enabled && \
    meson compile -C builddir && \
    yes | meson install -C builddir
RUN sudo ldconfig

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
    \. "$HOME/.nvm/nvm.sh" && \
    nvm install 22

RUN git clone --depth 1 -b gstreamer-1.26.7 https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
RUN cd gst-plugins-rs/net/webrtc && \
    cargo build && \
    cd gstwebtrc-api && \
    npm install && \
    npm run build

# Webserver dependencies
RUN sudo apt install ros-humble-rosbridge-server
RUN wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -
RUN pnpm config set store-dir ~/.local/share/pnpm/store

# Computer vision Python packages

# https://pytorch.org/get-started/locally/
# Change (or remove) --index-url to use a different compute platform (make sure to use the correct cu/rocm version for you GPU)
# Note that the GPU versions take a lot more space ~4GB
# You will also have to enable gpu in docker-compose.yml (and have drivers on host machine)
# We probably shouldn't be using pip or sudo pip but it works so...
RUN python3 -m pip install \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cpu
    # --index-url https://download.pytorch.org/whl/cu128
    # --index-url https://download.pytorch.org/whl/rocm6.3
# Install ultralytics
RUN python3 -m pip install \
    ultralytics
# Uninstall numpy for apt managed (for opencv), and remove opencv to use the one we built
RUN python3 -m pip uninstall numpy && \
    python3 -m pip uninstall opencv-python

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

# Place new packages here or ones not needed in any build dependencies
RUN apt-get install -y --no-install-recommends \
    x11-apps \
    dos2unix \
    python3-colcon-clean

USER $USERNAME

# Append ROS and PATH setup to .bashrc
RUN echo "" >> ~/.bashrc && \
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && \
    echo "source /home/uas/workspace/uas_ws/install/local_setup.bash" >> ~/.bashrc && \
    echo "source /usr/share/colcon_cd/function/colcon_cd.sh" >> ~/.bashrc && \
    echo "export _colcon_cd_root=/opt/ros/humble/" >> ~/.bashrc && \
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc && \
    echo 'export GST_PLUGIN_PATH="/home/uas/gst-plugins-rs/target/debug:$$GST_PLUGIN_PATH"' && \
    echo "" >> ~/.bashrc
