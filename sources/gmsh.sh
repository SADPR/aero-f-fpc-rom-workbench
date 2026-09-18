#!/bin/bash

. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/env.sh"

# convert .msh to .top
/home/pavery/bin/gmsh2top domain

# convert .top to .exo
"$XP2EXO_EXECUTABLE" domain.top domain.exo
