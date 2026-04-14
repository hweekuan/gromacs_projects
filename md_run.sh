#!/bin/bash
#
# md_run.sh - Full molecular dynamics simulation pipeline for TRP-cage protein.
#
# This script automates a complete GROMACS MD simulation workflow starting from
# a raw PDB structure through energy minimization and NVT equilibration.
#
# Pipeline overview:
#   1. PDB → GROMACS topology (.gro + .top)
#   2. Define simulation box (dodecahedron)
#   3. Solvate with SPC/E water model
#   4. Neutralize system charge with counterions (Na+/Cl-)
#   5. Energy minimization (steepest descent)
#   6. NVT equilibration phase 0 (initial thermalization)
#   7. NVT equilibration phase 1 (production-ready equilibration)
#
# Prerequisites:
#   - GROMACS installed at /usr/local/gromacs/bin/
#   - Input files: trpcage001.pdb, ions.mdp, nvt0.mdp, nvt1.mdp
#   - The .mdp files define simulation parameters (timestep, temperature, etc.)
#
# Input:  trpcage001.pdb  (TRP-cage miniprotein, PDB ID: 2M7D)
# Output: nvt1.gro, nvt1.trr (final equilibrated structure and trajectory)
#

# ---- Step 1: Generate topology from PDB ----
# pdb2gmx converts PDB to GROMACS format, assigns force field parameters.
#   -ignh: Ignore hydrogen atoms in PDB (regenerate them based on force field)
#   -water spce: Use SPC/E water model
#   Interactive input "1" selects the force field (typically OPLS-AA or AMBER)
/usr/local/gromacs/bin/gmx pdb2gmx -ignh -f trpcage001.pdb -o trpcage001_processed.gro -water spce << EOF
1
EOF

# ---- Step 2: Define simulation box ----
# Create a rhombic dodecahedron box (more volume-efficient than cubic).
#   -c: Center the protein in the box
#   -d 1.0: Minimum 1.0 nm distance from protein to box edge
#   -bt dodecahedron: Box type — uses ~29% less volume than cubic
/usr/local/gromacs/bin/gmx editconf -f trpcage001_processed.gro -o trpcage001_newbox.gro -c -d 1.0 -bt dodecahedron

# ---- Step 3: Solvate the system ----
# Fill the box with pre-equilibrated SPC water molecules (spc216.gro).
# Also updates topol.top with the number of added water molecules.
/usr/local/gromacs/bin/gmx solvate -cp trpcage001_newbox.gro -cs spc216.gro -o trpcage001_solv.gro -p topol.top

# ---- Step 4: Add counterions to neutralize net charge ----
# First, preprocess to create a .tpr (portable run input) file.
# Then replace solvent molecules with Na+/Cl- ions to make the system charge-neutral.
#   -pname NA / -nname CL: Positive/negative ion names
#   -neutral: Add just enough ions to neutralize the system
#   Piping "SOL" tells genion to replace solvent molecules with ions.
/usr/local/gromacs/bin/gmx grompp -f ions.mdp -c trpcage001_solv.gro -p topol.top -o ions.tpr
echo "SOL" | /usr/local/gromacs/bin/gmx genion -s ions.tpr -o trpcage001_ions.gro -p topol.top -pname NA -nname CL -neutral

# ---- Step 5: Energy minimization ----
# Relax the system to remove steric clashes and bad contacts introduced
# by solvation and ion placement. Uses steepest descent algorithm.
# NOTE: This step reuses ions.mdp — see bug report for potential issue.
/usr/local/gromacs/bin/gmx grompp -f ions.mdp -c trpcage001_ions.gro -p topol.top -o em.tpr
/usr/local/gromacs/bin/gmx mdrun -v -deffnm em

# ---- Step 6: NVT equilibration phase 0 ----
# Initial thermalization at constant Number, Volume, Temperature.
# Uses nvt0.mdp parameters (shorter/gentler equilibration settings).
# Input: em.gro (energy-minimized structure)
/usr/local/gromacs/bin/gmx grompp -f nvt0.mdp -c em.gro -p topol.top -o nvt0.tpr
/usr/local/gromacs/bin/gmx mdrun -deffnm nvt0

# ---- Step 7: NVT equilibration phase 1 (production equilibration) ----
# Continued NVT equilibration with nvt1.mdp parameters (longer run, possibly
# different thermostat or coupling settings).
# Input: nvt0.gro (output of phase 0)
## (Repeat the grompp and mdrun steps for your specific .mdp files)
/usr/local/gromacs/bin/gmx grompp -f nvt1.mdp -c nvt0.gro -p topol.top -o nvt1.tpr
/usr/local/gromacs/bin/gmx mdrun -deffnm nvt1


