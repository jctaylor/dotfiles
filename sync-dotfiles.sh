#!/bin/bash
#

usage="
Usage: $(basename $(realpath $0)) [--help]

Sync files/subdirectories) to \${HOME} directory.

"

for src_dir in $(find home -type d); do
    dir_path=$( echo $src_dir | sed "s#.*home/#${HOME}/#" )
    echo "create dir would be mkdir -p $dir_path"
done

for src_file in $(find home -type f); do
    file=$( sed "s#.*home/#{${HOME}/#" )
    echo "CMD: ln -f -n --backup=numbered $src_file $file"
done

