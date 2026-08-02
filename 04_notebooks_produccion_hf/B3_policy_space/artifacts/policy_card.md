# Policy card — Serie A4 (policy / uplift targeting)

## Scope

| Campo | Valor |
|-------|--------|
| **scenario** | `real/ihdp` |
| **scenario_id** | `real_ihdp` |
| **population** | Official **test** split of the IHDP-style scenario (n=150) |
| **outcome (Y)** | `outcome` (cognitive / development score scale of the benchmark) |
| **treatment (T)** | `treatment` (binary program assignment in the SEM) |
| **features (X)** | `bw`, `b.head`, `preterm`, `birth.o`, `nnhealth`, `momage`, `sex`, `twin`, `b.marr`, `mom.lths`, `mom.hs`, `mom.scoll`, `cig`, `first`, `booze`, `drugs`, `work.dur`, `prenatal`, `ark`, `ein`, `har`, `mia`, `pen`, `tex`, `was` |
| **scoring method** | `t_learner` (CATE / uplift score from Notebook A3 when available) |
| **policy mode** | `topk` (treat if score ≥ threshold calibrated to budget) |
| **budget_fraction (B)** | 0.20 (20% of units) |
| **threshold (λ)** | 7.947752 |
| **observed treat rate under π (test)** | 0.2000 |
| **random_state** | 42 |

## Decision rule

1. Compute uplift score \(s(x) = \\hat\\tau(x)\) with the scoring method above.
2. Calibrate threshold \(λ\) so that approximately fraction **B** of units have \(s(x) ≥ λ\) (empirical quantile on the calibration scores, usually test scores for this notebook).
3. Decision: \(π(x) = 1\\{ s(x) ≥ λ \\}\).

## Interface (Serie B / B3)

```python
from joblib import load
policy = load("artifacts/A4/policy.joblib")
out = policy.predict(X=X_new)           # needs embedded score model
# or: out = policy.predict(scores=s)    # precomputed uplift scores
# out["decision"]      -> {0,1} array
# out["uplift_score"]  -> float array
```

## Assumptions (identification / policy)

- **Unconfoundedness / ignorability** given the listed covariates (true *by design* of the synthetic SEM; **not** proven for real clinical IHDP).
- **SUTVA** (no interference; stable treatment version).
- **Overlap** sufficient for the CATE model used to score units.
- Budget constraint is a **hard capacity** stylized as top-B% targeting (myopic; not full offline policy optimization with costs).
- Welfare comparisons that use `tau` are **oracle evaluations** for teaching only.

## Risks and limitations

- Data are **synthetic with Hill-style variable names** — not clinical or administrative records.
- CATE scores inherit model bias; ranking quality ≠ identification of τ(x).
- Equity tables (e.g. treat rate by `bw_tercile`) are **descriptive**, not a fairness proof or legal compliance check.
- Threshold calibrated on a small test set (n≈150) is noisy; production systems need re-calibration and monitoring (Serie B).
- Embedded scorer is a **T-learner RF** for `predict(X)`; if A3 used another `method_selected` for ranking, X-only scores may differ slightly from the CSV column.

## Non-claims (explicit)

- This artifact does **not** claim clinical validity, regulatory approval, or external validity to real infants/programs.
- Beating a random baseline on oracle welfare does **not** justify deployment.
- Equity analysis does **not** certify absence of disparate impact.
- The policy is a **teaching handoff** for B3 (Gradio Space), not a production decision system.

## Artifacts in this folder

- `policy.joblib` — serialized :class:`Policy`
- `policy_card.md` — this document
- `uplift_curve.png` — Qini / uplift ranking figure
- `equity_table.csv` — treat rates by group
