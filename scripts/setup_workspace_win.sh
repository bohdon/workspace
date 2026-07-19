#! /bin/bash

echo "Installing Windows workspace"

if should_install "All"; then
    INSTALL_ALL=true
fi

# bashrc
if should_install "bashrc"; then
    install_bashrc "${workspace_dir}/prefs/shell/${os_name}/bashrc"
    cp "${workspace_dir}/prefs/shell/win/inputrc" "$HOME/.inputrc"
fi

# Terminal
if should_install "Terminal prefs"; then
    mkdir -p "$HOME/AppData/Local/Microsoft/WIndows Terminal/Fragments/$USERNAME"
    cp -av "prefs/Terminal/settings.json" "$HOME/AppData/Local/Microsoft/WIndows Terminal/Fragments/$USERNAME/settings.json"
    powershell -ExecutionPolicy Bypass -File "prefs/Terminal/InstallTerminalSettings.ps1"
fi

# Git Config
if should_install "Git Config"; then
    set -x
    git config --global include.path "${workspace_dir}/prefs/git/gitconfig"
    { set +x; } 2>/dev/null
fi

# Explorer Settings
if should_install "Explorer prefs"; then
    powershell -ExecutionPolicy Bypass -File "prefs/Explorer/SetExplorerSettings.ps1"
fi

# Theme Settings
if should_install "Theme prefs"; then
    powershell -ExecutionPolicy Bypass -File "prefs/Windows/SetWindowsTheme.ps1"
fi

# Mouse Settings
if should_install "Mouse prefs"; then
    powershell -ExecutionPolicy Bypass -File "prefs/Windows/SetMouseSettings.ps1"
fi

# Caps Loc to Control
if should_install "Caps Lock as Control"; then
    regedit.exe "prefs/Windows/CapsLockMappedToControl.reg"
fi

# VS Code
if should_install "VS Code prefs"; then
    cp -av "prefs/Code/win-linux/." "$HOME/AppData/Roaming/Code/"
fi

# AutoHotkey utils
if should_install "AutoHotkey utils"; then
    set -x
    link "$(pwd)/utils/ahk/AlwaysOnTop.ahk" "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/AlwaysOnTop.ahk"
    link "$(pwd)/utils/ahk/WindowMover.ahk" "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/WindowMover.ahk"
    { set +x; } 2>/dev/null
fi
