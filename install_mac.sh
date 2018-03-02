
if should_install "All"; then
    INSTALL_ALL=true
fi

# Visual Studio Code
if should_install "Visual Studio Code prefs"; then
    cp -av "prefs/Code/mac/." "$HOME/Library/Application Support/Code/"
fi

# Sublime Text 3
if should_install "Sublime Text 3 prefs"; then
    cp -av "prefs/Sublime Text 3/." "$HOME/Library/Application Support/Sublime Text 3/"
fi

# Git Config
if should_install "Git Config"; then
    set -x
    git config --global include.path "`pwd`/prefs/git/gitconfig"
    { set +x; } 2> /dev/null
fi
