# Dev Env

A batteries-included opinionated environment for UAS Multirotor PX4/ROS2 project development.

## Features

- Includes ROS2 Humble, PX4 16.0, uXRCE-DDS, and other development tools/dependencies
- VSCode configuration pre-configured (generic editor documentation coming soon)
- QGroundControl bundled in the system path with `qgc`

[See here for the full walkthrough](https://utat-uas.github.io/wiki/Multirotor/Tutorials/)

## Repository Layout

```cs
.                   // Mounted to /home/uas/workspace in container
├── .devcontainer/  // Container configuration + setup
├── .vscode/        // VSCode configuration
├── repos/          // Repository lists for vcstool
└── uas_ws/         // ROS2 workspace
    └── src/        // ROS2 packages
        └── ...
```

The PX4 repository is cloned to `/home/uas`

## Getting Started

OS Support:
- [x] **Linux (x86_64)**: Working, any distro, optimal, beautiful, perfect.
- [x] **Windows (x86_64)**: Working*
- [ ] MacOS: Non-working (Gazebo does not work)
- [ ] Windows (ARM): untested
- [ ] Linux (ARM): untested
- [ ] FreeBSD: untested
- [ ] Linux (RISC-V): untested

*Gazebo seems unable to use integrated GPUs however, and dedicated GPU setup has not been tested

Recommended at least ~15GB of free space (more is better).
- Container is about ~12GB (it takes a lot of packages to run this stuff).
- Extra 3GB for the container storage, files, caching, logs, etc.
- With GPU accelerated PyTorch ~25GB of free space is required

Assuming you have Docker and VSCode already installed. (For Windows Docker should be installed via WSL in order for X11 apps to work) (For Linux rootless Docker will not work as the workspace ownership will be weird)

See [Virtual Desktop](#virtual-desktop) for enabling a browser accessible desktop.

1. Clone this repository and open it in VScode. Ensure you have [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension installed.
2. Take the time now to [enable GPU passthrough](#gpu) for Gazebo and Computer Vision tasks.
3. You should be prompted by a pop-up in the bottom right to open this folder in a container.
    - If not, open command palette `ctrl+shift+p` and search for `Dev Containers: Open Folder in Container`.
4. VScode should begin building the container
    - On a fast PC with fast internet this takes about 15 minutes
    - On a slow PC with slow internet this could take 30++ minutes
5. Test that your setup works by running the `sim` command
6. For version control GitHub via `SSH` is required: [GitHub docs](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
7. Enable `ssh-agent` [passthrough](https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials) for devcontainers.
8. From `/home/uas/workspace` Run `vcs import < ./repos/latest.repos`
    - If new repositories do not appear in VScode source control, from command palette run `Developer: Reload Window` to refresh.
    - If new repositories are still not visible on the source control tab click the `...` then `View & Sort` > `repositories` and check the ones you want to see. Alternatively under `Views` enable `Source Control Repositories` for an alternate layout.
9. Once in the container run `cd uas_ws` and run `colcon build --symlink-install`.
10. Read each repositories `README.md` for more information on working with them.

## vcstool

We use [vcstool](https://github.com/dirk-thomas/vcstool) to easily manage the repositories and checkout to specific commits. All examples are run in `~/workspace` (default dir). Aliases have been provided for convenience in the comment #.

For example to fetch (and switch) to the latest commit:

```
vcs import < ./repos/latest.repos # vcsl
```

Then assuming you have no conflicting changes, pull the latest commits into your local repo:

```
vcs pull -n # vcsp
```

You can also checkout to specific tags or branches, defined in `.repos` file, for example to use the `stable` tag:

```
vcs import < ./repos/stable.repos
```

Managing remote and local tags are tricky, if you would like to pull (overwrite) tags from remote then:

```
vcs custom -n --git --args fetch --tags --force # vcst
```

## GPU

A GPU is highly recommend for Computer Vision tasks. It is also nice to have for Gazebo otherwise you will get around 12 fps (although the RTF factor seems fine).

Setup will vary widely between OS and hardware configurations, it is likely best you consult external sources for your specific configuration.

### Nvidia

Windows/WSL2:

TODO DOCUMENTATION NEEDED

Ubuntu:

TODO DOCUMENTATION NEEDED

NixOS:

`hardware.nvidia-container-toolkit.enable = true;`

Uncomment the `deploy` section in `docker-compose.yaml`

### AMD

Pytorch does not work with AMD cards earlier than the RX 6000 (Navi 2x) series

TODO DOCUMENTATION NEEDED

### Intel

Pytorch does support Intel GPUs.

TODO DOCUMENTATION NEEDED

### iGPU

Linux: If it works on the host it should just work

Windows/WSL2: Seems to be unsupported for Gazebo

## Virtual Desktop

Warning large performance hit (~2 times slower when run on my machine), use only if necessary.

All files in `.devcontainer` directory.

In `devcontainer.json` uncomment the `features` object and ports `6080`, `5901` in `forwardPorts` and `portAttributes`.

In `docker-compose.yml` comment out `environment:` and associated intended variables.

Rebuild the container (it should hopefully use the cached layers), and open `localhost:6080` in your browser, login and you shoudl see a desktop. All GUI applications will now open in here when run from the terminal.

Tips:
- On the pullout tab on the left under `settings` set `Scaling Mode:` to `Remote Resizing` to set the resolution of the desktop to your own.

## Customization

If you have a preferred workflow/tools that are not installed/enabled by default (you will know if this is you). Instead of polluting the Dockerfile with random packages/scripts add a custom setup script in `.devcontainer/profiles/`, then set the `USER_PROFILE` var in `.devcontainers/post-create.sh`. Keep in mind this script runs once after container creation. Submit a PR with your setup script if you think its useful/interesting.

Or use an existing [devcontainer-feature](https://containers.dev/features)

Adding VSCode extensions can be done via:

https://code.visualstudio.com/docs/devcontainers/containers#_always-installed-extensions

## Installing more software in the container

The container is based on `Ubuntu 22.04.5 LTS`, the `uas` user is configured with passwordless `sudo`.

```sh
# Probably have to run this the first time you open the container
sudo apt update
# Install more software e.g. btop
sudo apt install btop
# Use pip (as sudo unless using venv) to install more python modules (only if necessary)
sudo pip install pyjokes
```

## QGroundControl

QGroundControl is bundled with the container and will work with the PX4/Gazebo simulation. Simply run `qgc`.

### Joystick

Enable usb joystick by uncommenting the `/dev/input:/dev/input` volume in `.devcontainer/docker-compose.yml` (security note: this passes through all of your input devices to the container). Depending on your joystick you may need [https://github.com/sezanzeb/input-remapper/tree/main?tab=readme-ov-file](https://github.com/sezanzeb/input-remapper/tree/main?tab=readme-ov-file), or edit and export the `SDL_GAMECONTROLLERCONFIG` environment variable. See `./profiles` for examples.

In QGroundControl on the Vehicle Configuration page the Joystick option should be visible, enable joystick input, calibrate if necessary and assign button actions.

Depending on the simulation/Docker/OS/hardware you will get communication loss errors from QGroundControl, set `COM_RC_LOSS_T` to some large number like 5 seconds, probably don't do this on a real drone but for simulation its fine.

### Configuration

If you want to allow an instance of QGroundControl running natively on the host system to connect to the simulation, goto `.devcontainer/docker-compose.yml` and uncomment `network_mode: host`, you should also comment out `forwardPorts` in `.devcontainer/devcontainer.json` to fix some behavioral issues. Rebuild the container.

After rebuild make sure that no ports are forwarded from the devcontainer, by default the `ports` tab is on the same panel as the terminal. Select any open ports and right click `stop forwarding`. (this is the behavior for Linux, other operating systems may be different)

Note that `network_mode: host` will make it more likely that other issues will occur. You may get firewall issues which will prevent ROS2 from running.
