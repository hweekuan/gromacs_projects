#!/bin/bash

# replace non-standard amino acids with standard amino acids
# then split the multi-model file into individual files with
# one model each. also rename the files with model ID for
# easier management of files. max 999 models.

# see script below on how to use this script
if [ $# -ne 3 ]; then
    echo "usage <search_split_rename.sh> <input file> <src string> <target string>"
    exit 0
fi

# replace strings to standardize amino acids
cat $1 | sed s/HETATM/"ATOM  "/g > log_standard1.log
cat log_standard1.log | sed s/$2/$3/g > log_standard.log

# remove unused file
rm log_standard1.log

pdb_splitmodel log_standard.log

bn=`basename -s .pdb $1`

echo "basename is $bn"

for file in log_standard_*.pdb; do
    echo $file
    # Extract the number from the filename (removes 'file' and '.jpg')
    num=$(echo "$file" | grep -oE '_([0-9]+)\.pdb$' | grep -oE '[0-9]+')
    echo "num is $num"
    # Pad to 3 digits and construct new name
    new_name=$(printf "%s%03d.pdb" "$bn" "$num")
    echo $new_name
    mv $file $new_name
done


