# Workspace

Tools for setting up workspace preferences, installing common apps and development environments across platforms.

## Install

Run in bash (Git for Windows) to clone and run the setup script.

- `curl -fsSL https://raw.github.com/bohdon/workspace/main/install.sh | bash`

## Setup Script

Run `setup.sh` to see the available commands.

- `setup.sh apps` install common apps
- `setup.sh ws` install workspace prefs and keybindings

## Gather Script

Run `gather.sh` to pull prefs out of installed apps into this repo, the reverse of `setup.sh`. Run with no args to select from a menu, or pass a known app name:

- `gather.sh` select apps from the menu
- `gather.sh code` gather VS Code settings

Apps and their config locations live in `scripts/gather_<OS>.sh`, one script per platform.

## Features

- `bashrc` with several everyday aliases and helper functions
- AutoHotkey scripts to move windows just like on linux
- `gitconfig` aliases
- VS Code prefs and keybindings for ijkl navigation
- Zed settings and keymap
- General system prefs and hotkeys
