################################################################################
# Include for do-update.sh
        set -u
        fatal() {
            # Called when there is an unrecoverable error
            echo "FATAL: $*" >&2
            exit 1
        }

        case $strategy in
            copy) update_cmd="copy";;
            hard) update_cmd="ln -L";;
            symb) update_cmd="ln -s";;
            *) fatal "Invalid strategy \"$strategy\""
        esac

        if [ -n "${backup_dir}" ] && [ ! -d "${backup_dir}" ]; then
            mkdir -p "${backup_dir}" || fatal "Could not create backup dir"
        fi

        backup() {
            if [ -n "${backup_dir}" ]; then
                cp -n "$1" "${backup_dir}"
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
                    rm -f "$file"
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
                    delete "$dst" || echo >&2 "Failed to update \"$src\" to \"$dst\""; return 1
                    $update_cmd "$src" "$dst" || \
                        echo >&2 "Update command failed: $update_cmd \"$src\" to \"$dst\"" ; return 1
                else
                    echo >&2 "Not updating $dst. Source file hash has changed"
                    return 1 
                fi
            fi
            return 0
        }

        verify_git_branch() {
            orig_branch="$1"
            if [ ! "$orig_branch" = "$(git rev-parse --abbrev-ref HEAD)" ]; then
                git switch "$orig_branch" || fatal "Could not switch to git branch $orig_branch"
            fi

            # Abort if the git branch has changed since the script was generated.
            if git status --porcelain | grep "^.M" ; then
                echo "WARNING: git branch has modified content"
                git status
                echo "    How do you want to proceed ?"
                select action in abort commit ignore
                do
                    case $action in
                        abort)
                            fatal "Git branch has been modified since script was generated"
                            ;;
                        commit) 
                            echo "Starting sub-shell. Clean up repo and exit the shell"
                            bash -i
                            ;;
                        ignore)
                            echo "Ignoring repo. If any files have changed this script may fail"
                            ;;
                    esac
                done
            fi
        }

        verify_git_branch "$git_branch"

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
