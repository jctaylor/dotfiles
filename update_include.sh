################################################################################
# Include for do-update.sh
        case $strategy in
            copy) udpate_cmd="copy";;
            hard) udpate_cmd="ln -L";;
            symb) update_cmd="ln -s";;
            *) fatal "Invalid strategy \"$strategy\""
        esac

        fatal() {
            # Called when there is an unrecoverable error
            echo "FATAL: $*" >&2
            exit 1
        }

        if [ -n "${backup_dir}" ] && [ ! -d "${backup_dir}" ]; then
            mkdir -p "${backup_dir}" || fatal "Could not create backup dir"
        fi

        backup() {
            if [ -n "${backup_dir}" ]; then
                cp "$1" "${backup_dir}"
            fi
        }

        delete() {
            file="$1"      # file to delete
            orig_hash="$2" # hash of file when script was generated (if no given this is no-op)

            if [ -f $file ] && [ -n "$orig_hash" ]; then
                curr_hash=($(md5sum $file) )
                if [ $curr_hash = $orig_hash ]; then
                    # It's okay to delete
                    backup "$file"
                    rm -f "$delete_file"
                else
                    echo >&2 "Not deleting \"$file\". Hash has changed"
                    return 1 
                fi
            fi
            return 0
        }

        update() {
            src="$1"
            dst="$2"
            orig_hash="$3" # hash of src when script was generated (if no given this is no-op)

            # Unlike delete, it is an error if the src does not exist
            if [ ! -f "$src" ]; then
                echo >&2 "Update failed. \"$file\" does not exist"
            fi

            if [ -n "$orig_hash" ]; then
                curr_hash=($(md5sum $src) )
                if [ $curr_hash = $orig_hash ]; then
                    # It's okay to update
                    backup "$dst"
                    $strategy "$src" "$dst" || \
                        echo >&2 "failed to update \"$src\" to \"$dst\""
                else
                    echo >&2 "Not updating $dst. Source file hash has changed"
                    return 1 
                fi
            fi
            return 0
        }

        verify_git_branch() {
            orig_branch="$1"
            git switch "$orig_branch" || fatal "Could not switch to git branch $orig_branch"

            # Abort if the git branch has changed since the script was generated.
            git status --porcelain | grep "^.M" || \
                fatal "Git branch has been modified since script was generated"
        }

        verfiy_git_branch

        # Called at the end of the generated script
        update_branch() {
            # Check the git branch to see if there have been any changes
            # since this script started. 
            if git status --porcelain | grep "^.M"; then
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
            else
                echo "git branch $git_branch clean"
            fi
        }

################################################################################
# Update actions ...
