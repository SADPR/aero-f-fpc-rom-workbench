#!/usr/bin/env python3
"""Accuracy table for the ROM families, in quantities that survive a
parameter sweep.

Why not just the relative L2 over the time history (eq. 30 of the closure
paper): on this case the lift oscillates about zero, so that norm is dominated
by phase rather than amplitude, and a 1% error in shedding frequency
accumulates into a ~70% reported error over 25 cycles. It also stops being
comparable between parameter points once the Strouhal number itself varies
with Re.

So the headline columns are physical and local in time:

  St        shedding frequency, from ascending zero crossings of the lift
  C_L' rms  lift amplitude in the limit cycle
  C_D mean  mean drag in the limit cycle

The relative L2 of the lift is still reported, for continuity with the paper,
together with the phase drift per cycle that explains it.

Usage: python3 simulations/error_metrics.py [--window 90 150]
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parent.parent

# label -> postprocessing directory
MODELS = [
    ("HPROM-35",        "run.post_hrom.9999.01"),
    ("HPROM-10",        "run.post_hrom.9999_10.01"),
    ("HQPROM",          "run.post_hrom_quad.9999.01"),
    ("HPROM-ANN-5",     "run.post_hrom_ann.9999.01"),
    ("HPROM-RBF-5",     "run.post_hrom_rbf.9999.01"),
    ("HPROM-GPR-5",     "run.post_hrom_gp.9999.01"),
    ("Local-HPROM",     "run.post_hrom_local.9999.01"),
    ("Local-HQPROM",    "run.post_hrom_local_quad.9999.01"),
    ("Local-HPROM-ANN", "run.post_hrom_local_ann.9999.01"),
    ("Local-HPROM-RBF", "run.post_hrom_local_rbf.9999.01"),
    ("Local-HPROM-GPR", "run.post_hrom_local_gp.9999.01"),
]

COL_TIME, COL_DRAG, COL_LIFT = 1, 4, 6


def load(directory: str):
    path = REPO / "simulations" / directory / "postpro" / "LiftandDrag.out"
    if not path.exists():
        return None
    d = np.loadtxt(path)
    return d[:, COL_TIME], d[:, COL_DRAG], d[:, COL_LIFT]


def crossings(t: np.ndarray, y: np.ndarray) -> np.ndarray:
    """Ascending zero crossings, linearly interpolated."""
    neg = np.signbit(y)
    idx = np.where(np.diff(neg.astype(int)) == -1)[0]
    return np.array([t[i] + (t[i + 1] - t[i]) * (-y[i]) / (y[i + 1] - y[i])
                     for i in idx])


def strouhal(t: np.ndarray, lift: np.ndarray) -> float | None:
    """With L = 1 and U = 1 in this setup, St is just the shedding frequency."""
    c = crossings(t, lift)
    if len(c) < 3:
        return None
    return 1.0 / np.mean(np.diff(c))


def drift_per_cycle(t, lift_ref, lift_mod) -> float | None:
    """Phase lag growth, in percent of a period per shedding cycle.

    Fitted over the whole history rather than the limit-cycle window, since
    the drift accumulates from the moment the two frequencies differ.
    """
    cr, cm = crossings(t, lift_ref), crossings(t, lift_mod)
    n = min(len(cr), len(cm))
    if n < 4:
        return None
    period = np.mean(np.diff(cr))
    lag = cm[:n] - cr[:n]
    slope = np.polyfit(np.arange(n), lag, 1)[0]      # time units per cycle
    return slope / period * 100.0


def rel_l2(ref: np.ndarray, mod: np.ndarray) -> float:
    return float(np.linalg.norm(mod - ref) / np.linalg.norm(ref) * 100.0)


def metrics(ref, mod, window) -> dict:
    t, drag_r, lift_r = ref
    _, drag_m, lift_m = mod
    n = min(len(t), len(lift_m))
    t, drag_r, lift_r = t[:n], drag_r[:n], lift_r[:n]
    drag_m, lift_m = drag_m[:n], lift_m[:n]

    lo, hi = window
    w = (t >= lo) & (t <= hi)

    st_r, st_m = strouhal(t[w], lift_r[w]), strouhal(t[w], lift_m[w])
    cl_r, cl_m = lift_r[w].std(), lift_m[w].std()
    cd_r, cd_m = drag_r[w].mean(), drag_m[w].mean()

    return {
        "St":        st_m,
        "St_err":    None if (st_r is None or st_m is None) else (st_m - st_r) / st_r * 100,
        "CLrms_err": (cl_m - cl_r) / cl_r * 100,
        "CDmean_err": (cd_m - cd_r) / cd_r * 100,
        "REl2_lift": rel_l2(lift_r, lift_m),
        "REl2_drag": rel_l2(drag_r, drag_m),
        "drift":     drift_per_cycle(t, lift_r, lift_m),
    }


def fmt(v, spec="+.2f") -> str:
    return "-" if v is None else format(v, spec)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--window", nargs=2, type=float, default=[90.0, 150.0],
                    metavar=("T0", "T1"),
                    help="limit-cycle window for the physical quantities")
    args = ap.parse_args()
    window = tuple(args.window)

    ref = load("run.fom")
    if ref is None:
        raise SystemExit("HDM reference not found: run.fom/postpro/LiftandDrag.out")

    st_ref = strouhal(*[a[(ref[0] >= window[0]) & (ref[0] <= window[1])]
                        for a in (ref[0], ref[2])])

    rows = []
    for label, directory in MODELS:
        mod = load(directory)
        if mod is None:
            continue
        m = metrics(ref, mod, window)
        m["model"] = label
        rows.append(m)

    print()
    print(f"HDM reference:  St = {st_ref:.5f}   "
          f"C_L' rms = {ref[2][(ref[0] >= window[0])].std():.4e}   "
          f"C_D mean = {ref[1][(ref[0] >= window[0])].mean():.4e}")
    print(f"limit-cycle window: t = [{window[0]:.0f}, {window[1]:.0f}]  "
          f"(~{(window[1] - window[0]) * st_ref:.0f} shedding cycles)")
    print()

    head = ["model", "St", "St err %", "C_L' err %", "C_D err %",
            "RE2 lift %", "drift %/cyc"]
    cells = [[r["model"], fmt(r["St"], ".5f"), fmt(r["St_err"]),
              fmt(r["CLrms_err"]), fmt(r["CDmean_err"]),
              fmt(r["REl2_lift"], ".2f"), fmt(r["drift"])] for r in rows]
    w = [max(len(head[i]), *(len(c[i]) for c in cells)) for i in range(len(head))]
    print("  " + "  ".join(h.rjust(w[i]) if i else h.ljust(w[i])
                           for i, h in enumerate(head)))
    print("  " + "  ".join("-" * w[i] for i in range(len(head))))
    for c in cells:
        print("  " + "  ".join(x.rjust(w[i]) if i else x.ljust(w[i])
                               for i, x in enumerate(c)))
    print()

    out = REPO / "simulations" / "postpro_compare" / "accuracy_metrics.csv"
    fields = ["model", "St", "St_err", "CLrms_err", "CDmean_err",
              "REl2_lift", "REl2_drag", "drift"]
    with out.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r.get(k) for k in fields})
    print(f"Wrote {out.relative_to(REPO)}")


if __name__ == "__main__":
    main()
