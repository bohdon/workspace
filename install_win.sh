set -x

cd $(dirname $0)

# simple cross-platform symlink util
link() {
    # use mklink if on windows
    if [[ -n "$WINDIR" ]]; then
        # determine if the link is a directory
        # also convert '/' to '\'
        if [[ -d "$1" ]]; then
            cmd <<< "mklink /D \"`cygpath -w \"$2\"`\" \"`cygpath -w \"$1\"`\"" > /dev/null
        else
            cmd <<< "mklink \"`cygpath -w \"$2\"`\" \"`cygpath -w \"$1\"`\"" > /dev/null
        fi
    else
        ln -sf "$1" "$2"
    fi
}


# code
cp -av "prefs/Code/win/." "$HOME/AppData/Roaming/Code/"

# conemu
cp -av "prefs/ConEmu/ConEmu.xml" "$HOME/AppData/Roaming/"

# sublime text
cp -av "prefs/Sublime Text 3/." "$HOME/AppData/Roaming/Sublime Text 3/"

# git
git config --global include.path "~/dev/workspace/prefs/git/gitconfig"

# ahk utils
link "`pwd`/utils/ahk/WindowMover.ahk" "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/WindowMover.ahk"
link "`pwd`/utils/ahk/DisableAltTap.ahk" "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/DisableAltTap.ahk"