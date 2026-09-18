#!/bin/bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/env.sh"

# Number of mesh subdomains; must match the decomposition used by preprocess.sh.
NS="${NS:-8}"

if [[ ! -x "$XP2EXO_EXECUTABLE" ]]; then
  echo "ERROR: Missing executable: $XP2EXO_EXECUTABLE"
  exit 1
fi

if [[ ! -d "$XP2EXO_COMPAT_LIB_DIR" ]]; then
  echo "ERROR: Missing library directory: $XP2EXO_COMPAT_LIB_DIR"
  exit 1
fi

export LD_LIBRARY_PATH="$XP2EXO_COMPAT_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

missing_libs="$(ldd "$XP2EXO_EXECUTABLE" 2>/dev/null | awk '/not found/{print $1}')"
if [[ -n "$missing_libs" ]]; then
  echo "ERROR: xp2exo shared libraries missing:"
  echo "$missing_libs"
  exit 1
fi

if [[ ! -f "../../sources/domain.top.dec.${NS}" ]]; then
  echo "ERROR: Missing decomposition file ../../sources/domain.top.dec.${NS}"
  echo "Use NS=<nsubdomains> to match preprocess.sh (currently expected 8)."
  exit 1
fi

for field in Pressure Velocity Vorticity; do
  if [[ ! -f "postpro/${field}.xpost" ]]; then
    echo "ERROR: Missing postpro/${field}.xpost. Run bash sower.sh first."
    exit 1
  fi
done

rm -f fluid_solution.exo fluid_solution.exo.*
"$XP2EXO_EXECUTABLE" ../../sources/domain.top fluid_solution.exo \
  "../../sources/domain.top.dec.${NS}" \
  postpro/Pressure.xpost postpro/Velocity.xpost postpro/Vorticity.xpost

if compgen -G "fluid_solution.exo*" > /dev/null; then
  ls -1 fluid_solution.exo*
  echo "Wrote Exodus output listed above."
else
  echo "ERROR: xp2exo completed but produced no fluid_solution.exo* output files."
  exit 1
fi
