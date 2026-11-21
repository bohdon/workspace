#! /bin/bash

collect_workspace() {
    echo "Select workspace features"
    declare -ga chosen_ws=()
    multiselect chosen_ws "bashrc" "Terminal prefs" "gitconfig" "Explorer prefs" "Theme prefs" "Mouse prefs" "Caps Lock as Control" "VS Code prefs" "Zed prefs" "WindowMover / AlwaysOnTop"
}

apply_workspace() {
    echo -e "\nApplying workspace..."

    if selected chosen_ws "bashrc"; then
        install_bashrc "${workspace_dir}/prefs/shell/${platform}/bashrc"
        cp "${workspace_dir}/prefs/shell/win/inputrc" "$HOME/.inputrc"
    fi

    if selected chosen_ws "Terminal prefs"; then
        mkdir -p "$HOME/AppData/Local/Microsoft/WIndows Terminal/Fragments/$USERNAME"
        cp -av "prefs/Terminal/settings.json" "$HOME/AppData/Local/Microsoft/WIndows Terminal/Fragments/$USERNAME/settings.json"
        powershell -ExecutionPolicy Bypass -File "prefs/Terminal/InstallTerminalSettings.ps1"
    fi

    if selected chosen_ws "gitconfig"; then
        set -x
        git config --global include.path "${workspace_dir}/prefs/git/gitconfig"
        { set +x; } 2>/dev/null
    fi

    if selected chosen_ws "Explorer prefs"; then
        powershell -ExecutionPolicy Bypass -File "prefs/Explorer/SetExplorerSettings.ps1"
    fi

    if selected chosen_ws "Theme prefs"; then
        powershell -ExecutionPolicy Bypass -File "prefs/Windows/SetWindowsTheme.ps1"
    fi

    if selected chosen_ws "Mouse prefs"; then
        powershell -ExecutionPolicy Bypass -File "prefs/Windows/SetMouseSettings.ps1"
    fi

    if selected chosen_ws "Caps Lock as Control"; then
        regedit.exe "prefs/Windows/CapsLockMappedToControl.reg"
    fi

    if selected chosen_ws "VS Code prefs"; then
        cp -av "prefs/Code/win-linux/." "$HOME/AppData/Roaming/Code/"
    fi

    if selected chosen_ws "Zed prefs"; then
        mkdir -p "$HOME/AppData/Roaming/Zed"
        cp -av "prefs/Zed/keymap.json" "$HOME/AppData/Roaming/Zed/keymap.json"
        cp -av "prefs/Zed/settings.json" "$HOME/AppData/Roaming/Zed/settings.json"
    fi

    if selected chosen_ws "WindowMover / AlwaysOnTop"; then
        # set -x
        link "$(pwd)/utils/ahk/AlwaysOnTop.ahk" "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/AlwaysOnTop.ahk"
        dotnet build -c Release ./utils/WindowMover

        echo "$(pwd)/utils/WindowMover/bin/Release/net8.0-windows/WindowMover.exe"
        echo "$(cygpath -w "$(pwd)/utils/WindowMover/bin/Release/net8.0-windows/WindowMover.exe")"
        link "$(pwd)/utils/WindowMover/bin/Release/net8.0-windows/WindowMover.exe" "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/WindowMover.exe"
        # { set +x; } 2>/dev/null
    fi
}
