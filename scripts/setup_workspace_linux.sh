#! /bin/bash

echo "Installing Linux workspace"

if should_install "All"; then
    INSTALL_ALL=true
fi

# bashrc
if should_install "bashrc"; then
    install_bashrc "${workspace_dir}/prefs/shell/${os_name}/bashrc"
fi

# Navigation hotkeys
if should_install "Keybindings"; then
    echo "Setting keybindings..."

    # switch app windows with alt+`
    gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>grave']"

    # custom keybindings
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
    # super+e to show files
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Files"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "<Super>e"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "nautilus -w"
    # super+` to toggle terminal
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name "Guake"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding "<Super>grave"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command "guake"

    # guake keybindings
    gsettings set guake.general window-losefocus true
    gsettings set guake.keybindings.global show-hide "<Super>grave" # default F12
    gsettings set guake.general window-height 70 # default 50
    gsettings set guake.general restore-tabs-startup false # default true
    gsettings set guake.style cursor-shape 1 # default 0
    gsettings set guake.keybindings.local close-terminal "<Super>w" # default super+x
    # change just the bg and fg colors
    gsettings set guake.style.font palette '#000000000000:#cccc00000000:#4e4e9a9a0606:#c4c4a0a00000:#34346565a4a4:#757550507b7b:#060698209a9a:#d3d3d7d7cfcf:#555557575353:#efef29292929:#8a8ae2e23434:#fcfce9e94f4f:#72729f9fcfcf:#adad7f7fa8a8:#3434e2e2e2e2:#eeeeeeeeecec:#9988a692a81a:#222222222222'
    gsettings set guake.style.background transparency 100
fi

# Caps Loc to Control
if should_install "Caps Lock as Control"; then
    echo "Setting Caps Lock as Control..."
    gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"
fi

# VS Code
if should_install "VS Code prefs"; then
    cp -av "prefs/Code/win-linux/." "$HOME/.config/Code/"
fi

# Git Config
if should_install "Git Config"; then
    set -x
    git config --global include.path "${workspace_dir}/prefs/git/gitconfig"
    { set +x; } 2>/dev/null
fi
