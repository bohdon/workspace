#! /bin/bash
workspace_dir="$(dirname "$0")/.."
python "${workspace_dir}/utils/notify.py" "$@"
