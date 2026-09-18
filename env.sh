#!/usr/bin/env bash
# Central configuration for this workbench: tool locations and run defaults.
#
# Every preprocess/run/trainer script sources this file, so moving the
# workbench to another machine means editing only this file.
#
# Any value can be overridden per invocation by exporting it first:
#   AEROF=/path/to/aerof.opt NP=16 bash run_fom.sh
#
# Note: AEROF and PYTHON point outside the repository and are therefore
# machine-specific. The mesh/IO tools ship with the repository, so their
# defaults are repository-relative and need no editing.

: "${REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# AERO-F solver. Built from /home/sares/aero-f with
#   scripts/configure_torch_local.sh && cmake --build build_local -j$(nproc)
: "${AEROF:=/home/sares/aero-f/build_local/bin/aerof.opt}"

# Mesh partitioning and IO tools shipped with this repository.
: "${SOWER_EXECUTABLE:=$REPO_ROOT/sower}"
: "${PARTNMESH_EXECUTABLE:=$REPO_ROOT/partnmesh}"
: "${XP2EXO_EXECUTABLE:=$REPO_ROOT/xp2exo_bundle/xp2exo}"
: "${XP2EXO_COMPAT_LIB_DIR:=$REPO_ROOT/xp2exo_bundle/lib}"

# Python interpreter for the manifold trainers. Must provide torch,
# scikit-learn, matplotlib and tensorboard; the system python3 does not.
: "${PYTHON:=/home/sares/aero-f/.venv_torch_cpu/bin/python}"

# Default MPI rank count for online/offline solver runs.
: "${NP:=8}"

export REPO_ROOT AEROF SOWER_EXECUTABLE PARTNMESH_EXECUTABLE \
       XP2EXO_EXECUTABLE XP2EXO_COMPAT_LIB_DIR PYTHON NP
