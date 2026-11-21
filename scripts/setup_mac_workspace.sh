#! /bin/bash

collect_workspace() {
    echo "Select workspace features"
    declare -ga chosen_ws=()
    multiselect chosen_ws "zshrc" "VS Code prefs" "Zed prefs" "gitconfig"
}

apply_workspace() {
    echo -e "\nApplying workspace..."

    if selected chosen_ws "zshrc"; then
        install_bashrc "${workspace_dir}/prefs/shell/${platform}/zshrc"
    fi

    if selected chosen_ws "VS Code prefs"; then
        cp -av "prefs/Code/mac/." "$HOME/Library/Application Support/Code/"
    fi

    if selected chosen_ws "Zed prefs"; then
        mkdir -p "$HOME/.config/zed"
        cp -av "prefs/Zed/keymap.json" "$HOME/.config/zed/keymap.json"
        cp -av "prefs/Zed/settings.json" "$HOME/.config/zed/settings.json"
    fi

    if selected chosen_ws "gitconfig"; then
        set -x
        git config --global include.path "${workspace_dir}/prefs/git/gitconfig"
        { set +x; } 2>/dev/null
    fi
}
