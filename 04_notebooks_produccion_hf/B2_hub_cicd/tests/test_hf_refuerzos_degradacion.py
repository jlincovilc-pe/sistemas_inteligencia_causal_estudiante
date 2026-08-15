#!/usr/bin/env python3
"""Test: ``hf_refuerzos.py`` degrada con aviso cuando no hay token.

Reproduce el escenario *sin token* sin red: inyecta un módulo
``huggingface_hub`` simulado cuyo ``whoami()`` lanza
``LocalTokenNotFoundError`` (la excepción real de huggingface_hub cuando no
hay token configurado) y verifica que **todos** los comandos degradan con
exit 0 en vez de reventar con traceback, y que nunca se llega a
``create_repo``/``upload_folder``/``upload_file``.

Esto atrapa automáticamente regresiones del tipo "se llama a ``create_repo``
antes de chequear autenticación" (bug que existió en ``cmd_dataset_a1``,
``cmd_dataset_a2`` y ``cmd_model_a2``) sin depender de una prueba manual con
una instalación real sin token.

Correr
------
::

    pytest 04_notebooks_produccion_hf/B2_hub_cicd/tests/ -q
    python 04_notebooks_produccion_hf/B2_hub_cicd/tests/test_hf_refuerzos_degradacion.py
"""

from __future__ import annotations

import contextlib
import io
import sys
import types
from pathlib import Path
from typing import List

# ---------------------------------------------------------------------------
# Módulo huggingface_hub simulado (sin red, sin token)
# ---------------------------------------------------------------------------

_calls: List[str] = []


class _LocalTokenNotFoundError(Exception):
    """Misma semántica que huggingface_hub.errors.LocalTokenNotFoundError."""


class _FakeApi:
    """API simulada que falla en whoami() como si no hubiera token.

    Cualquier llamada a create_repo/upload_* es un bug del script (nunca se
    debe llegar ahí sin autenticación) y por tanto lanza AssertionError.
    """

    def whoami(self):
        _calls.append("whoami")
        raise _LocalTokenNotFoundError(
            "Token is required to call the /whoami-v2 endpoint, but no token found."
        )

    def create_repo(self, *args, **kwargs):
        _calls.append("create_repo")
        raise AssertionError("create_repo no debería llamarse sin token")

    def upload_folder(self, *args, **kwargs):
        _calls.append("upload_folder")
        raise AssertionError("upload_folder no debería llamarse sin token")

    def upload_file(self, *args, **kwargs):
        _calls.append("upload_file")
        raise AssertionError("upload_file no debería llamarse sin token")


def _install_fake_hub() -> types.ModuleType:
    mod = types.ModuleType("huggingface_hub")

    def HfApi():
        return _FakeApi()

    def notebook_login():
        raise AssertionError("notebook_login no debería llamarse en modo simulado")

    mod.HfApi = HfApi
    mod.notebook_login = notebook_login
    sys.modules["huggingface_hub"] = mod
    return mod


# ---------------------------------------------------------------------------
# Carga del script bajo prueba
# ---------------------------------------------------------------------------

_SCRIPTS = Path(__file__).resolve().parent.parent / "scripts"
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

import hf_refuerzos  # noqa: E402  (importa huggingface_hub de forma perezosa)


def _run(command: List[str]) -> int:
    """Ejecuta un comando del CLI capturando stderr (avisos)."""
    err = io.StringIO()
    with contextlib.redirect_stderr(err):
        rc = hf_refuerzos.main(command)
    return rc, err.getvalue()


def _reset_calls() -> None:
    _calls.clear()


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


def test_comandos_degradan_sin_token() -> None:
    """Todos los subcomandos terminan con exit 0 y aviso, sin traceback."""
    _install_fake_hub()
    for cmd in ("setup", "dataset-a1", "dataset-a2", "model-a2", "todo"):
        _reset_calls()
        rc, err = _run([cmd])
        assert rc == 0, f"{cmd}: exit={rc} (esperado 0 por degradación)"
        assert "[aviso]" in err, f"{cmd}: falta el aviso de degradación en stderr"
        assert "no se pudo autenticar" in err, f"{cmd}: aviso de autenticación ausente"
        # El chequeo de auth ocurrió y nunca se llegó a subir nada.
        assert "whoami" in _calls, f"{cmd}: nunca se chequeó la autenticación"
        assert "create_repo" not in _calls, f"{cmd}: llegó a create_repo sin token"
        assert "upload_folder" not in _calls and "upload_file" not in _calls, (
            f"{cmd}: llegó a upload sin token"
        )


def test_degradacion_con_dry_run_y_repo_id() -> None:
    """Incluso con --dry-run o --repo-id, sin token se degrada (no se sube)."""
    _install_fake_hub()
    for cmd in (
        ["dataset-a1", "--dry-run"],
        ["dataset-a2", "--repo-id", "cualquiera/jobs"],
        ["model-a2", "--dry-run", "--repo-id", "cualquiera/dml"],
    ):
        _reset_calls()
        rc, err = _run(cmd)
        assert rc == 0, f"{cmd}: exit={rc}"
        assert "[aviso]" in err
        assert "whoami" in _calls
        assert "create_repo" not in _calls
        assert "upload_folder" not in _calls and "upload_file" not in _calls


def test_flujo_real_con_token_simulado_dry_run() -> None:
    """Con token (whoami OK), --dry-run lista archivos sin llamar a create_repo.

    Cubre la rama feliz de resolución de repo id con namespace y la
    previsualización, sin tocar la red.
    """

    class _FakeApiOK:
        def whoami(self):
            _calls.append("whoami")
            return {"name": "estudiante-prueba"}

        def create_repo(self, *args, **kwargs):
            _calls.append("create_repo")
            raise AssertionError("create_repo no debería llamarse en dry-run")

        def upload_folder(self, *args, **kwargs):
            _calls.append("upload_folder")
            raise AssertionError("upload_folder no debería llamarse en dry-run")

        def upload_file(self, *args, **kwargs):
            _calls.append("upload_file")
            raise AssertionError("upload_file no debería llamarse en dry-run")

    mod = types.ModuleType("huggingface_hub")
    mod.HfApi = _FakeApiOK
    mod.notebook_login = lambda: None
    sys.modules["huggingface_hub"] = mod

    _reset_calls()
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        rc = hf_refuerzos.main(["dataset-a1", "--dry-run"])
    assert rc == 0
    assert "estudiante-prueba/jobs-observed" in out.getvalue(), (
        "repo id debe usar el namespace del usuario autenticado"
    )
    assert "create_repo" not in _calls
    assert "upload_folder" not in _calls


if __name__ == "__main__":
    _install_fake_hub()
    failures = 0
    for fn in (
        test_comandos_degradan_sin_token,
        test_degradacion_con_dry_run_y_repo_id,
        test_flujo_real_con_token_simulado_dry_run,
    ):
        try:
            fn()
            print(f"  [PASS] {fn.__name__}")
        except AssertionError as exc:
            failures += 1
            print(f"  [FAIL] {fn.__name__}: {exc}")
    print("-" * 60)
    print(f"Result: {'PASS' if failures == 0 else 'FAIL'} ({3 - failures}/3 checks)")
    raise SystemExit(1 if failures else 0)
