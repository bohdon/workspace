#! /bin/bash

cd $(dirname $0)

source scripts/common.sh

ALL_COMMANDS="ws/workspace apps python node"

# run command by name
if [[ "$1" ]]; then
    if [[ $1 == "ws" ]]; then
        cmd="workspace"
    else
        cmd="$1"
    fi

    os_script="scripts/setup_${cmd}_${os_name}.sh"
    generic_script="scripts/setup_${cmd}.sh"

    if [ -f $os_script ]; then
        source "$os_script"
    elif [ -f $generic_script ]; then
        source "$generic_script"
    else
        echo "No setup script for '${cmd}' on '${os_name}'"
    fi

else
    echo -e "usage: setup.sh [COMMAND]\n  $ALL_COMMANDS"
fi
