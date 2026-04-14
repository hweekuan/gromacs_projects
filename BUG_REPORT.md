# Bug Report

Identified during code review on 2026-04-14.

---

## BUG-001: Typo in GROMACS path (`extract_trajectory.sh:19`)

**Severity:** Critical (script will fail)

**File:** `extract_trajectory.sh`, line 19

**Description:** The path `/usr/local/gramacs/bin/gmx` has a typo — `gramacs` should be `gromacs`.

**Current:**
```bash
/usr/local/gramacs/bin/gmx trjconv -f test.gro -s test.gro -o test.trr
```

**Expected:**
```bash
/usr/local/gromacs/bin/gmx trjconv -f test.gro -s test.gro -o test.trr
```

---

## BUG-002: Misleading assertion message in `gro2torch.py:27`

**Severity:** Low (cosmetic, does not affect logic)

**File:** `gro2torch.py`, line 27 (original)

**Description:** The assertion error message says `'cannot read xtcfile'` but the code is actually checking for a `.trr` file, not `.xtc`. This is likely a leftover from when the code used `.xtc` format.

**Current:**
```python
assert os.path.isfile(trrfile),'cannot read xtcfile'
```

**Expected:**
```python
assert os.path.isfile(trrfile),'cannot read trrfile'
```

---

## BUG-003: Stale comments reference `.xtc` format (`gro2torch.py:10-16`, original)

**Severity:** Low (documentation mismatch)

**File:** `gro2torch.py`, original lines 10-16

**Description:** The header comments describe converting `.gro` to `.xtc` and appending `.xtc` to the base filename, but the actual code uses `.trr` files throughout. The `.trr` format is correct here because it stores velocities (needed for momentum calculation), while `.xtc` does not.

---

## BUG-004: Energy minimization uses `ions.mdp` instead of dedicated `em.mdp` (`md_run.sh:18`)

**Severity:** Medium (may produce incorrect simulation results)

**File:** `md_run.sh`, line 18 (original)

**Description:** Step 5 (energy minimization) reuses `ions.mdp` as the parameter file:
```bash
/usr/local/gromacs/bin/gmx grompp -f ions.mdp -c trpcage001_ions.gro -p topol.top -o em.tpr
```
Typically, energy minimization requires its own `.mdp` file (e.g., `em.mdp`) with parameters like `integrator = steep`, `emtol`, `emstep`, and `nsteps` tuned for minimization. Using `ions.mdp` (which is normally a minimal preprocessing file) may lead to incorrect or suboptimal energy minimization.

---

## BUG-005: Missing interactive input for final `trjconv` (`extract_trajectory.sh:19`)

**Severity:** Medium (command may hang or fail)

**File:** `extract_trajectory.sh`, line 19 (original)

**Description:** The final `trjconv` command does not pipe any group selection input, unlike the previous `trjconv` call which uses a heredoc. `trjconv` typically prompts the user to select an output group interactively. Without piped input, this command will hang waiting for user input (or fail in non-interactive mode).

**Current:**
```bash
/usr/local/gramacs/bin/gmx trjconv -f test.gro -s test.gro -o test.trr
```

**Expected:** Should include a heredoc or `echo` to provide the group selection, e.g.:
```bash
/usr/local/gromacs/bin/gmx trjconv -f test.gro -s test.gro -o test.trr <<EOF
0
EOF
```

---

## BUG-006: Bash script has `.pdb` file extension (`probe_aa.pdb`)

**Severity:** Low (confusing but functional)

**File:** `probe_aa.pdb`

**Description:** This file is a bash script (starts with `#!/bin/bash`) but has a `.pdb` extension, which is the standard extension for Protein Data Bank structure files. This is confusing and may cause issues with file type detection, syntax highlighting, and discoverability.

**Recommendation:** Rename to `probe_aa.sh`.

---

## BUG-007: Hardcoded index group numbers (`extract_trajectory.sh`)

**Severity:** Medium (will fail on different systems)

**File:** `extract_trajectory.sh`, lines 8-11 and 14-16

**Description:** The index group numbers `1|13` (for combining protein + solvent) and `17` (for selecting the combined group in trjconv) are hardcoded. These indices depend on the specific system topology and will differ for other protein systems or when the number of atom groups changes. The existing comments acknowledge this risk but there is no validation or dynamic lookup.

**Recommendation:** Add a preliminary step that runs `gmx make_ndx` with `-f nvt0.gro` in dry-run mode, or document the expected group indices as a prerequisite check.

---

## BUG-008: Unquoted variables risk word splitting (`search_split_rename.sh`, `probe_aa.pdb`)

**Severity:** Low (fails on filenames with spaces)

**Files:** `search_split_rename.sh` (lines 15-16, 35), `probe_aa.pdb` (lines 18-20)

**Description:** Shell variables like `$1`, `$file`, etc. are not quoted. If a filename contains spaces or special characters, the script will break due to word splitting.

**Examples:**
```bash
# Current (unsafe):
cat $1 | sed s/HETATM/"ATOM  "/g > log_standard1.log
mv $file $new_name

# Safe:
cat "$1" | sed s/HETATM/"ATOM  "/g > log_standard1.log
mv "$file" "$new_name"
```
