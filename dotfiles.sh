#!/bin/bash

set -u

# Set some normalized paths
script_name=$( realpath "$0" )
script_dir="$( dirname "$script_name" )"          # e.g. /home/jason/dotfiles
script_name="$( basename "$script_name" )"        # e.g. dotfiles.sh
src_path="$( realpath "$script_dir"/home )"       # e.g. /home/jason/dotfiles/home
time_stamp="$(date +%Y-%m-%d_%H.%M.%S)"
time_stamp_file="${script_dir}/TIMESTAMP"

backup_dir="${script_dir}/BACKUP/$time_stamp"
state_dir="${script_dir}/STATE"
manage_file="${state_dir}/MANAGED_FILES.txt"
update_include="${script_dir}/update_include.sh"    # Included in the do-update script

# This script will generate this next one which is a flat verbose script that
# can be used to verify the actions are correct and tweaked if needed.
update_script="${script_dir}/do-update.sh"


usage="

Usage: $script_name [--help|-h] COMMAND [OPTIONS] [FILE|DIR ...]

This script synchronizes \"dotfiles\" that are found in ${script_dir}/home. It
can synchronize both ways.

Concept and assumptions:

Because, I kept changing my mind, there are 3 \"strategies\" supported for  this
dotfile script:
    1. Symbolic links to dotfiles repo
    2. Hard links to repo
    3. Copies

Content is \"managed\" as either a file or directory. For example, .bashrc
is an independent file, whereas, ~/.config/nvim is managed as a directory.

NOTE: Currently,

    * files in \"\$HOME/\" or \"\$HOME/.local/bin/\" (but not subdirectories
    are managed as \"files\".  (e.g .bashrc, .bash_alias, etc.)

    * directories in \"\$HOME/.config/\" are managed as \"directories\"
    (e.g. .../.config/nvim .../.config/tmux)

This script may need some more sophisticated logic if that assumption is
no longer valid.

Because you might edit managed files directly in the HOME directory, this
script tries to provide *some* protection for inconsistencies between HOME
and \"../dotfiles/home\".

The script will complain if the git branch has modified files in it.

If files in HOME are newer than the TIMESTAMP file (updated each time the
script is called) the script will confirm before overwriting those files.

The updates are made indirectly. By default, this script generates a new script
verbose \"${update_script}\" that makes the actual changes. You can inspect and/or
tweak the \"${update_script}\" before running it.

By default, this script will update all files in the dotfiles repo. This can
be limited by specifying files and/or directories as arguments.

ARGUMENTS:

    FILE | DIR ...  Limit the update to these files or directories. If not
                    specified, all files in the repo are considered.

OPTIONS:

    --help          Show this help end exit.

    --update-now    Make updates now. The default action without this is to make
                    a script that can be run to make the necessary changes.

    --add PATH ...  Use this to add new files or directories to the dotfiles
                    repo. PATH is either a file or directory in the HOME
                    directory.

    --verbose       Increase the verbosity level of the output with each time
                    it is seen on the command line (i.e. it can be used multiple
                    times).

    TODO --diff          Show the differences instead of creating an update.

    --force         Force chosen strategy. If this flag is specified, all files
                    that are using a strategy different from the current
                    strategy will be modified to match even if the files are
                    otherwise consistent.

    --interactive   Script will prompt for confirmation before each change.

    --no-backup     Don't make backup files. Normally, files in the HOME
                    directory modified (or deleted) real files.

TIME STAMP OPTIONS:

    By default, if files in HOME are found to have been modified since the last
    time this script was run, the script will prompt for which action to take.

    --trust-time    Trust time stamps. Newer files in HOME will be pulled into
                    the repo. After running the update script, the repo will
                    have modified files.

    --trust-repo    Ignore time stamps and assume repo files are correct.


STRATEGY OPTIONS:

    --copy          Make copies of the files

    --hard          Make hard links.
                    NB: This script is not smart enough to notice when the repo
                        is on a different file system).

    --symbolic      Make symbolic links (default).


EXAMPLES:

    # Update all files
    $script_name

    # Hard link strategy. For files that need to be updated, use a hard link
    $script_name --hard

    # Force all managed files to be hard links to the repo files, even those
    # that do not otherwise need to be updated.
    # In other words, files that are copies or symbolic links that are
    # up-to-date, will be replaced with hard links.
    $script_name --hard --force

    # Only update .bashrc and kitty
    $script_name .bashrc kitty

"

# My abort function
fatal() {
    # Called when there is an unrecoverable error
    echo "FATAL: $*" >&2
    exit 1
}


# Verbosity sensitive level output
message() {
    # message MESSAGE_LEVEL MESSAGE
    local msg_level="$1"
    shift
    # A high VERBOSE_LEVEL means we need to be have a high $verbose value it to be displayed
    if [ "$msg_level" -le "$verbose" ]; then
        echo "$*" >&2
    fi
}


# Prerequisites
if [ "${BASH_VERSINFO}" -lt 4 ]; then
    fatal "This script \"$script_name\" requires bash version 4.0 or greater"
    # TODO  re-write to use 3.27.0+
    #       need to get rid of mapfile and maybe some array stuff
    # -or-
    #       Put some more tests here. What else do I rely on that might not be
    #       standard.
fi

################################################################################
####  Parse command line and set global parameters

# Main script parameters
diff="no"        # This is not a "diff"
force="no"       # Don't "force" strategy on consistent files
update="no"      # Don't automatically run the do-update script
strategy="hard"  # hard, copy
trust="neither"  # Prompt for inconsistencies
verbose=0        # Verbosity level

## Working directory is not changed yet to allow --add to pick up files
## specified relative to the CWD.
## After parsing command line arguments, the working directory is changed
## to .../home

add_files=() # Files in HOME (but not in dotfiles) that should be pulled into the repo
update_files=()
update_dirs=()
## Parse command line
##
while [ "$#" -gt 0 ]; do
    case "$1" in

        *-a*)    # Add files or directories to dotfiles repo
            shift
            if [ -z "$1" ]; then
                fatal "Must specify a valid file or directory to add"
            fi

            path=$( realpath "$1" )

            # Make sure we're not trying to add a file from the dotfiles repo
            ## FIXME This needs some work
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

        *-s*)   # Use symbolic link strategy
            strategy="symb"
            message 3 "Setting strategy to symbolic links."
            ;;

        *-u*)    # Update now (i.e. make the script and immediately run it)
            script="no"
            message 2 "Changes will be made now (no script)"
            ;;

        *-v*)    # Increase verbosity each time this flag is seen
            verbose=$(( verbose + 1 ))
            message 3 "verbose level increased to $verbose"
            ;;

        *)  # Specifying files or directories will limit the update to those
            # These paths should be specified relative to $HOME or ${script_dir}/home
            file="${1#${HOME}}"             # be forgiving
            file="${1#${script_dir}/home}"  # be very forgiving
            if [ -f "$file" ]; then
                # A config file in $HOME (e.g. .bashrc)
                # If this is a file inside a managed directory, an error will be caught later
                update_files+=( "$1" )
            elif [ -d "$file" ] ; then
                # A "config" dir (e.g. .config/tmux
                update_dirs+=("$file")
            else
                # Wasn't a file or directory in the repo
                fatal "Unknown path or option $1"
            fi
            ;;
    esac
    shift
done

## WORKING directory from here on out is .../${script_dir}/home
##
cd -P "${script_dir}"/home || fatal  "This script assumes it is run from ${script_dir} and expects ${script_dir}/home to exist"

# Inspect git branch
# For now, we don't allow an update if there are modified files in the git branch
# TODO Could be smarter on only complain if any "update_files" or "update_dirs"
#      have modified files. i.e. could ignore out-of-date files if they are not
#      going to be updated anyway.
inspect_git_branch() {
    # Make sure this is run on a clean git branch

    git_branch="$( git rev-parse --abbrev-ref HEAD || fatal "Failed to get git branch name")"
    state_file="${state_dir}/$git_branch"

    if git status --porcelain | grep "^.M" ; then
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
    else
        message 2 "On branch $git_branch (clean)"
    fi
}

inspect_git_branch

# Get the complete list of managed files and directories.
#
# TODO This could be more rigorous. It is based on assumptions
#      that files in home/ and home/.local/bin are managed individually
#      and directories in home/.config are managed as directories.
#
allowed_files=()   # repo files treated individually
allowed_dirs=()    # repo directories treated as units
mapfile -t allowed_files < <( find . ./.local/bin -maxdepth 1 -mindepth 1 -type f )
mapfile -t allowed_dirs < <( find .config -maxdepth 1 -mindepth 1 -type d )

validate_request_files() {
    for file in "${request_files[@]}"; do
        allowed_file=false
        for allow_file in "${allowed_files[@]}"; do
            if [ "$file" = "$allow_file" ]; then
                allowed_file=true
                break
            fi
        done
        allowed_dir=false
        for allow_dir in "${allowed_dirs[@]}"; do
            if [ "$file" = "$allow_file" ]; then
                allowed_dir=true
                break
            fi
        done
        if [ $allowed_file = false ] && [ $allowed_dir = false ]; then
            fatal "Requested path $file is not a valid dotfile or dotfile dir"
        fi
    done
}

#FIXME Finish writing update_files list when file are specified on the command line

# If there were no files or directories specified on the command line, all repo
# files are to be updated.
if [ "${#update_files[@]}" = 0 ] && [ "${#update_dirs[@]}" = 0 ]; then
    update_files=( "${allowed_files[@]}" )
    update_dirs=( "${allowed_dirs[@]}" )
fi


# Get a list of files in the manged_dir directories that don't
# appear in the repo. These either need to be pulled into the repo
# or deleted, depending on time stamps (and trust variable)
#
# FIXME This is not smart enough to delete empty directories
# FIXME A better way to ignore tmp and cache directories
#

extra_dir_files=()
mapfile -t extra_dir_files < \
    <( comm -2 -3 2>/dev/null \
        <(find $( printf "${HOME}/%s " "${update_dirs[@]}" ) -type f | grep -v tpm/ | grep -v .mypy_cache | sort ) \
        <(find $( printf "%s " "${update_dirs[@]}" ) -type f | sed "s#^#${HOME}/#" | sort  ) \
    )

delete_files=()  # List of files that might need to be deleted
# add_files=()   # That are to be pulled into the repo. Some may have been added on the command line
if [ "${#extra_dir_files[@]}" -eq  0 ]; then
    message 1 "No extra files in managed directories"
else
    message 1 "There are extra files in managed directories"
    for hfile in "${extra_dir_files[@]}"; do
        # hfile are full path i.e. $HOME/...
        if [ ! -f "$time_stamp_file" ] || [ "$hfile" -nt "$time_stamp_file" ]; then
            if [ "$trust" = repo ]; then
                delete_files+=( "$hfile" )
                message 2 "Adding extraneous $hfile to the delete list (trust repo selected)"
            else
                # Add this hfile to the repo. It was created after the last
                # time this script was run.
                add_files+=( "$hfile" )
                message 2 "Adding extraneous $hfile to the repo (newer than time stamp}"
            fi
        else
            # The file is older than than time stamp file
            # (probably from a different git branch)
            delete_files+=( "$hfile" )
            message 2 "Adding extraneous $hfile to the delete list (probably from a different branch?)"
        fi
    done
fi
# Updating/creating the time stamp file here since this is near
# where it used.
date > "${time_stamp_file}"
echo "git branch: $git_branch" >> "${time_stamp_file}"

# Expand update_dirs and add the files into update_files. update_dirs is not needed anymore.
mapfile -t -O "${#update_files[@]}" update_files < <(find $( printf "%s " "${update_dirs[@]}" ) -type f | sort  )


## Sort udpate files into to_home (normal action), and to_repo (added and newer files)
to_repo=( "${add_files[@]}" )    # Full path $HOME/...
to_home=()                       # Relative path
for rfile in "${update_files[@]}"; do
    hfile="${HOME}/$rfile"
    if [ ! -f "$hfile" ]; then
        # Doesn't exist in HOME
        to_home+=( "$rfile" )
    elif cmp "$rfile" "$hfile" >/dev/null 2>&1; then
        # Files match 
        if [ "$force" = yes ]; then
            # Although the file content is the same
            # we still need to see if it is using the correct strategy
            if [ "$rfile" -ef "$hfile" ] && [ ! "$strategy" = hard ]; then
                # The files have the same inode (hard links)
                to_home+=( "$rfile" )
            elif [ -L "$hfile" ] && [ ! "$strategy" = symb ]; then
                # The home file is a symbolic link
                to_home+=( "$rfile" )
            elif [ ! "$rfile" -ef "$hfile" ] && [ ! "$strategy" = copy ]; then
                # The hfile is not a hard link or a symbolic link to the repository
                # that means it must be a copy
                to_home+=( "$rfile" )
            fi
        fi
        message 3 "The files ${hfile} and ${script_dir}/home/$rfile are the same"
    else
        if [ "$trust" = repo ] ; then
            # Overrides time stamp and just trusts that the repo version is correct
            to_home+=( "$rfile" )
        elif [ "$trust" = home ] ; then
            # Overrides time stamp and just trusts that the home version is correct
            to_repo+=( "$hfile" )
        elif [ "$rfile" -nt "$hfile" ]; then
            # The repo file is newer and different than the one in the HOME dir
            # This is sort of the main purpose of this script
            to_home+=( "$rfile" )
        else
            # Home version of the file is newer, so move it to the repo
            to_repo+=( "$hfile" )  # Full path
        fi
    fi
done

_set_file_record() {
    # Sets global file_record[@]
    #
    # file_record[0] = modify time
    # file_record[1] = md5 hash
    # file_record[2] = file name
    #
    # Written to the update script so that it can verify the source files have not changed
    file="$1"
    if [ -f "$file" ]; then
        file_record=( "[$(stat -c %z "$file" )]" $(md5sum "$file" | sed 's/ \+/ "/' | sed 's/$/"/') $2 )
    else
        file_record=( "" "" "$file" ) # If the file does not exist the record is null
    fi
}

generate_update_script() {
    # Input global arrays:
    #       delete_files[@] - array of files in the home directory that should
    #                          be removed in the new config
    #
    #       to_home[@] ----- array of repo files (relative path) that are used
    #                          to update HOME directory files
    #
    #       to_repo[@] ----- array of files in the HOME directory that are newer
    #                           then the repo versions. These are full paths.
    #
    # Other input:
    #
    #       backup_dir ---- Directory to save files that will get overwritten,
    #                       or empty string to indicate no backup. It is passed
    #                       the update script which uses it.
    #       strategy ------ copy, symb, or hard
    #
    # It will generate a *somewhat* flattened update script.    #
    #
    #

    echo "#!/bin/bash"
    echo "#"
    echo "# Created by $script_name $time_stamp"
    echo "# Run this script to update HOME files"
    echo "#"
    echo "    cd \"$script_dir\" || exit 1"
    echo "    backup_dir=\"${backup_dir}\""
    echo "    strategy=$strategy"
    echo "    git_branch=$git_branch"
    cat ${update_include}               # Some predefined functions
    echo "#"
    echo "#    DELETE"
    for file in "${delete_files[@]}"; do
        _set_file_record "$file" REMOVE
        echo "delete \"$file\" ${file_record[1]}"
    done
    echo "#"
    echo '#    UPDATE  dotfiles --> HOME'
    echo "#"
    for rfile in "${to_home[@]}"; do
        hfile="$(realpath -m $HOME/$rfile)"  # -m canonicalize missing file
	sfile="$(realpath $rfile)"           # rfile must exist (its the source)
        dfile="$hfile"
        _set_file_record "$sfile" UPDATE # This echos the record and set file_record
        echo "update \"$sfile\" \"$dfile\" ${file_record[1]}"
    done
    echo "#"
    echo '#    UPDATE  HOME --> dotfiles'
    echo "#"
    for hfile in "${to_repo[@]}"; do
	sfile="$hfile"
        dfile="./${hfile#${HOME}/}"    # Works since repo files are relative
        _set_file_record "$sfile" UPDATE
        echo "update \"$sfile\" \"$dfile\" ${file_record[1]}"
    done
    echo "#"
    echo "#    CLEAN UP"
    echo "#"
    echo "find ${HOME}/.config -type d -empty -delete  # delete empty directories"
    echo "update_branch                             # Update git branch if needed"
    echo

}

rm -rf "${update_script}"
generate_update_script >  "${update_script}" && chmod +x "${update_script}"

exit $?

