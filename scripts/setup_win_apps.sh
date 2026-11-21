#! /bin/bash

collect_apps() {
    echo "Select apps to install"
    declare -ga chosen_apps=()
    multiselect chosen_apps "Python 3.13" "uv pip: black[d]" "uv pip: pre-commit" "node" "AutoHotkey" "Lightshot" "wiztree" "Bitwarden" "Notion" "JetBrains Toolbox"
}

apply_apps() {
    echo -e "\nInstalling apps..."
    local pkgs="" uvpkgs=""

    if selected chosen_apps "Python 3.13"; then
        choco install python313 -y
    fi

    if selected chosen_apps "uv pip: black[d]"; then
        uvpkgs="${uvpkgs} black[d]"
    fi

    if selected chosen_apps "uv pip: pre-commit"; then
        uvpkgs="${uvpkgs} pre-commit"
    fi

    if [[ $uvpkgs ]]; then
        uv pip install --system $uvpkgs
    fi

    if selected chosen_apps "node"; then
        choco install node
    fi

    if selected chosen_apps "AutoHotkey"; then
        pkgs="${pkgs} autohotkey.portable"
    fi

    if selected chosen_apps "Lightshot"; then
        pkgs="${pkgs} lightshot"
    fi

    if selected chosen_apps "wiztree"; then
        pkgs="${pkgs} wiztree"
    fi

    if selected chosen_apps "Bitwarden"; then
        pkgs="${pkgs} bitwarden"
    fi

    if selected chosen_apps "Notion"; then
        pkgs="${pkgs} notion"
    fi

    if selected chosen_apps "JetBrains Toolbox"; then
        pkgs="${pkgs} jetbrainstoolbox"
    fi

    install_pkgs $pkgs
}
