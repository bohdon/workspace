#! /bin/bash

# install or update the workspace repo, then run setup
# usage: curl -fsSL https://raw.github.com/bohdon/workspace/main/install.sh | bash

set -euo pipefail

command -v git >/dev/null || { echo "git is required to install this repo" >&2; exit 1; }

repo_dir="$HOME/workspace"

if [[ -d "$repo_dir/.git" ]]; then
    # already installed: fast-forward only, so local edits never get merged into silently
    echo "Updating existing repo at $repo_dir"
    git -C "$repo_dir" pull --ff-only || { echo "Update failed - resolve manually in $repo_dir" >&2; exit 1; }
elif [[ -e "$repo_dir" ]]; then
    # a directory we don't own: refuse rather than clone over it
    echo "'$repo_dir' exists but isnt a git repo, skipping overwrite" >&2
    exit 1
else
    echo "Cloning into $repo_dir"
    git clone https://github.com/bohdon/workspace.git "$repo_dir"
fi

# run setup from the freshly cloned copy so its interactive prompts read the terminal:
# when invoked as 'curl ... | bash' stdin is the (already consumed) pipe, not a tty
if [[ -t 0 ]]; then
    bash "$repo_dir/setup.sh" "$@"
else
    bash "$repo_dir/setup.sh" "$@" < /dev/tty
fi
