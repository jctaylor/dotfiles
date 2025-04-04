#!/bin/bash

script_name=$(realpath $0)
script_dir=$( dirname $script_name )
script_name=$( basename $script_name )

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

"


# Script parameters
strategy=hard_link   # diff, copy, hard_link
dry_run=""
new_files=()   # An array of new files to add
backup_dir=

while [ -n "$1" ]; do
    case "$1" in
        *-h* )   # match -h --h --help -h-anything
            echo "$usage"
            exit 0
            ;;
        -d)
            echo >&2 "ERROR: ambiguous option --dry-run or --diff"
            exit 1
            ;;
        *-dr* )
            cmd_prefix="echo dry run: "
            ;;
        *-di*)
            # show differences
            strategy=diff
            ;;
        *-c*)
            strategy=copy
            ;;
        *-b*)
            backup_dir="$script_dir/backup$(date +%Y-%m-%d_%H.%M.%S)"
            if mkdir -p $backup_dir; then
                echo "ERROR: Could not create backup directory $backup_dir"
            fi
            ;;
        -v)
            set -x
            ;;
        *-a*)
            # All options after --add the don't start with '-' are considered files.
            # If you need to add a file that starts with '-' you can give the full path or add it manually
            echo ${2:0:1}
            while [ -n "$2" ] && [ "${2:0:1}" != "-" ]; do 
                new_files+=("$2")
                shift
            done
            ;;
        *)
            echo "Unknown option $1 $usage" >&2
            exit 1
            ;;
    esac
    shift
done

set -u


if [ $strategy = diff ]; then
    backup_dir="" # make no sense to backup when just comparing files
fi



function repo_from_real_file {
    # Convert an installed path into repo path
    echo "$1" |  sed "s#${HOME}/#${script_dir}/#"
}


function real_from_repo_file {
    # Convert a repo path into installed path
    echo "$1" |  sed "s#${script_dir}/#${HOME}/#"
}


function sync_file {

    # If backup is selected, real files are copied to a backup directory before copying or linking
    if [ -n "$backup_dir" ] && [[ $1 == ${script_dir}* ]]; then
        $cmd_prefix cp "$1" "$backup_dir/"
    fi

    case $strategy in
        hard_link)
            $cmd_prefix ln -f -n "$1" "$2"
            ;;
        symbolic_link)
            $cmd_prefix ln -s -f -n  "$1" "$2"
            ;;
        copy_file)
            $cmd_prefix cp -f "$1" "$2"
            ;;
        show_diff)
            $cmd_prefix diff "$1" "$2"
            ;;
        *)
            echo >&2 "ERROR: not valid strategy $strategy"
            exit 1
            ;;
    esac

}

function log {
    if [ "$debug" = debug ]; then
        echo "$*"
    fi
}

# Work from this script directory
cd "$script_dir"


echo "
Running $script_name from $script_dir
"

# Make any needed directories in HOME. 
# If there is a directory in dotfile/home that is not in ${HOME}, create it in HOME.
for src_dir in $(find home -type d); do
    dir_path=$( echo $src_dir | sed "s#.*home/#${HOME}/#" )
    if [ -n "$dir_path" ] && [ ! -d $dir_path ]; then
        $cmd_prefix mkdir -p "$dir_path"
    fi
done


# Sync files either direction. Take the newer file as authoritative
for repo_file in $(find home -type f -print0 | xargs -0 realpath ); do
    real_file=$(real_from_repo_file $repo_file)
    echo $real_file $repo_file
    if [ $real_file -ot $repo_file ]; then
        # copy or link repo file to real file
        #echo "$repo_file --> $real_file"
        sync_file $real_file $repo_file
    elif [ $repo_file -ot $real_file ]; then
        sync_file $repo_file $real_file
        # copy or link real file to repo
        #echo "$real_file --> $repo_file"
    elif [ $repo_file -ef $real_file ]; then
        # they are the same file, nothing to do
        #echo "$real_file matches repo"
        :
    else
        echo >&2 "WARNING: check $repo_file and $real_file manualy"
    fi
done

# Add new files
# New files that exist in HOME can be added to the repo to track with the --add option
if [ ${#new_files[@]} -ne 0 ]; then 
    for new_file in "${new_files[@]}"; do
        if [ -f $new_file ]; then
            real_file=$(realpath $new_file)
            repo_file=$(repo_from_real_file $real_file )
            if [ -f $repo_file ]; then
                echo >&2 "WARNING: Trying to add a new file \"${new_file}\" that is already tracked"
            else
                $cmd_prefix  $real_file $repo_file
            fi
        else
            echo >&2 "WARNING: file \"$real_file\" not found"
        fi
    done
fi

git status

exit 0

