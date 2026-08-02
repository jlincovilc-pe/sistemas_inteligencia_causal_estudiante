#!/usr/bin/env bash
# Auditoría local del monorepo de práctica (A + B + labs).
# Uso (desde la raíz del monorepo):
#   bash scripts/audit_repo.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PYA="${ROOT}/03_notebooks_caso_estudio/.venv/bin/python"
PYB="${ROOT}/04_notebooks_produccion_hf/B1_fastapi_dml/.venv/bin/python"
if [[ ! -x "$PYA" ]]; then
  echo "WARN: no Serie A venv at 03_…/.venv — using python3"
  PYA="python3"
fi
if [[ ! -x "$PYB" ]]; then
  PYB="$PYA"
fi

export PYTHONPATH="${ROOT}/05_labs_sesion:${ROOT}/03_notebooks_caso_estudio:${ROOT}/04_notebooks_produccion_hf/B1_fastapi_dml:${ROOT}/04_notebooks_produccion_hf/B4_monitoring_dashboard:${ROOT}/04_notebooks_produccion_hf/B3_policy_space${PYTHONPATH:+:$PYTHONPATH}"

fail=0
run() {
  local name="$1"; shift
  echo ""
  echo "========== $name =========="
  if "$@"; then
    echo "OK $name"
  else
    echo "FAIL $name"
    fail=1
  fi
}

run "compileall" "$PYA" -m compileall -q \
  03_notebooks_caso_estudio/lib \
  04_notebooks_produccion_hf/B1_fastapi_dml/app \
  04_notebooks_produccion_hf/autograder \
  05_labs_sesion

run "serie_a_pytest" "$PYA" -m pytest 03_notebooks_caso_estudio/tests/ -q --tb=line
run "labs_pytest" "$PYA" -m pytest 05_labs_sesion/tests/ -q --tb=line
run "b1_pytest" "$PYB" -m pytest 04_notebooks_produccion_hf/B1_fastapi_dml/tests/ -q --tb=line

run "grade_a1" "$PYA" 03_notebooks_caso_estudio/autograder/grade_a1.py --skip-notebook-audit
run "grade_a2" "$PYA" 03_notebooks_caso_estudio/autograder/grade_a2.py --skip-notebook-audit
run "grade_a3" "$PYA" 03_notebooks_caso_estudio/autograder/grade_a3.py --skip-notebook-audit
run "grade_a4" "$PYA" 03_notebooks_caso_estudio/autograder/grade_a4.py --skip-notebook-audit
run "grade_b1" "$PYB" 04_notebooks_produccion_hf/autograder/grade_b1.py
run "grade_b2" "$PYA" 04_notebooks_produccion_hf/autograder/grade_b2.py
run "grade_b3" "$PYA" 04_notebooks_produccion_hf/autograder/grade_b3.py
run "grade_b4" "$PYA" 04_notebooks_produccion_hf/autograder/grade_b4.py

# Artifact sync
run "artifact_sync" "$PYA" - <<'PY'
from pathlib import Path
import hashlib, sys
def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest() if Path(p).is_file() else None
pairs = [
    ("03_notebooks_caso_estudio/artifacts/A2/dml_estimator.joblib",
     "04_notebooks_produccion_hf/B1_fastapi_dml/artifacts/dml_estimator.joblib"),
    ("03_notebooks_caso_estudio/artifacts/A4/policy.joblib",
     "04_notebooks_produccion_hf/B3_policy_space/artifacts/policy.joblib"),
]
ok = True
for a, b in pairs:
    sa, sb = sha(a), sha(b)
    if sa is None or sb is None or sa != sb:
        print(f"MISMATCH {a} vs {b}")
        ok = False
    else:
        print(f"match {Path(a).name}")
sys.exit(0 if ok else 1)
PY

echo ""
if [[ "$fail" -eq 0 ]]; then
  echo "========== AUDIT PASS =========="
  exit 0
else
  echo "========== AUDIT FAIL =========="
  exit 1
fi
