# HK 20260410

# class to convert .gro file from gromacs to
# torch tensors for trajectory of configurations

import torch
import MDAnalysis as mda
import numpy as np
import os

# function to convert .gro and .xtc files into
# torch tensors giving q and p with shape [ttpts,nparticles,dim]
# need to use gromacs to convert .gro file into .xtc file
# use this command
# gmx trjconv -f test.gro -o test.xtc
#
# input of function is a base_filename which will be
# appended with '.gro' and '.xtc'
#

def gro2torch(base_filename):

    grofile = base_filename + '.gro'
    trrfile = base_filename + '.trr'

    assert os.path.isfile(grofile),'cannot read grofile'
    assert os.path.isfile(trrfile),'cannot read xtcfile'

    # Load the multi-frame .gro file
    u = mda.Universe(grofile,trrfile)

    n_frames = u.trajectory.n_frames
    n_atoms = len(u.atoms)

    print('n_frames',n_frames)
    print('n_atoms',n_atoms)

    # Initialize arrays for position (x,y,z) and velocity (vx,vy,vz)
    positions  = np.zeros((n_frames, n_atoms, 3))
    velocities = np.zeros((n_frames, n_atoms, 3))
    momenta    = np.zeros((n_frames, n_atoms, 3))
    masses     = np.zeros((n_frames, n_atoms, 3))

    # Iterate through trajectory
    for ts in u.trajectory:
        positions[ts.frame] = u.atoms.positions
        #if hasattr(u.atoms, 'velocities'):
        assert ts.has_velocities,'no velocity found'
        masses[ts.frame] = u.atoms.masses[:,np.newaxis]
        velocities[ts.frame] = u.atoms.velocities
        momenta[ts.frame] = masses[ts.frame]*velocities[ts.frame]

    # 'positions' and 'velocities' now contain data over time

    # q.shape,p.shape = [ttpts,nparticles,dim]
    q = torch.from_numpy(positions)
    p = torch.from_numpy(momenta)

    return q,p


if __name__=='__main__':

    basename = 'test'
    q,p = gro2torch(basename)

    print('q.shape',q.shape)
    print('p.shape',p.shape)
    print('p',p)
