#!/usr/bin/env bash
# Runs the whole tutorial pipeline: FOM, then every ROM/HROM family, then the
# comparison plots. Each stage is logged separately and a failing family does
# not abort the rest, so one run reports the state of all of them.
#
# Assumes the mesh preprocessing (preprocess.sh) and the startup run have
# already been done, since those are shared by every family.
#
# Usage:  bash run_full_pipeline.sh [family ...]
#         with no arguments, runs every family.

set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

LOGDIR="$REPO_ROOT/pipeline_logs"
mkdir -p "$LOGDIR"
SUMMARY="$LOGDIR/summary.txt"

stage() {                       # stage <name> <workdir> <command...>
  local name="$1" wd="$2"; shift 2
  local log="$LOGDIR/${name}.log"
  printf '%-52s ' "$name"
  if ( cd "$REPO_ROOT/$wd" || exit 1
       # solver runs expect these to exist; only inside simulation dirs
       case "$wd" in simulations/*) mkdir -p log references results postpro ;; esac
       "$@" ) >"$log" 2>&1; then
    echo "OK"; echo "OK   $name" >>"$SUMMARY"; return 0
  else
    echo "FAIL  -> $log"; echo "FAIL $name" >>"$SUMMARY"; return 1
  fi
}

plot() {                        # plot <tag> <label> <postpro dir>
  local tag="$1" label="$2" dir="$3"
  printf '%-52s ' "plot:$tag"
  if ( cd "$REPO_ROOT" && "$PYTHON" simulations/plot_compare_postpro.py \
        --tag "$tag" --reference HDM:simulations/run.fom/postpro \
        --model "$label:$dir" ) >"$LOGDIR/plot_${tag}.log" 2>&1; then
    echo "OK"; echo "OK   plot:$tag" >>"$SUMMARY"
  else
    echo "FAIL  -> $LOGDIR/plot_${tag}.log"; echo "FAIL plot:$tag" >>"$SUMMARY"
  fi
}

# ---------------------------------------------------------------- FOM
fam_fom() {
  stage fom simulations/run.fom bash run_fom.sh
}

# ------------------------------------------------- linear (n=35 baseline)
fam_linear() {
  stage lin.pod       simulations/run.offline.9999.01   bash run_pod.sh    || return
  stage lin.hyper     simulations/run.offline.9999.01   bash run_hyper.sh  || return
  stage lin.presplit  .                                 bash preprocess.hrom.sh || return
  stage lin.hrom      simulations/run.hrom.9999.01      bash run_hrom.sh   || return
  stage lin.post      simulations/run.post_hrom.9999.01 bash run_post_hrom.sh || return
  plot hprom_35_vs_hdm HPROM-35 simulations/run.post_hrom.9999.01/postpro
}

# ------------------------------------------------------------ quadratic
fam_quad() {
  stage quad.pod      simulations/run.offline_quad.9999.01   bash run_pod_quad.sh   || return
  stage quad.hyper    simulations/run.offline_quad.9999.01   bash run_hyper_quad.sh || return
  stage quad.presplit .                                      bash preprocess.hrom_quad.sh || return
  stage quad.hrom     simulations/run.hrom_quad.9999.01      bash run_hrom_quad.sh  || return
  stage quad.post     simulations/run.post_hrom_quad.9999.01 bash run_post_hrom_quad.sh || return
  plot hprom_quad_vs_hdm HQPROM simulations/run.post_hrom_quad.9999.01/postpro
}

# --------------------------------------------------------- local linear
fam_local() {
  stage loc.pod       simulations/run.offline_local.9999.01   bash run_pod_local.sh   || return
  stage loc.hyper     simulations/run.offline_local.9999.01   bash run_hyper_local.sh || return
  stage loc.presplit  .                                       bash preprocess.hrom_local.sh || return
  stage loc.hrom      simulations/run.hrom_local.9999.01      bash run_hrom_local.sh  || return
  stage loc.post      simulations/run.post_hrom_local.9999.01 bash run_post_hrom_local.sh || return
  plot hprom_local_vs_hdm Local-HPROM simulations/run.post_hrom_local.9999.01/postpro
}

# ------------------------------------------------------ local quadratic
fam_local_quad() {
  stage locq.pod      simulations/run.offline_local_quad.9999.01   bash run_pod_local_quad.sh   || return
  stage locq.hyper    simulations/run.offline_local_quad.9999.01   bash run_hyper_local_quad.sh || return
  stage locq.presplit .                                            bash preprocess.hrom_local_quad.sh || return
  stage locq.hrom     simulations/run.hrom_local_quad.9999.01      bash run_hrom_local_quad.sh  || return
  stage locq.post     simulations/run.post_hrom_local_quad.9999.01 bash run_post_hrom_local_quad.sh || return
  plot hprom_local_quad_vs_hdm Local-HQPROM simulations/run.post_hrom_local_quad.9999.01/postpro
}

# ------------------------------------------------------------------ ANN
fam_ann() {
  stage ann.pod       simulations/run.offline_ann.9999.01   bash run_pod_ann.sh     || return
  stage ann.train     simulations/run.offline_ann.9999.01   bash run_ann_trainer.sh || return
  stage ann.hyper     simulations/run.offline_ann.9999.01   bash run_hyper_ann.sh   || return
  stage ann.presplit  .                                     bash preprocess.hrom_ann.sh || return
  stage ann.hrom      simulations/run.hrom_ann.9999.01      bash run_hrom_ann.sh    || return
  stage ann.post      simulations/run.post_hrom_ann.9999.01 bash run_post_hrom_ann.sh || return
  plot hprom_ann_5_vs_hdm HPROM-ANN-5 simulations/run.post_hrom_ann.9999.01/postpro
}

# ------------------------------------------------------------------ RBF
fam_rbf() {
  stage rbf.prepare   simulations/run.offline_rbf.9999.01   bash prepare_from_pod_base_rbf.sh || return
  stage rbf.train     simulations/run.offline_rbf.9999.01   bash run_rbf_trainer.sh || return
  stage rbf.hyper     simulations/run.offline_rbf.9999.01   bash run_hyper_rbf.sh   || return
  stage rbf.presplit  .                                     bash preprocess.hrom_rbf.sh || return
  stage rbf.hrom      simulations/run.hrom_rbf.9999.01      bash run_hrom_rbf.sh    || return
  stage rbf.post      simulations/run.post_hrom_rbf.9999.01 bash run_post_hrom_rbf.sh || return
  plot hprom_rbf_5_vs_hdm HPROM-RBF-5 simulations/run.post_hrom_rbf.9999.01/postpro
}

# ------------------------------------------------------------------ GPR
fam_gp() {
  stage gp.prepare    simulations/run.offline_gp.9999.01   bash prepare_from_pod_base_gp.sh || return
  stage gp.train      simulations/run.offline_gp.9999.01   bash run_gp_trainer.sh || return
  stage gp.hyper      simulations/run.offline_gp.9999.01   bash run_hyper_gp.sh   || return
  stage gp.presplit   .                                    bash preprocess.hrom_gp.sh || return
  stage gp.hrom       simulations/run.hrom_gp.9999.01      bash run_hrom_gp.sh    || return
  stage gp.post       simulations/run.post_hrom_gp.9999.01 bash run_post_hrom_gp.sh || return
  plot hprom_gpr_5_vs_hdm HPROM-GPR-5 simulations/run.post_hrom_gp.9999.01/postpro
}

# ------------------------------------------------------------ local ANN
fam_local_ann() {
  stage locann.pod      simulations/run.offline_local_ann.9999.01   bash run_pod_local_ann.sh || return
  stage locann.train    simulations/run.offline_local_ann.9999.01   bash run_ann_trainer.sh || return
  stage locann.hyper    simulations/run.offline_local_ann.9999.01   bash run_hyper_local_ann.sh || return
  stage locann.presplit .                                           bash preprocess.hrom_local_ann.sh || return
  stage locann.hrom     simulations/run.hrom_local_ann.9999.01      bash run_hrom_local_ann.sh || return
  stage locann.post     simulations/run.post_hrom_local_ann.9999.01 bash run_post_hrom_local_ann.sh || return
  plot hprom_local_ann_vs_hdm Local-HPROM-ANN simulations/run.post_hrom_local_ann.9999.01/postpro
}

# ------------------------------------------------------------ local RBF
fam_local_rbf() {
  stage locrbf.pod      simulations/run.offline_local_rbf.9999.01   bash run_pod_local_rbf.sh || return
  stage locrbf.train    simulations/run.offline_local_rbf.9999.01   bash run_rbf_trainer.sh || return
  stage locrbf.hyper    simulations/run.offline_local_rbf.9999.01   bash run_hyper_local_rbf.sh || return
  stage locrbf.presplit .                                           bash preprocess.hrom_local_rbf.sh || return
  stage locrbf.hrom     simulations/run.hrom_local_rbf.9999.01      bash run_hrom_local_rbf.sh || return
  stage locrbf.post     simulations/run.post_hrom_local_rbf.9999.01 bash run_post_hrom_local_rbf.sh || return
  plot hprom_local_rbf_vs_hdm Local-HPROM-RBF simulations/run.post_hrom_local_rbf.9999.01/postpro
}

# ------------------------------------------------------------ local GPR
fam_local_gp() {
  stage locgp.pod      simulations/run.offline_local_gp.9999.01   bash run_pod_local_gp.sh || return
  stage locgp.train    simulations/run.offline_local_gp.9999.01   bash run_gp_trainer.sh || return
  stage locgp.hyper    simulations/run.offline_local_gp.9999.01   bash run_hyper_local_gp.sh || return
  stage locgp.presplit .                                          bash preprocess.hrom_local_gp.sh || return
  stage locgp.hrom     simulations/run.hrom_local_gp.9999.01      bash run_hrom_local_gp.sh || return
  stage locgp.post     simulations/run.post_hrom_local_gp.9999.01 bash run_post_hrom_local_gp.sh || return
  plot hprom_local_gpr_vs_hdm Local-HPROM-GPR simulations/run.post_hrom_local_gp.9999.01/postpro
}

# ------------------------------------------------- linear n=10 comparator
fam_linear10() {
  stage l10.pod      simulations/run.offline.9999_10.01   bash run_pod.sh   || return
  stage l10.hyper    simulations/run.offline.9999_10.01   bash run_hyper.sh || return
  stage l10.presplit .                                    bash preprocess.hrom_10.sh || return
  stage l10.hrom     simulations/run.hrom.9999_10.01      bash run_hrom.sh  || return
  stage l10.post     simulations/run.post_hrom.9999_10.01 bash run_post_hrom.sh || return
  plot hprom_10_vs_hdm HPROM-10 simulations/run.post_hrom.9999_10.01/postpro
}

ALL=(fom linear linear10 quad local local_quad ann rbf gp local_ann local_rbf local_gp)
families=("${@:-${ALL[@]}}")

: >"$SUMMARY"
echo "pipeline started $(date -Is)" | tee -a "$SUMMARY"
for f in "${families[@]}"; do
  echo "--- family: $f ---" | tee -a "$SUMMARY"
  "fam_$f" || echo "family $f stopped early" | tee -a "$SUMMARY"
done
echo "pipeline finished $(date -Is)" | tee -a "$SUMMARY"
echo; echo "=== summary ==="; cat "$SUMMARY"
