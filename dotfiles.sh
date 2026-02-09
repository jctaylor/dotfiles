#!/bin/bash

# Set some normalized paths
script_name=$( realpath "$0" )
script_dir="$( dirname "$script_name" )"          # e.g. /home/jason/dotfiles
script_name="$( basename "$script_name" )"        # e.g. dotfiles.sh
src_path="$( realpath "$script_dir"/home )"       # e.g. /home/jason/dotfiles/home
time_stamp="$(date +%Y-%m-%d_%H.%M.%S)"
backup_dir="${script_dir}/BACKUP/$time_stamp"
state_dir="${script_dir}/STATE"
managed_files_name="MANAGED_FILES.txt"

# This script will generate this next one which is a flat verbose script that 
# can be used to verify the actions are correct and tweaked if needed. 
update_script="${script_dir}/do_update.sh"

usage="

Usage: $script_name [--help|-h] COMMAND [OPTIONS] [FILE|DIR ...]

This script synchronizes \"dotfiles\" that are found in ${script_dir}/home. It
can synchronize both ways.

Different \"strategies\" can be used. Strategies are one of; symbolic links,
hard links or independent copies of the dotfile repo files.

This version of the script uses a state file (one for each git branch in the
dotfile repo) to determine which files need to be modified.

Not all files and directories are considered equal. 
There are config files and config directories.
config files are independent of each other.
config directories are treated as a unit. e.g. \$HOME/.config/nvim. 
If we make changes to nvim that include removing some files, the update script
should know to remove those files.
When updating a config directory, it will be made to reflect the dotfile repo
for that directory.

For several reasons, we would not want the same behaviour for individual dotfile
in the home directory. If a gitbranch does not include .bash_alias, we probably
don't want to delete on that is already there.

This script will try to determine if dotfile that have changed in HOME (but not
dotfiles) since the last update, should be sync to the dotfiles directory.

By default, this script does not modify any of the dotfiles. Instead it
generates a flat script $( basname "${update_script}" ) that can be run to make the updates.

Files that are in \$HOME (but not a sub-directory of \$HOME are 
It tries to be smart. If files are modified in the home directory after an
update, it will ask if those changes should be pulled into the git repo.

This is not fool proof. Hence the generate-an-update-script strategy.

ARGUMENTS:

    FILE | DIR ...  Limit the update to these files or directories. If not
                    specified, all files in the repo are considered.

OPTIONS:

    --help          Show this help end exit.

    --update        Make updates now. The default action without this is to make
                    a script that can be run to make the necessary changes.

    --add PATH ...  Use this to add new files or directories to the dotfiles repo.
                    PATH is either a file or directory in the HOME directory.

    --verbose       Increase the verbosity level of the output with each time
                    it is seen on the command line (i.e. it can be used multiple
                    times).

    --diff          Show the differences instead of creating an update.

    --force         Force chosen strategy. If this flag is specified, all files
                    that are using a strategy different from the current
                    strategy will be modified to match even if the files are
                    otherwise consistent.

    --interactive   Script will prompt for confirmation before each change.

    --no-backup     Don't make backup files. Normally, files in the HOME
                    directory modified (or deleted) real files.

STRATEGY OPTIONS:

    --copy          Make copies of the files

    --hard          Make hard links.
                    NB: This script is not smart enough to notice when the repo
                        is on a different file system).

    --symbolic      Make symbolic links (default).


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

    # Dont do anything. Just show what would be done
    $script_name --dry-run

    # Don't change the any files, just show the differences
    $script_name --diff

    # Update config files for nvim and kitty and nothing else
    $script_name nvim kitty

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
    # need to get rid of mapfile and maybe some array stuff
fi


# Main script parameters
diff="no"        # This is not a "diff"
force="no"       # Don't "force" strategy on consistent files
update="no"      # Create but don't run update script.
strategy="symb"  # hard, copy
trust="time"     # repo, home  Trust time stamps, repo version, or home version
verbose=0        # Verbosity level


# Verbosity sensitive level output
message() {
    # message [VERBOSE_LEVEL] MESSAGE
    level="$1"
    # A high VERBOSE_LEVEL means we need to be have a high $verbose value it to be displayed
    if [ "$level" -le "$verbose" ]; then
        echo "$*" >&2
    fi
}

### WORKING directory from here on out is ...

cd -P "${script_dir}"/home || \
    fatal  "This script assumes it is run from ${script_dir} and expects ${script_dir}/home to exist"

## Update managed files list file
## Look for new directories. If any are found, ask if they should be added as directories
## or as files within those directories
## can use some logic to ignore parent directories that already contain managed files or directories
## since ./home/.config is a parent of nvim, kitty, etc. it is ignored (or just marked as a parent)





# 1. Add any new subdirectories as managed subdirectories
# 2. Add any new files as managed files.
# To remove files 

## Load managed_files lists
managed_files=()
managed_dirs=()
delete_paths=()  # file or directories seen in MANAGED_FILES.txt but does not appear in repo
parent_dirs=()   # parent dirs can not be considered as managed dirs
while read -r line || [ -n "$line" ]; do
   echo "|${line}|"
   if [ -z "${line}" ] || [ "${line:0:1}" = "#" ]; then
       :
   else
       if [ -f "./home/$line" ] ; then
           managed_files+=( "${line}" )

       elif [ -d "./home/$line" ] ; then
           managed_dirs+=( "${line}" )
       else
           # Listed as managed but not seen in the repo
           delete_paths+=( "$line" )
       fi
       parent_dir+=( "$(basename "${line}" )" )
   fi
done < "${managed_files_name}"

## TODO Test managed_files to ensure none are listed in managed_dirs

## Parse command line
add_files=() # Files in HOME that should be included in the repo
requested_files=()
requested_dirs=()
# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in

        *-a*)    # Add files or directories to dotfiles repo
            shift
            if [ -z "$1" ]; then
                fatal "Must specify a valid file or directory to add"
            fi

            path=$( realpath "${HOME}/$1" )

            # Make sure we're not trying to add a file from the dotfiles repo
            if [[ "${path}" == *"${script_dir}"* ]]; then
                fatal "Cannot add dotfiles files to dotfiles \"${path}\" is within \"${script_dir}\""
            elif [ -f "${path}" ]; then
                add_files+=( "${path}" )
            elif [ -d "${path}" ]; then
                # Use mapfile to append to the existing array (-O offset index)
                mapfile -t -O "${#add_files[@]}" add_files < <( find "${path}" -type f )
            else
                fatal "Failed to add \"${path}\". It is not a regular file or directory."
            fi
            ;;

        *-n*)    # No backups (why?)
            backup_dir=""
            message 4 "No backups will be made"
            ;;

        *-c*)
            strategy="copy"
            message 3 "Setting strategy to copy links"
            ;;

        *-d*)    # Show diffs but don't otherwise modify anything
            strategy="diff"
            message 2 "Will show diffs. No files will be updated."
            ;;

        *-f*)     # Force all files to conform to the chosen strategy
            force="yes"
            ;;

        *-ha*)    # use hard link strategy
            strategy="hard"
            message 3 "Setting strategy to hard links"
            ;;

        -h|--he*) # Display help and exit
            echo "$usage"; exit 0
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
                requested_files+="$1"
            elif [ "$1" = bin ]; then
                # Short hand to add all files in ~/.local/bin
                requested_files+=( "$(find ./local/bin -type f)" )
            elif [ -f ".local/bin/$1" ]; then
                # A specific file in ~/.local/bin
                requested_files+=( ".local/bin/$1" )
            elif [ -d ".config/$1" ] ; then
                # A "config" dir in $HOME/.config (managed as a single unit)
                requested_dirs+=(".config/$1")
            elif [ -d "$1" ]; then
                # This is a "config" dir in $HOME (managed as a single unit)
                requested_dirs+=( "$1" )
            else
                fatal "Unknown option $1"
            fi
            ;;
    esac
    shift
done

mkdir -p "../STATE"

# Make sure this is run on a clean git branch

git_branch="$( git rev-parse --abbrev-ref HEAD || fatal "Failed to get git branch name")"
state_file="${state_dir}/$git_branch"

if git status --porcelain | grep "^.M" ; then
    message 2 "On branch $git_branch (clean)"
else
    # Go interactive
    message 0 "Git branch has un-committed files."
    git status >&2
    read -p "Commit modifications and proceed [y/N]? " yn
    case $yn in
        y*|Y*) #
            git add -u
            git commit
            git status
            ;;
        *)
            message 0 "Clean up git repo and try again"
            exit 0
    esac
fi


_set_file_record() {
    # Used by _write_script to set file_record[@] and also echo it to the update script
    file="$1"
    if [ -f "$file" ]; then
        file_record=( "[$(stat -c %z "$file" )]" $(md5sum "$file" | sed 's/ \+/ "/' | sed 's/$/"/') $2 )
        # also add a command to add the record to the state file
        echo "    echo \"$file_record\" > \$state_file"
    else 
        file_record=() # If the file does not exist the record is null
    fi
}

_write_script() {
    # Input global arrays:
    #       delete_files[@] -- array of files in the home directory that should
    #                          be removed in the new config
    #
    #       update_files[@] -- array of repo files that are used to update HOME
    #                          directory files
    #
    #       pull_files[@] ---- array of file in the HOME directory that are
    #                          used to update dotfiles repo
    #
    # Other input:
    #       backup_dir ---- Directory to save files that will get overwritten,
    #                       or empty string to indicate no backup. It is passed
    #                       the update script which uses it.
    #       strategy ------ copy, symb, or hard
    #
    # This is a private method only called by "write_script"
    # It will generate the flattened update script that can be inspected before running.
    # It is verbose by design.
    #
    # The output script relies on some convenience functions found in update_utils.sh
    #

    echo "# Created by $script_name $time_stamp"
    echo "# Run this script to update HOME files"
    echo "cd \"$src_dir\""
    echo "backup_dir=${backup_dir}"
    echo "strategy=$strategy"
    echo "git_branch=$git_branch"
    cat update_utils.sh  # include the utility functions directly in the update script
    echo "verify_git_branch"
    echo "verify_recent $(data +%Y%m%d%H%M) 10"  # make sure the script is no more than 10 minutes old
    echo


    echo "###### update actions follow ######"
    echo "#    DELETE"
    echo "# Delete files that should no longer be there:"
    for file in "$delete_files[@]"; do
        hfile="$(realpath "$HOME/$rfile")"
        _set_file_record "$hfile" REMOVE
        echo "  delete \"$hfile\" ${file_record[1]}"
    done

    echo
    echo '#    UPDATE'
    echo '#    dotfiles --> HOME'
    echo "# syntax: "
    echo "#         update REPO_PATH HOME_PATH REPO_HASH BACKUP_DIR"
    echo "# BACKUP_DIR may be an empty string"
    for rfile in "${update_files[@]}"; do
        hfile="$(realpath "$HOME/$rfile")"
        dfile="$(realpath "./$rfile")"
        _set_file_record "$dfile" UPDATE # This echos the record and set file_record
        echo "    update \"$dfile\" \"$hfile\" ${file_record[1]}"
    done

    echo
    echo '#    UPDATE'
    echo '#    HOME --> dotfiles'
    echo "# syntax: "
    echo "#         update  HOME_PATH REPO_PATH HOME_HASH BACKUP_DIR"
    echo "# BACKUP_DIR may be an empty string"
    for file in "$pull_files"; do
        hfile="$(realpath "$HOME/$rfile")"
        dfile="$(realpath "./$rfile")"
        _set_file_record "$hfile" UPDATE
        echo "    update \"$hfile\" \"$dfile\" ${file_record[1]}"
    done

    echo "   update_branch # Update git branch if needed"
}

write_script() {
    _write_script > "$out_script"
    message 1 "$out_script created"
}

if [ ! -f "${state_file}" ]; then
    # First time using these dotfiles with this git branch
    # This is the simplest case
    mkdir ../STATE || fatal "Failed to make STATE directory"
    mapfile -t update_list < <(find ../home -type f) # all files need to be updated
    delete_list=() # No files to delete ERROR
    pull_files=()  # Not pulling any HOME dir files into repo
    write_script
    message 0 "Run $(realpath $update_script) to complete the updates."
    message 0 "** You should verify the script first **"
    exit 0
fi







# Build a list of individual dotfiles to update
config_files=() # (".bashrc" ".profile" ... )

# Build a list of config dirs that are treated as whole unit configs.
# This is needed to figure out which files to delete
config_dirs=()  # ( ".config/nvim" ".config/kitty" ... )

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


