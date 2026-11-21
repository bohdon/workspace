#! /bin/bash

ALL_APPS="code zed"

code_gather() {
    local code_dir="$HOME/AppData/Roaming/Code/User"

    gather "$code_dir/settings.json" "prefs/Code/win-linux/User/settings.json"
    gather "$code_dir/keybindings.json" "prefs/Code/win-linux/User/keybindings.json"
}

zed_gather() {
    local zed_dir="$HOME/AppData/Roaming/Zed"

    gather "$zed_dir/keymap.json" "prefs/Zed/keymap.json"
    gather "$zed_dir/settings.json" "prefs/Zed/settings.json"
}

# run gathers for the app given, or prompt for which apps to gather
if [[ "$1" ]]; then
    gather_app "$1"
else
    gather_apps
fi
