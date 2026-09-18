#!/bin/bash

. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/env.sh"

# Sower executable

# Postprocess fluid solution
$SOWER_EXECUTABLE -fluid -merge -con ../../data/OUTPUT.con -mesh ../../data/OUTPUT.msh \
	-result results/Pressure.bin -output postpro/Pressure

$SOWER_EXECUTABLE -fluid -merge -con ../../data/OUTPUT.con -mesh ../../data/OUTPUT.msh \
        -result results/Velocity.bin -output postpro/Velocity

$SOWER_EXECUTABLE -fluid -merge -con ../../data/OUTPUT.con -mesh ../../data/OUTPUT.msh \
        -result results/Vorticity.bin -output postpro/Vorticity
