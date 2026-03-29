################################################################################
# Include for do-update.sh
        fatal() {
            # Called when there is an unrecoverable error
            echo "FATAL: $*"
            exit 1
        }

        update_cmd() {
	    echo "UPDATE COMMAND"
            case "$strategy" in
                copy)
                    cp "$@"
                    ;;
                hard)
                    ln "$@"
                    ;;
                symb)
                    ln -s "$@"
                    ;;
                *)
		    fatal "Invalid strategy \"$strategy\""
		    ;;
            esac
        return 0
        }

        if [ -n "${backup_dir}" ] && [ ! -d "${backup_dir}" ]; then
            mkdir -p "${backup_dir}" || fatal "Could not create backup dir"
        fi

        backup() {
            if [ -n "${backup_dir}" ] && [ -f "$1" ]; then
                cp --backup "$1" "${backup_dir}" || fatal "Could not backup $1 to $backup_dir"
            fi
        }

        delete() {
            file="$1"      # file to delete
            orig_hash="$2"

            if [ -n "$orig_hash"  ]; then
                # If there was a hash given, make sure it has not changed
                curr_hash=( $(md5sum $file) )
                if [ ! "${curr_hash[0]}" = "$orig_hash" ]; then
                    echo >&2 "Not deleting \"$file\". Hash has changed"
                    return 1
                fi
            fi

            backup "$file"
            rm -f "$file"

            return 0
        }

        update() {
            src="$1"
            dst="$2"

            # Unlike delete, it is an error if the src does not exist
            if [ ! -f "$src" ]; then
                echo >&2 "Update failed. \"$file\" does not exist"
            fi

            if [ -n "$3" ]; then
                # If there was a hash, makes sure the source hash has not changed
                curr_hash=( $(md5sum $src) )
                if [ ! "${curr_hash[0]}" = "$3" ]; then
                    echo >&2 "Not updating $dst. Source file hash has changed"
                    echo >&2 "current digest: $curr_hash  previous digest: $3"
                    return 1
                fi
            fi

            backup "$dst"
            delete "$dst" || echo >&2 "Failed to update \"$src\" to \"$dst\""
            update_cmd "$src" "$dst" || \
                echo >&2 "Update command failed \"$src\" to \"$dst\""

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
                git status
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
