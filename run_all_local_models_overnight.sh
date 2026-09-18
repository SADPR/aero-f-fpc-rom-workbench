#!/usr/bin/env bash
set -euo pipefail

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

echo "=== LOCAL ANN (PROM/HROM) ==="
cd "$REPO_ROOT/simulations/run.offline_local_ann.9999.01"
./clean_offline_local_ann_preprocessing_outputs.sh
bash run_pod_local_ann.sh
bash run_ann_trainer.sh
./clean_offline_local_ann_hyper_outputs.sh
bash run_hyper_local_ann.sh

cd "$REPO_ROOT"
./clean.hrom_local_ann.sh
bash preprocess.hrom_local_ann.sh

# Optional local PROM-ANN
#cd "$REPO_ROOT/simulations/run.rom_local_ann.9999"
#./clean_rom_local_ann_run_outputs.sh
#bash run_rom_local_ann.sh

cd "$REPO_ROOT/simulations/run.hrom_local_ann.9999.01"
./clean_hrom_local_ann_run_outputs.sh
bash run_hrom_local_ann.sh

cd "$REPO_ROOT/simulations/run.post_hrom_local_ann.9999.01"
./clean_post_hrom_local_ann_run_outputs.sh
bash run_post_hrom_local_ann.sh

cd "$REPO_ROOT"
"$PYTHON" simulations/plot_compare_postpro.py \
  --tag hprom_local_ann_vs_hdm \
  --reference HDM:simulations/run.fom/postpro \
  --model Local-HPROM-ANN:simulations/run.post_hrom_local_ann.9999.01/postpro

echo "=== LOCAL RBF (PROM/HROM) ==="
cd "$REPO_ROOT/simulations/run.offline_local_rbf.9999.01"
./clean_offline_local_rbf_preprocessing_outputs.sh
bash run_pod_local_rbf.sh
bash run_rbf_trainer.sh
./clean_offline_local_rbf_hyper_outputs.sh
bash run_hyper_local_rbf.sh

cd "$REPO_ROOT"
./clean.hrom_local_rbf.sh
bash preprocess.hrom_local_rbf.sh

# Optional local PROM-RBF
#cd "$REPO_ROOT/simulations/run.rom_local_rbf.9999"
#./clean_rom_local_rbf_run_outputs.sh
#bash run_rom_local_rbf.sh

cd "$REPO_ROOT/simulations/run.hrom_local_rbf.9999.01"
./clean_hrom_local_rbf_run_outputs.sh
bash run_hrom_local_rbf.sh

cd "$REPO_ROOT/simulations/run.post_hrom_local_rbf.9999.01"
./clean_post_hrom_local_rbf_run_outputs.sh
bash run_post_hrom_local_rbf.sh

cd "$REPO_ROOT"
"$PYTHON" simulations/plot_compare_postpro.py \
  --tag hprom_local_rbf_vs_hdm \
  --reference HDM:simulations/run.fom/postpro \
  --model Local-HPROM-RBF:simulations/run.post_hrom_local_rbf.9999.01/postpro

echo "=== LOCAL GPR (PROM/HROM) ==="
cd "$REPO_ROOT/simulations/run.offline_local_gp.9999.01"
./clean_offline_local_gp_preprocessing_outputs.sh
bash run_pod_local_gp.sh
bash run_gp_trainer.sh
./clean_offline_local_gp_hyper_outputs.sh
bash run_hyper_local_gp.sh

cd "$REPO_ROOT"
./clean.hrom_local_gp.sh
bash preprocess.hrom_local_gp.sh

# Optional local PROM-GPR
#cd "$REPO_ROOT/simulations/run.rom_local_gp.9999"
#./clean_rom_local_gp_run_outputs.sh
#bash run_rom_local_gp.sh

cd "$REPO_ROOT/simulations/run.hrom_local_gp.9999.01"
./clean_hrom_local_gp_run_outputs.sh
bash run_hrom_local_gp.sh

cd "$REPO_ROOT/simulations/run.post_hrom_local_gp.9999.01"
./clean_post_hrom_local_gp_run_outputs.sh
bash run_post_hrom_local_gp.sh

cd "$REPO_ROOT"
"$PYTHON" simulations/plot_compare_postpro.py \
  --tag hprom_local_gpr_vs_hdm \
  --reference HDM:simulations/run.fom/postpro \
  --model Local-HPROM-GPR:simulations/run.post_hrom_local_gp.9999.01/postpro

echo "=== ALL LOCAL RUNS COMPLETED ==="
