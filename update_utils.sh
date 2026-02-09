# Functions that are included in the generated update.sh script
#
#

script_name=$( realpath "$0" )
script_dir="$( dirname "$script_name" )"
script_name="$( basename "$script_name" )"
src_path="$( realpath "$script_dir"/home )"
dotfile_path=$( realpath "${script_dir}"/.. )  # Full path used with the --add option
time_stamp="$(date +%Y-%m-%d_%H.%M.%S)"


fatal() {
    # Called when there is an unrecoverable error
    echo "FATAL: $*" >&2
    exit 1
}

delete() {
    file="$1"      # file to delete
    orig_hash="$2" # hash of file when script was generated (if no given this is no-op)

    if [ -f $file ] && [ -n "$orig_hash" ]; then
        curr_hash=($(md5sum $file) )
        if [ $curr_hash = $orig_hash ]; then
            # It's okay to delete
            rm -f "$delete_file"
        else
            err_message="Won't delete. File hash is different from when script was created"
            return 1 
        fi
    fi
    return 0
}

move() {
    src="$1"      # file to move (it must exist)
    dst="$2"      # destination
    orig_hash="$3" # hash of src when script was generated (if no given this is no-op)

    # Unlike delete, it is an error if the src does not exist
    if [ ! -f "$src" ]; then
        err_message="move failed. File does not exist"
    fi

    if [ -n "$orig_hash" ]; then
        curr_hash=($(md5sum $src) )
        if [ $curr_hash = $orig_hash ]; then
            # It's okay to delete
            mv "$src" "$dst" || err_message "failed to move \"$src\" to \"$dst\""; return 1
        else
            err_message="Won't move. Source file hash has changed"
            return 1 
        fi
    fi
    return 0
}


case $strategy in
    copy) udpate_cmd="copy";;
    hard) udpate_cmd="ln -L";;
    symb) update_cmd="ln -s";;
    *) fatal "Invalid strategy \"$strategy\""
esac

update_home() {
    src="$1"
    dst="$2"
    orig_hash="$3"  # new file hash
    curr_hash=($(md5sum $src) )
    if [ $curr_hash = $orig_hash ]; then
        $update_cmd "$src" "$dst" || err_message "failed to update \"$src\" to \"$dst\""; return 1
    else
        err_message="Won't update. Source file hash has changed"
        return 1 
    fi
    return 0
}

update_repo() {
    src="$1"
    dst="$2"
    orig_hash="$3"  # new file hash
    curr_hash=($(md5sum $src) )
    if [ $curr_hash = $orig_hash ]; then
        if [ $strategy = symb ]; then
            # If a HOME file is added or modified we need a real
            # file in the repo and a link to it from the home directory
            mv "$src" "$dst"
            ln -s "$dst" "$src"
        else
            # Otherwise it i 
            $update_cmd "$src" "$dst" || err_message "failed to update \"$src\" to \"$dst\""; return 1
        fi
    else
        err_message="Won't update. Source file hash has changed"
        return 1 
    fi
    return 0
}

verify_git_branch() {
    orig_branch="$1"
    git switch "$orig_branch" || fatal "Could not switch to git branch $orig_branch"

    # Abort if the git branch has changed since the script was generated.
    git status --porcelain | grep "^.M" || fatal "Git branch has been modified since script was generated"
}

verfiy_recent() {
    generate_time="$1"
    max_age="$2"        # minutes after generate time
    current_time=$( date +%Y%m%d%H%M )  # YYYYMMDDHHmm
    if (( generate_time + max_age < current_time )); then
        fatal "This script is too old. Regenerate with dotfiles.sh"
    fi
}

add_new_file() {
    new_file="$1"
    file_hash="$2"
    [ -f "$new_file" ] || fatal "File does not exist"
    [ $file_hash = $cur_hash ] || fatal "File hash changed since this script was generated"


    if [ -f 

}

update_branch() {
    # Check the git branch to see if there have been any changes
    # since this script started. 
    if git status --porcelain | grep "^.M"; then
        echo "git branch $git_branch clean"
    else
        echo "Some files have been modified (pulled from HOME directory)"
        git status >2
        read -p "Commit modifications before exiting [y/N]? " yn
        case $yn in
            y*|Y*) #
                git add -u
                git commit
                ;;
            *)
                echo "Leaving git repo in modified state"
        esac
    fi
}

state_file="$script_dir/STATE/$git_branch"
