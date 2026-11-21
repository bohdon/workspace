#! /bin/bash

# Install apps and prefs

cd $(dirname $0)

source scripts/common.sh

setup_script="scripts/setup_${platform}.sh"

if [ -f "$setup_script" ]; then
    source "$setup_script"
else
    echo "No setup script for '${platform}'"
fi
