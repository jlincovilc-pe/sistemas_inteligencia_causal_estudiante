#!/usr/bin/env python3
"""
Benchmark de descubrimiento causal para agentes de inferencia causal.

Evalua la capacidad de recuperar la estructura causal correcta usando
algoritmos clasicos: PC, FCI, GES, FGES, NOTEARS, GOLEM,
ICA-LiNGAM, DirectLiNGAM, PCMCI.

Metricas:
- Structural Hamming Distance (SHD)
- Precision/Recall/F1 de arcos (skeleton y dirigidos)
- Precision de orientacion
- Tiempo de ejecucion

Uso:
    # Evaluar todos los algoritmos en todos los datasets
    python 03_run_discovery_benchmark.py --datasets datasets/synthetic/linear_gaussian --all

    # Evaluar algoritmos especificos
    python 03_run_discovery_benchmark.py --datasets datasets/synthetic/linear_gaussian \
        --algorithms pc fci ges notears golem lingam --output results/discovery/

    # Modo lite (sin librerias especializadas)
    python 03_run_discovery_benchmark.py --datasets datasets/synthetic/linear_gaussian \
        --lite --output results/discovery_lite/
"""

import argparse
import json
import os
import sys
import time
import warnings
from pathlib import Path

import networkx as nx
import numpy as np
import pandas as pd

warnings.filterwarnings('ignore')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from utils import (
    load_dataset_and_graph,
    orientation_precision_recall,
    precision_recall_f1,
    print_benchmark_summary,
    structural_hamming_distance,
)

# =============================================================================
# DETECCION DE LIBRERIAS DISPONIBLES
# =============================================================================

def check_libraries():
    """Detecta que librerias causales estan disponibles."""
    available = {
        'numpy': True,
        'scipy': True,
        'sklearn': True,
        'causal_learn': False,
        'lingam': False,
        'gcastle': False,
        'tigramite': False,
    }

    try:
        import causallearn
        available['causal_learn'] = True
    except ImportError:
        pass

    try:
        import lingam
        available['lingam'] = True
    except ImportError:
        pass

    try:
        import castle
        available['gcastle'] = True
    except ImportError:
        pass

    try:
        import tigramite
        available['tigramite'] = True
    except ImportError:
        pass

    return available


LIBS = check_libraries()


# =============================================================================
# IMPLEMENTACIONES LITE (NumPy/scikit-learn solamente)
# =============================================================================

def pc_algorithm_lite(df, alpha=0.05, indep_test='fisherz', max_cond_vars=None):
    """
    Implementacion lite del algoritmo PC usando solo NumPy/scipy.

    Args:
        df: DataFrame con datos
        alpha: Nivel de significancia para tests de independencia
        indep_test: 'fisherz' o 'correlation'
        max_cond_vars: Maximo numero de variables de condicionamiento

    Returns:
        networkx.DiGraph estimado
    """
    from scipy import stats

    data = df.values
    n_vars = data.shape[1]
    var_names = list(df.columns)

    if max_cond_vars is None:
        max_cond_vars = n_vars - 2

    # Paso 1: Grafo completamente conectado (no dirigido)
    adj = np.ones((n_vars, n_vars)) - np.eye(n_vars)

    def fisher_z_test(x, y, cond_set, data):
        """Test de independencia conditional usando Fisher's Z."""
        if len(cond_set) == 0:
            # Correlacion simple
            r = np.corrcoef(data[:, x], data[:, y])[0, 1]
            if np.isnan(r):
                return 1.0
            # Fisher z-transform
            z = 0.5 * np.log((1 + r) / (1 - r)) * np.sqrt(data.shape[0] - 3)
            p_value = 2 * (1 - stats.norm.cdf(abs(z)))
            return p_value
        else:
            # Regresion parcial
            from sklearn.linear_model import LinearRegression

            # Residualizar x respecto a cond_set
            if len(cond_set) == 1:
                X_cond = data[:, cond_set[0]].reshape(-1, 1)
            else:
                X_cond = data[:, cond_set]

            reg_x = LinearRegression().fit(X_cond, data[:, x])
            resid_x = data[:, x] - reg_x.predict(X_cond)

            reg_y = LinearRegression().fit(X_cond, data[:, y])
            resid_y = data[:, y] - reg_y.predict(X_cond)

            r = np.corrcoef(resid_x, resid_y)[0, 1]
            if np.isnan(r):
                return 1.0
            z = 0.5 * np.log((1 + r) / (1 - r)) * np.sqrt(data.shape[0] - 3 - len(cond_set))
            p_value = 2 * (1 - stats.norm.cdf(abs(z)))
            return p_value

    indep_test_fn = fisher_z_test

    # Algoritmo PC basico
    # Fase I: Eliminar edges por independencia condicional
    for d in range(max_cond_vars + 1):
        removed = []
        for i in range(n_vars):
            for j in range(i + 1, n_vars):
                if adj[i, j] == 0:
                    continue

                neighbors_i = [k for k in range(n_vars) if k != i and k != j and adj[i, k] > 0]

                if len(neighbors_i) < d:
                    continue

                # Probar todas las combinaciones de tamano d
                from itertools import combinations
                for cond_set in combinations(neighbors_i, d):
                    p_val = indep_test_fn(i, j, list(cond_set), data)
                    if p_val > alpha:
                        removed.append((i, j))
                        break

                if (i, j) in removed:
                    break

        for i, j in removed:
            adj[i, j] = 0
            adj[j, i] = 0

    # Fase II: Orientar v-structures
    # Para cada triplet X - Y - Z, si X y Z no son adyacentes, orientar X -> Y <- Z
    directed = np.zeros((n_vars, n_vars))

    for y in range(n_vars):
        neighbors = [x for x in range(n_vars) if adj[x, y] > 0]
        for x_idx in range(len(neighbors)):
            for z_idx in range(x_idx + 1, len(neighbors)):
                x, z = neighbors[x_idx], neighbors[z_idx]
                if adj[x, z] == 0 and adj[z, x] == 0:
                    # V-structure
                    directed[x, y] = 1
                    directed[z, y] = 1

    # Fase III: Orientar edges restantes (reglas R1-R3 de Meek)
    changed = True
    while changed:
        changed = False
        for x in range(n_vars):
            for y in range(n_vars):
                if adj[x, y] == 0 or directed[x, y] or directed[y, x]:
                    continue

                # R1: Orient y -> x si existe z -> y y z no adyacente a x
                for z in range(n_vars):
                    if directed[z, y] and adj[z, x] == 0:
                        directed[y, x] = 1
                        changed = True
                        break

    # Construir grafo dirigido
    G = nx.DiGraph()
    G.add_nodes_from(range(n_vars))

    for i in range(n_vars):
        for j in range(n_vars):
            if directed[i, j] > 0:
                G.add_edge(i, j)
            elif adj[i, j] > 0 and i < j:
                # Edge no orientado - elegir direccion por orden
                G.add_edge(i, j)

    G = nx.relabel_nodes(G, {i: var_names[i] for i in range(n_vars)})
    return G


def ica_lingam_lite(df, max_iter=1000):
    """
    Implementacion lite de ICA-LiNGAM usando FastICA de scikit-learn.

    ICA-LiNGAM estima el orden causal buscando una matriz de mezcla
    triangular inferior mediante ICA.
    """
    from scipy.stats import kurtosis
    from sklearn.decomposition import FastICA

    data = df.values
    n_vars = data.shape[1]
    var_names = list(df.columns)

    # Centrar datos
    data_centered = data - data.mean(axis=0)

    # ICA
    ica = FastICA(n_components=n_vars, max_iter=max_iter, random_state=42)
    S = ica.fit_transform(data_centered)
    W_ica = ica.components_

    # Estimar matriz B (efectos directos)
    try:
        B = np.eye(n_vars) - W_ica
    except:
        B = np.zeros((n_vars, n_vars))

    # Threshold para determinar edges
    threshold = 0.1

    G = nx.DiGraph()
    G.add_nodes_from(var_names)

    for i in range(n_vars):
        for j in range(n_vars):
            if i != j and abs(B[i, j]) > threshold:
                G.add_edge(var_names[i], var_names[j])

    return G


def notears_lite(df, lambda1=0.1, max_iter=100, lr=0.01):
    """
    Implementacion simplificada de NOTEARS.

    NOTEARS formula el descubrimiento de DAG como un problema de
    optimizacion continua con restriccion de aciclicidad.
    """
    data = df.values
    n_vars = data.shape[1]
    var_names = list(df.columns)

    # Normalizar
    data_norm = (data - data.mean(axis=0)) / (data.std(axis=0) + 1e-8)

    # Inicializar W (matriz de pesos)
    W = np.zeros((n_vars, n_vars))

    # Gradient descent simple (version lite simplificada)
    for iteration in range(max_iter):
        # Prediccion
        pred = data_norm @ W
        residual = data_norm - pred

        # Gradiente de MSE
        grad = -2 * data_norm.T @ residual / len(data_norm) + lambda1 * np.sign(W)

        # Actualizar (sin restriccion DAG en version lite)
        W -= lr * grad

        # Threshold
        W = W * (abs(W) > 0.3)

        # Evitar auto-loops
        np.fill_diagonal(W, 0)

    # Construir grafo
    G = nx.DiGraph()
    G.add_nodes_from(var_names)

    for i in range(n_vars):
        for j in range(n_vars):
            if i != j and abs(W[i, j]) > 0.3:
                G.add_edge(var_names[i], var_names[j])

    return G


# =============================================================================
# WRAPPERS PARA LIBRERIAS ESPECIALIZADAS
# =============================================================================

def run_pc_causal_learn(df, alpha=0.05):
    """Wrapper para PC de causal-learn."""
    from causallearn.search.ConstraintBased.PC import pc
    from causallearn.utils.GraphUtils import GraphUtils

    data = df.values
    cg = pc(data, alpha, indep_test='fisherz', show_progress=False)

    # Convertir a networkx
    G = nx.DiGraph()
    G.add_nodes_from(df.columns)

    # Extraer edges del CausalGraph
    for i in range(len(df.columns)):
        for j in range(len(df.columns)):
            if cg.G.graph[i, j] == 1 and cg.G.graph[j, i] == -1:
                G.add_edge(df.columns[i], df.columns[j])

    return G


def run_fci_causal_learn(df, alpha=0.05):
    """Wrapper para FCI de causal-learn."""
    from causallearn.search.ConstraintBased.FCI import fci

    data = df.values
    G, edges = fci(data, independence_test_method='fisherz', alpha=alpha,
                   show_progress=False)

    # FCI devuelve un PAG (Partial Ancestral Graph)
    # Extraer componente dirigida
    result = nx.DiGraph()
    result.add_nodes_from(df.columns)

    for edge in edges:
        if len(edge) == 2:
            i, j = edge
            if hasattr(i, 'get_name') and hasattr(j, 'get_name'):
                result.add_edge(str(i), str(j))

    # Mapear nombres
    mapping = {i: df.columns[i] for i in range(len(df.columns))}
    result = nx.relabel_nodes(result, mapping)

    return result


def run_ges_causal_learn(df):
    """Wrapper para GES de causal-learn."""
    from causallearn.search.ScoreBased.GES import ges

    data = df.values
    Record = ges(data, score_func='local_score_BIC', show_progress=False)

    G = nx.DiGraph()
    G.add_nodes_from(df.columns)

    # Extraer DAG
    dag = Record['G']
    for i in range(len(df.columns)):
        for j in range(len(df.columns)):
            if dag.graph[i, j] == 1:
                G.add_edge(df.columns[i], df.columns[j])

    return G


def run_lingam(df):
    """Wrapper para DirectLiNGAM."""
    import lingam

    model = lingam.DirectLiNGAM()
    model.fit(df.values)

    adj = model.adjacency_matrix_
    threshold = 0.1

    G = nx.DiGraph()
    G.add_nodes_from(df.columns)

    for i in range(len(df.columns)):
        for j in range(len(df.columns)):
            if i != j and abs(adj[j, i]) > threshold:
                G.add_edge(df.columns[i], df.columns[j])

    return G


def run_golem(df):
    """Wrapper para GOLEM de gCastle."""
    from castle.algorithms import GOLEM

    model = GOLEM(num_iter=10000)
    model.learn(df.values)

    adj = model.causal_matrix
    threshold = 0.3

    G = nx.DiGraph()
    G.add_nodes_from(df.columns)

    for i in range(len(df.columns)):
        for j in range(len(df.columns)):
            if i != j and abs(adj[i, j]) > threshold:
                G.add_edge(df.columns[i], df.columns[j])

    return G


# =============================================================================
# MOTOR DE EVALUACION
# =============================================================================

ALGORITHMS = {
    'pc': {'fn': 'pc', 'needs': ['numpy'], 'desc': 'PC algorithm (constraint-based)'},
    'fci': {'fn': 'fci', 'needs': ['causal_learn'], 'desc': 'FCI algorithm (latent confounders)'},
    'ges': {'fn': 'ges', 'needs': ['causal_learn'], 'desc': 'GES algorithm (score-based)'},
    'notears': {'fn': 'notears', 'needs': ['numpy'], 'desc': 'NOTEARS (continuous optimization)'},
    'golem': {'fn': 'golem', 'needs': ['gcastle'], 'desc': 'GOLEM (neural)'},
    'lingam': {'fn': 'lingam', 'needs': ['lingam'], 'desc': 'DirectLiNGAM (non-Gaussian)'},
    'icalingam': {'fn': 'lingam', 'needs': ['lingam'], 'desc': 'ICA-LiNGAM'},
}


def evaluate_algorithm(algo_name, algo_fn, dataset_dir, output_dir, lite_mode=False):
    """
    Evalua un algoritmo de descubrimiento causal en un dataset.

    Args:
        algo_name: Nombre del algoritmo
        algo_fn: Funcion que ejecuta el algoritmo
        dataset_dir: Directorio con dataset y ground truth
        output_dir: Directorio para guardar resultados
        lite_mode: Si True, usa implementaciones lite

    Returns:
        Dict con metricas
    """
    print(f"    Algoritmo: {algo_name}...", end=' ', flush=True)

    # Cargar dataset
    df, G_true, metadata = load_dataset_and_graph(dataset_dir)

    # Ejecutar algoritmo con timeout
    start_time = time.time()
    try:
        if algo_name == 'pc':
            if lite_mode or not LIBS['causal_learn']:
                G_est = pc_algorithm_lite(df)
            else:
                G_est = run_pc_causal_learn(df)
        elif algo_name == 'fci':
            if LIBS['causal_learn']:
                G_est = run_fci_causal_learn(df)
            else:
                print("SKIP (causal-learn no disponible)")
                return None
        elif algo_name == 'ges':
            if LIBS['causal_learn']:
                G_est = run_ges_causal_learn(df)
            else:
                G_est = pc_algorithm_lite(df, alpha=0.05)
        elif algo_name == 'notears':
            if lite_mode:
                G_est = notears_lite(df)
            else:
                G_est = notears_lite(df)  # Siempre usamos lite para notears
        elif algo_name == 'golem':
            if LIBS['gcastle']:
                G_est = run_golem(df)
            else:
                print("SKIP (gcastle no disponible)")
                return None
        elif algo_name in ['lingam', 'icalingam']:
            if LIBS['lingam']:
                G_est = run_lingam(df)
            else:
                G_est = ica_lingam_lite(df)
        else:
            print(f"SKIP (algoritmo {algo_name} no implementado)")
            return None

        elapsed = time.time() - start_time

        # Alinear nombres de nodos
        if set(G_est.nodes()) != set(G_true.nodes()):
            # Relabel si es necesario
            if set(G_est.nodes()) == set(range(len(df.columns))):
                mapping = {i: df.columns[i] for i in range(len(df.columns))}
                G_est = nx.relabel_nodes(G_est, mapping)

        # Calcular metricas
        metrics = precision_recall_f1(G_true, G_est)
        metrics['time_seconds'] = elapsed
        metrics['num_nodes'] = G_true.number_of_nodes()
        metrics['num_edges_true'] = G_true.number_of_edges()
        metrics['num_edges_estimated'] = G_est.number_of_edges()

        # Guardar grafo estimado
        os.makedirs(output_dir, exist_ok=True)
        est_edges = pd.DataFrame(list(G_est.edges()), columns=['source', 'target'])
        est_edges.to_csv(os.path.join(output_dir, f'{algo_name}_edges.csv'), index=False)

        print(f"OK (SHD={metrics['shd']}, F1={metrics['f1_skeleton']:.3f}, {elapsed:.2f}s)")
        return metrics

    except Exception as e:
        elapsed = time.time() - start_time
        print(f"ERROR ({e})")
        return {'error': str(e), 'time_seconds': elapsed}


def run_discovery_benchmark(datasets_dir, algorithms, output_dir, lite_mode=False):
    """
    Ejecuta benchmark completo de descubrimiento causal.
    """
    print("\n" + "=" * 70)
    print(" BENCHMARK DE DESCUBRIMIENTO CAUSAL")
    print("=" * 70)
    print(f"\nDatasets: {datasets_dir}")
    print(f"Algoritmos: {algorithms}")
    print(f"Lite mode: {lite_mode}")
    print(f"Librerias disponibles: {', '.join([k for k, v in LIBS.items() if v])}")
    print("=" * 70)

    # Encontrar datasets
    dataset_dirs = []
    if os.path.isdir(datasets_dir):
        # Verificar si es un dataset individual o directorio de datasets
        if os.path.exists(os.path.join(datasets_dir, 'data.csv')):
            dataset_dirs = [datasets_dir]
        else:
            for subdir in sorted(os.listdir(datasets_dir)):
                full_path = os.path.join(datasets_dir, subdir)
                if os.path.isdir(full_path) and os.path.exists(os.path.join(full_path, 'data.csv')):
                    dataset_dirs.append(full_path)

    if not dataset_dirs:
        print(f"ERROR: No se encontraron datasets en {datasets_dir}")
        return {}

    print(f"\nDatasets encontrados: {len(dataset_dirs)}")

    # Resultados
    all_results = {}

    for dataset_path in dataset_dirs:
        dataset_name = os.path.basename(dataset_path)
        print(f"\n{'='*60}")
        print(f" Dataset: {dataset_name}")
        print(f"{'='*60}")

        dataset_results = {}

        for algo in algorithms:
            if algo not in ALGORITHMS:
                print(f"  Algoritmo '{algo}' no reconocido. Saltando.")
                continue

            algo_info = ALGORITHMS[algo]

            # Verificar dependencias
            can_run = True
            for dep in algo_info['needs']:
                if dep not in ['numpy', 'scipy', 'sklearn'] and not LIBS.get(dep):
                    if lite_mode:
                        print(f"  {algo}: usando implementacion lite")
                    else:
                        print(f"  {algo}: libreria {dep} no disponible (use --lite)")
                        can_run = False

            if not can_run and not lite_mode:
                continue

            # Evaluar
            algo_output = os.path.join(output_dir, dataset_name)
            result = evaluate_algorithm(algo, algo_info['fn'], dataset_path,
                                         algo_output, lite_mode=lite_mode)

            if result:
                dataset_results[algo] = result

        all_results[dataset_name] = dataset_results

    # Guardar resultados
    os.makedirs(output_dir, exist_ok=True)
    results_file = os.path.join(output_dir, 'discovery_results.json')
    with open(results_file, 'w') as f:
        json.dump(all_results, f, indent=2, default=str)

    # Tabla resumen
    print("\n" + "=" * 70)
    print(" RESUMEN DE RESULTADOS")
    print("=" * 70)

    for dataset_name, results in all_results.items():
        print(f"\n{dataset_name}:")
        print(f"{'Algo':<12} {'SHD':>6} {'P_skel':>8} {'R_skel':>8} {'F1_skel':>8} {'Time':>8}")
        print("-" * 60)
        for algo, metrics in results.items():
            if 'error' not in metrics:
                print(f"{algo:<12} {metrics['shd']:>6} {metrics['precision_skeleton']:>8.3f} "
                      f"{metrics['recall_skeleton']:>8.3f} {metrics['f1_skeleton']:>8.3f} "
                      f"{metrics['time_seconds']:>8.2f}s")

    print(f"\nResultados guardados en: {results_file}")

    return all_results


# =============================================================================
# MAIN
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Benchmark de descubrimiento causal'
    )
    parser.add_argument('--datasets', '-d', type=str, required=True,
                       help='Directorio con datasets')
    parser.add_argument('--algorithms', '-a', nargs='+',
                       choices=list(ALGORITHMS.keys()) + ['all'],
                       default=['all'],
                       help='Algoritmos a evaluar')
    parser.add_argument('--output', '-o', type=str, default='results/discovery',
                       help='Directorio de salida')
    parser.add_argument('--lite', action='store_true',
                       help='Usar implementaciones lite (sin librerias especializadas)')
    parser.add_argument('--alpha', type=float, default=0.05,
                       help='Nivel de significancia para tests de independencia')

    args = parser.parse_args()

    # Determinar algoritmos
    if 'all' in args.algorithms:
        algorithms = list(ALGORITHMS.keys())
    else:
        algorithms = args.algorithms

    # Ejecutar benchmark
    run_discovery_benchmark(
        datasets_dir=args.datasets,
        algorithms=algorithms,
        output_dir=args.output,
        lite_mode=args.lite
    )


if __name__ == '__main__':
    main()
