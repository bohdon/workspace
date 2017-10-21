set -x

# code
cp -a "prefs/Code/win/." "$HOME/AppData/Roaming/Code/"

# conemu
cp -a "prefs/ConEmu/ConEmu.xml" "$HOME/AppData/Roaming/"

# git
git config --global include.path "~/dev/workspace/prefs/git/gitconfig"