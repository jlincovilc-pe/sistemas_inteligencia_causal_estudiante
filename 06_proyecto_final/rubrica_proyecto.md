# Rúbrica del proyecto final (100 pts → 40% del curso)

**Enfoque profesional:** se premia la *decisión de negocio basada en efecto* y el *sistema en HF*, no la novedad metodológica por sí sola.

| Criterio | Pts | Notas |
|---|---:|---|
| Pregunta causal + estimando + supuestos | 12 | DAG o lista de supuestos defendible; población de validez |
| Datos y transparencia | 8 | monorepo (o esquema equivalente); `what_is_real` / synthetic |
| Estimación correcta (ATE y/o CATE) | 15 | código reproducible; sin fuga de truth en entrenamiento |
| **Disrupción: predictivo vs causal** | **15** | *Obligatorio* — ver § abajo |
| Despliegue (API y/o Space en **HF real** o local documentado) | 18 / 13 | **18 pts solo con push real verificable a HF Hub/Space (URL pública o log de subida); 13 pts como techo si es local documentado.** Humo obligatorio en ambos casos |
| Model card causal | 10 | estimando, supuestos, límites (Ap. G) |
| Monitoreo o límites operativos | 8 | drift / alertas / “cuándo no usar” |
| Defensa y claridad (negocio + técnico) | 9 | video + README en 3 capas (Cap. 32) |
| Peer review (calidad de feedback) | 5 | S30 |
| **Total** | **100** | |

**¿Por qué 5 pts de diferencia?** El curso se llama *IA Causal en Producción* con foco en **Hugging Face**: el despliegue real (Hub o Space, con URL pública o log de subida) es la vía esperada y se premia con el techo completo de 18 pts. La opción **local documentada** queda como *resguardo ante fallas de conectividad el día de la entrega*, no como alternativa gratuita: quien la use entrega un sistema que no es consultable desde afuera, y por eso su techo es 13 pts. Los 5 pts de diferencia salen del propio criterio de Despliegue — el total sigue sumando **100**.

**No aprueba** si el humo falla (endpoint/Space caído o predicciones absurdas), **o** si falta la sección de disrupción predictivo vs causal.

---

## Sección obligatoria — Predictivo vs causal (15 pts)

El proyecto debe incluir un artefacto (notebook, informe corto o sección del README) que responda:

1. **Política/ranking predictivo:** p. ej. ordenar por $\hat Y$ o “riesgo” / outcome predicho y tratar al top-B%.  
2. **Política causal:** ordenar por $\hat\tau(x)$ (CATE) o ATE agregado según el caso, con la misma restricción de presupuesto $B$.  
3. **Comparación cuantitativa** de al menos una métrica entre ambas (p. ej. welfare oracle/IPW, Qini, tasa de solapamiento de tratados, o tabla de subgrupos).  
4. **Implicación de negocio en 5–10 líneas:** ¿cambia a quién se trata, el valor esperado o el riesgo de equidad?  

| Subcriterio | Pts | 0 | parcial | pleno |
|---|---:|---|---|---|
| Define baseline predictivo con $B$ claro | 3 | ausente | vago | reproducible |
| Define política causal comparable | 3 | ausente | incompleta | comparable 1:1 |
| Métrica de comparación | 5 | no hay números | una métrica débil | métrica + tabla/figura |
| Narrativa de decisión | 4 | genérica | plausible | concreta y acotada por supuestos |

---

## Alineación monografía / monorepo

- Lectura de apoyo: Caps. 15, 19–22, 30–32; Ap. E, G, H.  
- Código de referencia: Series A/B del monorepo; no es obligatorio reimplementar todo desde cero, pero hay que declarar qué se reutiliza.  
- Plan: `PLAN_INTEGRACION_MONOGRAFIA.md`.
