#!/usr/bin/env python3
"""Collect a Burgers-paper-style comparison table for every ROM family.

Reads what the pipeline already wrote -- the per-stage logs under
pipeline_logs/ and the error summaries under simulations/postpro_compare/ --
and reports, per family: the reduced dimension n, the number of ECSW sample
nodes, the online wall-clock time, the speedup over the HDM, and the relative
L2 errors in drag and lift.

No solver runs are needed; this only parses artifacts.

Usage: python3 simulations/summarize_runs.py [--logs pipeline_logs]
"""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# label, hyper log stem, hrom log stem, error tag, offline dir, primary dim
# (primary dim None = the whole retained basis is primary, i.e. no closure map)
FAMILIES = [
    ("HPROM-35",        "lin.hyper",    "lin.hrom",    "hprom_35_vs_hdm",         "run.offline.9999.01",            None),
    ("HPROM-10",        "l10.hyper",    "l10.hrom",    "hprom_10_vs_hdm",         "run.offline.9999_10.01",         None),
    ("HQPROM",          "quad.hyper",   "quad.hrom",   "hprom_quad_vs_hdm",       "run.offline_quad.9999.01",       None),
    ("HPROM-ANN-5",     "ann.hyper",    "ann.hrom",    "hprom_ann_5_vs_hdm",      "run.offline_ann.9999.01",        5),
    ("HPROM-RBF-5",     "rbf.hyper",    "rbf.hrom",    "hprom_rbf_5_vs_hdm",      "run.offline_rbf.9999.01",        5),
    ("HPROM-GPR-5",     "gp.hyper",     "gp.hrom",     "hprom_gpr_5_vs_hdm",      "run.offline_gp.9999.01",         5),
    ("Local-HPROM",     "loc.hyper",    "loc.hrom",    "hprom_local_vs_hdm",      "run.offline_local.9999.01",      None),
    ("Local-HQPROM",    "locq.hyper",   "locq.hrom",   "hprom_local_quad_vs_hdm", "run.offline_local_quad.9999.01", None),
    ("Local-HPROM-ANN", "locann.hyper", "locann.hrom", "hprom_local_ann_vs_hdm",  "run.offline_local_ann.9999.01",  3),
    ("Local-HPROM-RBF", "locrbf.hyper", "locrbf.hrom", "hprom_local_rbf_vs_hdm",  "run.offline_local_rbf.9999.01",  3),
    ("Local-HPROM-GPR", "locgp.hyper",  "locgp.hrom",  "hprom_local_gpr_vs_hdm",  "run.offline_local_gp.9999.01",   3),
]


def read(path: Path) -> str:
    try:
        return path.read_text(errors="replace")
    except OSError:
        return ""


def total_time(text: str) -> float | None:
    """Wall-clock from AERO-F's own timing block."""
    m = re.search(r"^Total Simulation\s+:\s+([\d.]+)", text, re.M)
    return float(m.group(1)) if m else None


def span(values) -> str:
    """A single value, or its range when it varies across clusters."""
    if not values:
        return "-"
    lo, hi = min(values), max(values)
    return str(lo) if lo == hi else f"{lo}-{hi}"


def dimensions(offline: str, primary: int | None) -> tuple[str, str]:
    """Return (n, n_bar) read from the offline artifacts rather than the logs.

    For a quadratic manifold the reduced dimension lives in state.qdim, since
    the log only reports what a conventional subspace would have retained.
    Otherwise the column count of state.coords is the total retained
    dimension: all primary when there is no closure map, and split into
    n + n_bar when there is one.
    """
    base = REPO / "simulations" / offline / "nonlinearrom"

    qdim = base / "state.qdim"
    if qdim.exists():
        dims = [int(l.split()[1]) for l in read(qdim).splitlines()[1:] if l.split()]
        return span(dims), "-"

    totals = []
    for coords in sorted(base.glob("cluster*/state.coords")):
        for line in read(coords).splitlines()[1:]:
            if line.strip():
                totals.append(len(line.split(",")))
                break
    if not totals:
        return "-", "-"
    if primary is None:
        return span(totals), "-"
    return str(primary), span([t - primary for t in totals])


def sample_nodes(text: str) -> str:
    """ECSW sample nodes, summed over clusters (layer 0 of the reduced mesh)."""
    n = [int(x) for x in re.findall(r"layer 0: added (\d+) sample", text)]
    return str(sum(n)) if n else "-"


def errors(tag: str) -> tuple[str, str]:
    path = REPO / "simulations" / "postpro_compare" / f"{tag}_error_summary.csv"
    if not path.exists():
        return "-", "-"
    drag = lift = "-"
    with path.open() as fh:
        for row in csv.DictReader(fh):
            if row["signal"].startswith("Drag"):
                drag = f"{float(row['rel_l2_pct']):.3f}"
            elif row["signal"].startswith("Lift"):
                lift = f"{float(row['rel_l2_pct']):.2f}"
    return drag, lift


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--logs", default="pipeline_logs")
    args = ap.parse_args()
    logs = REPO / args.logs

    hdm = total_time(read(logs / "fom.log"))

    rows = []
    for label, hyper, hrom, tag, offline, primary in FAMILIES:
        t = total_time(read(logs / f"{hrom}.log"))
        drag, lift = errors(tag)
        n, n_bar = dimensions(offline, primary)
        rows.append({
            "model":   label,
            "n":       n,
            "nbar":    n_bar,
            "Ne":      sample_nodes(read(logs / f"{hyper}.log")),
            "time":    f"{t:.2f}" if t else "-",
            "speedup": f"{hdm / t:.0f}x" if (t and hdm) else "-",
            "drag":    drag,
            "lift":    lift,
        })

    hdr = ("model", "n", "nbar", "Ne", "time", "speedup", "drag", "lift")
    names = {"model": "Computational model", "n": "n", "nbar": "n_bar",
             "Ne": "sample nodes",
             "time": "online (s)", "speedup": "speedup",
             "drag": "drag RE2 (%)", "lift": "lift RE2 (%)"}
    width = {k: max(len(names[k]), *(len(r[k]) for r in rows)) for k in hdr}

    print()
    print(f"HDM: {hdm:.2f} s" if hdm else "HDM: unavailable (no fom.log)")
    print()
    print("  " + "  ".join(names[k].ljust(width[k]) for k in hdr))
    print("  " + "  ".join("-" * width[k] for k in hdr))
    for r in rows:
        print("  " + "  ".join(r[k].ljust(width[k]) for k in hdr))
    print()

    out = REPO / "simulations" / "postpro_compare" / "run_summary.csv"
    with out.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=hdr)
        w.writeheader()
        w.writerows(rows)
    print(f"Wrote {out.relative_to(REPO)}")


if __name__ == "__main__":
    main()
