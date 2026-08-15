#!/usr/bin/env python3
"""Refuerzos Hugging Face del sílabo — S2 (setup), S5 (dataset A1), S8 (dataset A2), S13 (modelo A2).

Implementa los cuatro cierres cortos de Hugging Face definidos en
``01_silabo/silabo.typ`` §7 (sesiones 2, 5, 8 y 13), reutilizando la misma
API ``huggingface_hub`` que los notebooks de la Serie B (B2). Subir a HF es
**opcional y manual** (política del monorepo: 100 % local); este script es el
único punto de contacto del curso con el Hub para los refuerzos.

Sesiones cubiertas
------------------
S02 — setup: verifica token y cuenta (``notebook_login()`` cuando hace falta).
S05 — publica el dataset de A1 (Jobs) ya procesado: ``observed_*.csv`` +
      sidecars (metadata/identification/splits) como *dataset* versionado.
S08 — publica el dataset limpio de A2 (IHDP medium, sin fuga de truth) como
      *dataset* versionado.
S13 — publica el estimador DML de A2 (``dml_estimator.joblib`` +
      ``feature_list.json`` + ``training_meta.json``) como *model* versionado.

Contrato de capas (nunca se sube truth)
---------------------------------------
Se suben únicamente archivos observables + sidecars de identificación:
``observed_train/validation/test.csv``, ``metadata.json``,
``identification.json``, ``splits.json``. **Nunca** ``truth_*.csv`` ni
``data.csv`` (dataset completo con truth), para respetar el contrato del
benchmark y la política de ``lib.data_io.load_truth``.

Degradación (no falla)
----------------------
- Si ``huggingface_hub`` no está instalado: aviso + exit 0 (nada se sube).
- Si no hay token configurado (``AuthorizationError``): aviso con el comando
  para configurarlo + exit 0 (nada se sube).
- Si el artefacto de origen no existe (p. ej. A2 joblib aún no exportado):
  aviso + exit 0 para no romper el flujo de una sesión que corre antes que A2.
- Cualquier otro error real (red, repo duplicado sin ``exist_ok``, etc.):
  exit 1 con el mensaje.

Uso
---
::

    python scripts/hf_refuerzos.py --help
    python scripts/hf_refuerzos.py setup                 # S2
    python scripts/hf_refuerzos.py dataset-a1 --dry-run  # S5 (previsualiza)
    python scripts/hf_refuerzos.py dataset-a1            # S5
    python scripts/hf_refuerzos.py dataset-a2            # S8
    python scripts/hf_refuerzos.py model-a2              # S13
    python scripts/hf_refuerzos.py todo --repo-id-base eco490-2026

Checklist de entrega del refuerzo HF (script)
---------------------------------------------
- [ ] ``python scripts/hf_refuerzos.py setup`` confirma la cuenta con el token local
- [ ] S5: ``dataset-a1`` publica ``observed_*`` + sidecars (sin truth) y la URL se reporta
- [ ] S8: ``dataset-a2`` publica el IHDP medium sin columnas de fuga (solo observables)
- [ ] S13: ``model-a2`` publica joblib + feature_list + training_meta con su README
- [ ] ``--dry-run`` muestra el plan exacto de repos y archivos antes de subir nada
"""

from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Sequence

# ---------------------------------------------------------------------------
# Rutas del monorepo (relativas a la ubicación de este archivo)
# ---------------------------------------------------------------------------
_THIS = Path(__file__).resolve()
SCRIPTS_DIR = _THIS.parent                      # .../B2_hub_cicd/scripts
B2_DIR = SCRIPTS_DIR.parent                     # .../B2_hub_cicd
HF_DIR = B2_DIR.parent                          # .../04_notebooks_produccion_hf
REPO_ROOT = HF_DIR.parent                       # raíz del monorepo
SERIE_A = REPO_ROOT / "03_notebooks_caso_estudio"

# Escenarios de datos (contracto de capas: observables + sidecars, sin truth)
SCENARIO_A1 = REPO_ROOT / "data_benchmark_causal" / "causal_benchmark_synthetic" / "datasets" / "real" / "jobs"
SCENARIO_A2 = REPO_ROOT / "data_benchmark_causal" / "causal_benchmark_synthetic" / "datasets" / "synthetic" / "inference" / "ihdp_medium"
ARTIFACTS_A2 = SERIE_A / "artifacts" / "A2"

# Archivos permitidos en un dataset público (nunca truth_*.csv ni data.csv)
DATASET_FILES = (
    "observed_train.csv",
    "observed_validation.csv",
    "observed_test.csv",
    "metadata.json",
    "identification.json",
    "splits.json",
)


def _warning(msg: str) -> None:
    print(f"[aviso] {msg}", file=sys.stderr)


def _huggingface_hub():
    """Import huggingface_hub o degradar con aviso (exit 0)."""
    try:
        from huggingface_hub import HfApi, notebook_login  # type: ignore
        return HfApi, notebook_login
    except ImportError:
        _warning(
            "huggingface_hub no está instalado (es dependencia de la Serie B, "
            "no de la Serie A). Nada se subió. Instala con: "
            "pip install 'huggingface_hub>=0.20'"
        )
        return None, None


def _authenticated(api) -> Optional[Dict]:
    """Devuelve ``whoami()`` o ``None`` con aviso si no hay token válido."""
    if api is None:
        return None
    try:
        return api.whoami()
    except Exception as exc:  # AuthorizationError y otros de red/credenciales
        _warning(
            f"no se pudo autenticar contra Hugging Face ({type(exc).__name__}: {exc}). "
            "Configura tu token primero (sesión 2):\n"
            "    python -c \"from huggingface_hub import notebook_login; notebook_login()\"\n"
            "o exporta HF_TOKEN. Nada se subió."
        )
        return None


def _scenario_files_ready(scenario_dir: Path) -> List[Path]:
    """Lista los archivos observables existentes de un escenario (sin truth)."""
    return [scenario_dir / name for name in DATASET_FILES if (scenario_dir / name).is_file()]


def _readme_for_dataset(scenario_id: str, title: str, description: str) -> str:
    return (
        f"# {title}\n\n"
        f"`scenario_id`: `{scenario_id}`\n\n"
        f"{description}\n\n"
        "## Contenido\n\n"
        "Solo archivos observables y sidecars de identificación (contrato de capas "
        "del Causal Benchmark Ecosystem). **No** incluye `truth_*.csv`.\n\n"
        "| Archivo | Rol |\n"
        "|---|---|\n"
        "| `observed_train/validation/test.csv` | Datos observables por split |\n"
        "| `metadata.json` | Semilla, ATE del generador, `what_is_real/synthetic` |\n"
        "| `identification.json` | Anotación de identificación del SEM (no es prueba) |\n"
        "| `splits.json` | Splits oficiales del escenario |\n"
    )


def _publish_dataset(api, repo_id: str, scenario_dir: Path, scenario_id: str,
                     title: str, description: str, *, dry_run: bool) -> None:
    """Crea/actualiza un repo de tipo dataset con los observables del escenario."""
    files = _scenario_files_ready(scenario_dir)
    if not files:
        _warning(f"no hay archivos observables en {scenario_dir}; nada que publicar")
        return
    print(f"  · dataset `{repo_id}` <- {len(files)} archivos de {scenario_dir.name}")
    for f in files:
        print(f"      + {f.name}")
    if dry_run:
        print("  (dry-run: no se creó ningún repo ni se subió nada)")
        return

    api.create_repo(repo_id=repo_id, repo_type="dataset", exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="hf_refuerzo_dataset_") as tmp:
        tmp_path = Path(tmp)
        for f in files:
            shutil.copy2(f, tmp_path / f.name)
        (tmp_path / "README.md").write_text(
            _readme_for_dataset(scenario_id, title, description), encoding="utf-8"
        )
        api.upload_folder(
            repo_id=repo_id,
            repo_type="dataset",
            folder_path=str(tmp_path),
            commit_message=f"Refuerzo HF S05/S08 — {title}",
        )
    print(f"  ✓ publicado: https://huggingface.co/datasets/{repo_id}")


def _publish_model(api, repo_id: str, artifact_dir: Path, *, dry_run: bool) -> None:
    """Publica el estimador DML de A2 como modelo (S13)."""
    joblib_path = artifact_dir / "dml_estimator.joblib"
    if not joblib_path.is_file():
        _warning(
            f"no existe {joblib_path}. Exporta primero con "
            "`python scripts/export_a2_artifacts.py` (o corriendo el notebook A2). "
            "Nada se subió."
        )
        return
    sidecars = [
        artifact_dir / "feature_list.json",
        artifact_dir / "training_meta.json",
    ]
    print(f"  · model `{repo_id}` <- {joblib_path.name} + sidecars")
    if dry_run:
        print("  (dry-run: no se creó ningún repo ni se subió nada)")
        return

    api.create_repo(repo_id=repo_id, repo_type="model", exist_ok=True)
    api.upload_file(
        path_or_fileobj=str(joblib_path),
        path_in_repo=joblib_path.name,
        repo_id=repo_id,
        repo_type="model",
        commit_message="Refuerzo HF S13 — dml_estimator.joblib",
    )
    for sc in sidecars:
        if sc.is_file():
            api.upload_file(
                path_or_fileobj=str(sc),
                path_in_repo=sc.name,
                repo_id=repo_id,
                repo_type="model",
                commit_message=f"Refuerzo HF S13 — {sc.name}",
            )
    readme = (
        "# Estimador DML (PLR/Lasso) — A2 → B1\n\n"
        "Artefacto del Notebook A2 (`synthetic/inference/ihdp_medium`). "
        "Interfaz: `const_marginal_ate()`, `ate()`, `predict(X)`.\n\n"
        "- `dml_estimator.joblib` — estimador serializado\n"
        "- `feature_list.json` — 25 covariables en orden de entrenamiento\n"
        "- `training_meta.json` — scenario_id, seed, ATE puntual, IC, supuestos\n\n"
        "Documentación formal: `model_card` causal de la Serie B2 (Cap. 19 / Ap. G).\n"
    )
    with tempfile.NamedTemporaryFile(
        "w", suffix=".md", prefix="hf_refuerzo_model_", delete=False, encoding="utf-8"
    ) as fh:
        fh.write(readme)
        tmp_readme = Path(fh.name)
    try:
        api.upload_file(
            path_or_fileobj=str(tmp_readme),
            path_in_repo="README.md",
            repo_id=repo_id,
            repo_type="model",
            commit_message="Refuerzo HF S13 — README del artefacto",
        )
    finally:
        tmp_readme.unlink(missing_ok=True)
    print(f"  ✓ publicado: https://huggingface.co/{repo_id}")


def cmd_setup(args: argparse.Namespace) -> int:
    """S2 — verificar cuenta y token."""
    HfApi, notebook_login = _huggingface_hub()
    if HfApi is None:
        return 0
    api = HfApi()
    who = _authenticated(api)
    if who is None:
        if args.dry_run:
            print("[setup] dry-run: verificaría la cuenta con el token configurado")
        return 0
    name = who.get("name") or who.get("fullname") or "unknown"
    print(f"[setup] Sesión 2 OK — cuenta HF autenticada: {name}")
    print(f"[setup] tu namespace para repos del curso: {name}")
    return 0


def cmd_dataset_a1(args: argparse.Namespace) -> int:
    """S5 — dataset de A1 (Jobs) ya procesado."""
    repo_id = args.repo_id or "eco490-a1/jobs-observed"
    _publish_dataset(
        _huggingface_hub()[0](),
        repo_id,
        SCENARIO_A1,
        scenario_id="real_jobs",
        title="Jobs (LaLonde-style) — observables, caso A1",
        description=(
            "Escenario `real/jobs` del Causal Benchmark Ecosystem: programa de "
            "capacitación laboral (n=1722, ATE generador ≈ 1600). Solo observables."
        ),
        dry_run=args.dry_run,
    )
    return 0


def cmd_dataset_a2(args: argparse.Namespace) -> int:
    """S8 — dataset limpio de A2 (IHDP medium, sin fuga de truth)."""
    repo_id = args.repo_id or "eco490-a2/ihdp-medium-observed"
    _publish_dataset(
        _huggingface_hub()[0](),
        repo_id,
        SCENARIO_A2,
        scenario_id="synthetic_inference_ihdp_medium",
        title="IHDP medium — observables limpios, caso A2",
        description=(
            "Escenario `synthetic/inference/ihdp_medium` (n=2000, 25 covariables). "
            "Publicado tras la auditoría de features sin fuga causal del Cap. 9 "
            "(solo columnas observables; sin `truth_*.csv`)."
        ),
        dry_run=args.dry_run,
    )
    return 0


def cmd_model_a2(args: argparse.Namespace) -> int:
    """S13 — modelo DML de A2 al Hub como artefacto versionado."""
    repo_id = args.repo_id or "eco490-a2/dml-plr-ate"
    _publish_model(
        _huggingface_hub()[0](),
        repo_id,
        ARTIFACTS_A2,
        dry_run=args.dry_run,
    )
    return 0


def main(argv: Optional[Sequence[str]] = None) -> int:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument(
        "--dry-run",
        action="store_true",
        help="Previsualiza repos y archivos sin crear nada ni subir nada",
    )
    common.add_argument(
        "--repo-id",
        default=None,
        help="Override del repo de destino (p. ej. eco490-2026/jobs-observed)",
    )

    parser = argparse.ArgumentParser(
        parents=[common],
        description=(
            "Refuerzos HF del sílabo (S2 setup · S5 dataset A1 · S8 dataset A2 · "
            "S13 modelo A2). Subida opcional y manual; degrada con aviso si falta "
            "token o huggingface_hub."
        ),
    )
    sub = parser.add_subparsers(dest="command", required=True)

    for name, help_text in (
        ("setup", "S2 — verificar cuenta y token (notebook_login)"),
        ("dataset-a1", "S5 — subir observables de Jobs (A1)"),
        ("dataset-a2", "S8 — subir IHDP medium limpio (A2)"),
        ("model-a2", "S13 — subir dml_estimator.joblib (A2)"),
        ("todo", "Ejecuta setup + dataset-a1 + dataset-a2 + model-a2"),
    ):
        sub.add_parser(name, parents=[common], help=help_text)

    args = parser.parse_args(argv)
    HfApi, _ = _huggingface_hub()
    if HfApi is None:
        return 0  # degradación: aviso ya impreso

    if args.command == "setup":
        return cmd_setup(args)
    if args.command == "dataset-a1":
        return cmd_dataset_a1(args)
    if args.command == "dataset-a2":
        return cmd_dataset_a2(args)
    if args.command == "model-a2":
        return cmd_model_a2(args)
    if args.command == "todo":
        rc = 0
        rc |= cmd_setup(args)
        rc |= cmd_dataset_a1(args)
        rc |= cmd_dataset_a2(args)
        rc |= cmd_model_a2(args)
        return rc
    parser.error(f"comando desconocido: {args.command}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
