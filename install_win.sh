
if should_install "All"; then
    INSTALL_ALL=true
fi

# Explorer Settings
if should_install "Explorer prefs"; then
    powershell -ExecutionPolicy Bypass -File "prefs/Explorer/SetExplorerSettings.ps1"
fi

# Caps Loc to Control
if should_install "Caps Lock as Control"; then
    regedit.exe "prefs/Windows/CapsLockMappedToControl.reg"
fi

# Visual Studio Code
if should_install "Visual Studio Code prefs"; then
    cp -av "prefs/Code/win/." "$HOME/AppData/Roaming/Code/"
fi

# Sublime Text 3
if should_install "Sublime Text 3 prefs"; then
    cp -av "prefs/Sublime Text 3/." "$HOME/AppData/Roaming/Sublime Text 3/"
fi

# Git Config
if should_install "Git Config"; then
    set -x
    git config --global include.path "`pwd`/prefs/git/gitconfig"
    { set +x; } 2> /dev/null
fi

# ConEmu
if should_install "ConEmu prefs"; then
    cp -av "prefs/ConEmu/ConEmu.xml" "$HOME/AppData/Roaming/"
fi

# AutoHotkey utils
if should_install "AutoHotkey utils"; then
    set -x
    link "`pwd`/utils/ahk/WindowMover.ahk" "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/WindowMover.ahk"
    link "`pwd`/utils/ahk/DisableAltTap.ahk" "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/DisableAltTap.ahk"
    { set +x; } 2> /dev/null
fi