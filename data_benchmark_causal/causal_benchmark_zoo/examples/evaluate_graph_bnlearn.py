from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from causal_benchmark_zoo.graph_metrics import evaluate_graph_json
from causal_benchmark_zoo.registry import BENCHMARKS_ROOT


for benchmark_id in ["bnlearn_asia", "bnlearn_alarm"]:
    reference = BENCHMARKS_ROOT / benchmark_id / "graphs" / "graph.json"
    # Self-comparison should be perfect and is a smoke test for the evaluator.
    metrics = evaluate_graph_json(reference, reference)
    print(benchmark_id, metrics.to_dict())
