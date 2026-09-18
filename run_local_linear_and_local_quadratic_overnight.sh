#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

echo "=== LOCAL LINEAR (PROM/HROM) ==="
cd "$REPO_ROOT/simulations/run.offline_local.9999.01"
./clean_offline_local_preprocessing_outputs.sh
bash run_pod_local.sh
./clean_offline_local_hyper_outputs.sh
bash run_hyper_local.sh

cd "$REPO_ROOT"
./clean.hrom_local.sh
bash preprocess.hrom_local.sh

# Optional local linear ROM
#cd "$REPO_ROOT/simulations/run.rom_local.9999"
#./clean_rom_local_run_outputs.sh
#bash run_rom_local.sh

cd "$REPO_ROOT/simulations/run.hrom_local.9999.01"
./clean_hrom_local_run_outputs.sh
bash run_hrom_local.sh

cd "$REPO_ROOT/simulations/run.post_hrom_local.9999.01"
./clean_post_hrom_local_run_outputs.sh
bash run_post_hrom_local.sh

cd "$REPO_ROOT"
"$PYTHON" simulations/plot_compare_postpro.py \
  --tag hprom_local_vs_hdm \
  --reference HDM:simulations/run.fom/postpro \
  --model Local-HPROM:simulations/run.post_hrom_local.9999.01/postpro

echo "=== LOCAL QUADRATIC (QPROM/HQPROM) ==="
cd "$REPO_ROOT/simulations/run.offline_local_quad.9999.01"
./clean_offline_local_quad_preprocessing_outputs.sh
bash run_pod_local_quad.sh
./clean_offline_local_quad_hyper_outputs.sh
bash run_hyper_local_quad.sh

cd "$REPO_ROOT"
./clean.hrom_local_quad.sh
bash preprocess.hrom_local_quad.sh

# Optional local quadratic ROM
#cd "$REPO_ROOT/simulations/run.rom_local_quad.9999"
#./clean_rom_local_quad_run_outputs.sh
#bash run_rom_local_quad.sh

cd "$REPO_ROOT/simulations/run.hrom_local_quad.9999.01"
./clean_hrom_local_quad_run_outputs.sh
bash run_hrom_local_quad.sh

cd "$REPO_ROOT/simulations/run.post_hrom_local_quad.9999.01"
./clean_post_hrom_local_quad_run_outputs.sh
bash run_post_hrom_local_quad.sh

cd "$REPO_ROOT"
"$PYTHON" simulations/plot_compare_postpro.py \
  --tag hprom_local_quad_vs_hdm \
  --reference HDM:simulations/run.fom/postpro \
  --model Local-HQPROM:simulations/run.post_hrom_local_quad.9999.01/postpro

echo "=== LOCAL LINEAR + LOCAL QUADRATIC COMPLETED ==="
