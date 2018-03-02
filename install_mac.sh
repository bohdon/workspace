set -x

# code
cp -av "prefs/Code/mac/." "$HOME/Library/Application Support/Code/"

# sublime text
cp -av "prefs/Sublime Text 3/." "$HOME/Library/Application Support/Sublime Text 3/"

# git
git config --global include.path "~/dev/workspace/prefs/git/gitconfig"
