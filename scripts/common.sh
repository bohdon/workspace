#! /bin/bash
# shared utils for running setup scripts

if [ "$OSTYPE" == "darwin"* ]; then
    os_name="mac"
elif [ "$OSTYPE" == "msys" ]; then
    os_name="win"
elif [ "$OSTYPE" == "linux-gnu"* ]; then
    os_name="linux"
else
    echo "Unrecognized OS: '${OSTYPE}'"
    exit 1
fi

# simple cross-platform symlink util
link() {
    # use mklink if on windows
    if [[ -n "$WINDIR" ]]; then
        # determine if the link is a directory
        # also convert '/' to '\'
        if [[ -d "$1" ]]; then
            cmd <<<"mklink /D \"$(cygpath -w \"$2\")\" \"$(cygpath -w \"$1\")\"" >/dev/null
            # " # syntax highlight fix
        else
            cmd <<<"mklink \"$(cygpath -w \"$2\")\" \"$(cygpath -w \"$1\")\"" >/dev/null
            # " # syntax highlight fix
        fi
    else
        ln -sf "$1" "$2"
    fi
}

should_install() {
    if [[ "$INSTALL_ALL" == true ]]; then
        return 0
    fi

    # echo -n "Install $1? (y/n) "
    read -p "Install $1? (y/n) " -r -n 1 answer
    echo
    if [[ $answer =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}
