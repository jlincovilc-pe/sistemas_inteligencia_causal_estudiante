// ============================================================
//  IA Causal en Producción — Edición 2026
//  Monografía del Curso ECO-490 / ECON-540
// ============================================================

#import "template/template.typ": *

#show: project

// ============================
//  Frontmatter (numeración romana)
// ============================
#frontmatter[
  #include "frontmatter/portada.typ"
  #include "frontmatter/colofon.typ"
  #include "frontmatter/prefacio.typ"
  #include "frontmatter/como_usar.typ"
  #include "frontmatter/notacion.typ"

  // Índices separados (cada uno en su propia página)
  #pagebreak()
  #outline(title: [Índice general], depth: 3, indent: auto)
  #pagebreak()
  #outline(title: [Índice de figuras], target: figure.where(kind: image))
  #pagebreak()
  #outline(title: [Índice de tablas], target: figure.where(kind: table))
  #pagebreak()
  #outline(title: [Índice de algoritmos], target: figure.where(kind: "algorithm"))
  #pagebreak()
  #outline(title: [Índice de listados], target: figure.where(kind: raw))
]

// ============================
//  Mainmatter (numeración arábiga, capítulos 1-32)
// ============================
#mainmatter[

  // --- Parte 0: Introducción --------------------------------
  #include "partes/parte0.typ"
  #include "capitulos/cap00_causalidad_elemental.typ"        // Cap. 1
  #include "capitulos/cap00b_anatomia_sistema.typ"            // Cap. 2

  // --- Parte I: Fundamentos estructurales y de datos --------
  #include "partes/parte1.typ"
  #include "capitulos/cap00c_scm_pch.typ"                     // Cap. 3
  #include "capitulos/cap00d_ingenieria_datos.typ"             // Cap. 4
  #include "capitulos/cap01_prediccion_causalidad.typ"         // Cap. 5
  #include "capitulos/cap02_regularizacion_postseleccion.typ"  // Cap. 6
  #include "capitulos/cap02b_datos_entrenamiento.typ"          // Cap. 7
  #include "capitulos/cap02c_intervencion_contrafactual.typ"   // Cap. 8
  #include "capitulos/cap02d_features_sin_fuga.typ"            // Cap. 9

  // --- Parte II: Estimación causal flexible y primer despliegue
  #include "partes/parte2.typ"
  #include "capitulos/cap03_ortogonalidad_crossfitting.typ"    // Cap. 10
  #include "capitulos/cap04_dml.typ"                           // Cap. 11
  #include "capitulos/cap05_metalearners.typ"                  // Cap. 12
  #include "capitulos/cap06_arboles_bosques.typ"                // Cap. 13
  #include "capitulos/cap07_validacion.typ"                     // Cap. 14
  #include "capitulos/cap07b_despliegue_servicio.typ"           // Cap. 15

  // --- Parte III: Diseños de identificación con ML -----------
  #include "partes/parte3.typ"
  #include "capitulos/cap08_pds.typ"                            // Cap. 16
  #include "capitulos/cap09_panel_dmliv.typ"                    // Cap. 17
  #include "capitulos/cap10_mapa_decision.typ"                  // Cap. 18

  // --- Parte IV: Publicación y operación en producción -------
  #include "partes/parte4.typ"
  #include "capitulos/cap10b_hf_hub.typ"                        // Cap. 19
  #include "capitulos/cap10c_cicd.typ"                          // Cap. 20

  // --- Parte V: Heterogeneidad, políticas y targeting --------
  #include "partes/parte5.typ"
  #include "capitulos/cap11_policy_learning.typ"                // Cap. 21
  #include "capitulos/cap12_uplift_targeting.typ"                // Cap. 22

  // --- Parte VI: Explicación, equidad y decisión estructural -
  #include "partes/parte6.typ"
  #include "capitulos/cap12b_explicacion_equidad.typ"           // Cap. 23
  #include "capitulos/cap16_etica_interpretabilidad.typ"         // Cap. 24
  #include "capitulos/cap12c_decisiones_estructurales.typ"       // Cap. 25
  #include "capitulos/cap12d_generalizacion.typ"                 // Cap. 26

  // --- Parte VII: Métodos avanzados ---------------------------
  #include "partes/parte7.typ"
  #include "capitulos/cap13_deep_causal.typ"                     // Cap. 27
  #include "capitulos/cap14_scm_matrix_completion.typ"           // Cap. 28

  // --- Parte VIII: Estructura, monitoreo y frontera -----------
  #include "partes/parte8.typ"
  #include "capitulos/cap15_descubrimiento_grafos.typ"           // Cap. 29
  #include "capitulos/cap15b_monitoreo.typ"                      // Cap. 30
  #include "capitulos/cap15c_aprendizaje_continuo.typ"           // Cap. 31
  #include "capitulos/cap15d_lado_humano.typ"                    // Cap. 32

]

// ============================
//  Apéndices (numeración A, B, C, ...)
// ============================
#appendix-mode[
  #include "apendices/apA_notacion_fundamentos.typ"
  #include "apendices/apB_librerias_entorno.typ"
  #include "apendices/apC_datos_dgp.typ"
  #include "apendices/apD_glosario.typ"
  #include "apendices/apE_proyecto_rubrica.typ"
  #include "apendices/apF_checklists.typ"
  #include "apendices/apG_model_card_causal.typ"
  #include "apendices/apH_checklist_despliegue.typ"
]

// ============================
//  Bibliografía
// ============================
#pagebreak()
#bibliography("bibliografia/refs.yml", title: "Bibliografía", style: "chicago-author-date")
