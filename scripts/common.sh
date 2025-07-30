#! /bin/bash
# shared utils for running setup scripts

if [[ "$OSTYPE" == "darwin"* ]]; then
    os_name="mac"
    installer="brew"
    bashrc_file="$HOME/.zshrc"
elif [[ "$OSTYPE" == "msys" ]]; then
    os_name="win"
    installer="choco"
    bashrc_file="$HOME/.bash_profile"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    os_name="linux"
    installer="sudo apt-get"
    bashrc_file="$HOME/.bashrc"
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

install_pkgs() {
    if [[ $1 ]]; then
        set -x
        $installer install -y $@
        { set +x; } 2>/dev/null
    else
        echo "No packages seleced to install"
    fi
}

install_bashrc() {
    comment="# source https://github.com/bohdon/workspace bashrc"
    script="if [ -f $1 ]; then\n    . $1\nfi"

    if [[ -f $bashrc_file ]] && $(grep -Eq "$comment" $bashrc_file); then
        echo "${bashrc_file} unchanged"
        return
    fi

    echo -e "\n$comment\n$script" >> "$bashrc_file"
    echo "Updated $bashrc_file"
}
