# Ground truth taxonomy

Allowed `ground_truth.type` values:

| Type | Meaning | Active example |
|---|---|---|
| `graph` | Reference graph exists; no treatment effect implied | `bnlearn_asia`, `bnlearn_alarm` |
| `sem` | Structural equation model known or expected | `csuite_lingauss` pending/manual |
| `ate` | Average Treatment Effect known/computable | none active |
| `cate` | Conditional Average Treatment Effect known/computable | none active |
| `experimental_reference_estimate` | Experimental estimate with uncertainty | `lalonde_nsw` pending/manual |
| `none` | No acceptable ground truth | none active |

Graph ground truth and ATE ground truth are different objects. A graph benchmark should not be used to score an ATE estimator without defining intervention, outcome, population, and estimand.
