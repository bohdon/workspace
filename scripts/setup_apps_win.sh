#! /bin/bash

echo "Installing Windows applications"

if should_install "All"; then
    INSTALL_ALL=true
fi

pkgs=""

if should_install "ConEmu"; then
    pkgs="${pkgs} conemu"
fi

if should_install "AutoHotkey"; then
    pkgs="${pkgs} autohotkey.portable"
fi

if should_install "Lightshot"; then
    pkgs="${pkgs} lightshot"
fi

if should_install "wiztree"; then
    pkgs="${pkgs} wiztree"
fi

if should_install "Bitwarden"; then
    pkgs="${pkgs} bitwarden"
fi

if should_install "Notion"; then
    pkgs="${pkgs} notion"
fi

if should_install "JetBrains Toolbox"; then
    pkgs="${pkgs} jetbrainstoolbox"
fi

install_pkgs $pkgs
