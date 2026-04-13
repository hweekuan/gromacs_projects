#!/bin/bash
# 1. Process the PDB file and generate a topology
/usr/local/gromacs/bin/gmx pdb2gmx -ignh -f trpcage001.pdb -o trpcage001_processed.gro -water spce << EOF
1
EOF

# 2. Define simulation box (dodecahedron for efficiency)
/usr/local/gromacs/bin/gmx editconf -f trpcage001_processed.gro -o trpcage001_newbox.gro -c -d 1.0 -bt dodecahedron

# 3. Solvate the system with water
/usr/local/gromacs/bin/gmx solvate -cp trpcage001_newbox.gro -cs spc216.gro -o trpcage001_solv.gro -p topol.top

# 4. Add ions to neutralize the system
/usr/local/gromacs/bin/gmx grompp -f ions.mdp -c trpcage001_solv.gro -p topol.top -o ions.tpr
echo "SOL" | /usr/local/gromacs/bin/gmx genion -s ions.tpr -o trpcage001_ions.gro -p topol.top -pname NA -nname CL -neutral

# 5. Energy Minimization
/usr/local/gromacs/bin/gmx grompp -f ions.mdp -c trpcage001_ions.gro -p topol.top -o em.tpr
/usr/local/gromacs/bin/gmx mdrun -v -deffnm em

# 5.1 generate nvt.tpr
/usr/local/gromacs/bin/gmx grompp -f nvt0.mdp -c em.gro -p topol.top -o nvt0.tpr
/usr/local/gromacs/bin/gmx mdrun -deffnm nvt0

## 6. NVT/NPT Equilibration and Production MD
## (Repeat the grompp and mdrun steps for your specific .mdp files)
/usr/local/gromacs/bin/gmx grompp -f nvt1.mdp -c nvt0.gro -p topol.top -o nvt1.tpr
/usr/local/gromacs/bin/gmx mdrun -deffnm nvt1


