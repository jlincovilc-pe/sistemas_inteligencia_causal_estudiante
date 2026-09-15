# `causal-model-card-v1.schema.json`

Contrato machine-readable de la *model card* causal, documentado en el Apéndice G §G.4
de `02_monografia/main.pdf` y referenciado desde los Caps. 15, 19 y 20 de la
monografía. Hasta esta pasada existía solo como *listing* dentro del apéndice — no
como archivo real del monorepo.

- `causal-model-card-v1.schema.json` — el esquema (JSON Schema, Draft 2020-12).
- `ejemplo_valido.json` — instancia de ejemplo basada en los valores reales de
  `model_card/MODEL_CARD.md` (ATE, IC, n, spec del estimador de B1/A2).

## Validar a mano

```bash
python3 -c "
import json, jsonschema
from jsonschema import Draft202012Validator
schema = json.load(open('causal-model-card-v1.schema.json'))
instance = json.load(open('ejemplo_valido.json'))
Draft202012Validator(schema).validate(instance)
print('OK')
"
```

## Qué NO incluye esta pasada (a propósito)

- No se creó `scripts/validar_schema.py` (referenciado en el workflow de CI del
  Cap. 20) ni se modificó `B1_fastapi_dml/app/main.py` — el endpoint `/metadata`
  real hoy devuelve una forma más simple que este esquema (sin `schema_version`,
  `estimando.tipo/formula`, etc.). Cerrar esa brecha implica tocar código que ya
  pasa el autograder `grade_b1.py`, y por regla de esta sesión no se modifica nada
  que afecte la evaluación de los estudiantes sin autorización explícita.
- No se modificó `model_card/MODEL_CARD.md` (Markdown, para personas) — el schema
  es el contrato para la versión machine-readable, no un reemplazo de la card.
