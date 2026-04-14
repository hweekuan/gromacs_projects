#!/bin/bash
#
# extract_trajectory.sh - Extract and post-process MD trajectory data.
#
# This script takes the raw NVT equilibration output and produces cleaned
# trajectory files (test.gro, test.trr) suitable for conversion to PyTorch
# tensors via gro2torch.py.
#
# Pipeline:
#   1. Create a custom index group combining protein + solvent atoms
#   2. Apply periodic boundary condition (PBC) corrections to trajectory
#   3. Generate a .trr trajectory file for downstream tensor conversion
#
# Prerequisites:
#   - Completed MD simulation (nvt0.gro, nvt1.tpr, nvt1.trr must exist)
#   - GROMACS installed at /usr/local/gromacs/bin/
#
# Output: test.gro, test.trr (cleaned trajectory files)
#
# IMPORTANT: The index group numbers (1|13, 17) are system-specific and
#            must be verified by running `gmx make_ndx` interactively first.
#

# ---- Step 1: Create custom index group ----
# make_ndx creates an index file (index.ndx) with atom group definitions.
# "1|13" merges group 1 (Protein) with group 13 (Solvent) into a new combined
# group. These index numbers are system-dependent — verify with `gmx make_ndx`
# before running.
# Interactive inputs via heredoc:
#   Line 1: "1|13" = combine groups 1 and 13
#   Line 2: "q"    = quit and save index.ndx
/usr/local/gromacs/bin/gmx make_ndx -f nvt0.gro <<EOF
1|13
q
EOF

# ---- Step 2: Apply PBC corrections and extract trajectory ----
# trjconv fixes periodic boundary artifacts so molecules aren't split across
# box boundaries.
#   -s nvt1.tpr: Reference structure for topology info
#   -f nvt1.trr: Input trajectory with raw coordinates
#   -pbc whole: Make broken molecules whole across PBC boundaries
#   -n index.ndx: Use custom index file from step 1
# Interactive input "17" selects the combined protein+solvent group.
# WARNING: Group index 17 is hardcoded — may differ for other systems.
/usr/local/gromacs/bin/gmx trjconv -s nvt1.tpr -f nvt1.trr -pbc whole -n index.ndx -o test.gro <<EOF
17
EOF

# ---- Step 3: Generate .trr trajectory for gro2torch.py ----
# Convert the cleaned .gro trajectory to .trr format which preserves
# velocities — required by gro2torch.py for momentum calculation.
# NOTE: Path has a typo ("gramacs" instead of "gromacs") — see bug report.
/usr/local/gramacs/bin/gmx trjconv -f test.gro -s test.gro -o test.trr
