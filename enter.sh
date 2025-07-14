#!/usr/bin/env bash

# LINUX ONLY: enter dev container from local shell (need devcontainer cli installed)
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash
