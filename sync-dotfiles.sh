#!/bin/bash

script_name=$(realpath "$0")
script_dir=$( dirname "$script_name")
script_name=$( basename "$script_name" )

usage="

Usage: $script_name [--help] [--dry-run] [--verbose] [--copy] [--add-file FILE ...]

Sync config files from $script_dir/home to \${HOME} directory.

It tries to be smart about which file is authoritative.

The default strategy is to use hardlinks for the files. This way you can edit the real config file and the repo version
will be updated (assuming you are using a proper editor that edits a file as apposed to deleting and the recreating
the file.  If the editor does replace the file, this script should do the right thing because the date of the edited
file will be older than the corresponding repo file.


OPTIONS:

    NOTE: Options are a fuzzy match --h == -h == --help, -d == --d --dry == --dry-run

    --help          Show this help

    --dry-run       Dry run, show what would be done

    --diff          Show differences between the repo and the installed files

    --copy          Copy (not hard link) (TODO what if is already a hard link?)

    --symbolic      Create symbolic links

    --add FILE ...  Add an existing file in the \$HOME to the repo (i.e. place it under dotfile control).
                    NOTE: File names that start with '-' will be treated as an option not a filename.
                    In that case, add the file to $script_dir manually.

    --verbose       Verbose output.
"


function fatal {
    # Call this if there is an unrecoverable error
    echo "$*" >&2
    exit 1
}

# Script parameters
strategy=hard_link   # diff, copy, hard_link
verbose=0
new_files=()   # An array of new files to add
backup_dir=
cmd=" "
dry_run=""

while [ -n "$1" ]; do
    case "$1" in
        *-h* )   # match -h --h --help -h-anything
            echo "$usage"
            exit 0
            ;;
        -d)
            fatal "ERROR: ambiguous option --dry-run or --diff"
            ;;
        *-dr* )
            cmd="echo dry run: "
            dry_run="echo "
            ;;
        *-di*)
            # show differences
            strategy="diff"
            ;;
        *-c*)
            strategy="copy"
            ;;
        *-b*)
            backup_dir="$script_dir/backup$(date +%Y-%m-%d_%H.%M.%S)"
            ;;
        -v)
            verbose=$(("$verbose" + 1))
            ;;
        *-a*)
            # All options after --add the don't start with '-' are considered files.
            # If you need to add a file that starts with '-' you can give the full path or add it manually
            echo "${2:0:1}"
            while [ -n "$2" ] && [ "${2:0:1}" != "-" ]; do 
                new_files+=("$2")
                shift
            done
            ;;
        *)
            fatal "Unknown option $1 $usage" >&2
            ;;
    esac
    shift
done

if [ "$verbose" -gt 2 ]; then
    set -x
    if [ "$verbose" -gt 9 ]; then
        verbose=9
    fi
fi


case $strategy in
    hard_link)
        cmd+="ln -f -n "
        ;;
    symbolic_link)
        cmd+="ln -s -f -n "
        ;;
    copy_file)
        cmd+="cp -f "
        ;;
    show_diff)
        cmd+="diff "
        ;;
    *)
        fatal "ERROR: not valid strategy"
        ;;
esac


set -u

function log {
    # log [LEVEL] MESSAGE
    if [[ "$1" =~ ^[0-9]$ ]]; then
        # The first argument is a number
        level="$1"
        shift
    else
        level=0  # default level
    fi
    if [ "$level" -ge "$verbose" ]; then
        return
    fi
    echo "$*"
}


if [ -n "$backup_dir" ]; then
    log 1 "Creating backup directory $backup_dir"
    mkdir -p "$backup_dir" || fatal "ERROR: Could not create backup directory $backup_dir"
fi

if [ "$strategy" = diff ]; then
    if [ -n "$backup_dir" ]; then
        log 2 backup directory ignored if subcommand is \"diff\"
    fi
    backup_dir="" # make no sense to backup when just comparing files
fi



function repo_from_real_file {
    # Convert an installed path into repo path
    echo "$1" |  sed "s#${HOME}#${script_dir}/home#"
}


function real_from_repo_file {
    # Convert a repo path into installed path
    echo "$1" |  sed "s#${script_dir}/home#${HOME}#"
}


# Work from this script directory
cd "$script_dir" || fatal "ERROR: could not switch to $script_dir"

log 1 "
Running $script_name from $script_dir
"

# Make any needed directories in HOME. 
# If there is a directory in dotfile/home that is not in ${HOME}, create it in HOME.
while read -r src_dir; do
    dir_path="${src_dir//"$script_dir/home"/"${HOME}"}"
    log 2 "making sure $dir_path exists"
    if [ -n "$dir_path" ] && [ ! -d "$dir_path" ]; then
        $dry_run mkdir -p "$dir_path"
    fi
done < <(find home -type d )


# Sync files either direction. Take the newer file as authoritative
for repo_file in $(find home -type f -print0 | xargs -0 realpath ); do
    real_file="$(real_from_repo_file "$repo_file")"
    if [ -f "$real_file" ] && [ "$real_file" -nt "$repo_file" ]; then
        # copy or link real file to repo
        log 1 "$cmd $real_file $repo_file"
        $cmd "$real_file" "$repo_file"
    elif [ "$repo_file" -nt "$real_file" ]; then
        # copy or link repo file to real file
        log 1 "$cmd $repo_file $real_file"
        $cmd "$repo_file" "$real_file"
    elif [ "$repo_file" -ef "$real_file" ]; then
        # they are the same file, nothing to do
        log 2 "$repo_file  $real_file are the same"
    else
        echo >&2 "WARNING: check $repo_file and $real_file manualy"
    fi
done

# Add new files
# New files that exist in HOME can be added to the repo to track with the --add option
if [ ${#new_files[@]} -ne 0 ]; then 
    for new_file in "${new_files[@]}"; do
        if [ -f "$new_file" ]; then
            real_file="$(realpath "$new_file")"
            repo_file="$(repo_from_real_file "$real_file" )"
            if [ -f "$repo_file" ]; then
                echo >&2 "WARNING: Trying to add a new file \"${new_file}\" that is already tracked"
            else
                $dry_run cp "$real_file" "$repo_file"
                git add "$repo_file"
            fi
        else
            echo >&2 "WARNING: file \"$real_file\" not found"
        fi
    done
    git status
fi

exit 0

