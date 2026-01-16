#!/bin/bash

# Set some normalized paths
script_name=$(realpath "$0")
script_dir=$(dirname "$script_name")
script_name=$(basename "$script_name")
dotfile_path=$( realpath ${script_dir}/.. )  # Full path used with the --add option 
backup_dir="${script_dir}/backup"

out_script="${script_dir}/_update.sh"

# Make sure we are in dotfiles directory
cd -P ${script_dir}/home

set -u

usage="

Usage: $script_name [--help|-h] [OPTIONS] [FILE ...] [DIRECTORY ...]

This script synchronizes \"dotfiles\" that are found in ${script_dir}/home. It
can synchronize both ways. If a dotfile in the home directory is newer than the
corresponding one in the dotfiles/home directory, it is assumed that that file
is correct. It will copy this file to the dotfile repo.

If you can not trust timestamps, you can specify --repo which will force this
script to assume the files in the repo are correct and will replace those that
differ in the home directory. Likewise, if --home is specified, it will updated
repo files to match those in the home directory.

Different \"strategies\" can be used. Home directory files can be, symbolic
links, hard links or copies of those in the dotfile repo.

The files to consider for \"syncing\" i.e. \"updating\" are either specified on
the command line. File names or directory names can be specified. Only base
names need to be specified. All files under a specified directory are synced.

If it ever happens that more than one file (or directory) has the same base
name, all files (or directories) with that name will be synced.


ARGUMENTS:

    FILE ...        Files that are to be synced

    DIRECTORY ...   Files from these directories will be synced


OPTIONS:

    --script        Write out a script of actions to take  NOT IMPLEMENTED

    --status        Just show status

    --add PATH ...  All files listed after this are to be added to git control.
                    If the path is a file, it is added. If the PATH is a
                    directory all new files within that path are added.
                    If any of the files are already part of the dotfiles repo,
                    they are simply ignored (i.e. not an error).

    --help          Show this help end exit.

    --verbose       Verbose output. Use multiple times for increased verbosity.

    --dry-run       Dry run, show what would be done.

    --diff          Show the differences between files.

    --force         Force chosen strategy. Say a file is up to date as a hard
                    link with the repo, if --symbolic is chosen, remove the hard
                    link and replace it with a symbolic link

    --interactive   Confirm before making changes to a file.

    --backup-off    Do not backup modified (or deleted) real files.

Trust options:

    --repo          Trust repo version. Ignore timestamps.

    --home          Trust home version. Ignore timestamps.

Strategy options:

    --copy          Make copies of the files

    --hard          Make hard links.

    --symbolic      Make symbolic links.


EXAMPLES:

    # By default, create symbolic links to the git repo mirror for
    # any real files that are out of date. If the real file is newer
    # copy it to the repo and replace the real file with symbolic link
    $script_name

    # Create hard links for any out of date files
    $script_name --hard

    # Create hard links for any out of date files
    # Replace all other files with hard links to the repo if they are not already
    $script_name --hard --force

    # Don't do anything. Just show what would be done
    $script_name --dry-run

    # Don't change the any files, just show the differences
    $script_name --diff

    # Update config files for nvim and kitty and nothing else
    $script_name nvim kitty

"

#### TODO Need to deal with files removed from the dotfiles repo. what's the best way to keep track?

# Main script parameters
diff=no       # This is not a "diff" command
dryrun=no     # Not doing a dry run
force=no      # Don't modify files that are consistent but using a different strategy
script=no
strategy=symb # hard, copy
trust=time    # repo, home  Trust time stamps, repo version, or home version
verbose=0     # Verbosity level


fatal() {
    # Called when there is an unrecoverable error
    echo "FATAL:$*" >&2
    exit 1
}

message() {
    # message [VERBOSE_LEVEL] MESSAGE
    # A high VERBOSE_LEVEL means we need to be have a high verbosity for it to be displayed
    # message 0 message This message will always be displayed
    # message 4 uninteresting message will only be displayed if there is a high verbosity
    if [[ "$1" =~ ^[0-9]$ ]]; then
        level="$1"
        shift
    else
        level=1  # default level
    fi

    if [ "$level" -le "$verbose" ]; then
        echo "$*" >&2  # Must be stderr because it is used in functions where the message is captured
        if [ $script = yes ]; then
            echo "# $*" >> $out_script
        fi
    fi
}


message 3 Default strategy is to make symbolic links

# Create a list of files to add
files_to_add=()

# Files deleted from repo.
# We need this to know which files should be removed from the home directory.
# However, we also need a way to say, don't deleted files that were deleted
# from git that were only deleted because they were added in error. (Clear?) I
# added and committed .bash_history by mistake, then removed it from git so it
# shows up in the deleted list. For now it's hard coded here. If the list grows
# there will need to be a better way.
deleted_git_files="$( git log --pretty=format: --name-only --diff-filter=D . | sort -u | grep -v .bash_history )"

# This is used to collect files specified on the command line.
# It may contain duplicates so we'll carefully build a set
# of unique filenames from it after command line parsing is done.
temp_file_list=()

# Used to collect a list of names of files that have been deleted from git
# that may still exist in place
temp_deleted_list=()


# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        *-a*)    # Add files to dotfile repo
            shift
            if [ -z "$1" ]; then
                fatal "Must specify a valid file or directory to add"
            fi

            path=$( realpath "${HOME}/$1" )

            if [[ "${path}" == *"${dotfile_path}"* ]]; then
                fatal "Cannot add dotfiles files to dotfiles \"${path}\" is within \"${dotfile_path}\""
            elif [ -f "${path}" ]; then
                files_to_add+=( "${path}" )
            elif [ -d "${path}" ]; then
                IFS=$'\n' files_to_add+=( $( find "${path}" -type f ) )
            else
                fatal "Failed to add \"${path}\". It is not a regular file or directory."
            fi
            ;;

        *-b*)    # Turn off backups
            backup=no
            backup_dir=""
            ;;

        *-c*)
            strategy=copy
            message 3 "Setting strategy to copy links"
            ;;

        *-dr*)
            dryrun=yes
            ;;

        *-di*)
            strategy=diff
            message 2 "Will show diffs. No files will be updated."
            ;;

        *-d*)
            fatal "Ambiguous argument \"$1\" could be --dry-run or --diff"
            ;;

        *-ha*)    # use hard links
            strategy=hard
            message 3 "Setting strategy to hard links"
            ;;

        -h | --he*) # Help
            echo "$usage"; exit 0
            ;;

        *-ho*)   # Trust home files
            trust=home
            message 1 "Ignoring time stamps. Trusting home directory (real) version"
            ;;

        *-h*)    # Ambiguous
            fatal "Ambiguous argument \"$1\" could be --hard, --home or --help"
            ;;

        *-sc*)  # Script file
            script=yes
            rm -f "$out_script"
            message 3 "Setting strategy to symbolic links."
            ;;

        *-st*)  # Status
            status=yes
            message 3 "Setting strategy to symbolic links."
            ;;

        *-sy*)  # Symbolic
            strategy=symb
            message 3 "Setting strategy to symbolic links."
            ;;

        *-s*)
            fatal "Ambigous argument \"$1\" could be, --symbolic, --static, or --script"
            ;;

        *-r*)  # Assume repo file are good (ignore time stamps)
            trust=repo
            message 1 "Ignoring time stamps. Trusting repo version"
            ;;

        *-v*)
            verbose=$(($verbose + 1))
            message 2 "verbose level set to $verbose"
            ;;

        *)
            # This should be a file or directory to include in the update.
            # Add all files that match this name "$1" and all files that
            # are in directories that match "$1"
            # Its possible that more the one file or more than one directory
            # will match. All the files will be added.
            # At this point the working directory is ${script_dir}/home/
            # It's okay if files get specified twice. A list of unique files
            # will be created below

            # Add files that match $1
            num=${#temp_file_list[@]}  # Note the number of files before adding "$1"

            temp_file_list+=( $( find . -type f -name "$1" | sed 's#..##' ) )

            # Add files from directories that match "$1"
            # This code allows for more than one directory matching "$1", however,
            # that is not case when this is written
            dirs=( $( find . -type d -name "$1" ) )
            if [ -n "${dirs[0]}" ] ; then
                # Add all files from all the dirs found (probably only one!)
                temp_file_list+=( $( find "${dirs[@]}" -type f | sed 's#..##' || true ) )
                for dir in "${dirs[@]}"; do
                    # Add any files that appear in the deleted_files_list 
                    # for this $dir
                    temp_deleted_list+=( $(echo "$deleted_git_files" | grep "${dir}" )  )
                done
            fi

            # Check to see if something was actually added to the list
            # If not this is an error
            if (( "$num" == "${#temp_file_list[@]}" )) ; then
                fatal "Option $1 did not specify a file, directory or option $usage"
            fi
            ;;
    esac
    shift
done


if [ -n "${backup_dir}" ]; then
    mkdir -p "${backup_dir}"
fi

repo_files=()
delete_files=()

# Determine the list of files to update
if [ "${#temp_file_list[@]}" = 0 ]; then
    # This is the default. (Should it be?)
    # All repo files are candidates for updating.
    message 1 No files where specified. All repo files are considered.
    mapfile -t repo_files < <( find . -type f | sed 's#..##' )

    delete_files=( $deleted_git_files )
else
    message 3 Adding files to the update list
    # Only files specified on the command line are to be updated.
    # Create the repo_file list without any duplicate (temp_file_list may have some)
    for file in "${temp_file_list[@]}"; do
        found=0
        for repo_file in "${repo_files[@]}"; do
            if [ "$repo_file" = "$file" ]; then
                found=1
                message 3 $file specified again
                break
            fi
        done
        if [ $found = 0 ]; then
            message 3 Adding file \"$file\" to the list update to
            repo_files+=("$file")
        fi
    done
    message 3 Adding files to the delete list
    # Only files specified on the command line are to be updated.
    # Create the repo_file list without any duplicate (temp_file_list may have some)
    for file in "${temp_deleted_files[@]}"; do
        found=0
        for repo_file in "${delete_files[@]}"; do
            if [ "$repo_file" = "$file" ]; then
                found=1
                message 3 $file specified again
                break
            fi
        done
        if [ $found = 0 ]; then
            message 3 Adding file \"$file\" to the delete list
            delete_files+=("$file")
        fi
    done
fi


if (( $verbose > 2 )) ; then
    echo "File update list:" >&2
    for file in "${repo_files[@]}" ; do
        echo "    \"$file\"" >&2
    done
    if [ "${#files_to_add[@]}" != 0 ]; then
        echo "File add list:" >&2
        for file in "${files_to_add[@]}"; do
            echo "    \"$file\"" >&2
        done
    fi
    if [ "${#delete_files[@]}" != 0 ]; then
        echo "File delete list: " >&2
        for file in "${delete_files[@]}"; do
            echo "    \"$file\"" >&2
        done
    fi
fi


# Define wrapper functions for rm, cp, mv, ln and diff
# When doing a dry run, we can just echo the command instead of running it.

do_cmd() {
    if [ $script = yes ]; then
        local args=("$@")
        args[-1]="\"${args[-1]}\""
        if [ $# -gt 2 ]; then
            args[-2]="\"${args[-2]}\""   # rm command only has one file argument
        fi
        echo "${args[@]}" >> "$out_script"
    elif [ $dryrun = yes ]; then
        echo "    ==> $@"
    elif [ $status=no ]; then
        command "$@"
    fi
    # if status=yes do nothing here!
}

rm() {
    do_cmd rm "$@"
}

cp() {
    do_cmd cp "$@"
}

ln() {
    do_cmd ln "$@"
}

diff() {
    do_cmd diff "$@"
}

mv() {   # not actually used but just in case it get added in
    if [ $dryrun = no ]; then
        command mv "$@"
    elif [ $script = yes ]; then
        echo rm "$@" >> "$out_script"
    else
        echo "  ==>  " mv "$@"
    fi
}


# Given the "repo" file, return path of the equivalent "real" file
real_from_repo() {
    echo "${HOME}/$1"
    # This function was more complicate that a trivial string concatenation in a previous version
}


# At the end of the script, report if any of the functions here modified the repository
repo_modified=no

# Get the file status
# Input repo filename
file_status() {
    local repo_file="$1"
    local real_file="$(real_from_repo "$repo_file")"
    local status=unknown

    if [ ! -f "$repo_file" ]; then
        ls -l
        fatal "Repo file: \"$repo_file\" does not exist in " $(pwd)
    fi

    message 3 "Checking file \"$repo_file\" status"
    # compare the files. The first find the cases where no update is needed
    if [ "${real_file}" -ef "${repo_file}" ]; then
        # real file is a hard link to repo
        status=hard
        needs_update=no
    elif [ -h "${real_file}" ]; then
        # real file is a symbolic link to the repo file
        status=symb
        needs_update=no
    elif cmp --silent "${repo_file}" "${real_file}" &>/dev/null; then
        # two independent files that are the same
        status=copy
        needs_update=no
    elif [ ! -f "${real_file}" ]; then
        # The real file is missing.
        status=missing
        needs_update=update_real
    elif [ $trust = time ] && [ "${real_file}" -nt "${repo_file}" ]; then
        # real file is newer (edited outside the repo)
        status=diff
        needs_update=update_repo
    elif [ $trust = time ] && [ "${repo_file}" -nt "${real_file}" ]; then
        # repo file is newer
        status=diff
        needs_update=update_real
    elif [ $trust = repo ] ; then
        # The files differ and we are trusting the repo version so
        # the real version needs updating.
        status=diff
        needs_update=udpate_real
    elif [ $trust = real ]; then
        # The files differ and we are trusting the real version so
        # the repo version needs updating.
        status=diff
        needs_update=update_repo
    else
        # I think the only way to get here is if trust ∉ {"time","real","repo"}
        fatal "Missed a test case for ${real_file} and ${repo_file},  trust = ${trust}"
    fi

    if [ $needs_update = update_real ] && [ -f "${real_file}" ]; then
        # Record hash and timestamp of the real file in
        # "previous" file.
        hash=( $(md5sum "${real_file}") )
        timeStamp="$( stat -c %y "${real_file}" | sed 'y/ :/_./' )"
        echo $timeStamp ${hash[0]} ${hash[1]}  >> "${script_dir}/previous"
        # Since we only want to backup real files that actually change contents
        # do it here. 
        if [ backup = yes ]; then
            cp "${real_file}" "${backup_dir}"
        fi
    fi

    if [ $needs_update = update_repo ] ; then
        if [ -n "$( git status -s "$repo_file")"  ]; then
        # Don't allow overwriting modified repo files
            fatal "Repo file \"$repo_file, needs to be committed first"
        fi
        message 3 "Repo will be modified"
        repo_modified=yes # Unless we error out first, the repo will have modifications
    fi

    # When "forcing" a strategy, files that don't otherwise need updating do
    # if they are current using a different strategy
    if [ "$needs_update" = no ] && [ "$force" = yes ] &&  [ $strategy != status ]; then
        message 3 "   Updating to change strategy"
        needs_update=update_real
    fi

    # Return the status information
    echo "${repo_file}" $needs_update ${status}
}

# Update the file
do_update() {
    src="$1"
    dst="$2"
    if [ ! -f "$src" ]; then
        fatal "Could not update $src to $dst!  File \"$src\" does not exist"
    fi

    if [ -f "$dst" ]; then
        message 3 $( md5sum $src $dst )
    else
        message 3 $( md5sum $src )
    fi

    if [ $diff = no ] && [ -f "$dst" ] ; then
        rm "$dst" || fatal "Could not remove destination file $dst"
    fi

    case $strategy in
        copy)
            cp "$src" "$dst"
            message 1 "cp $src $dst"
            ;;

        symb)
            ln -s "$src" "$dst"
            message 1 "ln -s $src $dst" # symbolic link"
            ;;

        hard)
            ln "$src" "$dst"
            message 1 "ln $src $dst  # hard link"
            ;;

        diff)
            echo
            echo "=========== $src $dst ============"
            diff "$src" "$dst"
            echo "-----------------------"
            echo
            ;;

        *)
            fatal "Unknown strategy \"$strategy\""
            ;;
    esac
}

success=yes

# Determine what files need to be updated
# NOTE: All of these arrays hold the repo path as the reference
real_updates=()  # Will hold a list of repo files that will be used to update real files
repo_updates=()  # Will hold a list of repo files that will be updated to match the real files
clean_files=()   # Holds files that are not changed
for repo_file in "${repo_files[@]}"; do
    if [ ! -f "${repo_file}" ]; then
        ls
        ls ./
        fatal "Repo file: \"$repo_file\" does not exist CWD: $(pwd)"
    fi
    stats=( $(file_status "${repo_file}") )
    message 4 "File: ${stats[0]}  Needs update: ${stats[1]}  File status: ${stats[2]}"
    case ${stats[1]} in
        update_real)
            real_updates+=("${repo_file}")
            message 3 Adding ${repo_file} to real file update list
            ;;
        update_repo)
            repo_updates+=("${repo_file}")
            message 2 Adding ${repo_file} to REPO update list
            ;;
        *)
            clean_files+=("${repo_file}")
            message 3 "${stats[0]} (${stats[2]}) is up to date"
            ;;
    esac
done

# set -x                                      ############### DEBUG
# trap read debug                             ############### DEBUG

if [ status = yes ]; then
    verbose = 1000
fi

## real --> repo
# Update repo files to match real files that are more up to date
# If the strategy is NOT copy, then add them to the real_updates list
# so an appropriate "strategy" (i.e. link) is used.
# (That is why repo files need to be updated first)
message 4 "Files being updated (real-->repo):"
for repo_file in "${repo_updates[@]}"; do
    real_file="$(real_from_repo "${repo_file}")"
    rm "${repo_file}"
    cp "${real_file}" "${repo_file}"
    message 3 "    ${real_file}  -->  ${repo_file}"
    if [ $strategy != copy ]; then
        real_updates+=("${repo_file}")
    fi
done

## repo --> real
# Update real files from repo
# This is sort of the main job of this script; update dotfiles from changes in the repo
message 4 "Files being updated (repo-->real):"
for repo_file in "${real_updates[@]}"; do
    real_file="$(real_from_repo "${repo_file}")"
    message 3 "    ${repo_file}  -->  ${real_file}"
    do_update "${repo_file}" "${real_file}"
done

## delete real file
message 1 "Files to delete:"
for repo_file in "${delete_files[@]}"; do
    real_file="$(real_from_repo "${repo_file}")"
    if [ -f "${real_file}" ]; then
        message 2 "    ${real_file}"
        rm "${real_file}"
    fi
done

## Show clean files! 
message 2 "Clean files:"
for repo_file in "${clean_files[@]}" ; do
    real_file="$(real_from_repo "${repo_file}")"
    message 2 "    ${real_file} is clean"
done

exit 0


