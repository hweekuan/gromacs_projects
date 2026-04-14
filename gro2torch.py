"""
gro2torch.py - Convert GROMACS trajectory data to PyTorch tensors.

Author: HK
Date: 2026-04-10

This module reads GROMACS molecular dynamics output files (.gro topology
and .trr trajectory) and converts the position and momentum data into
PyTorch tensors suitable for downstream machine learning workflows.

Dependencies:
    - torch: For tensor conversion
    - MDAnalysis: For reading GROMACS trajectory formats
    - numpy: For intermediate array operations

Typical usage:
    1. Run a GROMACS MD simulation to produce .gro and .trr files.
    2. Call gro2torch(base_filename) where base_filename is the common
       prefix (e.g., 'test' will load 'test.gro' and 'test.trr').
    3. Returns (q, p) tensors with shape [n_frames, n_atoms, 3].
"""

import torch
import MDAnalysis as mda
import numpy as np
import os


def gro2torch(base_filename):
    """Convert GROMACS .gro/.trr files to PyTorch position and momentum tensors.

    Reads a GROMACS topology file (.gro) and trajectory file (.trr) using
    MDAnalysis, extracts per-frame atomic positions and velocities, computes
    momenta (mass * velocity), and returns them as PyTorch tensors.

    Args:
        base_filename (str): Common prefix for the input files. The function
            will look for '<base_filename>.gro' and '<base_filename>.trr'.

    Returns:
        tuple[torch.Tensor, torch.Tensor]: A tuple (q, p) where:
            - q: Position tensor with shape [n_frames, n_atoms, 3]
            - p: Momentum tensor with shape [n_frames, n_atoms, 3],
                 computed as mass * velocity for each atom at each frame.

    Raises:
        AssertionError: If either the .gro or .trr file does not exist,
            or if a trajectory frame lacks velocity data.
    """

    # Construct file paths from the base filename
    grofile = base_filename + '.gro'
    trrfile = base_filename + '.trr'

    # Validate that both input files exist before proceeding
    # NOTE: The .trr assertion message incorrectly says 'xtcfile' — see bug report
    assert os.path.isfile(grofile),'cannot read grofile'
    assert os.path.isfile(trrfile),'cannot read xtcfile'

    # Create an MDAnalysis Universe by combining topology (.gro) with
    # trajectory (.trr). The Universe object provides access to atoms,
    # coordinates, velocities, and other per-frame properties.
    u = mda.Universe(grofile,trrfile)

    n_frames = u.trajectory.n_frames
    n_atoms = len(u.atoms)

    print('n_frames',n_frames)
    print('n_atoms',n_atoms)

    # Pre-allocate numpy arrays for all frames.
    # Each array has shape (n_frames, n_atoms, 3) where 3 = x, y, z dimensions.
    # 'masses' is broadcast to (n_atoms, 3) per frame for element-wise momentum calc.
    positions  = np.zeros((n_frames, n_atoms, 3))
    velocities = np.zeros((n_frames, n_atoms, 3))
    momenta    = np.zeros((n_frames, n_atoms, 3))
    masses     = np.zeros((n_frames, n_atoms, 3))

    # Iterate through each trajectory frame (timestep) and extract data.
    # ts.frame gives the 0-based frame index for array indexing.
    for ts in u.trajectory:
        # Store atomic positions (in Angstroms by default in MDAnalysis)
        positions[ts.frame] = u.atoms.positions

        # Require velocity data — .trr files store velocities, .xtc files do not
        #if hasattr(u.atoms, 'velocities'):
        assert ts.has_velocities,'no velocity found'

        # Broadcast masses from shape (n_atoms,) to (n_atoms, 3) via np.newaxis
        # so that each spatial component is multiplied by the atom's mass
        masses[ts.frame] = u.atoms.masses[:,np.newaxis]
        velocities[ts.frame] = u.atoms.velocities

        # Compute momentum: p = m * v (element-wise multiplication)
        momenta[ts.frame] = masses[ts.frame]*velocities[ts.frame]

    # Convert numpy arrays to PyTorch tensors for ML pipelines.
    # Final tensor shapes: [n_frames, n_atoms, 3]
    #   q = generalized coordinates (positions)
    #   p = generalized momenta (mass * velocity)
    q = torch.from_numpy(positions)
    p = torch.from_numpy(momenta)

    return q,p


if __name__=='__main__':
    # Example usage: convert 'test.gro' + 'test.trr' to tensors
    # and print shapes and momentum values for verification
    basename = 'test'
    q,p = gro2torch(basename)

    print('q.shape',q.shape)
    print('p.shape',p.shape)
    print('p',p)
