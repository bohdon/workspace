#! /bin/bash

echo "Installing Mac workspace"

if should_install "All"; then
    INSTALL_ALL=true
fi

# zshrc
if should_install "zshrc"; then
    install_bashrc "${workspace_dir}/prefs/shell/${os_name}/zshrc"
fi

# VS Code
if should_install "VS Code prefs"; then
    cp -av "prefs/Code/mac/." "$HOME/Library/Application Support/Code/"
fi

# Git Config
if should_install "Git Config"; then
    set -x
    git config --global include.path "${workspace_dir}/prefs/git/gitconfig"
    { set +x; } 2>/dev/null
fi
