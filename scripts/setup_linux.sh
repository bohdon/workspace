#! /bin/bash

# resolve sibling scripts from this script's own dir, not the caller's cwd
script_dir="$(dirname "${BASH_SOURCE[0]}")"

source "$script_dir/setup_linux_apps.sh"
source "$script_dir/setup_linux_workspace.sh"

# collect every menu first, so nothing changes until all choices are made
collect_apps
collect_workspace

if confirm; then
    apply_apps
    apply_workspace
else
    echo "Cancelled, nothing applied"
fi
