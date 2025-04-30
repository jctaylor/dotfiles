#!/bin/bash

script_name=$(realpath "$0")
script_dir=$(dirname "$script_name")   # e.g. /home/user/dotfile
script_name=$(basename "$script_name")

usage="

Usage: $script_name [--help] [--list] [--dry-run] [--verbose] [kitty] [python [version] [version2] ... ] [c] 

Requires sudo. On Linux (including WSL), uses 'sudo apt install <package1> '
Installs programs in user space.


OPTIONS:

    --help          Show this help end exit.

    --dry-run       Dry run, show what would be done.

    --verbose       Verbose output. Use multiple times for increased verbosity.

    all             Install everything without prompting

    ML              Install machine learning bundle

    C               Install gcc, clang, cmake

    python          Install python

    dev             Install C bundle

    sql             sqlite stuff

    vm              Virtual box

    nvim            Neovim

"

function fatal {
    # Call this if there is an unrecoverable error
    echo "FATAL:$*" >&2
    exit 1
}

verbose=0
function log {
    # log [LEVEL] MESSAGE
    if [[ "$1" =~ ^[0-9]$ ]]; then
        level="$1"
        shift
    else
        level=0  # default level
    fi

    if [ "$level" -le "$verbose" ]; then
        echo "$*"
    fi
}

# all
#   dev
#       C
#       python
#       nvim -- include lsp etc.
#   ml
#       python
#       nvim
#   sql
#   vm
#
bundle=()

all=( dev ML C
while [ -n "$1" ]; do
    case "$1" in
        -h)
            echo "$usage"
            exit 0
            ;;
        all)
            python=

        *-v*)
            verbose=$(($verbose + 1))
            if [ $verbose -gt 5 ]; then
                set -x
                verbose=5
                echo "Maximum verbosity is 5"
            fi
            ;;
        *-f*)
            force_strategy=force
            ;;
        *-a*)
            # All options after --add the don't start with '-' are considered files.
            # If you need to add a file that starts with '-' you can give the full path or add it manually
            shift
            while [ -n "$1" ] && [ "${2:0:1}" != "-" ]; do
                file=$(realpath $1)
                if [ -d "$1" ]; then
                    # Add a directory
                    new_files+=($(find $1 -type f))
                elif [ -f "$1" ]; then
                    # Add a single file
                    new_files+=($1)
                fi
                shift
            done
            ;;
        *-i*)
            confirm=confirm
            ;;
        *)
            fatal "Unknown option $1 $usage" >&2
            ;;
    esac
    shift
done

if [ ]


# Debian based linux
if [ -n "$apt" ]; then
    sudo apt update
elif [ -n "brew" ]; then
    # https://mac.install.guide/homebrew/4
    # boot strap homebrew
    if ! which brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
fi


case $os in
    deb)
    ubuntu)
    linux)
    wsl)
        sudo apt update
        ;;
    mac)
        # 
        

if [ -n python ]; then
    sudo apt install python3 python3-dev python3-nvim python3-venv

log 1 "
$script_name finished
=====================================
"
exit 0

