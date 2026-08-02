"""
Utilidades para benchmarks de descubrimiento causal e inferencia causal.

Incluye:
- Generadores de grafos causales (Erdos-Renyi, Scale-Free)
- Modelos de ecuaciones estructurales (SEM) lineales y no lineales
- Funciones de evaluacion metrica (SHD, SID, precision/recall)
- Helpers para guardar/cargar datasets y grafos
"""

import numpy as np
import pandas as pd
import networkx as nx
from typing import Dict, List, Tuple, Optional, Callable
from itertools import combinations
import json
import os
import warnings

warnings.filterwarnings('ignore')

# =============================================================================
# GENERADORES DE GRAFOS CAUSALES
# =============================================================================

def generate_dag_er(num_vars: int, num_edges: int, seed: int = 42) -> nx.DiGraph:
    """
    Genera un DAG usando modelo Erdos-Renyi.
    
    Args:
        num_vars: Numero de nodos
        num_edges: Numero de arcos deseados
        seed: Semilla para reproducibilidad
    
    Returns:
        networkx.DiGraph con estructura causal
    """
    rng = np.random.default_rng(seed)
    nodes = list(range(num_vars))
    
    # Matriz de adyacencia triangular superior (DAG)
    adj = np.zeros((num_vars, num_vars))
    possible_edges = [(i, j) for i in range(num_vars) for j in range(i+1, num_vars)]
    
    rng.shuffle(possible_edges)
    selected = possible_edges[:min(num_edges, len(possible_edges))]
    
    for i, j in selected:
        adj[i, j] = 1
    
    G = nx.from_numpy_array(adj, create_using=nx.DiGraph())
    return G


def generate_dag_sf(num_vars: int, num_edges: int, seed: int = 42) -> nx.DiGraph:
    """
    Genera un DAG con estructura scale-free (Barabasi-Albert adaptado).
    
    Args:
        num_vars: Numero de nodos
        num_edges: Numero de arcos deseados
        seed: Semilla para reproducibilidad
    
    Returns:
        networkx.DiGraph con estructura scale-free
    """
    rng = np.random.default_rng(seed)
    G = nx.DiGraph()
    G.add_nodes_from(range(num_vars))
    
    # Iniciar con 2 nodos conectados
    if num_vars >= 2 and num_edges >= 1:
        G.add_edge(0, 1)
    
    in_degrees = np.zeros(num_vars)
    out_degrees = np.zeros(num_vars)
    
    if num_vars >= 2:
        out_degrees[0] = 1
        in_degrees[1] = 1
    
    # Agregar nodos uno por uno (preferential attachment)
    for new_node in range(2, num_vars):
        num_attach = min(rng.integers(1, 3), num_edges - G.number_of_edges())
        
        for _ in range(num_attach):
            if G.number_of_edges() >= num_edges:
                break
            
            # Preferir nodos con mayor grado de salida como fuentes
            if out_degrees.sum() > 0:
                probs_out = out_degrees[:new_node] / out_degrees[:new_node].sum()
                source = rng.choice(new_node, p=probs_out)
            else:
                source = rng.integers(0, new_node)
            
            if not G.has_edge(source, new_node):
                G.add_edge(source, new_node)
                out_degrees[source] += 1
                in_degrees[new_node] += 1
    
    # Completar hasta num_edges con conexiones aleatorias respetando DAG
    remaining = num_edges - G.number_of_edges()
    attempts = 0
    while remaining > 0 and attempts < 1000:
        i = rng.integers(0, num_vars - 1)
        j = rng.integers(i + 1, num_vars)
        if not G.has_edge(i, j):
            G.add_edge(i, j)
            remaining -= 1
        attempts += 1
    
    return G


def generate_dag_hierarchical(num_vars: int, num_layers: int, 
                               num_edges: int, seed: int = 42) -> nx.DiGraph:
    """
    Genera un DAG jerarquico por capas.
    
    Args:
        num_vars: Numero total de nodos
        num_layers: Numero de capas jerarquicas
        num_edges: Numero de arcos deseados
        seed: Semilla para reproducibilidad
    
    Returns:
        networkx.DiGraph jerarquico
    """
    rng = np.random.default_rng(seed)
    
    # Distribuir nodos en capas
    layer_sizes = []
    remaining = num_vars
    for i in range(num_layers - 1):
        size = max(1, remaining // (num_layers - i))
        layer_sizes.append(size)
        remaining -= size
    layer_sizes.append(remaining)
    
    layers = []
    node_id = 0
    for size in layer_sizes:
        layers.append(list(range(node_id, node_id + size)))
        node_id += size
    
    G = nx.DiGraph()
    G.add_nodes_from(range(num_vars))
    
    # Conectar capas consecutivas
    edges_added = 0
    for l in range(num_layers - 1):
        for source in layers[l]:
            # Cada nodo se conecta al menos a un nodo de la siguiente capa
            target = rng.choice(layers[l + 1])
            G.add_edge(source, target)
            edges_added += 1
    
    # Agregar edges adicionales aleatorios hacia adelante
    attempts = 0
    while edges_added < num_edges and attempts < 5000:
        l1 = rng.integers(0, num_layers - 1)
        l2 = rng.integers(l1 + 1, num_layers)
        source = rng.choice(layers[l1])
        target = rng.choice(layers[l2])
        if not G.has_edge(source, target):
            G.add_edge(source, target)
            edges_added += 1
        attempts += 1
    
    return G


# =============================================================================
# GENERADORES DE MODELOS DE ECUACIONES ESTRUCTURALES (SEM)
# =============================================================================

def generate_linear_gaussian_sem(G: nx.DiGraph, num_samples: int,
                                  weight_range: Tuple[float, float] = (0.5, 2.0),
                                  noise_var: float = 1.0,
                                  seed: int = 42) -> Tuple[pd.DataFrame, np.ndarray]:
    """
    Genera datos de un SEM lineal Gaussiano.
    
    X_j = sum(padres(X_j) * w) + N(0, noise_var)
    
    Args:
        G: Grafo causal (DAG)
        num_samples: Numero de muestras
        weight_range: Rango de pesos causales
        noise_var: Varianza del ruido
        seed: Semilla
    
    Returns:
        (DataFrame con datos, matriz de pesos W)
    """
    rng = np.random.default_rng(seed)
    nodes = sorted(G.nodes())
    n = len(nodes)
    
    # Matriz de pesos
    W = np.zeros((n, n))
    for i, j in G.edges():
        W[i, j] = rng.uniform(*weight_range) * rng.choice([-1, 1])
    
    # Orden topologico para generacion
    topo_order = list(nx.topological_sort(G))
    
    # Generar datos
    X = np.zeros((num_samples, n))
    for node in topo_order:
        parents = list(G.predecessors(node))
        if len(parents) > 0:
            X[:, node] = X[:, parents] @ W[parents, node]
        X[:, node] += rng.normal(0, np.sqrt(noise_var), num_samples)
    
    df = pd.DataFrame(X, columns=[f'X{i}' for i in range(n)])
    return df, W


def generate_linear_non_gaussian_sem(G: nx.DiGraph, num_samples: int,
                                      weight_range: Tuple[float, float] = (0.5, 2.0),
                                      noise_type: str = 'laplace',
                                      seed: int = 42) -> Tuple[pd.DataFrame, np.ndarray]:
    """
    Genera datos de un SEM lineal no Gaussiano (para LiNGAM).
    
    Args:
        G: Grafo causal (DAG)
        num_samples: Numero de muestras
        weight_range: Rango de pesos causales
        noise_type: 'laplace', 'uniform', 'exponential', 'gumbel'
        seed: Semilla
    
    Returns:
        (DataFrame con datos, matriz de pesos W)
    """
    rng = np.random.default_rng(seed)
    nodes = sorted(G.nodes())
    n = len(nodes)
    
    W = np.zeros((n, n))
    for i, j in G.edges():
        W[i, j] = rng.uniform(*weight_range) * rng.choice([-1, 1])
    
    topo_order = list(nx.topological_sort(G))
    
    # Generadores de ruido no Gaussiano
    noise_generators = {
        'laplace': lambda size: rng.laplace(0, 1, size),
        'uniform': lambda size: rng.uniform(-np.sqrt(3), np.sqrt(3), size),
        'exponential': lambda size: rng.exponential(1, size) - 1,
        'gumbel': lambda size: rng.gumbel(0, 1, size),
        't': lambda size: rng.standard_t(5, size),
        'gamma': lambda size: rng.gamma(2, 1, size) - 2
    }
    
    noise_fn = noise_generators.get(noise_type, noise_generators['laplace'])
    
    X = np.zeros((num_samples, n))
    for node in topo_order:
        parents = list(G.predecessors(node))
        if len(parents) > 0:
            X[:, node] = X[:, parents] @ W[parents, node]
        X[:, node] += noise_fn(num_samples)
    
    df = pd.DataFrame(X, columns=[f'X{i}' for i in range(n)])
    return df, W


def generate_nonlinear_sem(G: nx.DiGraph, num_samples: int,
                            nonlinearity: str = 'mlp',
                            seed: int = 42) -> pd.DataFrame:
    """
    Genera datos de un SEM no lineal.
    
    Args:
        G: Grafo causal (DAG)
        num_samples: Numero de muestras
        nonlinearity: 'mlp' (red neuronal), 'polynomial', 'gp' (proceso Gaussiano)
        seed: Semilla
    
    Returns:
        DataFrame con datos no lineales
    """
    rng = np.random.default_rng(seed)
    nodes = sorted(G.nodes())
    n = len(nodes)
    
    topo_order = list(nx.topological_sort(G))
    X = np.zeros((num_samples, n))
    
    for node in topo_order:
        parents = list(G.predecessors(node))
        
        if len(parents) == 0:
            X[:, node] = rng.normal(0, 1, num_samples)
        else:
            parent_data = X[:, parents]
            
            if nonlinearity == 'mlp':
                # MLP simple con 1 capa oculta
                hidden_dim = max(2, len(parents) * 2)
                W1 = rng.normal(0, 1, (len(parents), hidden_dim))
                b1 = rng.normal(0, 0.5, hidden_dim)
                W2 = rng.normal(0, 1, hidden_dim)
                b2 = 0
                
                hidden = np.maximum(parent_data @ W1 + b1, 0)  # ReLU
                X[:, node] = hidden @ W2 + b2 + rng.normal(0, 0.5, num_samples)
            
            elif nonlinearity == 'polynomial':
                # Polinomio de grado 2
                result = np.zeros(num_samples)
                coeffs = rng.normal(0, 1, len(parents))
                for i, p in enumerate(parents):
                    result += coeffs[i] * parent_data[:, i]
                    result += 0.3 * parent_data[:, i] ** 2
                # Interacciones de pares
                for i in range(len(parents)):
                    for j in range(i+1, len(parents)):
                        result += 0.2 * parent_data[:, i] * parent_data[:, j]
                X[:, node] = result + rng.normal(0, 0.5, num_samples)
            
            elif nonlinearity == 'gp':
                # Simulacion de GP con kernel RBF
                result = np.zeros(num_samples)
                for i, p in enumerate(parents):
                    result += np.sin(2 * parent_data[:, i]) + 0.5 * parent_data[:, i] ** 2
                X[:, node] = result + rng.normal(0, 0.5, num_samples)
    
    df = pd.DataFrame(X, columns=[f'X{i}' for i in range(n)])
    return df


def generate_heteroscedastic_sem(G: nx.DiGraph, num_samples: int,
                                  seed: int = 42) -> pd.DataFrame:
    """
    Genera SEM con ruido heteroscedastico (varianza depende de padres).
    Util para probar robustez de metodos.
    """
    rng = np.random.default_rng(seed)
    nodes = sorted(G.nodes())
    n = len(nodes)
    topo_order = list(nx.topological_sort(G))
    X = np.zeros((num_samples, n))
    
    for node in topo_order:
        parents = list(G.predecessors(node))
        if len(parents) == 0:
            X[:, node] = rng.normal(0, 1, num_samples)
        else:
            parent_data = X[:, parents]
            mean_effect = parent_data.sum(axis=1) * 0.5
            # Varianza depende de la magnitud de los padres
            noise_var = 0.1 + np.abs(parent_data).mean(axis=1) * 0.5
            X[:, node] = mean_effect + rng.normal(0, 1, num_samples) * np.sqrt(noise_var)
    
    df = pd.DataFrame(X, columns=[f'X{i}' for i in range(n)])
    return df


# =============================================================================
# DATASETS PARA INFERENCIA CAUSAL (TRATAMIENTO)
# =============================================================================

def generate_ihdp_synthetic(num_samples: int = 1000, seed: int = 42,
                             num_covariates: int = 25) -> Tuple[pd.DataFrame, Dict]:
    """
    Genera datos sinteticos estilo IHDP para inferencia causal.
    
    Simula el Infant Health and Development Program con:
    - Covariables continuas y binarias (caracteristicas del nino y madre)
    - Tratamiento binario (programa de intervencion)
    - Outcomes potenciales Y(0) y Y(1) observables
    - Efecto de tratamiento heterogeneo
    
    Args:
        num_samples: Numero de unidades
        seed: Semilla
        num_covariates: Numero de covariables
    
    Returns:
        (DataFrame, metadata con ground truth)
    """
    rng = np.random.default_rng(seed)
    n = num_samples
    
    # Covariables (mixtas)
    X = rng.normal(0, 1, (n, num_covariates))
    
    # Tratamiento con sesgo de seleccion (no completamente aleatorio)
    # Mas probable recibir tratamiento si covariables indican riesgo
    logit_ps = -0.5 + 0.3 * X[:, 0] + 0.2 * X[:, 1] - 0.15 * X[:, 2] + 0.1 * X[:, 3]
    ps = 1 / (1 + np.exp(-logit_ps))
    T = rng.binomial(1, ps)
    
    # Outcome potencial Y(0) - control
    Y0 = (50 + 10 * X[:, 0] + 5 * X[:, 1] + 3 * X[:, 4] + 2 * X[:, 5] 
          + X[:, 6] * X[:, 7] + rng.normal(0, 5, n))
    
    # Efecto de tratamiento heterogeneo (ATE ≈ 4.0)
    tau = 4.0 + 2.0 * X[:, 0] + 1.5 * X[:, 2] - X[:, 3]
    
    # Outcome potencial Y(1) - tratado
    Y1 = Y0 + tau
    
    # Outcome observado
    Y = T * Y1 + (1 - T) * Y0
    
    # Crear DataFrame
    df = pd.DataFrame(X, columns=[f'x{i}' for i in range(num_covariates)])
    df['treatment'] = T
    df['outcome'] = Y
    df['y0'] = Y0  # Ground truth (normalmente no observable)
    df['y1'] = Y1  # Ground truth
    df['tau'] = tau  # Efecto individual
    
    metadata = {
        'ate_true': float(tau.mean()),
        'att_true': float(tau[T == 1].mean()),
        'seed': seed,
        'num_samples': n,
        'num_covariates': num_covariates,
        'treatment_ratio': float(T.mean()),
        'description': 'IHDP-style synthetic dataset with heterogeneous treatment effects'
    }
    
    return df, metadata


def generate_lalonde_style(num_samples: int = 1000, seed: int = 42) -> Tuple[pd.DataFrame, Dict]:
    """
    Genera datos estilo LaLonde para evaluacion de programas.
    
    Simula un programa de entrenamiento laboral con:
    - Covariables demograficas
    - Ingresos pre-tratamiento
    - Tratamiento (participacion en programa)
    - Outcome: ingresos post-tratamiento
    
    Args:
        num_samples: Numero de unidades
        seed: Semilla
    
    Returns:
        (DataFrame, metadata)
    """
    rng = np.random.default_rng(seed)
    n = num_samples
    
    # Covariables demograficas
    age = rng.integers(18, 55, n)
    educ = rng.integers(5, 17, n)
    black = rng.binomial(1, 0.25, n)
    hispan = rng.binomial(1, 0.15, n)
    married = rng.binomial(1, 0.5, n)
    nodegree = (educ < 12).astype(int)
    
    # Ingresos pre-tratamiento (con tendencia)
    re74 = np.maximum(0, 5 * age + 200 * educ + 1000 * married + rng.normal(5000, 3000, n))
    re75 = re74 * 0.9 + rng.normal(200, 2000, n)
    
    # Tratamiento (sesgado hacia desempleados)
    logit_ps = (-1.0 - 0.02 * age + 0.05 * educ - 0.3 * married 
                - 0.001 * re74 / 1000 + 0.5 * nodegree)
    ps = 1 / (1 + np.exp(-logit_ps))
    T = rng.binomial(1, ps)
    
    # Outcome potencial sin tratamiento
    Y0 = (2000 + 30 * age + 100 * educ + 500 * married 
          + 0.3 * re74 + rng.normal(0, 4000, n))
    
    # Efecto de tratamiento (ATE ≈ 1800, similar a NSW)
    tau = 1800 + 50 * educ - 20 * age + rng.normal(0, 500, n)
    Y1 = Y0 + tau
    
    # Outcome observado
    Y = T * Y1 + (1 - T) * Y0
    
    df = pd.DataFrame({
        'age': age,
        'educ': educ,
        'black': black,
        'hispan': hispan,
        'married': married,
        'nodegree': nodegree,
        're74': re74,
        're75': re75,
        'treatment': T,
        're78': Y,
        'y0': Y0,
        'y1': Y1,
        'tau': tau
    })
    
    metadata = {
        'ate_true': float(tau.mean()),
        'att_true': float(tau[T == 1].mean()),
        'seed': seed,
        'description': 'LaLonde-style job training program evaluation'
    }
    
    return df, metadata


def generate_twins_style(num_samples: int = 2000, seed: int = 42) -> Tuple[pd.DataFrame, Dict]:
    """
    Genera datos estilo Twins para inferencia con gemelos.
    
    Simula datos de gemelos donde:
    - Ambos outcomes son observables (diferencia intra-gemelar)
    - El tratamiento es el peso al nacer (bajo = 1)
    - El outcome es mortalidad en el primer ano
    
    Args:
        num_samples: Numero de pares de gemelos
        seed: Semilla
    
    Returns:
        (DataFrame, metadata)
    """
    rng = np.random.default_rng(seed)
    n_pairs = num_samples // 2
    
    # Covariables compartidas por el par de gemelos
    mother_age = rng.integers(15, 45, n_pairs)
    mother_educ = rng.integers(8, 20, n_pairs)
    prenatal_care = rng.binomial(1, 0.8, n_pairs)
    gestation = rng.normal(38, 2, n_pairs)
    
    # Para cada gemelo
    data_list = []
    for i in range(n_pairs):
        for twin in [0, 1]:
            # Peso al nacer afectado por covariables
            birth_weight = (2000 + 100 * gestation[i] + 50 * prenatal_care[i] 
                          + rng.normal(0, 300))
            birth_weight = max(500, birth_weight)  # Minimo 500g
            
            # Tratamiento = bajo peso (< 2500g)
            low_bw = 1 if birth_weight < 2500 else 0
            
            # Mortalidad (outcome)
            logit_mort = (-5.0 + 0.002 * (2500 - birth_weight) 
                         - 0.05 * mother_age[i] + 0.1 * (1 - prenatal_care[i]))
            mortality = rng.binomial(1, 1 / (1 + np.exp(-logit_mort)))
            
            data_list.append({
                'pair_id': i,
                'twin_id': twin,
                'mother_age': mother_age[i],
                'mother_educ': mother_educ[i],
                'prenatal_care': prenatal_care[i],
                'gestation': gestation[i],
                'birth_weight': birth_weight,
                'treatment': low_bw,
                'mortality': mortality
            })
    
    df = pd.DataFrame(data_list)
    
    # Calcular ATE verdadero usando diferencias intra-gemelares
    ate_true = df.groupby('pair_id').apply(
        lambda x: x.loc[x['treatment'] == 1, 'mortality'].mean() 
                  - x.loc[x['treatment'] == 0, 'mortality'].mean() 
                  if len(x['treatment'].unique()) > 1 else np.nan
    ).dropna().mean()
    
    metadata = {
        'ate_true': float(ate_true) if not np.isnan(ate_true) else 0.0,
        'num_pairs': n_pairs,
        'seed': seed,
        'description': 'Twins-style low birth weight mortality study'
    }
    
    return df, metadata


# =============================================================================
# SERIES TEMPORALES PARA PCMCI
# =============================================================================

def generate_var_process(num_vars: int, num_lags: int, num_samples: int,
                          sparsity: float = 0.3, seed: int = 42) -> Tuple[pd.DataFrame, Dict]:
    """
    Genera proceso VAR (Vector Autoregressive) para probar PCMCI.
    
    X_t = sum(A_l * X_{t-l}) + eps_t
    
    Args:
        num_vars: Numero de variables
        num_lags: Numero de retardos
        num_samples: Longitud de la serie
        sparsity: Proporcion de ceros en matrices de coeficientes
        seed: Semilla
    
    Returns:
        (DataFrame, metadata con ground truth de relaciones causales)
    """
    rng = np.random.default_rng(seed)
    
    # Generar matrices de coeficientes para cada lag
    A = []
    causal_links = []
    
    for lag in range(1, num_lags + 1):
        A_l = rng.normal(0, 0.3, (num_vars, num_vars))
        # Hacer esparsa
        mask = rng.random((num_vars, num_vars)) > sparsity
        A_l = A_l * mask
        A.append(A_l)
        
        # Registrar links causales
        for i in range(num_vars):
            for j in range(num_vars):
                if abs(A_l[i, j]) > 0.01:
                    causal_links.append({
                        'source': i,
                        'target': j,
                        'lag': lag,
                        'coefficient': float(A_l[i, j])
                    })
    
    # Asegurar estabilidad (autovalores dentro del circulo unitario)
    companion = np.zeros((num_vars * num_lags, num_vars * num_lags))
    for l in range(num_lags):
        companion[:num_vars, l*num_vars:(l+1)*num_vars] = A[l]
    companion[num_vars:, :-num_vars] = np.eye(num_vars * (num_lags - 1))
    
    eigenvalues = np.linalg.eigvals(companion)
    max_eig = max(abs(eigenvalues))
    
    # Escalar si inestable
    if max_eig >= 1:
        scale = 0.95 / max_eig
        A = [a * scale for a in A]
    
    # Generar serie temporal
    X = np.zeros((num_samples, num_vars))
    # Condiciones iniciales
    for t in range(num_lags):
        X[t, :] = rng.normal(0, 1, num_vars)
    
    for t in range(num_lags, num_samples):
        for lag in range(1, num_lags + 1):
            X[t, :] += X[t - lag, :] @ A[lag - 1]
        X[t, :] += rng.normal(0, 0.5, num_vars)
    
    # Crear DataFrame con lags como columnas
    columns = [f'X{i}' for i in range(num_vars)]
    df = pd.DataFrame(X, columns=columns)
    
    metadata = {
        'num_vars': num_vars,
        'num_lags': num_lags,
        'num_samples': num_samples,
        'sparsity': sparsity,
        'causal_links': causal_links,
        'seed': seed
    }
    
    return df, metadata


def generate_nonlinear_timeseries(num_vars: int, num_samples: int,
                                   seed: int = 42) -> Tuple[pd.DataFrame, Dict]:
    """
    Genera series temporales con relaciones causales no lineales.
    
    Utiliza funciones no lineales: sin(x), x^2, tanh(x)
    """
    rng = np.random.default_rng(seed)
    
    X = np.zeros((num_samples, num_vars))
    causal_links = []
    
    # Inicializar
    for i in range(num_vars):
        X[0, i] = rng.normal(0, 1)
    
    # Generar con relaciones no lineales
    for t in range(1, num_samples):
        for i in range(num_vars):
            if i == 0:
                X[t, i] = 0.5 * np.sin(X[t-1, i]) + 0.3 * X[t-1, (i+1) % num_vars] + rng.normal(0, 0.3)
                causal_links.append({'source': (i+1) % num_vars, 'target': i, 'lag': 1, 'type': 'linear'})
            elif i == 1:
                X[t, i] = 0.4 * (X[t-1, i-1] ** 2) * 0.1 + 0.5 * X[t-1, i] + rng.normal(0, 0.3)
                causal_links.append({'source': i-1, 'target': i, 'lag': 1, 'type': 'nonlinear'})
            else:
                X[t, i] = 0.3 * np.tanh(X[t-1, i-1]) + 0.4 * X[t-1, i] + 0.2 * X[t-1, (i+1) % num_vars] + rng.normal(0, 0.3)
                causal_links.append({'source': i-1, 'target': i, 'lag': 1, 'type': 'nonlinear'})
                causal_links.append({'source': (i+1) % num_vars, 'target': i, 'lag': 1, 'type': 'linear'})
    
    columns = [f'X{i}' for i in range(num_vars)]
    df = pd.DataFrame(X, columns=columns)
    
    metadata = {
        'num_vars': num_vars,
        'num_samples': num_samples,
        'causal_links': causal_links,
        'seed': seed,
        'type': 'nonlinear'
    }
    
    return df, metadata


# =============================================================================
# METRICAS DE EVALUACION - DESCUBRIMIENTO CAUSAL
# =============================================================================

def dag_to_cpdag(G: nx.DiGraph) -> nx.Graph:
    """
    Convierte un DAG a su CPDAG (Completed Partially Directed Acyclic Graph).
    Representa la clase de equivalencia Markoviana.
    
    Los arcos que no son parte de un v-structure se hacen no dirigidos.
    """
    cpdag = G.to_undirected()
    
    # Identificar v-structures: A -> B <- C donde A y C no son adyacentes
    for node in G.nodes():
        parents = list(G.predecessors(node))
        for i in range(len(parents)):
            for j in range(i + 1, len(parents)):
                p1, p2 = parents[i], parents[j]
                if not G.has_edge(p1, p2) and not G.has_edge(p2, p1):
                    # V-structure: mantener direccion
                    if cpdag.has_edge(p1, node):
                        cpdag[p1][node]['directed'] = True
                    if cpdag.has_edge(p2, node):
                        cpdag[p2][node]['directed'] = True
    
    return cpdag


def structural_hamming_distance(G_true: nx.DiGraph, G_est: nx.DiGraph) -> int:
    """
    Calcula la Structural Hamming Distance (SHD) entre dos DAGs.
    
    SHD = numero minimo de operaciones (add/remove/reverse edge) 
          para convertir G_est en G_true
    """
    nodes = sorted(set(G_true.nodes()) | set(G_est.nodes()))
    n = len(nodes)
    
    # Matrices de adyacencia
    A_true = nx.to_numpy_array(G_true, nodelist=nodes)
    A_est = nx.to_numpy_array(G_est, nodelist=nodes)
    
    # SHD: contar diferencias (ignorando direccion en parte)
    # Para DAGs puros: diferencias en la matriz de adyacencia
    diff = np.abs(A_true - A_est)
    
    # Sumar diferencias considerando que una inversión cuenta como 1
    shd = 0
    for i in range(n):
        for j in range(i + 1, n):
            true_ij = A_true[i, j]
            true_ji = A_true[j, i]
            est_ij = A_est[i, j]
            est_ji = A_est[j, i]
            
            if (true_ij, true_ji) == (est_ij, est_ji):
                continue
            elif true_ij + true_ji == est_ij + est_ji:
                # Misma estructura subyacente, diferente direccion
                shd += 1
            else:
                # Diferencia estructural
                shd += abs((true_ij + true_ji) - (est_ij + est_ji))
    
    return shd


def precision_recall_f1(G_true: nx.DiGraph, G_est: nx.DiGraph) -> Dict[str, float]:
    """
    Calcula precision, recall y F1 para la deteccion de arcos.
    
    Considera:
    - Skeleton: arco sin importar direccion
    - Orientacion: direccion correcta del arco
    """
    # Arcos verdaderos (skeleton)
    true_edges = set()
    for i, j in G_true.edges():
        true_edges.add(tuple(sorted([i, j])))
    
    # Arcos estimados (skeleton)
    est_edges = set()
    for i, j in G_est.edges():
        est_edges.add(tuple(sorted([i, j])))
    
    # Arcos con direccion correcta
    true_directed = set(G_true.edges())
    est_directed = set(G_est.edges())
    
    # Skeleton metrics
    tp_skeleton = len(true_edges & est_edges)
    fp_skeleton = len(est_edges - true_edges)
    fn_skeleton = len(true_edges - est_edges)
    
    precision_skeleton = tp_skeleton / (tp_skeleton + fp_skeleton) if (tp_skeleton + fp_skeleton) > 0 else 0
    recall_skeleton = tp_skeleton / (tp_skeleton + fn_skeleton) if (tp_skeleton + fn_skeleton) > 0 else 0
    f1_skeleton = 2 * precision_skeleton * recall_skeleton / (precision_skeleton + recall_skeleton) if (precision_skeleton + recall_skeleton) > 0 else 0
    
    # Directed metrics
    tp_directed = len(true_directed & est_directed)
    fp_directed = len(est_directed - true_directed)
    fn_directed = len(true_directed - est_directed)
    
    precision_dir = tp_directed / (tp_directed + fp_directed) if (tp_directed + fp_directed) > 0 else 0
    recall_dir = tp_directed / (tp_directed + fn_directed) if (tp_directed + fn_directed) > 0 else 0
    f1_dir = 2 * precision_dir * recall_dir / (precision_dir + recall_dir) if (precision_dir + recall_dir) > 0 else 0
    
    return {
        'precision_skeleton': precision_skeleton,
        'recall_skeleton': recall_skeleton,
        'f1_skeleton': f1_skeleton,
        'precision_directed': precision_dir,
        'recall_directed': recall_dir,
        'f1_directed': f1_dir,
        'shd': structural_hamming_distance(G_true, G_est)
    }


def orientation_precision_recall(G_true: nx.DiGraph, G_est: nx.DiGraph) -> Dict[str, float]:
    """
    Metricas especificas de orientacion: de los arcos correctamente detectados,
    cuantos tienen la direccion correcta?
    """
    true_edges = set()
    for i, j in G_true.edges():
        true_edges.add(tuple(sorted([i, j])))
    
    est_edges = set()
    for i, j in G_est.edges():
        est_edges.add(tuple(sorted([i, j])))
    
    # Arcos en comun (skeleton correcto)
    common_skeleton = true_edges & est_edges
    
    if len(common_skeleton) == 0:
        return {'orientation_precision': 0, 'orientation_recall': 0}
    
    # Verificar orientacion correcta
    correct_orientation = 0
    for i, j in G_est.edges():
        edge = tuple(sorted([i, j]))
        if edge in true_edges and G_true.has_edge(i, j):
            correct_orientation += 1
    
    # Arcos verdaderos cuyo skeleton fue detectado
    true_with_correct_skeleton = 0
    for i, j in G_true.edges():
        edge = tuple(sorted([i, j]))
        if edge in est_edges:
            true_with_correct_skeleton += 1
    
    orientation_precision = correct_orientation / len(est_edges) if len(est_edges) > 0 else 0
    orientation_recall = correct_orientation / true_with_correct_skeleton if true_with_correct_skeleton > 0 else 0
    
    return {
        'orientation_precision': orientation_precision,
        'orientation_recall': orientation_recall,
        'correctly_oriented': correct_orientation,
        'common_skeleton': len(common_skeleton)
    }


# =============================================================================
# METRICAS DE EVALUACION - INFERENCIA CAUSAL
# =============================================================================

def ate_error(ate_true: float, ate_est: float) -> Dict[str, float]:
    """Error en la estimacion del ATE."""
    return {
        'ate_true': ate_true,
        'ate_estimated': ate_est,
        'absolute_error': abs(ate_true - ate_est),
        'relative_error': abs(ate_true - ate_est) / abs(ate_true) if ate_true != 0 else float('inf'),
        'bias': ate_est - ate_true
    }


def pehe(tau_true: np.ndarray, tau_est: np.ndarray) -> Dict[str, float]:
    """
    Precision en Estimacion de Efectos Heterogeneos (PEHE).
    
    PEHE = sqrt(mean((tau_true - tau_est)^2))
    """
    pehe_val = np.sqrt(np.mean((tau_true - tau_est) ** 2))
    return {
        'pehe': float(pehe_val),
        'pehe_squared': float(np.mean((tau_true - tau_est) ** 2)),
        'mae_tau': float(np.mean(np.abs(tau_true - tau_est)))
    }


def coverage_and_length(ate_true: float, ci_lower: float, ci_upper: float) -> Dict[str, float]:
    """
    Cobertura del intervalo de confianza y su longitud.
    """
    covered = ci_lower <= ate_true <= ci_upper
    return {
        'covered': bool(covered),
        'ci_lower': ci_lower,
        'ci_upper': ci_upper,
        'ci_length': ci_upper - ci_lower,
        'ate_true': ate_true
    }


# =============================================================================
# GUARDAR Y CARGAR
# =============================================================================

def save_dataset_and_graph(df: pd.DataFrame, G: nx.DiGraph, output_dir: str,
                            metadata: Optional[Dict] = None):
    """
    Guarda dataset y grafo causal en un directorio.
    
    Estructura de salida:
    - data.csv: Dataset en formato CSV
    - graph_adjmatrix.csv: Matriz de adyacencia
    - graph_edges.csv: Lista de arcos
    - metadata.json: Metadatos (opcional)
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Dataset
    df.to_csv(os.path.join(output_dir, 'data.csv'), index=False)
    
    # Matriz de adyacencia
    nodes = sorted(G.nodes())
    adj_matrix = nx.to_numpy_array(G, nodelist=nodes)
    adj_df = pd.DataFrame(adj_matrix, index=[f'X{i}' for i in nodes], 
                           columns=[f'X{i}' for i in nodes])
    adj_df.to_csv(os.path.join(output_dir, 'graph_adjmatrix.csv'))
    
    # Lista de arcos
    edges_df = pd.DataFrame(list(G.edges()), columns=['source', 'target'])
    edges_df.to_csv(os.path.join(output_dir, 'graph_edges.csv'), index=False)
    
    # Metadatos
    if metadata:
        meta = metadata.copy()
        # Convertir tipos no serializables
        if 'causal_links' in meta:
            meta['causal_links'] = [{k: v for k, v in link.items()} for link in meta['causal_links']]
        with open(os.path.join(output_dir, 'metadata.json'), 'w') as f:
            json.dump(meta, f, indent=2, default=str)


def load_dataset_and_graph(input_dir: str) -> Tuple[pd.DataFrame, nx.DiGraph, Dict]:
    """
    Carga dataset y grafo causal desde un directorio.
    """
    df = pd.read_csv(os.path.join(input_dir, 'data.csv'))
    
    adj_df = pd.read_csv(os.path.join(input_dir, 'graph_adjmatrix.csv'), index_col=0)
    G = nx.from_pandas_adjacency(adj_df, create_using=nx.DiGraph())
    
    metadata = {}
    meta_path = os.path.join(input_dir, 'metadata.json')
    if os.path.exists(meta_path):
        with open(meta_path, 'r') as f:
            metadata = json.load(f)
    
    return df, G, metadata


# =============================================================================
# UTILIDADES ADICIONALES
# =============================================================================

def summarize_dataset(df: pd.DataFrame, G: Optional[nx.DiGraph] = None) -> Dict:
    """
    Genera resumen estadistico de un dataset.
    """
    summary = {
        'n_samples': len(df),
        'n_variables': len(df.columns),
        'variable_types': {col: str(df[col].dtype) for col in df.columns},
        'missing_values': df.isnull().sum().to_dict(),
        'descriptive_stats': df.describe().to_dict()
    }
    
    if G is not None:
        summary['graph_stats'] = {
            'n_nodes': G.number_of_nodes(),
            'n_edges': G.number_of_edges(),
            'density': nx.density(G),
            'max_in_degree': max([G.in_degree(n) for n in G.nodes()]) if G.number_of_nodes() > 0 else 0,
            'max_out_degree': max([G.out_degree(n) for n in G.nodes()]) if G.number_of_nodes() > 0 else 0
        }
    
    return summary


def print_benchmark_summary(benchmark_results: Dict):
    """Imprime resumen formateado de resultados de benchmark."""
    print("=" * 60)
    print("RESUMEN DE BENCHMARK")
    print("=" * 60)
    
    for dataset_name, results in benchmark_results.items():
        print(f"\n{dataset_name}:")
        print("-" * 40)
        for metric, value in results.items():
            if isinstance(value, float):
                print(f"  {metric}: {value:.4f}")
            else:
                print(f"  {metric}: {value}")
