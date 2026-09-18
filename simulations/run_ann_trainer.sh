#!/bin/bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/env.sh"

cd "$REPO_ROOT/simulations/run.offline_ann.9999.01"
bash run_ann_trainer.sh
