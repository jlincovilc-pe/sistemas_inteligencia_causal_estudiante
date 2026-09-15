# IA Causal en Producción — Monorepo del curso

Curso ECO-490 / ECON-540 (2026): causalidad estructural + estimación con ML + ingeniería de sistemas en Hugging Face.  
**16 semanas · 32 sesiones · 50% teoría / 50% producción.**

> **Sin CI en la nube.** Este monorepo se ejecuta y audita en local; no hay publicación automática configurada.  
> La Serie B *enseña* conceptos de HF (API, model card, Space, monitor); el push a Hub es **opcional y manual** del estudiante en su propia cuenta.

## Fuente de verdad

| Documento | Rol |
|---|---|
| [`01_silabo/silabo.pdf`](./01_silabo/silabo.pdf) | Calendario oficial: qué se evalúa y cuándo se entrega |
| [`PLAN_CURSO_COMPLETO.md`](./PLAN_CURSO_COMPLETO.md) | Práctica: sesiones, labs, A/B, datos, DoD de código |
| [`PLAN_INTEGRACION_MONOGRAFIA.md`](./PLAN_INTEGRACION_MONOGRAFIA.md) | Integración libro ↔ monorepo (profesionales, HF, efecto causal) |
| [`CHRONOGRAMA_SEMANAL.md`](./CHRONOGRAMA_SEMANAL.md) | Semana a semana: material del profesor y del estudiante |
| [`docs/NOTA_INSTRUCTORS.md`](./docs/NOTA_INSTRUCTORS.md) | Camino ★ vs electivos ◇ |
| [`02_monografia/`](./02_monografia/) | Monografía Typst 32 caps. + PDF |

**Posicionamiento:** curso para **profesionales** — estudios de caso, puesta en producción (HF opcional), utilidad de **estimar efectos** frente a solo predecir.

Si hay conflicto de **código/entregas**, manda el plan de práctica. Si hay conflicto de **numeración de capítulos del PDF**, manda el plan de integración + monografía.

Esta tabla es el mapa **por documento** (qué archivo manda en general). Para el mapa **por pregunta** (qué código corre, qué es electivo, diseño histórico, etc.) ver [`PLAN_INTEGRACION_MONOGRAFIA.md` §9](./PLAN_INTEGRACION_MONOGRAFIA.md#9-gobernanza-de-fuentes-de-verdad) — ambas tablas son consistentes entre sí y no se duplican.

---

## Mapa del repositorio

| Carpeta | Contenido |
|---|---|
| [`01_silabo/`](./01_silabo/) | Sílabo Typst + PDF (§12 cronograma) |
| [`02_monografia/`](./02_monografia/) | Monografía 32 caps. + PDF compilado |
| [`03_notebooks_caso_estudio/`](./03_notebooks_caso_estudio/) | Serie A (A1–A4) + `lib/` + autograders + tests |
| [`04_notebooks_produccion_hf/`](./04_notebooks_produccion_hf/) | Serie B (B1–B4): API, card/CI plantilla, Space, monitor |
| [`05_labs_sesion/`](./05_labs_sesion/) | 27 labs L01–L28 (sin L16) |
| [`06_proyecto_final/`](./06_proyecto_final/) | Guía + rúbrica + checklist humo |
| [`07_diapositivas/`](./07_diapositivas/) | 32 mazos Touying por capítulo (PDF 1–32) |
| [`data_benchmark_causal/`](./data_benchmark_causal/) | Datasets del curso (Jobs, IHDP, sintéticos, …) |
| [`scripts/audit_repo.sh`](./scripts/audit_repo.sh) | Auditoría local de práctica |

---

## Modelo pedagógico

```text
Sesión 90 min  →  capítulo monografía + lab corto L##  (formativo)
Bloque 2–3 sem →  entrega A# o B#                     (sumativa)
Semanas 15–16  →  proyecto final (HF opcional)        (40%)
```

**~27 labs** + **8 entregas (4A+4B)** + **proyecto**. No hay 32 notebooks de entrega.

### Serie A

| ID | Dataset | Sesiones |
|---|---|---|
| A1 | `real/jobs` | S4–S6 |
| A2 | `synthetic/inference/ihdp_medium` | S8–S11 → artefacto B1 |
| A3 | `real/ihdp` | S13–S15 |
| A4 | `real/ihdp` | S22–S23 → artefacto B3 |

### Serie B (todo ejecutable en local)

| ID | Insumo | Qué se practica |
|---|---|---|
| B1 | A2 joblib | FastAPI + Docker (local) |
| B2 | B1 | Model card + plantilla CI (sin Actions en la nube) |
| B3 | A4 policy | Gradio Space (local; push HF opcional) |
| B4 | drift sim. | Dashboard de monitoreo (local) |

### Hugging Face como hilo conductor

El curso tiene **10 puntos de contacto** con Hugging Face: **4 de refuerzo corto**
(cierre de 10 min) en S2 (setup cuenta/token), S5 (dataset A1 al Hub), S8 (dataset
limpio A2 al Hub) y S13 (modelo DML A2 al Hub); y **6 de contenido central** en S12
(endpoint B1), S17 (Hub/model cards B2), S18 (CI/CD B2), S23 (Space B3), S25
(monitoreo B4) y S31 (aprendizaje continuo/RL). Detalle en el sílabo §7.1.

---

## Instalación

Requisitos comunes a los tres sistemas operativos:

- **Git** (para clonar el repo).
- **Python 3.10+** (probado con 3.10–3.12).
- **Docker** — solo si vas a levantar el servicio B1 en contenedor (opcional; Docker Desktop en macOS/Windows, Docker Engine en Linux).

Cada carpeta de entrega (`03_notebooks_caso_estudio/`, `04_notebooks_produccion_hf/B*/`) trae su propio
`requirements.txt` (o `environment.yml`) y usa un `.venv` **local, no versionado** — se recrea en cada
máquina, no se comparte entre SO.

### Clonar el repositorio (igual en los tres SO)

```bash
git clone <URL-del-repo>
cd repositorio_causal_ml_produccion_estudiante
```

### Linux

```bash
cd 03_notebooks_caso_estudio
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest tests/ -q
```

Si `econml`/`doubleml` fallan al compilar, instala las cabeceras de build de tu distro
(ej. Ubuntu/Debian: `sudo apt install build-essential python3-dev`) o usa la alternativa
conda de abajo.

### macOS

```bash
cd 03_notebooks_caso_estudio
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest tests/ -q
```

Requiere las Command Line Tools de Xcode para compilar `econml`/`doubleml`
(`xcode-select --install` si no las tienes). En Apple Silicon, si `pip install` falla
para algún paquete científico, usa la alternativa conda de abajo (Miniforge).

### Windows

**PowerShell** (nativo, sin WSL):

```powershell
cd 03_notebooks_caso_estudio
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pytest tests/ -q
```

Si PowerShell bloquea la activación del entorno (`No se puede cargar el archivo... no
está firmado digitalmente`), habilita scripts para tu usuario una vez:
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

`econml`/`doubleml` pueden requerir los **Microsoft C++ Build Tools**
([visualstudio.microsoft.com/visual-cpp-build-tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/))
para compilar dependencias nativas. Si prefieres evitarlo, usa la alternativa conda de
abajo, que trae binarios precompilados.

Los dos scripts en Bash del repo (`scripts/audit_repo.sh` y
`04_notebooks_produccion_hf/B2_hub_cicd/scripts/prepare_hub_bundle.sh`) **no corren en
PowerShell/CMD nativos** — necesitas [Git Bash](https://git-scm.com/downloads) (se
instala junto con Git para Windows) o WSL para ejecutarlos.

### Alternativa multiplataforma: conda/mamba (recomendada si `pip` da problemas)

Evita compilar nada a mano; usa binarios precompilados en cualquier SO:

```bash
cd 03_notebooks_caso_estudio
conda env create -f environment.yml
conda activate causal-serie-a
pytest tests/ -q
```

### B1 (FastAPI + Docker) — mismos comandos en los tres SO

```bash
cd 04_notebooks_produccion_hf/B1_fastapi_dml
python -m venv .venv          # Windows: python  |  Linux/macOS: python3
source .venv/bin/activate     # Windows PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
pytest tests/ -q && python ../autograder/grade_b1.py
```

---

## Auditoría local

Linux/macOS, o Windows vía Git Bash/WSL:

```bash
bash scripts/audit_repo.sh
```

Compileall · pytest A · pytest labs · pytest B1 · grade A1–A4 · grade B1–B4 · sync de artefactos.

Plantilla educativa de CI (no activa):  
`04_notebooks_produccion_hf/B2_hub_cicd/templates/b1_smoke.yml`

---

## Git

```bash
git status
git pull
```

---

## Licencia y citación

Todo el repositorio se publica bajo licencia **MIT** — ver [`LICENSE`](./LICENSE).  
Los benchmarks en `data_benchmark_causal/` incluyen además su propio `LICENSE` (MIT) por submódulo.  
Citar fuentes originales de escenarios (Sachs, Hill, LaLonde, etc.) según `CITATION.cff`.
