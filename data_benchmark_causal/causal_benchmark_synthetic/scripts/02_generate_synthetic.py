#!/usr/bin/env python3
"""
Script de generacion de datasets sinteticos de benchmark para agentes de descubrimiento causal.

Genera datasets controlados con estructuras causales conocidas para evaluar:
1. Algoritmos de descubrimiento causal (PC, FCI, GES, NOTEARS, GOLEM, LiNGAM)
2. Estimadores de efectos de tratamiento (DML, Causal Forest, PSM, etc.)
3. Series temporales para PCMCI
4. Casos de borde (no identificacion, confusores latentes)

Uso:
    python 02_generate_synthetic.py --all --output datasets/synthetic/
    python 02_generate_synthetic.py --category linear --output datasets/synthetic/
    python 02_generate_synthetic.py --category ihdp --samples 2000 --output datasets/synthetic/
"""

import argparse
import json
import os
import sys

import networkx as nx
import numpy as np
import pandas as pd

# Agregar el directorio scripts al path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from utils import (
    generate_dag_er,
    generate_dag_hierarchical,
    generate_dag_sf,
    generate_heteroscedastic_sem,
    generate_ihdp_synthetic,
    generate_lalonde_style,
    generate_linear_gaussian_sem,
    generate_linear_non_gaussian_sem,
    generate_nonlinear_sem,
    generate_nonlinear_timeseries,
    generate_twins_style,
    generate_var_process,
    save_dataset_and_graph,
)

# =============================================================================
# CONFIGURACION DE BENCHMARKS
# =============================================================================

# Configuraciones para descubrimiento causal lineal Gaussiano
LINEAR_GAUSSIAN_CONFIGS = [
    {'name': '10_vars_10_edges', 'vars': 10, 'edges': 10, 'samples': 1000, 'graph_type': 'er'},
    {'name': '10_vars_20_edges', 'vars': 10, 'edges': 20, 'samples': 1000, 'graph_type': 'er'},
    {'name': '20_vars_20_edges', 'vars': 20, 'edges': 20, 'samples': 2000, 'graph_type': 'er'},
    {'name': '20_vars_40_edges', 'vars': 20, 'edges': 40, 'samples': 2000, 'graph_type': 'er'},
    {'name': '50_vars_50_edges', 'vars': 50, 'edges': 50, 'samples': 5000, 'graph_type': 'er'},
    {'name': '50_vars_100_edges', 'vars': 50, 'edges': 100, 'samples': 5000, 'graph_type': 'er'},
    {'name': '100_vars_150_edges', 'vars': 100, 'edges': 150, 'samples': 10000, 'graph_type': 'er'},
    {'name': '20_vars_sf', 'vars': 20, 'edges': 30, 'samples': 2000, 'graph_type': 'sf'},
    {'name': '50_vars_sf', 'vars': 50, 'edges': 75, 'samples': 5000, 'graph_type': 'sf'},
]

# Configuraciones para SEM no Gaussianos (LiNGAM)
NON_GAUSSIAN_CONFIGS = [
    {'name': '10_vars_laplace', 'vars': 10, 'edges': 15, 'samples': 1000, 'noise': 'laplace'},
    {'name': '20_vars_laplace', 'vars': 20, 'edges': 30, 'samples': 2000, 'noise': 'laplace'},
    {'name': '10_vars_uniform', 'vars': 10, 'edges': 15, 'samples': 1000, 'noise': 'uniform'},
    {'name': '20_vars_exponential', 'vars': 20, 'edges': 30, 'samples': 2000, 'noise': 'exponential'},
    {'name': '10_vars_gumbel', 'vars': 10, 'edges': 15, 'samples': 1000, 'noise': 'gumbel'},
    {'name': '10_vars_mixed_ng', 'vars': 10, 'edges': 15, 'samples': 2000, 'noise': 'mixed'},
]

# Configuraciones para SEM no lineales
NONLINEAR_CONFIGS = [
    {'name': '10_vars_mlp', 'vars': 10, 'edges': 15, 'samples': 1000, 'nl_type': 'mlp'},
    {'name': '20_vars_mlp', 'vars': 20, 'edges': 30, 'samples': 2000, 'nl_type': 'mlp'},
    {'name': '10_vars_polynomial', 'vars': 10, 'edges': 15, 'samples': 1000, 'nl_type': 'polynomial'},
    {'name': '20_vars_polynomial', 'vars': 20, 'edges': 30, 'samples': 2000, 'nl_type': 'polynomial'},
    {'name': '10_vars_gp', 'vars': 10, 'edges': 15, 'samples': 1000, 'nl_type': 'gp'},
    {'name': '10_vars_heteroscedastic', 'vars': 10, 'edges': 15, 'samples': 2000, 'nl_type': 'heteroscedastic'},
]

# Configuraciones para inferencia causal
INFERENCE_CONFIGS = [
    {'name': 'ihdp_small', 'samples': 1000, 'type': 'ihdp'},
    {'name': 'ihdp_medium', 'samples': 2000, 'type': 'ihdp'},
    {'name': 'ihdp_large', 'samples': 5000, 'type': 'ihdp'},
    {'name': 'lalonde_small', 'samples': 1000, 'type': 'lalonde'},
    {'name': 'lalonde_medium', 'samples': 2000, 'type': 'lalonde'},
    {'name': 'twins_small', 'samples': 2000, 'type': 'twins'},
    {'name': 'twins_medium', 'samples': 4000, 'type': 'twins'},
]

# Configuraciones para series temporales
TIMESERIES_CONFIGS = [
    {'name': '5_vars_2_lags', 'vars': 5, 'lags': 2, 'samples': 1000, 'sparsity': 0.3},
    {'name': '5_vars_3_lags', 'vars': 5, 'lags': 3, 'samples': 1000, 'sparsity': 0.5},
    {'name': '10_vars_2_lags', 'vars': 10, 'lags': 2, 'samples': 2000, 'sparsity': 0.3},
    {'name': '10_vars_3_lags', 'vars': 10, 'lags': 3, 'samples': 2000, 'sparsity': 0.5},
    {'name': '5_vars_nonlinear_ts', 'vars': 5, 'samples': 1000, 'nl': True},
]


# =============================================================================
# FUNCIONES DE GENERACION
# =============================================================================

def generate_linear_gaussian_benchmarks(output_dir: str, seed: int = 42):
    """Genera benchmarks lineales Gaussianos."""
    print("=" * 60)
    print("Generando benchmarks: Lineal Gaussiano")
    print("=" * 60)

    out_dir = os.path.join(output_dir, 'linear_gaussian')
    os.makedirs(out_dir, exist_ok=True)

    for i, config in enumerate(LINEAR_GAUSSIAN_CONFIGS):
        print(f"  [{i+1}/{len(LINEAR_GAUSSIAN_CONFIGS)}] {config['name']}...", end=' ')

        # Generar DAG
        if config['graph_type'] == 'er':
            G = generate_dag_er(config['vars'], config['edges'], seed=seed + i)
        elif config['graph_type'] == 'sf':
            G = generate_dag_sf(config['vars'], config['edges'], seed=seed + i)
        else:
            G = generate_dag_er(config['vars'], config['edges'], seed=seed + i)

        # Generar datos SEM lineal Gaussiano
        df, W = generate_linear_gaussian_sem(
            G, config['samples'],
            weight_range=(0.5, 2.0), noise_var=1.0, seed=seed + i
        )

        # Metadata
        metadata = {
            'type': 'linear_gaussian',
            'name': config['name'],
            'num_vars': config['vars'],
            'num_edges': config['edges'],
            'num_samples': config['samples'],
            'graph_type': config['graph_type'],
            'noise': 'gaussian(0,1)',
            'weight_range': [0.5, 2.0],
            'seed': seed + i
        }

        # Guardar
        dataset_dir = os.path.join(out_dir, config['name'])
        save_dataset_and_graph(df, G, dataset_dir, metadata)
        print(f"OK ({config['vars']} vars, {G.number_of_edges()} edges, {config['samples']} samples)")

    print(f"\nGuardados en: {out_dir}")
    return out_dir


def generate_non_gaussian_benchmarks(output_dir: str, seed: int = 100):
    """Genera benchmarks no Gaussianos para LiNGAM."""
    print("=" * 60)
    print("Generando benchmarks: No Gaussiano (LiNGAM)")
    print("=" * 60)

    out_dir = os.path.join(output_dir, 'non_gaussian')
    os.makedirs(out_dir, exist_ok=True)

    for i, config in enumerate(NON_GAUSSIAN_CONFIGS):
        print(f"  [{i+1}/{len(NON_GAUSSIAN_CONFIGS)}] {config['name']}...", end=' ')

        G = generate_dag_er(config['vars'], config['edges'], seed=seed + i)

        if config['noise'] == 'mixed':
            # Para simplificar, usamos Laplace como base para mixed
            noise_type = 'laplace'
            metadata_noise = 'mixed_laplace_base'
        else:
            noise_type = config['noise']
            metadata_noise = config['noise']

        df, W = generate_linear_non_gaussian_sem(
            G, config['samples'], weight_range=(0.5, 2.0),
            noise_type=noise_type, seed=seed + i
        )

        metadata = {
            'type': 'linear_non_gaussian',
            'name': config['name'],
            'num_vars': config['vars'],
            'num_edges': config['edges'],
            'num_samples': config['samples'],
            'noise_type': metadata_noise,
            'algorithm_target': 'ICA-LiNGAM, DirectLiNGAM',
            'seed': seed + i
        }

        dataset_dir = os.path.join(out_dir, config['name'])
        save_dataset_and_graph(df, G, dataset_dir, metadata)
        print(f"OK ({config['noise']})")

    print(f"\nGuardados en: {out_dir}")
    return out_dir


def generate_nonlinear_benchmarks(output_dir: str, seed: int = 200):
    """Genera benchmarks no lineales."""
    print("=" * 60)
    print("Generando benchmarks: No Lineal")
    print("=" * 60)

    out_dir = os.path.join(output_dir, 'nonlinear')
    os.makedirs(out_dir, exist_ok=True)

    for i, config in enumerate(NONLINEAR_CONFIGS):
        print(f"  [{i+1}/{len(NONLINEAR_CONFIGS)}] {config['name']}...", end=' ')

        G = generate_dag_er(config['vars'], config['edges'], seed=seed + i)

        if config['nl_type'] == 'heteroscedastic':
            df = generate_heteroscedastic_sem(G, config['samples'], seed=seed + i)
        else:
            df = generate_nonlinear_sem(G, config['samples'],
                                         nonlinearity=config['nl_type'], seed=seed + i)

        metadata = {
            'type': 'nonlinear_sem',
            'name': config['name'],
            'num_vars': config['vars'],
            'num_edges': config['edges'],
            'num_samples': config['samples'],
            'nonlinearity': config['nl_type'],
            'algorithm_target': 'NOTEARS (nonlinear), GES, Causal Forest',
            'seed': seed + i
        }

        dataset_dir = os.path.join(out_dir, config['name'])
        save_dataset_and_graph(df, G, dataset_dir, metadata)
        print(f"OK ({config['nl_type']})")

    print(f"\nGuardados en: {out_dir}")
    return out_dir


def generate_inference_benchmarks(output_dir: str, seed: int = 300):
    """Genera benchmarks para inferencia causal (tratamiento)."""
    print("=" * 60)
    print("Generando benchmarks: Inferencia Causal")
    print("=" * 60)

    out_dir = os.path.join(output_dir, 'inference')
    os.makedirs(out_dir, exist_ok=True)

    for i, config in enumerate(INFERENCE_CONFIGS):
        print(f"  [{i+1}/{len(INFERENCE_CONFIGS)}] {config['name']}...", end=' ')

        dataset_dir = os.path.join(out_dir, config['name'])
        os.makedirs(dataset_dir, exist_ok=True)

        if config['type'] == 'ihdp':
            df, metadata = generate_ihdp_synthetic(
                num_samples=config['samples'], seed=seed + i
            )
            # Guardar IHDP
            df.to_csv(os.path.join(dataset_dir, 'data.csv'), index=False)
            with open(os.path.join(dataset_dir, 'metadata.json'), 'w') as f:
                json.dump(metadata, f, indent=2, default=str)

            # Guardar version publica (sin y0, y1, tau)
            df_public = df.drop(columns=['y0', 'y1', 'tau'])
            df_public.to_csv(os.path.join(dataset_dir, 'data_public.csv'), index=False)

        elif config['type'] == 'lalonde':
            df, metadata = generate_lalonde_style(
                num_samples=config['samples'], seed=seed + i
            )
            df.to_csv(os.path.join(dataset_dir, 'data.csv'), index=False)
            with open(os.path.join(dataset_dir, 'metadata.json'), 'w') as f:
                json.dump(metadata, f, indent=2, default=str)

            df_public = df.drop(columns=['y0', 'y1', 'tau'])
            df_public.to_csv(os.path.join(dataset_dir, 'data_public.csv'), index=False)

        elif config['type'] == 'twins':
            df, metadata = generate_twins_style(
                num_samples=config['samples'], seed=seed + i
            )
            df.to_csv(os.path.join(dataset_dir, 'data.csv'), index=False)
            with open(os.path.join(dataset_dir, 'metadata.json'), 'w') as f:
                json.dump(metadata, f, indent=2, default=str)

            # Twins no tiene outcomes potenciales directamente
            df.to_csv(os.path.join(dataset_dir, 'data_public.csv'), index=False)

        print(f"OK (ATE_true={metadata['ate_true']:.2f})")

    print(f"\nGuardados en: {out_dir}")
    return out_dir


def generate_timeseries_benchmarks(output_dir: str, seed: int = 400):
    """Genera benchmarks de series temporales para PCMCI."""
    print("=" * 60)
    print("Generando benchmarks: Series Temporales (PCMCI)")
    print("=" * 60)

    out_dir = os.path.join(output_dir, 'timeseries')
    os.makedirs(out_dir, exist_ok=True)

    for i, config in enumerate(TIMESERIES_CONFIGS):
        print(f"  [{i+1}/{len(TIMESERIES_CONFIGS)}] {config['name']}...", end=' ')

        dataset_dir = os.path.join(out_dir, config['name'])
        os.makedirs(dataset_dir, exist_ok=True)

        if config.get('nl', False):
            # No lineal
            df, metadata = generate_nonlinear_timeseries(
                config['vars'], config['samples'], seed=seed + i
            )
        else:
            # VAR lineal
            df, metadata = generate_var_process(
                config['vars'], config['lags'], config['samples'],
                config['sparsity'], seed=seed + i
            )

        df.to_csv(os.path.join(dataset_dir, 'data.csv'), index=False)
        with open(os.path.join(dataset_dir, 'metadata.json'), 'w') as f:
            json.dump(metadata, f, indent=2, default=str)

        # Guardar ground truth de links causales
        links_df = pd.DataFrame(metadata['causal_links'])
        links_df.to_csv(os.path.join(dataset_dir, 'ground_truth_links.csv'), index=False)

        print(f"OK ({config['vars']} vars, {len(metadata['causal_links'])} causal links)")

    print(f"\nGuardados en: {out_dir}")
    return out_dir


def generate_edge_cases(output_dir: str, seed: int = 500):
    """
    Genera casos de borde para probar robustez:
    - Grafos con colinealidad alta
    - Grafos con confusores no observados
    - Grafos no identificables
    """
    print("=" * 60)
    print("Generando benchmarks: Casos de borde")
    print("=" * 60)

    out_dir = os.path.join(output_dir, 'edge_cases')
    os.makedirs(out_dir, exist_ok=True)

    # 1. Alta colinealidad
    print("  [1/3] Alta colinealidad...", end=' ')
    G_col = generate_dag_er(15, 20, seed=seed)
    df_col, W_col = generate_linear_gaussian_sem(G_col, 1000,
                                                    weight_range=(1.5, 3.0),  # Pesos grandes
                                                    noise_var=0.1, seed=seed)  # Ruido pequeno
    # Hacer covariables altamente correlacionadas
    corr_matrix = np.corrcoef(df_col.T)

    metadata_col = {
        'type': 'edge_case_colinearity',
        'description': 'High collinearity between predictors',
        'mean_abs_correlation': float(np.abs(corr_matrix[np.triu_indices_from(corr_matrix, k=1)]).mean()),
        'seed': seed
    }
    save_dataset_and_graph(df_col, G_col, os.path.join(out_dir, 'high_collinearity'), metadata_col)
    print("OK")

    # 2. Confusores no observados
    print("  [2/3] Confusores latentes...", end=' ')
    # Crear DAG donde un nodo confusor afecta a tratamiento y outcome
    G_latent = nx.DiGraph()
    G_latent.add_nodes_from(range(10))
    # Estructura: confusor -> treatment, confusor -> outcome, treatment -> outcome
    edges_latent = [
        (0, 8),   # confusor -> tratamiento
        (0, 9),   # confusor -> outcome
        (8, 9),   # tratamiento -> outcome
        (1, 8), (2, 8),  # otros predictores del tratamiento
        (3, 9), (4, 9),  # otros predictores del outcome
        (5, 1), (6, 2), (7, 3)  # jerarquia adicional
    ]
    G_latent.add_edges_from(edges_latent)
    df_latent, W_latent = generate_linear_gaussian_sem(G_latent, 2000, seed=seed + 1)

    # Version observada (sin el confusor X0)
    df_observed = df_latent.drop(columns=['X0'])

    metadata_latent = {
        'type': 'edge_case_latent_confounder',
        'description': 'Latent confounder (X0) affects both treatment and outcome',
        'treatment_var': 'X8',
        'outcome_var': 'X9',
        'latent_var': 'X0',
        'true_ate': float(W_latent[8, 9]),
        'seed': seed + 1
    }
    latent_dir = os.path.join(out_dir, 'latent_confounder')
    os.makedirs(latent_dir, exist_ok=True)
    df_observed.to_csv(os.path.join(latent_dir, 'data_observed.csv'), index=False)
    df_latent.to_csv(os.path.join(latent_dir, 'data_full.csv'), index=False)
    with open(os.path.join(latent_dir, 'metadata.json'), 'w') as f:
        json.dump(metadata_latent, f, indent=2, default=str)
    print("OK")

    # 3. Estructura no identificable (M-graph)
    print("  [3/3] M-graph no identificable...", end=' ')
    G_m = nx.DiGraph()
    G_m.add_nodes_from(range(6))
    # M-graph clasico: X -> M <- U -> Y, X -> Y
    # M es collider, condicionar en M abre camino
    edges_m = [(0, 2), (4, 2), (4, 5), (0, 5), (1, 0), (3, 5)]
    G_m.add_edges_from(edges_m)
    df_m, W_m = generate_linear_gaussian_sem(G_m, 1500, seed=seed + 2)

    metadata_m = {
        'type': 'edge_case_m_graph',
        'description': 'M-graph: conditioning on M opens path X->M<-U->Y',
        'identifiable': False,
        'valid_adjustment_sets': [],
        'seed': seed + 2
    }
    save_dataset_and_graph(df_m, G_m, os.path.join(out_dir, 'm_graph'), metadata_m)
    print("OK")

    print(f"\nGuardados en: {out_dir}")
    return out_dir


# =============================================================================
# MAIN
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Genera datasets sinteticos de benchmark para descubrimiento causal'
    )
    parser.add_argument('--output', '-o', type=str, default='datasets/synthetic',
                       help='Directorio de salida para los datasets')
    parser.add_argument('--category', '-c', type=str,
                       choices=['linear', 'nongaussian', 'nonlinear', 'inference',
                               'timeseries', 'edge_cases', 'all'],
                       default='all',
                       help='Categoria de datasets a generar')
    parser.add_argument('--seed', '-s', type=int, default=42,
                       help='Semilla base para reproducibilidad')
    parser.add_argument('--all', action='store_true',
                       help='Generar todas las categorias')

    args = parser.parse_args()

    # Determinar categorias a generar
    categories = []
    if args.all or args.category == 'all':
        categories = ['linear', 'nongaussian', 'nonlinear', 'inference', 'timeseries', 'edge_cases']
    else:
        categories = [args.category]

    print("\n" + "=" * 70)
    print(" GENERADOR DE DATASETS SINTETICOS - BENCHMARK DATASETS")
    print("=" * 70)
    print(f"Output directory: {args.output}")
    print(f"Categories: {categories}")
    print(f"Base seed: {args.seed}")
    print("=" * 70 + "\n")

    generated_dirs = []

    if 'linear' in categories:
        d = generate_linear_gaussian_benchmarks(args.output, seed=args.seed)
        generated_dirs.append(d)

    if 'nongaussian' in categories:
        d = generate_non_gaussian_benchmarks(args.output, seed=args.seed + 100)
        generated_dirs.append(d)

    if 'nonlinear' in categories:
        d = generate_nonlinear_benchmarks(args.output, seed=args.seed + 200)
        generated_dirs.append(d)

    if 'inference' in categories:
        d = generate_inference_benchmarks(args.output, seed=args.seed + 300)
        generated_dirs.append(d)

    if 'timeseries' in categories:
        d = generate_timeseries_benchmarks(args.output, seed=args.seed + 400)
        generated_dirs.append(d)

    if 'edge_cases' in categories:
        d = generate_edge_cases(args.output, seed=args.seed + 500)
        generated_dirs.append(d)

    # Resumen final
    print("\n" + "=" * 70)
    print(" RESUMEN DE GENERACION")
    print("=" * 70)
    print(f"\nDirectorios generados:")
    for d in generated_dirs:
        count = sum(1 for _ in os.listdir(d) if os.path.isdir(os.path.join(d, _)))
        print(f"  {d}: {count} datasets")

    print(f"\nTodos los datasets guardados en: {args.output}")
    print("\nPara ejecutar benchmarks de descubrimiento:")
    print(f"  python 03_run_discovery_benchmark.py --datasets {args.output}/linear_gaussian")
    print("\nPara ejecutar benchmarks de inferencia:")
    print(f"  python 04_run_inference_benchmark.py --datasets {args.output}/inference")


if __name__ == '__main__':
    main()
