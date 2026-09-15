# Checklist de humo — proyecto final

## Mínimo viable

- [ ] `GET /health` o Space carga sin error  
- [ ] `POST /predict` o UI devuelve decisión/efecto en < 2 s  
- [ ] Efecto o score en un rango plausible documentado (YAML o README)  
- [ ] Model card con estimando + supuestos + población + límites  
- [ ] Aviso de datos sintéticos visible  

## Despliegue real en Hugging Face (opcional, pero visible)

- [ ] URL del Space o del repo del Hub **viva** antes de la defensa en video (S31): abrir `https://huggingface.co/<usuario>/<repo>` y confirmar que la App / README carga y responde  
- [ ] (Si aplica) guardar el log de subida o la URL pública como evidencia verificable del push (rúbrica: 18 pts con push real vs 13 pts local)  

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
