#! /bin/bash

# shared utils for running setup scripts

workspace_dir=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/..")

if [[ "$OSTYPE" == "darwin"* ]]; then
    platform="mac"
    installer="brew"
    bashrc_file="$HOME/.zshrc"
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys"* ]]; then
    platform="win"
    installer="choco"
    bashrc_file="$HOME/.bash_profile"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    platform="linux"
    installer="sudo apt-get"
    bashrc_file="$HOME/.bashrc"
else
    echo "Unknown platform: '${OSTYPE}'"
    exit 1
fi

# colors
reset=$'\e[0m'
bold=$'\e[1m'
cyan=$'\e[36m'
grey=$'\e[90m'
blue=$'\e[94m'
white=$'\e[97m'

# show a multi select menu
# usage: multiselect RESULT_ARRAY "A" "B" ...
multiselect() {
    local -n _out=$1; shift
    local opts=("$@") n=$# cur=0 i key box ptr color

    # selection state
    local -a sel=()
    for ((i=0; i<n; i++)); do sel[i]=0; done

    # hide cursor, show it on return
    tput civis; trap 'tput cnorm' RETURN

    while true; do
    # redraw all rows, \r returns to column 1 and \033[K clears the rest of each line
    for ((i=0; i<n; i++)); do
        box="◻"; ptr=" "; color="$grey"
        # the arrow marks the row the keys act on, drawn in white
        if [[ $i == "$cur" ]]; then ptr=" "; color="$white"; fi
        # filled box marks a selected option
        if [[ ${sel[i]} == 1 ]]; then box="${blue}◼${color}"; fi
        printf '\r\033[K%s %s %s %s%s\n' "$color" "$ptr" "$box" "${opts[i]}" "$reset"
    done
    printf "${grey}↑/↓ ${white}navigate ${grey}• Space: ${white}select ${grey}• Enter: ${white}confirm${reset}\n"
    # one raw keypress without echo; Enter reads as an empty string
    IFS= read -rsn1 key
    # arrow keys send ESC plus 2 more bytes: "[A" for up, "[B" for down
    if [[ $key == $'\e' ]]; then read -rsn2 -t 0.01 key || key=esc; fi
    case $key in
        # up or k: previous row, wrapping around
        '[A'|k) cur=$(( (cur - 1 + n) % n ));;
        # down or j: next row, wrapping around
        '[B'|j) cur=$(( (cur + 1) % n ));;
        # space toggles selection
        ' ')    sel[cur]=$(( 1 - sel[cur] ));;
        # Enter confirms: erase the menu (up n+1 lines, clear to end of screen) and park the cursor at its top line
        '')     printf '\033[%dA\r\033[J' "$((n + 1))"; break;;
    esac
    # move back up n+1 lines (n rows + the help lines) so the next redraw overwrites the menu in place
    printf '\033[%dA' "$((n + 1))"
    done

    _out=()
    for ((i=0; i<n; i++)); do
        # hand the chosen labels back to the caller
        if [[ ${sel[i]} == 1 ]]; then _out+=("${opts[i]}"); fi
    done

    # print the results
    local label
    if [[ ${#_out[@]} -eq 0 ]]; then
        printf '  %s\n' "${grey}none${reset}"
    else
        for label in "${_out[@]}"; do
            printf '  %s\n' "${blue}${label}${reset}"
        done
    fi
    printf '\n'
}

# Reurn true if an item is in an array.
# usage: selected ARRAY_NAME ITEM
selected() {
    local -n arr=$1
    local item
    for item in "${arr[@]}"; do
        [[ "$item" == "$2" ]] && return 0
    done
    return 1
}

# Show a y/n confirmation before changes
confirm() {
    local answer
    echo -e "\n${bold}Apply the selected changes? ${grey}(y/n)${reset}"
    read -r -n 1 answer
    echo
    [[ $answer =~ ^[Yy]$ ]]
}

# simple cross-platform symlink util
link() {
    echo -e "linking ${cyan}${2}${reset} -> ${1}"
    # use mklink if on windows
    if [[ -n "$WINDIR" ]]; then
        # determine if the link is a directory
        # also convert '/' to '\'
        if [[ -d "$1" ]]; then
            cmd <<<"mklink /D \"$(cygpath -w "$2")\" \"$(cygpath -w "$1")\"" >/dev/null
            # " # syntax highlight fix
        else
            cmd <<<"mklink \"$(cygpath -w "$2")\" \"$(cygpath -w "$1")\"" >/dev/null
            # " # syntax highlight fix
        fi
    else
        ln -sf "$1" "$2"
    fi
}

install_pkgs() {
    if [[ $1 ]]; then
        set -x
        $installer install -y $@
        { set +x; } 2>/dev/null
    else
        echo "${grey}No apps to install${reset}"
    fi
}

# copy a settings file out of an app's config dir and into this repo
gather() {
    if [ ! -f "$1" ]; then
        echo "No $1, skipping"
        return
    fi

    mkdir -p "$(dirname "$2")"
    cp -av "$1" "$2"
}

# run "<APP>_gather" if the platform script defines that app
gather_app() {
    if declare -f "${1}_gather" >/dev/null; then
        "${1}_gather"
    else
        echo "${grey}No gather script for '${1}' on '${platform}'${reset}"
    fi
}

gather_apps() {
    echo -e "\n${bold}Select prefs to gather${reset}"

    declare -a apps=()
    multiselect apps $ALL_APPS

    if [ ${#apps[@]} -eq 0 ]; then
        echo "${grey}No apps selected${reset}"
    else
        if confirm; then
            for app in "${apps[@]}"; do
                gather_app "$app"
            done
        else
            echo "Cancelled"
        fi
    fi
}

install_bashrc() {
    comment="# source https://github.com/bohdon/workspace bashrc"
    script="if [ -f $1 ]; then\n    . $1\nfi"

    if [[ -f $bashrc_file ]] && $(grep -Eq "$1" $bashrc_file); then
        echo "${grey}${bashrc_file} unchanged${reset}"
        return
    fi

    echo -e "\n$comment\n$script" >> "$bashrc_file"
    echo "Updated $bashrc_file"
}
