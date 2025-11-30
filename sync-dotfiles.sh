#!/bin/bash

script_name=$(realpath "$0")
script_dir=$(dirname "$script_name")   # e.g. /home/user/dotfile
sync_dir="$script_dir/home"
script_name=$(basename "$script_name")

usage="

Usage: $script_name [--help] [--dry-run] [--verbose] [--copy] [--add-file FILE ...]

Sync config files from $script_dir/home to \${HOME} directory.

It tries to be smart about which file is authoritative.

There are 3 \"strategies\" that can be used:
    1. copy (real file is a copy of the repo file)
    2. symbolic_link (real file is a symbolic_link to the repo file)
    3. hard_link (real file is a hard link to the repo file)

The default strategy is to use hardlinks for the files. By using hard links, either the real file of the repo mirror
can be edited and to change the config files. When using the \"copy\" stratgey, changes do not take effect until
This argumenst assumes files are edited with a proper editor that actually edits a file as opposed to deleting the file
and recreating a new one.
The script should still do the correct thing since the time stamps will be used.

The copy strategy can fail if you edit a repo file and a real file.

TODO:   Maybe use commit time stamps pr hashes. If both the real file and the repo file have been changed then use a
        merge program when syncing.


OPTIONS:

    --help          Show this help end exit.

    --dry-run       Dry run, show what would be done.

    --add FILE ...  Add FILE to dotfile control. Use this to add exiting files in HOME to dotfile control.
                    If FILE starts with '-' (edge case!), prepend './' to the name so it is not interprreted as an option.
                    This is not used for new files within the git repo (they are automaticaly in scope).

    --verbose       Verbose output. Use multiple times for increased verbosity.

    --diff          Show differences between the repo and the installed files

    --copy          Copy strategy

    --symbolic      Symbolic link strategy

    --hard          Hard strategy (default)

    --force         Force strategy (hard link, symbolic link or copy).
                    Files previously synced by a different strategy with be re-synced with the current strategy.
                    The default is to leave equivalent files alone.
                    So some (or all) of the dotfiles are all hard links, they can be replaced by copies with:
                    $script_name --copy --force

    --interactive   Confirm before making changes

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


# Script parameters
strategy=hard_link   # diff, copy, hard_link
new_files=()         # array of new files to add to the repo
backup_dir=""
cmd_prefix=""
force_strategy="no"
dry=""
confirm=no


while [ -n "$1" ]; do
    case "$1" in
        -h)
            echo "ambiguous option --help --hard"
            exit 1
            ;;
        *-he* )
            echo "$usage"
            exit 0
            ;;
        *-ha*)
            strategy="hard_link"
            ;;
        -d)
            echo "ambiguous option --dry-run or --diff"
            exit 1
            ;;
        *-dr* )
            cmd_prefix="log 0 ==> "
            dry=dry
            ;;
        *-di*)
            # show differences but don't change
            strategy="show_diff"
            ;;
        *-c*)
            # copy file when sync needed
            strategy="copy_file"
            ;;
        *-s*)
            # copy file when sync needed
            strategy="symbolic_link"
            ;;
        *-b*)
            backup_dir="$script_dir/backup$(date +%Y-%m-%d_%H.%M.%S)"
            ;;
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

if [ -n "$dry" ] && [ $verbose = 0 ]; then 
    verbose=1
fi

threshold=$(( 5 - $verbose ))

# Check that script_dir is in the git dir
cd "$script_dir" || fatal "ERROR: could not switch to $script_dir"
git rev-parse --show-toplevel >/dev/null || fatal "ERROR: This script needs to be run from the dotfile repo"
log 2 "
Running $script_name from $script_dir
=====================================
"

# Work from this script directory

# Set the sync command depending on strategy
case $strategy in
    hard_link)  ## What if the dotfile repo is on a different file system?
        sync_cmd="ln -f -n "
        ;;
    symbolic_link)
        sync_cmd="ln -s -f -n "
        ;;
    copy_file)
        sync_cmd="cp -f "
        ;;
    show_diff)
        sync_cmd="diff_func "
        ;;
    *)
        fatal "ERROR: not valid strategy"
        ;;
esac

function run_cmd {

    if [ $confirm = confirm ]; then
        echo "RUN: $*"
        echo -n "Confirm [y/n]: " && read "x" && [ "$x" == y ] && $*
    else
        $cmd_prefix $*
        if [ ! "$dry" = dry ]; then
            log 2 "$*"
        fi
    fi
}


function diff_func {
    echo "
diff $1 $2
========================================================= "
    if [ ! -f $1 ]; then
        echo "File $1 does not exist"
    elif [ ! -f $2 ]; then
        echo "File $2 does not exist"
    fi
    diff $1 $2 || true
    echo "


    "
}


# Ignore backup dir if this is just a diff
if [ "$strategy" = diff ] && [ -n "$backup_dir" ]; then
    log 1 "backup directory option is ignored when \"--diff\" option is set"
    backup_dir="" # probably makes no sense to backup when just comparing files
fi

# Create the backup dir
if [ -n "$backup_dir" ]; then
    log 2 "Creating backup directory $backup_dir"
    run_cmd mkdir -p "$backup_dir" || fatal "ERROR: Could not create backup directory $backup_dir"
fi

total_file_count=0
changed_file_count=0
# sync_file
#
# Contains all the logic to handle syncing a particular file based on the requested strategy.
#
# This is the only place in this script that can modify dotfiles.
#
# $1 is the file (realpath) of a real file or a repo file
function sync_file {

    # Get the filename pair
    real=${file/${sync_dir}/${HOME}}   # Real path
    repo=${real/${HOME}/${sync_dir}}   # Repo path

    log 3 "Real: $real   Repo: $repo"

    if [ ! -f "$real" ] && [ ! -f "$repo" ]; then
        fatal "ERROR: Missing file: \$1 $1 real file \"$real\" repo file \"$repo\""
    fi

    # Determine which file is source and which is the destination.
    src_file=""
    dst_file=""
    dst_dir=""  # Not set when changing links. It's used to check the directory exists
    if [ -L "$real" ]; then
        # Case: symbolic link, nothing to do unless we are forcing a different strategy
        log 3 Symbolic link $real to $repo
        if [ $force_strategy = force ] && [ ! $strategy = symbolic_link ]; then
            log 2 "Replacing symbolic link for \"$real\""
            src_file=$repo
            dst_file=$real
        fi
    elif [ "$real" -ef "$repo" ]; then
        # Case: hard link, nothing to do unless we are forcing a different strategy
        log 3 Hard link $real to $repo
        if [ $force_strategy = force ] && [ ! $strategy = hard_link ]; then
            log 2 "Replacing hard link for \"$real\""
            src_file=$repo
            dst_file=$real
        fi
    elif [ "$real" -nt "$repo" ] && ! cmp -s $real $repo; then
        # Case: files differ and the real file is newer (or repo file does not exist)
        log 3 $real is NEWER than $repo
        src_file=$real
        dst_file=$repo
    elif [ "$repo" -nt "$real" ] && ! cmp -s $real $repo; then
        # Case: files differ and the repo file is newer (or real file does not exist)
        log 3 $repo is NEWER than $real
        src_file=$repo
        dst_file=$real
        if [ -d "$backup_dir" ] && [ -f $real ]; then
            # make a backup
            # TODO maybe don't backup if it matches a previously checked in version.
            log 3 Backing up $real to $backup_dir
            run_cmd cp $real $backup_dir || fatal "ERROR: failed to make a backup of $real to $backup_dir"
        fi
    elif cmp -s "$real" "$repo" ; then
        log 2 Files are equivalent copies of each other
        if [ $force_strategy = force ] && [ ! $strategy = copy ]; then
            log 2 Forcing strategy  $strategy
            src_file=$repo
            dst_file=$real
        fi
    else
        log 1 "WARNING: Could not determine how to sync \"$1\""
        return 1
    fi

    log 1 ""

    total_file_count=$(( $total_file_count + 1))
    if [ -z "$src_file" ]; then
        log 2 "Nothing to do for $real"
    else
        dst_dir=$(dirname "$dst_file")
        changed_file_count=$(( $changed_file_count + 1))
        if [ ! -d "$dst_dir" ]; then
            log 2 Destination directory $dst_file $dst_dir does not exist, creating it
            run_cmd mkdir -p "$dst_dir" || fatal "ERROR: Could not create desination directory $dst_dir"
        fi
        # DOES NOT WORK FOR DIFF $sync_cmd $src_file $dst_file || fatal "Command $sync_cmd FAILED!"
        run_cmd $sync_cmd $src_file $dst_file
    fi

}



# Sync files either direction. Take the newer file as authoritative
repo_files=($(find home -type f -print0 | xargs -0 realpath))

for file in ${repo_files[@]} ${new_files[@]}; do
    set -u
    sync_file $file
done


log 1 "
$script_name finished
Total file count: $total_file_count
Different files: $changed_file_count
=====================================
"
exit 0

