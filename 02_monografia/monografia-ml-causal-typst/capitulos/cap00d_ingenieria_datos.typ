// Capítulo 4 (nuevo) — Ingeniería de datos para sistemas causales
// Plantilla B: Sesión 4. Arranca el Notebook de caso de estudio #1.
#import "../template/template.typ": *

#chapter[Ingeniería de datos para sistemas causales]
<cap-ingenieria-datos-causales>

#theorem-number-reset()

#cuadrodecision[
  #table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    [*[Decisión]*], [Adoptar un esquema explícito de roles causales sobre los datos, no solo un esquema de tipos],
    [*[Alternativas]*], [Tabla ancha sin metadatos vs. esquema con roles etiquetados (tratamiento/resultado/covariable/instrumento)],
    [*[Trade-off clave]*], [Velocidad de prototipado vs. prevención sistemática de errores de identificación],
    [*[Stack]*], [pandas, Parquet, `pandera` (validación de esquema)],
    [*[Riesgo principal]*], [Que el tratamiento se filtre como covariable, o que una variable post-tratamiento contamine $X$],
  )
]

#monorepo[
  En el monorepo del curso (2026) los datos de práctica viven en #code[data_benchmark_causal/.../datasets/] como *CSV* + #code[metadata.json] (no Parquet obligatorio). Los roles de variables se resuelven con #code[lib.data_io.load_scenario] y el puente #code[lib.schema.CausalSchema.from_scenario("real/jobs")] (API alineada a este capítulo). Labs: #code[L04]–#code[L06]. Entrega: *Notebook A1* (Jobs). Stack: #code[03_notebooks_caso_estudio/lib/].
]

== El problema de diseño
<sec-datoscausales-problema>

La ingeniería de datos "genérica" —la que enseña @huyen2022dmls en su Capítulo 3— se pregunta qué formato de almacenamiento usar, qué modelo de datos (relacional, documento, grafo) es apropiado, y cómo pasar datos entre procesos. Todas esas preguntas siguen siendo relevantes para un sistema causal, pero hay una pregunta adicional, específica, que un pipeline puramente predictivo nunca necesita responder: *¿qué rol estructural juega cada columna del dataset?* En un problema de predicción, todas las columnas de entrada son, en principio, intercambiables: el modelo puede usarlas todas para minimizar el error. En un problema causal, las columnas no son intercambiables en absoluto: una es el *tratamiento* $D$, una es el *resultado* $Y$, algunas son *covariables* $X$ que pueden controlarse legítimamente, y —crucialmente— algunas columnas que *parecen* covariables razonables son en realidad variables *post-tratamiento*, que no deben controlarse porque están en la ruta causal entre $D$ e $Y$ y su inclusión sesga la estimación (un error que retomaremos formalmente en el @cap-intervencion-contrafactual al hablar de "buenos y malos controles").

Si el pipeline de datos no distingue estos roles desde el origen —si todo llega como una tabla ancha sin metadatos— la responsabilidad de no confundirlos recae enteramente en la memoria de quien escribe cada notebook, lo cual falla predeciblemente a medida que el sistema crece y más personas lo tocan.

== Opciones y trade-offs
<sec-datoscausales-opciones>

#opciones[
  - *Tabla ancha sin metadatos.* Cada notebook decide, mediante nombres de columnas hardcodeados en el código, cuál es $D$, cuál es $Y$ y cuáles son $X$. Es la opción más rápida para un análisis único y exploratorio, y la que domina en la práctica académica. Su costo aparece cuando el mismo dataset se reutiliza en varios notebooks o, peor, cuando el pipeline de producción necesita reconstruir las mismas columnas: nada impide que dos notebooks distintos definan a $X$ de forma sutilmente diferente (uno incluye una variable post-tratamiento, el otro no), produciendo estimaciones no comparables sin que nadie lo note.
  - *Esquema con roles etiquetados.* Se declara, en un único lugar (un archivo de configuración o una clase de datos), qué columna es el tratamiento, cuál el resultado, cuáles son covariables válidas para controlar, y cuáles son instrumentos si los hay. Todo notebook y todo servicio de producción consume ese esquema en lugar de hardcodear nombres de columnas. El costo es la fricción inicial de definir el esquema antes de poder "simplemente correr una regresión".
]

Un segundo trade-off, heredado directamente de @huyen2022dmls Capítulo 3, es el de formato de almacenamiento: formatos orientados a fila (CSV, JSON) son más simples de inspeccionar manualmente pero más lentos para leer solo un subconjunto de columnas —exactamente lo que un pipeline de estimación causal necesita hacer repetidamente (leer $Y$, $D$ y un subconjunto de $X$, sin cargar el resto)—; formatos orientados a columna (Parquet) son más eficientes para ese patrón de acceso y, además, permiten adjuntar metadatos de esquema directamente en el archivo.

== Decisión de referencia para el curso
<sec-datoscausales-decision>

Todos los datasets usados en el curso —tanto en la Serie A (casos de estudio) como en la Serie B (producción)— se acompañan de un *esquema de roles causales* explícito, almacenado junto con los datos en formato Parquet. El esquema mínimo declara cuatro listas de nombres de columna: `treatment`, `outcome`, `covariates` y, cuando aplica, `instruments`. Ninguna función de estimación del curso acepta un DataFrame "pelado"; todas reciben el DataFrame junto con su esquema, de modo que sea sintácticamente imposible, por ejemplo, pasar el tratamiento como una covariable por accidente.

== Implementación de referencia
<sec-datoscausales-implementacion>

#figure(
  kind: raw,
  caption: [Esquema de roles causales como estructura de datos explícita.],
  ```python
from dataclasses import dataclass, field
import pandas as pd

@dataclass
class CausalSchema:
    treatment: str
    outcome: str
    covariates: list[str]
    instruments: list[str] = field(default_factory=list)

    def validate(self, df: pd.DataFrame) -> None:
        declared = {self.treatment, self.outcome, *self.covariates, *self.instruments}
        missing = declared - set(df.columns)
        if missing:
            raise ValueError(f"Columnas declaradas en el esquema pero ausentes: {missing}")
        overlap = set(self.covariates) & {self.treatment, self.outcome}
        if overlap:
            raise ValueError(f"El tratamiento o el resultado no pueden ser covariables: {overlap}")

    def X(self, df: pd.DataFrame) -> pd.DataFrame:
        return df[self.covariates]

    def D(self, df: pd.DataFrame) -> pd.Series:
        return df[self.treatment]

    def Y(self, df: pd.DataFrame) -> pd.Series:
        return df[self.outcome]


# Ejemplo: dataset de retornos a la educacion (Card, 1995)
schema = CausalSchema(
    treatment="educ",
    outcome="wage",
    covariates=["exper", "black", "south", "married"],
    instruments=["nearc4"],
)
df = pd.read_parquet("data/close_college.parquet")
schema.validate(df)  # lanza error si, p.ej., "educ" quedo tambien en covariates
```
) <lst-causal-schema>

Este patrón —trivial en apariencia— es exactamente el tipo de decisión de infraestructura que @huyen2022dmls argumenta que rara vez se enseña y que sistemáticamente se paga como deuda técnica más adelante (@sculley2015hiddendebt).

== Aplicación al sistema causal del curso
<sec-datoscausales-aplicacion>

El Notebook de caso de estudio A1 (Módulo 1 del curso) exige explícitamente construir el `CausalSchema` del dataset elegido *antes* de correr ninguna estimación, precisamente para forzar la pregunta de identificación (@cap-causalidad-elemental, @cap-scm-pch) a un paso de ingeniería concreto y verificable, en vez de dejarla implícita en la cabeza de quien analiza los datos. Este mismo esquema reaparece, sin cambios, en el Notebook de producción B1 (despliegue del primer endpoint, Capítulo 15): la función de inferencia en producción usa `schema.covariates` para saber exactamente qué columnas esperar del cliente que consulta el servicio, cerrando el círculo entre el notebook de entrenamiento y el servicio desplegado.

== Señales de alerta y checklist operativo
<sec-datoscausales-alertas>

#checklist[
  - El nombre de la columna de tratamiento aparece hardcodeado en más de un notebook, con riesgo de que diverja.
  - Ninguna función de carga de datos valida que el tratamiento y el resultado no estén también en la lista de covariables.
  - No hay forma de saber, sin leer el código de generación de features, si alguna covariable fue medida *después* del tratamiento.
  - El formato de almacenamiento (CSV plano) obliga a cargar todas las columnas para leer solo tres.
]

== Ejercicios y notas bibliográficas
<sec-datoscausales-ejercicios>

=== Ejercicios conceptuales
<sec-datoscausales-ejercicios-conceptuales>

+ Para el dataset de becas del @cap-causalidad-elemental, proponga tres covariables legítimas para $X$ y una variable que, aunque correlacionada con el resultado, sería incorrecto incluir en $X$ por ser post-tratamiento. Justifique.

+ Explique por qué un esquema de roles causales explícito es más importante en un sistema con varios notebooks y varios colaboradores que en un análisis individual de una sola vez.

=== Ejercicio de infraestructura
<sec-datoscausales-ejercicios-infra>

+ Extienda la clase `CausalSchema` del listado @lst-causal-schema con un método `summary()` que imprima, para cada rol, el número de valores faltantes y el tipo de dato de las columnas correspondientes. Aplíquelo al dataset que usará en el Notebook A1.

=== Notas bibliográficas
<sec-datoscausales-notas>

@huyen2022dmls, Capítulo 3, desarrolla en profundidad los formatos y modelos de datos genéricos que este capítulo adapta al caso causal. La distinción entre controles legítimos y variables post-tratamiento se formaliza en el @cap-intervencion-contrafactual con el lenguaje de grafos causales; véase también la discusión de "buenos y malos controles" en @bareinboim2025causalai.
