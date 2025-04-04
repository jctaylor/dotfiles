#!/bin/bash

script_name=$(realpath $0)
script_dir=$( dirname $script_name )
script_name=$( basename $script_name )

usage="

Usage: $script_name [--help]

Sync files/subdirectories) to \${HOME} directory.

It tries to be smart about which file is athoritative.

Currently it is using hardlinks for the files.

"

if [ -n "$1" ]; then
    echo "$usage"
    exit 0
fi

debug=debug
#debug=
function log {
    if [ "$debug" = debug ]; then
        echo "$*"
    fi
}

cd "$script_dir"

# Find all the directories in ${script_dir}/home
for src_dir in $(find home -type d); do
    dir_path=$( echo $src_dir | sed "s#.*home/#${HOME}/#" )
    #log "Checking that $dir_path  exits"
    if [ -n "$dir_path" ] && [ ! -d $dir_path ]; then
        log "Making $dir_path"
        mkdir -p "$dir_path"
    else
        log "$dir_path already exists"
    fi
done


# Sync both ways. Take the newer file as correct
for src_file in $(find home -type f); do
    dst_file=$( echo $src_file | sed "s#.*home/#${HOME}/#" )
    src_file=$(realpath $src_file)
    if [ -f "$dst_file" ] && [ $dst_file -nt $src_file ]; then
        log "Repo file is newer than real file. Linking $src_file to $dst_file"
        ln -f -n  $dst_file $src_file  # Reverse copy:q
    elif [ $src_file -nt $dst_file ]; then
        log "Real file is newer than repo file. Linking $dst_file to $src_file"
        ln -f -n  $src_file $dst_file  # Reverse copy
    elif [ $src_file -ef $dst_file ]; then
        log "Same file $src_file $dst_file"
    else
        log "ERROR: check $src_file and $dst_file manualy"
    fi
done

exit 0

# TODO: find files in home that have been deleted from git repo
# The challenge is, we don't want to delete files in the home
# directory or .config, just because they don't exist in repo
#
#for src_dir in $(find home -maxdepth 1 -type d); do
#    dir_path=$( echo $src_dir | sed "s#.*home/#${HOME}/#" )
#    files=$(find ${dir_path) -type f})
#    for dst in $files; do
#        srd=$( echo "$dst" | sed 's/#')
#    
#done

