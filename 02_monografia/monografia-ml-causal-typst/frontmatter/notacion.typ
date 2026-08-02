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
    [$Y_i(d)$], [Resultado potencial bajo tratamiento $d$], [Capítulo 1],
    [$D_i$], [Tratamiento observado], [Todo el libro],
    [$X_i$], [Covariables pre-tratamiento], [Todo el libro],
    [$tau(x)$], [CATE: $E[Y(1) - Y(0) mid X = x]$], [Capítulos 1, 5--12],
    [$theta_0$], [Parámetro causal verdadero], [Capítulos 2--4, 8--9],
    [$"ATE"$ o $theta_("ATE")$], [ATE: $E[tau(X)]$], [Todo el libro],
    [$mu_d(x)$], [Outcome condicional: $E[Y mid X = x, D = d]$], [Capítulos 1, 4--5, 13],
    [$g_0(x)$], [Componente estructural PLR], [Capítulos 3--4],
    [$l_0(x)$], [Outcome regression PLR: $E[Y mid X = x]$], [Capítulos 3--4],
    [$e_0(x)$], [Propensity score: $E[D mid X = x]$], [Capítulos 4--7],
    [$m_0(x)$], [Tratamiento condicional: $E[D mid X = x]$], [Capítulos 3--4],
    [$psi(W, theta, eta)$], [Score ortogonal], [Capítulos 3--4],
    [$eta$], [Nuisance parameter], [Capítulos 3--4],
    [$W_i = (Y_i, D_i, X_i)$], [Observación $i$-ésima], [Todo el libro],
    [$Z_i$], [Instrumento], [Capítulos 8--9],
    [$Y_i^star$], [Transformed outcome], [Capítulos 5--7],
    [$cal(C)$], [Conjunto de ajuste (backdoor)], [Capítulos 1, 15],
    [$bold(W)$], [Matriz de adyacencia (NOTEARS)], [Capítulo 15],
    [$bold(w)$], [Pesos del control sintético], [Capítulo 14],
    [$omega_i(x)$], [Pesos locales (GRF)], [Capítulo 6],
    [$cal(V)$], [Varianza asintótica], [Capítulos 3--4],
    [$V(pi)$], [Policy value], [Capítulos 11--12],
    [$G$], [Atributo protegido], [Capítulo 16],
    [$alpha_i$], [Efecto fijo de unidad], [Capítulo 9],
    [$cal(L)_m$], [Hoja $m$-ésima del árbol], [Capítulo 6],
    [$u_i$], [Residuo Robinson (outcome)], [Capítulos 3--4],
    [$v_i$], [Residuo Robinson (tratamiento)], [Capítulos 3--4],
    [$lambda$], [Penalización / multipl. presupuestario], [Capítulos 2, 8, 11--12],
    [$n, N, T$], [Obs. i.i.d. / unidades / periodos], [Todo el libro],
    table.hline(stroke: 0.8pt),
  )
) <tab-notacion>
