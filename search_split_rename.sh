#!/bin/bash
#
# search_split_rename.sh - Standardize and split multi-model PDB files.
#
# Many PDB files from NMR experiments contain multiple models and may use
# non-standard residue labels (HETATM instead of ATOM, or non-standard
# 3-letter amino acid codes). This script:
#   1. Converts HETATM records to ATOM records
#   2. Replaces a user-specified residue name with a standard one
#   3. Splits multi-model PDB into individual single-model files
#   4. Renames output files with zero-padded model numbers (max 999 models)
#
# Usage:
#   ./search_split_rename.sh <input_file.pdb> <src_string> <target_string>
#
# Example:
#   ./search_split_rename.sh 2M7D.pdb "HIE" "HIS"
#   This replaces non-standard "HIE" (protonated histidine) with standard "HIS",
#   then splits into 2M7D001.pdb, 2M7D002.pdb, etc.
#
# Dependencies:
#   - pdb_splitmodel (from pdb-tools: pip install pdb-tools)
#
# Output: <basename>001.pdb, <basename>002.pdb, ... <basename>NNN.pdb
#

# Validate that exactly 3 arguments are provided
if [ $# -ne 3 ]; then
    echo "usage <search_split_rename.sh> <input file> <src string> <target string>"
    exit 0
fi

# ---- Step 1: Standardize residue records ----
# First pass: Convert all HETATM (heteroatom) records to ATOM records.
# HETATM is used for non-standard residues; converting to ATOM ensures
# GROMACS and other tools treat them as standard protein atoms.
# (Padded with spaces to maintain PDB column alignment: "ATOM  " = 6 chars)
cat $1 | sed s/HETATM/"ATOM  "/g > log_standard1.log

# Second pass: Replace the user-specified source string with the target string.
# This handles non-standard amino acid naming (e.g., HIE→HIS, CYX→CYS).
cat log_standard1.log | sed s/$2/$3/g > log_standard.log

# Clean up intermediate file
rm log_standard1.log

# ---- Step 2: Split multi-model PDB into individual files ----
# pdb_splitmodel reads MODEL/ENDMDL records and writes each model to a
# separate file named log_standard_<N>.pdb
pdb_splitmodel log_standard.log

# ---- Step 3: Rename split files with zero-padded model numbers ----
# Extract the base name from the input file (strip .pdb extension)
bn=`basename -s .pdb $1`

echo "basename is $bn"

# Iterate over all split model files and rename them
for file in log_standard_*.pdb; do
    echo $file
    # Extract the model number from the filename (e.g., "log_standard_1.pdb" → "1")
    num=$(echo "$file" | grep -oE '_([0-9]+)\.pdb$' | grep -oE '[0-9]+')
    echo "num is $num"
    # Zero-pad to 3 digits and construct new filename (e.g., "trpcage001.pdb")
    new_name=$(printf "%s%03d.pdb" "$bn" "$num")
    echo $new_name
    mv $file $new_name
done


