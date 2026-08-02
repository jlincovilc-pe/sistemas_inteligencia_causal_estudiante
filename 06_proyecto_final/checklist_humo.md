# Checklist de humo — proyecto final

## Mínimo viable

- [ ] `GET /health` o Space carga sin error  
- [ ] `POST /predict` o UI devuelve decisión/efecto en < 2 s  
- [ ] Efecto o score en un rango plausible documentado (YAML o README)  
- [ ] Model card con estimando + supuestos + población + límites  
- [ ] Aviso de datos sintéticos visible  

## Script de ejemplo (API)

```bash
curl -sf http://127.0.0.1:8000/health
curl -sf http://127.0.0.1:8000/predict -H 'Content-Type: application/json' -d '{"features":{...}}'
```

## Script de ejemplo (política)

```python
from joblib import load
import numpy as np
pol = load("artifacts/policy.joblib")
print(pol.predict(X=np.zeros((1, n_features))))
```

Alineado a autograders del curso: `grade_b1.py`, `grade_b3.py`.
