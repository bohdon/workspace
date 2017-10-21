set -x

# code
cp -av "prefs/Code/win/." "$HOME/AppData/Roaming/Code/"

# conemu
cp -av "prefs/ConEmu/ConEmu.xml" "$HOME/AppData/Roaming/"

# sublime text
cp -av "prefs/Sublime Text 3/." "$HOME/AppData/Roaming/Sublime Text 3/"

# git
git config --global include.path "~/dev/workspace/prefs/git/gitconfig"