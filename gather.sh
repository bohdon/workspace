#! /bin/bash

# Copy prefs back out of installed apps and into this repo, the reverse of setup.sh.

cd $(dirname $0)

source scripts/common.sh

gather_script="scripts/gather_${platform}.sh"

if [ -f "$gather_script" ]; then
    source "$gather_script"
else
    echo "No gather script for '${platform}'"
fi
