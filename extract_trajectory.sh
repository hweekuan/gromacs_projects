#!/bin/bash

# first line, is command
# second line is to group protein and solvent into one group, must check index,
# for this file it is "1|13", need to run gmx make_ndx to check
# 3rd line is quit
# last line EOF
/usr/local/gromacs/bin/gmx make_ndx -f nvt0.gro <<EOF
1|13
q
EOF

# second line, '17' may not work for all cases, need to be careful
/usr/local/gromacs/bin/gmx trjconv -s nvt1.tpr -f nvt1.trr -pbc whole -n index.ndx -o test.gro <<EOF
17
EOF

# make trajectory xtc file for use in converting .gro to torch tensor downstream
/usr/local/gramacs/bin/gmx trjconv -f test.gro -s test.gro -o test.trr
