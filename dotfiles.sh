#!/bin/bash

# TODO:
#  [ ] Consolidate --script and --dry-run. Over time they became almost the same thing

############ DEBUG #######################
############ DEBUG #######################
set -u
############ DEBUG #######################
############ DEBUG #######################

# Set some normalized paths
script_name=$( realpath "$0" )
script_dir=$( dirname "$script_name" )
script_name=$( basename "$script_name" )
dotfile_path=$( realpath "${script_dir}"/.. )  # Full path used with the --add option
backup_dir="${script_dir}/backup"

out_script="${script_dir}/_update.sh"

## USAGE

usage="

Usage: $script_name [--help|-h] [OPTIONS] [FILE|DIR ...]

This script synchronizes \"dotfiles\" that are found in ${script_dir}/home. It
can synchronize both ways. By default, if a dotfile in the home directory is
newer than the corresponding one in the dotfiles/home directory, it is assumed
that that file is correct. It will copy this file to the dotfile repo.

Different \"strategies\" can be used. Home directory files can be, symbolic
links, hard links or copies of those in the dotfile repo.

If timestamps cannot be trusted, --repo can be specified to force this script
to assume the files in the repo are correct. Likewise, if --home is specified,
it will updated repo files to match those in the home directory.

The files to consider for \"syncing\" i.e. \"updating\" are either specified on
the command line. Each argument is a base name of a file or directory that
matches a:
    1. file or directory in \$HOME,
    2. file or directory \$HOME/.config,
    3. \$HOME/.local/bin, or
    4. a file in \$HOME/.local/bin

Directories in \$HOME and \$HOME/.config are considered as a complete unit.
This means, if files within the dotfile repo version of these directories are
deleted, they should also be deleted in the \$HOME directory version.

\$HOME/.local/bin is not a unit. Each file in \$HOME/.local/bin is it own
entity. Many (most?) files in \$HOME/.local/bin are there because of some
package that is installed outside of the dotfiles repo.

It could have been more general than this, but in practise we usually want to
treat things like \$HOME/.config/nvim as a single unit.

ARGUMENTS:

    FILE | DIR ...  These arguments are either a file in ~/, or a directory in
                    ~/.local
                    or DIR in ~/.config/DIR

OPTIONS:

    --update        Make updates now. Without this, a script will be generated
                    that can be run to make the changes.

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

    # Default strategy. A symbolic link will be created for any files in the
    # home directory that need to be updated.
    # New files in subdirectories that are managed (other than home), will be copied into
    # the dotfiles repo.
    $script_name

    # Hard link strategy. For files that need to be updated, use a hard link
    $script_name --hard

    # Force all managed files to be hard links to the repo files, even those
    # that do not otherwise need to be updated.
    # In other words, files that are copies or symbolic links that are
    # up-to-date, will be replaced with hard links.
    $script_name --hard --force

    # Don't do anything. Just show what would be done
    $script_name --dry-run

    # Don't change the any files, just show the differences
    $script_name --diff

    # Update config files for nvim and kitty and nothing else
    $script_name nvim kitty

    # This is an error, you can not specify a subdirectory of a directory in .config
    $script_name nvim/lua

"

fatal() {
    # Called when there is an unrecoverable error
    echo "FATAL: $*" >&2
    exit 1
}

# Test for prerequisites

if [ "${BASH_VERSINFO}" -lt 4 ]; then
    fatal "This $script_name script needs bash version 4.0 or greater"
    # TODO re-write to use 3.27.0+
fi


# Main script parameters
diff="no"        # This is not a "diff"
dryrun="no"      # This is not a "dry run"
force="no"       # Don't "force" strategy on consistent files
script="yes"      # Changes are live (not saved as a script).
strategy="symb"  # hard, copy
status="no"      # We are not just getting the status
trust="time"     # repo, home  Trust time stamps, repo version, or home version
verbose=0        # Verbosity level


# Verbosity sensitive level output
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
            echo "# $*" >> "$out_script"
        fi
    fi
}

# Working directory must be .../<dotfiles>/home
cd -P "${script_dir}"/home || \
    fatal  "This script assumes it is run from ${script_dir} and expects ${script_dir}/home to exist"


# Build a list of individual dotfiles to update
config_files=() # (".bashrc" ".profile" ... )

# Build a list of config dirs that are treated as whole unit configs.
# This is needed to figure out which files to delete
config_dirs=()  # ( ".config/nvim" ".config/kitty" ... )


# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in

        *-a*)    # Add files to dotfile repo. Used to add files that exist in HOME that should be added to the repo
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
                # Use mapfile to append to the existing array (-O offset index)
                mapfile -t -O "${#files_to_add[@]}" files_to_add < <( find "${path}" -type f )
            else
                fatal "Failed to add \"${path}\". It is not a regular file or directory."
            fi
            ;;

        *-b*)    # Turn off backups
            backup_dir=""
            message 4 "No backups will be made"
            ;;

        *-c*)
            strategy="copy"
            message 3 "Setting strategy to copy links"
            ;;

        *-dr*)
            dryrun="yes"
            ;;

        *-di*)    # Show diffs but don't otherwise modify anything
            strategy="diff"
            message 2 "Will show diffs. No files will be updated."
            ;;

        *-d*)
            fatal "Ambiguous argument \"$1\" could be --dry-run or --diff"
            ;;

        *-f*)     # Force all files to conform to the chosen strategy
            force="yes"
            ;;

        *-ha*)    # use hard link strategy
            strategy="hard"
            message 3 "Setting strategy to hard links"
            ;;

        -h | --he*) # Display help and exit
            echo "$usage"; exit 0
            ;;

        *-ho*)   # Trust home files as authoritative
            trust="home"
            message 1 "Ignoring time stamps. Trusting home directory (real) version"
            ;;

        *-h*)    # Ambiguous
            fatal "Ambiguous argument \"$1\" could be --hard, --home or --help"
            ;;

        *-st*)   # Just display the status of the managed files
            status="yes"
            message 3 "Setting strategy to symbolic links."
            ;;

        *-sy*)   # Use symbolic link strategy
            strategy="symb"
            message 3 "Setting strategy to symbolic links."
            ;;

        *-s*)    # Ambiguous
            fatal "Ambiguous argument \"$1\" could be, --symbolic, --static, or --script"
            ;;

        *-r*)    # Trust the repo files as authoritative
            trust="repo"
            message 1 "Ignoring time stamps. Trusting repo version"
            ;;

        *-u*)    # Update now (i.e. don't bother making a script
            script="no"
            message 2 "Changes will be made now (no script)"
            ;;

        *-v*)    # Increase verbosity each time this flag is seen
            verbose=$(( verbose + 1 ))
            message 3 "verbose level increased to $verbose"
            ;;

        *)      # Add config file or directory to a list
            if [ -f "./$1" ]; then
                # A config file in $HOME (e.g. .bashrc)
                config_files+="$1"
            elif [ "$1" = bin ]; then
                # Short hand to add all files in ~/.local/bin
                config_files+=( "$(find ./local/bin -type f)" )
            elif [ -f ".local/bin/$1" ]; then
                # A specific file in ~/.local/bin
                config_files+=( ".local/bin/$1" )
            elif [ -d ".config/$1" ] ; then
                # A "config" dir in $HOME/.config (managed as a single unit)
                config_dirs+=(".config/$1")
            elif [ -d "$1" ]; then
                # This is a "config" dir in $HOME (managed as a single unit)
                config_dirs+=( "$1" )
            else
                fatal "Unknown option $1"
            fi
            ;;
    esac
    shift
done

#### Use config_files and config_dirs lists to create update_files and delete_files lists ...

# If no files or directories were specified on the command line, assume all files and directories
# are to be updated. This is probably the most common case!
if [ "${#config_files}" = 0 ] && [ "${#config_dirs}" = 0 ] then
    message 2 "No files or directories were specified. Updating all dotfiles"

    mapfile -t config_files < <( find . ./.local/bin -maxdepth 1 -mindepth 1 -type f )

    mapfile -t config_dirs < <( find . .config -maxdepth 1 -mindepth 1 -type d )
fi

# Files in config_dirs will be added to config_files after determining which files from
# config_dirs need to be deleted.
#
# This uses some heuristics to determine what to delete. If files are missing
# from both HOME and dotfiles of the same config, and "trust" is not specified
# as either "home" or "repo", then we don't know what to do so we need to abort.
#
# It's based on the idea that "config" directories are "units". If FILE exists
# in the $HOME/config_dir but not in the repo, and we are "trusting" the repo,
# $HOME/config_dir/FILE should be deleted.
#
delete_files=()
for config_dir in "$config_dirs"; do
    # Keep track if we think we need to delete from both HOME and dotfiles repo.
    delete_from_home=no

    if [ ! $trust = home ]; then
        # We're trusting the repo or time stamps
        # So, assume any file in HOME that does not exist in dotfiles should be deleted
        message 2 "Looking for files in ${HOME}/$config_dir that don't exist in ${script_dir}/home/$config_dir"
        # Get a list of all the files in the corresponding $HOME config dir
        # converted to the equivalent local path in the repo
        mapfile -t file_list < <( find "${HOME}/$config_dir" -type f | sed "s#$HOME/##" )
        for file in "$file_list" ; do
            if [ ! -f "$file" ] ; then
                # Found a file in a config directory in HOME
                # that does not exist in the repo (at least not anymore).
                # This means it should not be there.
                delete_files+=( "${HOME}/${file}" ) # add a HOME file to the delete list
                delete_from_home=yes
                message 3 "Adding ${HOME}/${file} to the delete list. It no longer exists in ${script_dir}/home/${file}"
            fi
        done
    fi

    # This is the opposite case. Files that have been deleted from $HOME but not the repo
    if [ ! $trust = repo ]; then
        # We're trusting HOME or time stamps
        # So, assume any file in dotfiles that does not exist in HOME should be deleted
        message 2 "Looking for files in ${script_dir}/home/$config_dir that don't exist in ${HOME}/$config_dir"
        # Loop over the dotfiles and see if it exists in HOME
        mapfile -t file_list < <( find "$config_dir" -type f )
        for file in "$file_list" ; do
            if [ ! -f "${HOME}/$file" ] ; then
                # Found a file in the repo config directory that does not exist in HOME config dir
                # This means it should not be in the repo (since we are trusting home)
                # If we also found one in the HOME config dir, we're in trouble ABORT!
                delete_files+=( "${file}" )  # add a repo file to the delete list
                [ delete_from_home = yes ] && fatal "Files missing from both ${HOME}/$config_dir and ${script_dir}/home/$config_dir."
                message 3 "Adding ${script_dir}/home/${file} to the delete list. It no longer exists in ${HOME}/${file}"
            fi
        done
    fi
    # As we loop through config directories, we can add the individual files to the config_files list
    # Use mapfile to append to the existing array (-O offset index)
    mapfile -t -O "${#config_files[@]}" config_files <  <( find "$config_dir" -type f )
done

## At this point, we should have a delete_files list and an config_files list

# Create a list of files that might need to be updated
# either repo --> HOME, or HOME --> repo
# It's possible there are duplicates, so remove them here
message 3 "Creating unique update file list"
IFS=$'\n' update_files=( $(printf "%s\n" "${config_files[@]}" | sort -u ))

message 1 "${#update_files[@]} files to update"
message 3 "Files to update: $(print "    %s\n" "$update_files[@]" ) "

#### At this point, we should have 2 arrays: update_files and delete_files


# Define wrapper functions for rm, cp, mv, ln and diff to override the actual commands.
# This makes it easy for dry run and script runs
do_cmd() {
    if [ $script = yes ]; then
        # Should quote file names for the case where the path contains
        # legitimate white space (not tested)
        local args=("$@")
        args[-1]="\"${args[-1]}\""
        # If there are 2 or more arguments there are 2 file names
        if [ $# -gt 2 ]; then
            args[-2]="\"${args[-2]}\""   # rm command only has one file argument
        fi
        message 3 "script: ${args[*]}"
        echo "${args[@]}" >> "$out_script"
    elif [ $dryrun = yes ]; then
        echo "    $*"
    elif [ "${status}" = "no" ]; then
        # It's not a "script", "dry run" or "status" request
        # so run the actual command ...
        message 2 "Running $*"
        command "$@"
    else
        message 1 "Ignoring command: $*"
    fi
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

# NB the "mv" command is not used.
# Confirm by searching '/^ \+mv'  -or-  '/^[^#]*\<mv\>'
# If needed ...
#  mv() {   # not actually used but just in case it get added in
#      do_cmd mv "$@"
#  }

# Given a "repo" file, return the equivalent "real" file
# In this script, repo files are relative to the ${script_dir}/home but
# real files are full paths /home/$USER/...
real_from_repo() {
    echo "${HOME}/$1"
}


# At the end of the script, report if any of the functions here modified the repository
# This can happen if a "real" file is used to update the repo, or it is determined that
# a repo file needs to be deleted.
repo_modified=no


# Get the file status
# $1 = repo filename
file_status() {
    local repo_file
    local real_file
    local status

    repo_file="$1"
    real_file="$(real_from_repo "$repo_file")"
    status=unknown

    ### TODO Consider new files added to HOME config directories!!!
    if [ ! -f "$repo_file" ]; then
        ls -l
        fatal "Repo file: \"$repo_file\" does not exist in $(pwd)"
    fi

    message 3 "Checking file \"$repo_file\" status"
    # compare the files. The first find the cases where no update is needed
    if [ "${real_file}" -ef "${repo_file}" ]; then
        # real file is a hard link to repo file
        status="hard"
        needs_update="no"

    elif [ -h "${real_file}" ]; then
        # real file is a symbolic link to the repo file
        status="symb"
        needs_update="no"

    elif cmp --silent "${repo_file}" "${real_file}" &>/dev/null; then
        # two identical copies of the same file
        status="copy"
        needs_update="no"

    elif [ ! -f "${real_file}" ]; then
        # The real file was removed
        status="missing"
        needs_update="update_real" # since 

    elif [ $trust = time ] && [ "${real_file}" -nt "${repo_file}" ]; then
        # real file is newer (edited outside the repo)
        status="diff"
        needs_update="update_repo"

    elif [ $trust = time ] && [ "${repo_file}" -nt "${real_file}" ]; then
        # repo file is newer
        status="diff"
        needs_update="update_real"

    elif [ $trust = repo ] ; then
        # The files differ and we are trusting the repo version so
        # the real version needs updating.
        status="diff"
        needs_update="udpate_real"

    elif [ $trust = real ]; then
        # The files differ and we are trusting the real version so
        # the repo version needs updating.
        status="diff"
        needs_update="update_repo"
    else
        # I think the only way to get here is if trust ∉ {"time","real","repo"}
        fatal "Missed a test case for ${real_file} and ${repo_file},  trust = ${trust}"
    fi

    if [ "${needs_update}" = "update_real" ] && [ -f "${real_file}" ]; then
        # Record hash and timestamp of the real file in
        # "previous" file.
        mapfile -t hash < <( md5sum "${real_file}" )
        timeStamp="$( stat -c %y "${real_file}" | sed 'y/ :/_./' )"
        echo "${timeStamp} ${hash[0]} ${hash[1]}"  >> "${script_dir}/previous"
        # Since we only want to backup real files (not repo files) do it here if the backup option is 
        # chosen
        if [ -n "${backup_dir}" ]; then
            cp --parents "${real_file}" "${backup_dir}"
        fi
    fi

    if [ $needs_update = update_repo ] ; then
        if [ -n "$( git status -s "$repo_file")"  ]; then
            # Don't overwrite an uncommitted repo file
            fatal "Repo file \"$repo_file, needs to be committed first"
        fi
        message 3 "Repo will be modified"
        repo_modified=yes # Unless we error out first, the repo will have modifications
    fi

    # When "forcing" a strategy, files that would not otherwise need to updated but are using a different
    # strategy are marked as "update_real" so they will match the requested strategy
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
        message 3 "$( md5sum "${src}" "${dst}" )"
    else
        message 3 "$( md5sum "${src}" )"
    fi

    if [ "${diff}" = no ] && [ -f "$dst" ] ; then
        rm "$dst" || fatal "Could not remove destination file $dst"
    fi

    case "${strategy}" in
        copy)
            cp "$src" "$dst"
            ;;

        symb)
            ln -s "$src" "$dst"
            ;;

        hard)
            ln "$src" "$dst"
            ;;

        diff)
            message 0
            message 0 "=========== $src $dst ============"
            diff "$src" "$dst"
            message 0 "-----------------------"
            message 0
            ;;

        *)
            fatal "Unknown strategy \"$strategy\""
            ;;
    esac
}



# Determine what files need to be updated
# NOTE: All of these arrays hold the repo path as the reference
real_updates=()  # Will hold a list of repo files that will be used to update real files
repo_updates=()  # Will hold a list of repo files that will be updated to match the real files
clean_files=()   # Holds files that are not changed
for repo_file in "${update_files[@]}"; do
    if [ ! -f "${repo_file}" ] && [ ! -f "${HOME}/${repo_file}" ]; then
        fatal "File ${repo_file} does not exist in repo $pwd or HOME"
    fi
    read -r -a stats < <(file_status "${repo_file}")
    message 4 "File: ${stats[0]}  Needs update: ${stats[1]}  File status: ${stats[2]}"
    case ${stats[1]} in
        update_real)
            real_updates+=("${repo_file}")
            message 3 "Adding ${repo_file} to real file update list"
            ;;
        update_repo)
            repo_updates+=("${repo_file}")
            message 2 "Adding ${repo_file} to REPO update list"
            ;;
        *)
            clean_files+=("${repo_file}")
            message 3 "${stats[0]} (${stats[2]}) is up to date"
            ;;
    esac
done

# set -x                                      ############### DEBUG
# trap read debug                             ############### DEBUG

if [ "$status" = "yes" ]; then
    # An hacky way to force output of file status
    verbose=1000
fi


# Convert repo_files to full path
# NB Remember that repo_files are relative to ${script_dir}
repo_files=( "${repo_files[@]/#/${HOME}/}" )


#### NB Almost all destructive operations only occur below this line ################
# One exception is above in the command line argument parsing where the
#      rm -f "$out_script"
# To search for destructive commands use this...
#               /[^#]*\(\<rm\>\|\<mv\>\|do_update\)

## real --> repo
# Update repo files to match real files that are more up to date
# If the strategy is NOT copy, then add them to the real_updates list
# so an appropriate "strategy" (i.e. link) is used.
# (That is why repo files need to be updated first)
message 4 "Files being updated (real-->repo):"
for repo_file in "${repo_updates[@]}"; do
    real_file="$(real_from_repo "${repo_file}")"
    rm "${script_dir}/${repo_file}"
    cp "${real_file}" "${repo_file}"
    message 3 "    ${real_file}  -->  ${repo_file}"
    if [ $strategy != copy ]; then
        # NB repo_file is expected to be relative to ${script_dir}
        real_updates+=("${repo_file}")
    fi
done


## repo --> real
# Update real files from repo
# This is sort of the main job of this script; update dotfiles from changes in the repo
message 2 "Updating files (repo-->real):"
for repo_file in "${real_updates[@]}"; do
    real_file="$(real_from_repo "${repo_file}")"
    message 2 "    ${repo_file}  -->  ${real_file}"
    do_update "${repo_file}" "${real_file}"
done

## delete real file
message 1 "Deleting files:"
for repo_file in "${delete_files[@]}"; do
    real_file="$(real_from_repo "${repo_file}")"
    if [ -f "${real_file}" ]; then
        message 1 "    ${real_file}"
        rm "${real_file}"
    fi
done

## Show clean files!
message 2 "Clean files:"
for repo_file in "${clean_files[@]}" ; do
    real_file="$(real_from_repo "${repo_file}")"
    message 2 "    ${real_file} is clean"
done

if [ "${repo_modified}" = "yes" ]; then
    echo
    message 1 "dotfiles repository has been modified"
    if (( verbose > 1 )) ; then
        cd -P "${script_dir}" || \
            fatal "Could not change directory to ${script_dir}. Check dotfiles git status!"
        git status
    elif (( verbose == 1 )); then
        git status -s
    fi
fi

exit 0


