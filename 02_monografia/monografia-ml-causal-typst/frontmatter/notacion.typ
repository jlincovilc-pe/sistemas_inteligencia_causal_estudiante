// Notación y convenciones
#import "../template/template.typ": *

#chapter[Notación y convenciones]
<sec-notacion>

La siguiente tabla resume los símbolos principales utilizados a lo largo de la monografía.

#figure(
  caption: [Símbolos y convenciones de notación.],
  numbering: none,
  table(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    stroke: none,
    table.hline(stroke: 0.8pt),
    table.header([*Símbolo*], [*Significado*], [*Uso*]),
    table.hline(stroke: 0.4pt),
    [$Y_(i)(d)$], [Resultado potencial bajo tratamiento $d$], [Capítulos 1, 5],
    [$D_i$], [Tratamiento observado], [Todo el libro],
    [$X_i$], [Covariables pre-tratamiento], [Todo el libro],
    [$tau(x)$], [CATE: $E[Y(1) - Y(0) | X = x]$], [Capítulos 5, 12--14, 16--18, 21--22],
    [$theta_0$], [Parámetro causal verdadero], [Capítulos 6, 10--11, 16--17],
    [$"ATE"$ o $theta_("ATE")$], [ATE: $E[tau(X)]$], [Todo el libro],
    [$mu_(d)(x)$], [Outcome condicional: $E[Y | X = x, D = d]$], [Capítulos 5, 11--12, 27],
    [$g_(0)(x)$], [Componente estructural PLR], [Capítulos 10--11],
    [$l_(0)(x)$], [Outcome regression PLR: $E[Y | X = x]$], [Capítulos 10--11],
    [$e_(0)(x)$], [Propensity score: $E[D | X = x]$], [Capítulos 11--14],
    [$m_(0)(x)$], [Tratamiento condicional: $E[D | X = x]$], [Capítulos 10--11],
    [$psi(W, theta, eta)$], [Score ortogonal], [Capítulos 10--11],
    [$eta$], [Nuisance parameter], [Capítulos 10--11],
    [$W_i = (Y_i, D_i, X_i)$], [Observación $i$-ésima], [Todo el libro],
    [$Z_i$], [Instrumento], [Capítulos 16--17],
    [$Y_i^star$], [Transformed outcome], [Capítulos 12--14],
    [$cal(C)$], [Conjunto de ajuste (backdoor)], [Capítulos 3, 8, 29],
    [$bold(W)$], [Matriz de adyacencia (NOTEARS)], [Capítulo 29],
    [$bold(w)$], [Pesos del control sintético], [Capítulo 28],
    [$omega_(i)(x)$], [Pesos locales (GRF)], [Capítulo 13],
    [$cal(V)$], [Varianza asintótica], [Capítulos 10--11],
    [$V(pi)$], [Policy value], [Capítulos 21--22],
    [$G$], [Atributo protegido], [Capítulo 24],
    [$alpha_i$], [Efecto fijo de unidad], [Capítulo 17],
    [$cal(L)_m$], [Hoja $m$-ésima del árbol], [Capítulo 13],
    [$u_i$], [Residuo Robinson (outcome)], [Capítulos 10--11],
    [$v_i$], [Residuo Robinson (tratamiento)], [Capítulos 10--11],
    [$lambda$], [Penalización / multipl. presupuestario], [Capítulos 6, 16, 21--22],
    [$n, N, T$], [Obs. i.i.d. / unidades / periodos], [Todo el libro],
    table.hline(stroke: 0.8pt),
  )
) <tab-notacion>
