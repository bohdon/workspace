#! /bin/bash

cd $(dirname $0)

source scripts/common.sh

ALL_COMMANDS="workspace apps python node"

# run command by name
if [[ "$1" ]]; then

    os_script="scripts/setup_${1}_${os_name}.sh"
    generic_script="scripts/setup_${1}.sh"

    if [ -f $os_script ]; then
        source "$os_script"
    elif [ -f $generic_script ]; then
        source "$generic_script"
    else
        echo "No setup script for '${1}' on '${os_name}'"
    fi

else
    echo -e "usage: setup.sh [COMMAND]\n  $ALL_COMMANDS"
fi
