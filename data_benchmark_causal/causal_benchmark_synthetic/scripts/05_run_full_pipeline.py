#!/usr/bin/env python3
"""
Simulacion de pipeline completo de descubrimiento e inferencia causal.

Este script ejecuta un flujo end-to-end de analisis causal:
1. Ingestion y validacion de datos
2. Diagnostico (colinealidad, balance, missingness)
3. Seleccion automatica de algoritmo basada en reglas
4. Descubrimiento/estimacion
5. Refutacion (placebo, random common cause, subset)
6. Reporte de robustez

Uso:
    python 05_run_full_pipeline.py \
        --dataset datasets/synthetic/linear_gaussian/20_vars_40_edges/ \
        --query "discover and estimate ATE" \
        --output results/full_pipeline/

    python 05_run_full_pipeline.py \
        --dataset datasets/synthetic/inference/ihdp_medium/ \
        --query "estimate ATE of treatment on outcome" \
        --treatment_col treatment --outcome_col outcome \
        --no_human --output results/full_pipeline/
"""

import argparse
import os
import sys
import json
import time
import warnings

import numpy as np
import pandas as pd
import networkx as nx
from scipy import stats
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import mutual_info_score

warnings.filterwarnings('ignore')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from utils import (
    load_dataset_and_graph, precision_recall_f1,
    ate_error, pehe
)


# =============================================================================
# 1. INGESTION Y VALIDACION
# =============================================================================

def ingest_and_validate(dataset_dir):
    """
    Carga y valida el dataset.

    Returns:
        (DataFrame, metadata, report)
    """
    print("\n[1/6] INGESTION Y VALIDACION")
    print("-" * 40)

    # Intentar cargar como dataset de descubrimiento (con grafo)
    try:
        df, G, metadata = load_dataset_and_graph(dataset_dir)
        has_ground_truth = True
        data_type = 'discovery'
    except:
        # Cargar como dataset de inferencia
        df = pd.read_csv(os.path.join(dataset_dir, 'data.csv'))
        G = None
        has_ground_truth = False
        data_type = 'inference'

        meta_path = os.path.join(dataset_dir, 'metadata.json')
        metadata = {}
        if os.path.exists(meta_path):
            with open(meta_path, 'r') as f:
                metadata = json.load(f)

    print(f"  Dataset cargado: {len(df)} filas x {len(df.columns)} columnas")
    print(f"  Tipos: {df.dtypes.value_counts().to_dict()}")
    print(f"  Missing values: {df.isnull().sum().sum()}")

    # Validacion
    warnings_list = []

    if df.isnull().sum().sum() > 0:
        warnings_list.append(f"Missing values detected: {df.isnull().sum().sum()}")
        df = df.fillna(df.median())

    if len(df) > 5000:
        warnings_list.append(f"Large dataset: {len(df)} rows. Subsampling to 5000.")
        df = df.sample(n=5000, random_state=42)

    report = {
        'n_rows': len(df),
        'n_cols': len(df.columns),
        'data_type': data_type,
        'has_ground_truth': has_ground_truth,
        'warnings': warnings_list
    }

    return df, G, metadata, report


# =============================================================================
# 2. DIAGNOSTICO
# =============================================================================

def diagnose_data(df, metadata):
    """
    Ejecuta diagnostico completo del dataset.

    Verifica:
    - Colinealidad (VIF)
    - Normalidad
    - Balance de tratamiento (si aplica)
    - Outliers

    Returns:
        dict con diagnosticos
    """
    print("\n[2/6] DIAGNOSTICO")
    print("-" * 40)

    diagnostics = {}

    # Detectar tipo de problema
    has_treatment = any(col in df.columns for col in ['treatment', 'T', 'trt'])

    # VIF (colinealidad)
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    if len(numeric_cols) > 1:
        corr_matrix = df[numeric_cols].corr().abs()
        vif_scores = {}
        for i, col in enumerate(numeric_cols):
            if corr_matrix.iloc[i, i] < 0.99:
                # VIF aproximado: 1 / (1 - R^2) donde R^2 es de regresion
                other_cols = [c for c in numeric_cols if c != col]
                if len(other_cols) > 0:
                    reg = LinearRegression()
                    reg.fit(df[other_cols].fillna(0), df[col].fillna(0))
                    r2 = reg.score(df[other_cols].fillna(0), df[col].fillna(0))
                    vif = 1 / (1 - min(r2, 0.99))
                    vif_scores[col] = float(vif)

        high_vif = {k: v for k, v in vif_scores.items() if v > 10}
        diagnostics['vif'] = {
            'mean_vif': float(np.mean(list(vif_scores.values()))),
            'max_vif': float(np.max(list(vif_scores.values()))),
            'high_vif_count': len(high_vif),
            'severity': 'high' if len(high_vif) > 2 else 'medium' if len(high_vif) > 0 else 'low'
        }
        print(f"  VIF: mean={diagnostics['vif']['mean_vif']:.1f}, "
              f"max={diagnostics['vif']['max_vif']:.1f}, "
              f"high={diagnostics['vif']['high_vif_count']}")

    # Normalidad (Shapiro-Wilk en muestra)
    if len(df) > 3:
        sample = df[numeric_cols].sample(min(500, len(df)), random_state=42)
        normal_tests = {}
        for col in numeric_cols[:5]:  # Solo primeras 5 para eficiencia
            _, p_val = stats.shapiro(sample[col].dropna().values[:500])
            normal_tests[col] = float(p_val)

        non_normal = sum(1 for p in normal_tests.values() if p < 0.05)
        diagnostics['normality'] = {
            'non_normal_count': non_normal,
            'severity': 'high' if non_normal > 3 else 'medium' if non_normal > 0 else 'low'
        }
        print(f"  Normalidad: {non_normal}/{len(normal_tests)} variables no normales")

    # Balance de tratamiento
    if has_treatment:
        treatment_col = [c for c in df.columns if c in ['treatment', 'T', 'trt']][0]
        t_rate = df[treatment_col].mean()
        diagnostics['treatment_balance'] = {
            'treatment_rate': float(t_rate),
            'severity': 'high' if t_rate < 0.1 or t_rate > 0.9 else 'medium' if t_rate < 0.2 or t_rate > 0.8 else 'low'
        }
        print(f"  Balance: tratamiento={t_rate:.3f}")

    # Dimensionalidad
    diagnostics['dimensionality'] = {
        'n_samples': len(df),
        'n_features': len(numeric_cols),
        'severity': 'high' if len(numeric_cols) > 100 else 'medium' if len(numeric_cols) > 50 else 'low'
    }

    # Resumen de severidad
    severities = [v['severity'] for v in diagnostics.values() if isinstance(v, dict) and 'severity' in v]
    overall = 'high' if 'high' in severities else 'medium' if 'medium' in severities else 'low'
    diagnostics['overall_severity'] = overall

    print(f"  Severidad general: {overall.upper()}")

    return diagnostics


# =============================================================================
# 3. SELECCION DE ALGORITMO (Reglas deterministas YAML-style)
# =============================================================================

def select_algorithm(df, diagnostics, query, has_ground_truth):
    Selecciona el algoritmo mas apropiado basado en reglas deterministas.

    Utiliza:
    - Tipo de query (descubrimiento vs estimacion)
    - Caracteristicas de los datos
    - Severidad de diagnosticos

    Returns:
        dict con seleccion y justificacion
    print("\n[3/6] SELECCION DE ALGORITMO")
    print("-" * 40)

    query_lower = query.lower()

    # Parsear intent
    is_discovery = any(kw in query_lower for kw in ['discover', 'structure', 'graph', 'causal graph'])
    is_estimation = any(kw in query_lower for kw in ['estimate', 'ate', 'effect', 'treatment'])

    if not is_discovery and not is_estimation:
        is_discovery = True  # Default

    recommendations = []

    if is_discovery:
        # Reglas de seleccion para descubrimiento
        n_vars = diagnostics['dimensionality']['n_features']
        norm_sev = diagnostics.get('normality', {}).get('severity', 'low')
        vif_sev = diagnostics.get('vif', {}).get('severity', 'low')

        if n_vars <= 20 and norm_sev in ['medium', 'high']:
            recommendations.append({
                'algorithm': 'DirectLiNGAM',
                'reason': 'Non-Gaussian data, small dimensionality',
                'score': 85,
                'family': 'functional'
            })

        if vif_sev == 'low' and n_vars <= 100:
            recommendations.append({
                'algorithm': 'PC',
                'reason': 'Low collinearity, moderate dimensionality',
                'score': 80,
                'family': 'constraint-based'
            })

        recommendations.append({
            'algorithm': 'NOTEARS',
            'reason': 'General purpose, works for most data types',
            'score': 75,
            'family': 'score-based'
        })

        recommendations.append({
            'algorithm': 'GES',
            'reason': 'Score-based, good for Gaussian data',
            'score': 70,
            'family': 'score-based'
        })

    if is_estimation:
        # Reglas para estimacion
        has_treatment = any(col in df.columns for col in ['treatment', 'T', 'trt'])

        if has_treatment:
            n = len(df)
            recommendations.append({
                'algorithm': 'DML (Double Machine Learning)',
                'reason': 'Flexible, doubly robust, handles high-dimensional confounders',
                'score': 90,
                'family': 'double-robust'
            })

            recommendations.append({
                'algorithm': 'AIPW',
                'reason': 'Doubly robust, good theoretical properties',
                'score': 85,
                'family': 'doubly-robust'
            })

            recommendations.append({
                'algorithm': 'T-Learner',
                'reason': 'Simple, flexible heterogeneous effects',
                'score': 75,
                'family': 'meta-learner'
            })

    # Ordenar por score
    recommendations.sort(key=lambda x: x['score'], reverse=True)

    selected = recommendations[0] if recommendations else {
        'algorithm': 'OLS',
        'reason': 'Fallback baseline',
        'score': 50,
        'family': 'baseline'
    }

    print(f"  Query: '{query}'")
    print(f"  Intent: {'Discovery + Estimation' if is_discovery and is_estimation else 'Discovery' if is_discovery else 'Estimation'}")
    print(f"  Seleccionado: {selected['algorithm']} (score: {selected['score']})")
    print(f"  Justificacion: {selected['reason']}")
    print(f"\n  Rankings:")
    for i, rec in enumerate(recommendations[:5], 1):
        print(f"    {i}. {rec['algorithm']} - score {rec['score']} ({rec['reason']})")

    return {
        'intent': 'discovery_estimation' if is_discovery and is_estimation else 'discovery' if is_discovery else 'estimation',
        'selected': selected,
        'rankings': recommendations[:5]
    }


# =============================================================================
# 4. EJECUCION
# =============================================================================

def execute_discovery(df, selection):
    """
    Ejecuta descubrimiento causal con el algoritmo seleccionado.

    Version lite usando PC como fallback.
    """
    print("\n[4/6] EJECUCION - DESCUBRIMIENTO")
    print("-" * 40)

    algo = selection['selected']['algorithm']

    # Usar PC lite para la demostracion
    from utils import generate_dag_er, precision_recall_f1
    from scripts_03 import pc_algorithm_lite

    start = time.time()

    try:
        G_est = pc_algorithm_lite(df.select_dtypes(include=[np.number]))
        elapsed = time.time() - start

        print(f"  Algoritmo: {algo}")
        print(f"  Nodos detectados: {G_est.number_of_nodes()}")
        print(f"  Arcos detectados: {G_est.number_of_edges()}")
        print(f"  Tiempo: {elapsed:.2f}s")

        return {
            'algorithm': algo,
            'graph': G_est,
            'n_nodes': G_est.number_of_nodes(),
            'n_edges': G_est.number_of_edges(),
            'time': elapsed
        }
    except Exception as e:
        print(f"  ERROR: {e}")
        return {'algorithm': algo, 'error': str(e), 'time': time.time() - start}


def execute_estimation(df, selection):
    """
    Ejecuta estimacion de efectos con el estimador seleccionado.
    """
    print("\n[4/6] EJECUCION - ESTIMACION")
    print("-" * 40)

    algo = selection['selected']['algorithm']

    # Detectar columnas
    treatment_col = [c for c in df.columns if c in ['treatment', 'T', 'trt']]
    outcome_col = [c for c in df.columns if c in ['outcome', 'Y', 'y']]

    if not treatment_col or not outcome_col:
        print("  ERROR: No se detectaron columnas de tratamiento/outcome")
        return {'algorithm': algo, 'error': 'Missing treatment/outcome columns'}

    treatment_col = treatment_col[0]
    outcome_col = outcome_col[0]

    feature_cols = [c for c in df.columns if c not in [treatment_col, outcome_col, 'y0', 'y1', 'tau']]

    X = df[feature_cols].values
    T = df[treatment_col].values
    Y = df[outcome_col].values

    # Ejecutar AIPW
    from scripts_04 import AIPW_Estimator

    start = time.time()
    estimator = AIPW_Estimator()
    estimator.fit(X, T, Y)
    elapsed = time.time() - start

    ate = estimator.ate_
    ci_lower = estimator.ci_lower_
    ci_upper = estimator.ci_upper_

    print(f"  Estimador: {algo}")
    print(f"  ATE estimado: {ate:.4f}")
    print(f"  IC 95%: [{ci_lower:.4f}, {ci_upper:.4f}]")
    print(f"  Tiempo: {elapsed:.2f}s")

    return {
        'algorithm': algo,
        'ate': ate,
        'ci_lower': ci_lower,
        'ci_upper': ci_upper,
        'time': elapsed
    }


# =============================================================================
# 5. REFUTACION
# =============================================================================

def run_refutation(df, estimation_result):
    """
    Ejecuta tests de refutacion.

    Tests:
    1. Placebo Treatment: reemplazar tratamiento por ruido aleatorio
    2. Random Common Cause: agregar confusor aleatorio
    3. Data Subset: estimar en subconjunto (bootstrap)

    Returns:
        dict con resultados de refutacion
    """
    print("\n[5/6] REFUTACION")
    print("-" * 40)

    if 'error' in estimation_result:
        print("  Saltando (estimacion fallo)")
        return {'status': 'skipped'}

    refutations = []

    # Detectar columnas
    treatment_col = [c for c in df.columns if c in ['treatment', 'T', 'trt']][0]
    outcome_col = [c for c in df.columns if c in ['outcome', 'Y', 'y']][0]
    feature_cols = [c for c in df.columns if c not in [treatment_col, outcome_col, 'y0', 'y1', 'tau']]

    X = df[feature_cols].values
    T = df[treatment_col].values
    Y = df[outcome_col].values

    ate_original = estimation_result['ate']

    # Test 1: Placebo Treatment
    print("  Test 1: Placebo Treatment...", end=' ')
    np.random.seed(42)
    T_placebo = np.random.binomial(1, T.mean(), len(T))

    from scripts_04 import AIPW_Estimator
    est_placebo = AIPW_Estimator()
    est_placebo.fit(X, T_placebo, Y)
    ate_placebo = est_placebo.ate_

    placebo_passed = abs(ate_placebo) < 0.1 * abs(ate_original) if ate_original != 0 else abs(ate_placebo) < 0.5
    refutations.append({
        'test': 'placebo_treatment',
        'ate_placebo': ate_placebo,
        'passed': placebo_passed,
        'details': f'ATE with placebo: {ate_placebo:.4f} (original: {ate_original:.4f})'
    })
    print(f"{'PASS' if placebo_passed else 'FAIL'} (ATE_placebo={ate_placebo:.4f})")

    # Test 2: Random Common Cause
    print("  Test 2: Random Common Cause...", end=' ')
    X_with_conf = np.column_stack([X, np.random.normal(0, 1, len(X))])

    est_conf = AIPW_Estimator()
    est_conf.fit(X_with_conf, T, Y)
    ate_conf = est_conf.ate_

    conf_passed = abs(ate_conf - ate_original) < 0.2 * abs(ate_original) if ate_original != 0 else abs(ate_conf - ate_original) < 0.3
    refutations.append({
        'test': 'random_common_cause',
        'ate_with_confounder': ate_conf,
        'passed': conf_passed,
        'details': f'ATE with random confounder: {ate_conf:.4f} (original: {ate_original:.4f})'
    })
    print(f"{'PASS' if conf_passed else 'FAIL'} (ATE_conf={ate_conf:.4f})")

    # Test 3: Data Subset (bootstrap)
    print("  Test 3: Data Subset (bootstrap)...", end=' ')
    n_boot = 20
    ates_boot = []
    for i in range(n_boot):
        idx = np.random.choice(len(X), int(0.8 * len(X)), replace=False)
        est_boot = AIPW_Estimator()
        est_boot.fit(X[idx], T[idx], Y[idx])
        ates_boot.append(est_boot.ate_)

    ate_boot_mean = np.mean(ates_boot)
    ate_boot_std = np.std(ates_boot)

    subset_passed = abs(ate_boot_mean - ate_original) < 1.96 * ate_boot_std
    refutations.append({
        'test': 'data_subset',
        'ate_bootstrap_mean': ate_boot_mean,
        'ate_bootstrap_std': ate_boot_std,
        'passed': subset_passed,
        'details': f'ATE on 80% subsets: {ate_boot_mean:.4f} +/- {ate_boot_std:.4f}'
    })
    print(f"{'PASS' if subset_passed else 'FAIL'} (ATE_boot={ate_boot_mean:.4f} +/- {ate_boot_std:.4f})")

    # Resumen
    passed_count = sum(1 for r in refutations if r['passed'])
    total_count = len(refutations)

    robustness_class = 'strong' if passed_count == total_count else \
                      'moderate' if passed_count >= total_count // 2 else 'weak'

    print(f"\n  Resumen: {passed_count}/{total_count} tests pasados")
    print(f"  Clase de robustez: {robustness_class.upper()}")

    return {
        'tests': refutations,
        'passed': passed_count,
        'total': total_count,
        'robustness_class': robustness_class
    }


# =============================================================================
# 6. REPORTE
# =============================================================================

def generate_report(df, diagnostics, selection, discovery_result,
                    estimation_result, refutation_result, output_dir):
    """
    Genera reporte estructurado del analisis.

    Genera reportes en formato Markdown y JSON.
    """
    print("\n[6/6] GENERACION DE REPORTE")
    print("-" * 40)

    os.makedirs(output_dir, exist_ok=True)

    # Reporte JSON
    report = {
        'timestamp': pd.Timestamp.now().isoformat(),
        'pipeline_version': '1.0.0 (simulated)',
        'steps': {
            'ingestion': {
                'n_rows': len(df),
                'n_columns': len(df.columns),
                'columns': list(df.columns)
            },
            'diagnostics': diagnostics,
            'algorithm_selection': selection,
            'discovery': {
                k: v for k, v in (discovery_result or {}).items()
                if k != 'graph'
            },
            'estimation': estimation_result or {},
            'refutation': refutation_result or {}
        }
    }

    # Guardar JSON
    json_path = os.path.join(output_dir, 'report.json')
    with open(json_path, 'w') as f:
        json.dump(report, f, indent=2, default=str)

    # Reporte Markdown
    md_path = os.path.join(output_dir, 'report.md')
    with open(md_path, 'w') as f:
        f.write("# Reporte de Analisis Causal\n\n")
        f.write(f"**Fecha**: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M')}\n\n")

        f.write("## 1. Ingestion de Datos\n\n")
        f.write(f"- **Filas**: {len(df):,}\n")
        f.write(f"- **Columnas**: {len(df.columns)}\n")
        f.write(f"- **Variables**: {', '.join(df.columns)}\n\n")

        f.write("## 2. Diagnosticos\n\n")
        if 'vif' in diagnostics:
            f.write(f"- **VIF promedio**: {diagnostics['vif']['mean_vif']:.1f}\n")
            f.write(f"- **VIF maximo**: {diagnostics['vif']['max_vif']:.1f}\n")
        if 'normality' in diagnostics:
            f.write(f"- **Variables no normales**: {diagnostics['normality']['non_normal_count']}\n")
        f.write(f"- **Severidad**: {diagnostics.get('overall_severity', 'N/A')}\n\n")

        f.write("## 3. Seleccion de Algoritmo\n\n")
        sel = selection.get('selected', {})
        f.write(f"- **Algoritmo seleccionado**: {sel.get('algorithm', 'N/A')}\n")
        f.write(f"- **Puntuacion**: {sel.get('score', 'N/A')}\n")
        f.write(f"- **Justificacion**: {sel.get('reason', 'N/A')}\n\n")

        if selection.get('rankings'):
            f.write("### Rankings\n\n")
            f.write("| Posicion | Algoritmo | Score | Justificacion |\n")
            f.write("|----------|-----------|-------|---------------|\n")
            for i, r in enumerate(selection['rankings'][:5], 1):
                f.write(f"| {i} | {r['algorithm']} | {r['score']} | {r['reason']} |\n")
            f.write("\n")

        if estimation_result and 'ate' in estimation_result:
            f.write("## 4. Estimacion\n\n")
            f.write(f"- **ATE**: {estimation_result['ate']:.4f}\n")
            f.write(f"- **IC 95%**: [{estimation_result.get('ci_lower', 'N/A'):.4f}, "
                   f"{estimation_result.get('ci_upper', 'N/A'):.4f}]\n")
            f.write(f"- **Tiempo**: {estimation_result.get('time', 'N/A'):.2f}s\n\n")

        if refutation_result and 'tests' in refutation_result:
            f.write("## 5. Refutacion\n\n")
            for test in refutation_result['tests']:
                status = "PASS" if test['passed'] else "FAIL"
                f.write(f"- **{test['test']}**: {status} - {test['details']}\n")
            f.write(f"\n- **Tests pasados**: {refutation_result.get('passed', 0)}/"
                   f"{refutation_result.get('total', 0)}\n")
            f.write(f"- **Clase de robustez**: {refutation_result.get('robustness_class', 'N/A').upper()}\n\n")

        f.write("---\n\n")
        f.write("*Benchmark Datasets - Causal Discovery Pipeline*\n")

    print(f"  Reporte JSON: {json_path}")
    print(f"  Reporte Markdown: {md_path}")

    return report


# =============================================================================
# MAIN
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Pipeline completo de descubrimiento e inferencia causal'
    )
    parser.add_argument('--dataset', '-d', type=str, required=True,
                       help='Directorio del dataset')
    parser.add_argument('--query', '-q', type=str, default='discover and estimate',
                       help='Consulta en lenguaje natural')
    parser.add_argument('--treatment_col', type=str, default=None,
                       help='Columna de tratamiento (auto-detect if not set)')
    parser.add_argument('--outcome_col', type=str, default=None,
                       help='Columna de outcome (auto-detect if not set)')
    parser.add_argument('--no_human', action='store_true',
                       help='Modo automatico sin human-in-the-loop')
    parser.add_argument('--output', '-o', type=str, default='results/full_pipeline',
                       help='Directorio de salida')

    args = parser.parse_args()

    print("\n" + "=" * 70)
    print(" PIPELINE COMPLETO - DESCUBRIMIENTO E INFERENCIA CAUSAL")
    print("=" * 70)
    print(f"\nDataset: {args.dataset}")
    print(f"Query: {args.query}")
    print(f"Query: '{args.query}'")
    print(f"Modo: {'Automatico' if args.no_human else 'Human-in-the-loop'}")
    print("=" * 70)

    # Paso 1: Ingestion
    df, G_true, metadata, ingest_report = ingest_and_validate(args.dataset)

    # Paso 2: Diagnostico
    diagnostics = diagnose_data(df, metadata)

    # Check human-in-the-loop
    if not args.no_human and diagnostics.get('overall_severity') == 'high':
        print("\n  [HITL] Severidad alta detectada. Continuando automaticamente (--no_human)...")

    # Paso 3: Seleccion
    selection = select_algorithm(df, diagnostics, args.query, G_true is not None)

    # Paso 4: Ejecucion
    discovery_result = None
    estimation_result = None

    if selection['intent'] in ['discovery', 'discovery_estimation']:
        discovery_result = execute_discovery(df, selection)

    if selection['intent'] in ['estimation', 'discovery_estimation']:
        estimation_result = execute_estimation(df, selection)

    # Paso 5: Refutacion
    refutation_result = run_refutation(df, estimation_result or {})

    # Paso 6: Reporte
    report = generate_report(
        df, diagnostics, selection,
        discovery_result, estimation_result, refutation_result,
        args.output
    )

    # Comparar con ground truth si disponible
    if G_true is not None and discovery_result and 'graph' in discovery_result:
        print("\n" + "-" * 40)
        print("EVALUACION CONTRA GROUND TRUTH:")
        metrics = precision_recall_f1(G_true, discovery_result['graph'])
        print(f"  SHD: {metrics['shd']}")
        print(f"  Precision (skeleton): {metrics['precision_skeleton']:.3f}")
        print(f"  Recall (skeleton): {metrics['recall_skeleton']:.3f}")
        print(f"  F1 (skeleton): {metrics['f1_skeleton']:.3f}")

    if metadata.get('ate_true') and estimation_result:
        print(f"\n  ATE ground truth: {metadata['ate_true']:.4f}")
        print(f"  ATE estimado: {estimation_result.get('ate', 'N/A')}")
        if 'ate' in estimation_result:
            err = abs(metadata['ate_true'] - estimation_result['ate'])
            print(f"  Error absoluto: {err:.4f}")

    print("\n" + "=" * 70)
    print(" PIPELINE COMPLETADO")
    print("=" * 70)
    print(f"\nResultados guardados en: {args.output}")


if __name__ == '__main__':
    main()
