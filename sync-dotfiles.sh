#!/bin/bash
#
#
script_name=$(realpath $0)
script_dir=$( dirname $script_name )
script_name=$( basename $script_name )

usage="
Usage: $script_name [--help]

Sync files/subdirectories) to \${HOME} directory.

"
debug=debug
debug=
function log {
    if [ "$debug" = debug ]; then
        echo "$*"
    fi
}

cd $script_dir

for src_dir in $(find home -type d); do
    dir_path=$( echo $src_dir | sed "s#.*home/#${HOME}/#" )
    log "Checking that $dir_path  exits"
    if [ -n "$dir_path" ] && [ ! -d $dir_path ]; then
        mkdir -p "$dir_path" from "$src_dir"
    else
        log "$dir_path already exists"
    fi
done


for src_file in $(find home -type f); do
    file=$( echo $src_file | sed "s#.*home/#${HOME}/#" )
    src_file=$(realpath $src_file)
    log "CMD: ln -f -n $src_file $file"
    ln -f -n "$src_file" "$file"
done

