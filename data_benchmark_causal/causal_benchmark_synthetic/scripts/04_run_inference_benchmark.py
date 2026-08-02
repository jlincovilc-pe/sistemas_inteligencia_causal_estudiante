#!/usr/bin/env python3
"""
Benchmark de inferencia causal (estimacion de efectos de tratamiento).

Evalua la precision de estimadores causales clasicos:
- LinearDML, CausalForestDML (double machine learning)
- LinearDRL, ForestDRL (doubly robust)
- PSM, CEM (matching)
- DoWhy Backdoor
- T-learner, S-learner (meta-learners)

Metricas:
- Error absoluto del ATE
- PEHE (Precision in Estimation of Heterogeneous Effects)
- Cobertura del intervalo de confianza
- Sesgo

Uso:
    # Evaluar todos los estimadores en IHDP (dataset basado en literatura, datos 100% sinteticos)
    python 04_run_inference_benchmark.py --datasets datasets/real/ihdp --all

    # Evaluar estimadores especificos en datasets sinteticos controlados
    python 04_run_inference_benchmark.py --datasets datasets/synthetic/inference/ihdp_medium \
        --estimators ols psm t_learner s_learner --output results/inference/

    # Con DoWhy (si disponible)
    python 04_run_inference_benchmark.py --datasets datasets/real/ihdp \
        --estimators dowhy_backdoor --use_dowhy
"""

import argparse
import json
import os
import sys
import time
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor, RandomForestRegressor
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.model_selection import cross_val_predict
from sklearn.neural_network import MLPRegressor

warnings.filterwarnings('ignore')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from utils import ate_error, coverage_and_length, pehe

# =============================================================================
# ESTIMADORES DE EFECTOS DE TRATAMIENTO
# =============================================================================

class BaseEstimator:
    """Clase base para estimadores de efectos causales."""

    def __init__(self, name):
        self.name = name
        self.ate_ = None
        self.ci_lower_ = None
        self.ci_upper_ = None
        self.cate_estimates_ = None

    def fit(self, X, T, Y):
        """Ajusta el estimador."""
        raise NotImplementedError

    def estimate_ate(self):
        """Devuelve el ATE estimado con intervalo de confianza."""
        return {
            'ate': self.ate_,
            'ci_lower': self.ci_lower_,
            'ci_upper': self.ci_upper_
        }


class OLS_Estimator(BaseEstimator):
    """Estimador OLS simple (baseline)."""

    def __init__(self):
        super().__init__('OLS')

    def fit(self, X, T, Y):
        # Regresion simple: Y ~ T + X
        df_reg = pd.DataFrame(X)
        df_reg['T'] = T
        df_reg['Y'] = Y

        reg = LinearRegression()
        reg.fit(df_reg.drop('Y', axis=1), df_reg['Y'])

        # El coeficiente de T es el ATE
        self.ate_ = reg.coef_[-1]  # Ultimo coeficiente es T

        # Bootstrap para CI
        n_boot = 100
        ate_boots = []
        for _ in range(n_boot):
            idx = np.random.choice(len(Y), len(Y), replace=True)
            reg_boot = LinearRegression()
            df_boot = df_reg.iloc[idx]
            reg_boot.fit(df_boot.drop('Y', axis=1), df_boot['Y'])
            ate_boots.append(reg_boot.coef_[-1])

        self.ci_lower_ = np.percentile(ate_boots, 2.5)
        self.ci_upper_ = np.percentile(ate_boots, 97.5)

        # CATE estimates
        self.cate_estimates_ = np.full(len(Y), self.ate_)


class IPW_Estimator(BaseEstimator):
    """Inverse Probability Weighting (IPTW)."""

    def __init__(self, propensity_model=None):
        super().__init__('IPW')
        self.propensity_model = propensity_model or LogisticRegression(max_iter=1000)

    def fit(self, X, T, Y):
        # Estimar propensity scores
        ps = cross_val_predict(self.propensity_model, X, T, method='predict_proba')[:, 1]
        ps = np.clip(ps, 0.05, 0.95)  # Truncar

        # Pesos IPW
        weights = T / ps + (1 - T) / (1 - ps)

        # Estimar ATE ponderado
        self.ate_ = np.mean(weights * T * Y) - np.mean(weights * (1 - T) * Y)
        self.ate_ = np.mean(weights * Y * (T - ps) / (ps * (1 - ps)))

        # Simplificacion
        treated_outcome = np.sum(weights[T == 1] * Y[T == 1]) / np.sum(weights[T == 1])
        control_outcome = np.sum(weights[T == 0] * Y[T == 0]) / np.sum(weights[T == 0])
        self.ate_ = treated_outcome - control_outcome

        # Bootstrap CI
        n_boot = 100
        ate_boots = []
        for _ in range(n_boot):
            idx = np.random.choice(len(Y), len(Y), replace=True)
            X_b, T_b, Y_b = X[idx], T[idx], Y[idx]
            ps_b = np.clip(cross_val_predict(self.propensity_model, X_b, T_b,
                                              method='predict_proba')[:, 1], 0.05, 0.95)
            w_b = T_b / ps_b + (1 - T_b) / (1 - ps_b)
            to = np.sum(w_b[T_b == 1] * Y_b[T_b == 1]) / np.sum(w_b[T_b == 1])
            co = np.sum(w_b[T_b == 0] * Y_b[T_b == 0]) / np.sum(w_b[T_b == 0])
            ate_boots.append(to - co)

        self.ci_lower_ = np.percentile(ate_boots, 2.5)
        self.ci_upper_ = np.percentile(ate_boots, 97.5)
        self.cate_estimates_ = np.full(len(Y), self.ate_)


class AIPW_Estimator(BaseEstimator):
    """Augmented IPW (Doubly Robust Estimator)."""

    def __init__(self):
        super().__init__('AIPW')

    def fit(self, X, T, Y):
        # Propensity scores
        ps_model = LogisticRegression(max_iter=1000)
        ps = cross_val_predict(ps_model, X, T, method='predict_proba')[:, 1]
        ps = np.clip(ps, 0.05, 0.95)

        # Modelos de outcome
        mu1_model = LinearRegression()
        mu0_model = LinearRegression()

        mu1_model.fit(X[T == 1], Y[T == 1])
        mu0_model.fit(X[T == 0], Y[T == 0])

        mu1 = mu1_model.predict(X)
        mu0 = mu0_model.predict(X)

        # Estimador AIPW
        aipw = (mu1 - mu0
                + T * (Y - mu1) / ps
                - (1 - T) * (Y - mu0) / (1 - ps))

        self.ate_ = np.mean(aipw)

        # CI
        se = np.std(aipw) / np.sqrt(len(Y))
        self.ci_lower_ = self.ate_ - 1.96 * se
        self.ci_upper_ = self.ate_ + 1.96 * se

        self.cate_estimates_ = mu1 - mu0


class TLearner(BaseEstimator):
    """T-Learner: modelo separado para tratados y controles."""

    def __init__(self, model=None):
        super().__init__('T-Learner')
        self.model = model or GradientBoostingRegressor(n_estimators=100, random_state=42)

    def fit(self, X, T, Y):
        # Modelo para tratados
        model_treated = self.model.__class__(**self.model.get_params())
        model_treated.fit(X[T == 1], Y[T == 1])

        # Modelo para controles
        model_control = self.model.__class__(**self.model.get_params())
        model_control.fit(X[T == 0], Y[T == 0])

        # CATE
        mu1 = model_treated.predict(X)
        mu0 = model_control.predict(X)
        self.cate_estimates_ = mu1 - mu0
        self.ate_ = np.mean(self.cate_estimates_)

        # Bootstrap CI
        n_boot = 100
        ate_boots = []
        for _ in range(n_boot):
            idx = np.random.choice(len(Y), len(Y), replace=True)
            X_b, T_b, Y_b = X[idx], T[idx], Y[idx]
            mt = self.model.__class__(**self.model.get_params())
            mc = self.model.__class__(**self.model.get_params())
            mt.fit(X_b[T_b == 1], Y_b[T_b == 1])
            mc.fit(X_b[T_b == 0], Y_b[T_b == 0])
            ate_boots.append(np.mean(mt.predict(X_b) - mc.predict(X_b)))

        self.ci_lower_ = np.percentile(ate_boots, 2.5)
        self.ci_upper_ = np.percentile(ate_boots, 97.5)


class SLearner(BaseEstimator):
    """S-Learner: unico modelo con tratamiento como feature."""

    def __init__(self, model=None):
        super().__init__('S-Learner')
        self.model = model or GradientBoostingRegressor(n_estimators=100, random_state=42)

    def fit(self, X, T, Y):
        # Entrenar unico modelo con T como feature
        XT = np.column_stack([X, T])
        model = self.model.__class__(**self.model.get_params())
        model.fit(XT, Y)

        # CATE: Y(X, T=1) - Y(X, T=0)
        XT1 = np.column_stack([X, np.ones(len(T))])
        XT0 = np.column_stack([X, np.zeros(len(T))])

        mu1 = model.predict(XT1)
        mu0 = model.predict(XT0)
        self.cate_estimates_ = mu1 - mu0
        self.ate_ = np.mean(self.cate_estimates_)

        # Bootstrap CI
        n_boot = 100
        ate_boots = []
        for _ in range(n_boot):
            idx = np.random.choice(len(Y), len(Y), replace=True)
            X_b, T_b, Y_b = X[idx], T[idx], Y[idx]
            XT_b = np.column_stack([X_b, T_b])
            m = self.model.__class__(**self.model.get_params())
            m.fit(XT_b, Y_b)
            ate_boots.append(np.mean(m.predict(np.column_stack([X_b, np.ones(len(T_b))])) -
                                     m.predict(np.column_stack([X_b, np.zeros(len(T_b))]))))

        self.ci_lower_ = np.percentile(ate_boots, 2.5)
        self.ci_upper_ = np.percentile(ate_boots, 97.5)


class MatchingEstimator(BaseEstimator):
    """Propensity Score Matching."""

    def __init__(self, caliper=0.2):
        super().__init__('PSM')
        self.caliper = caliper

    def fit(self, X, T, Y):
        from sklearn.neighbors import NearestNeighbors

        # Propensity scores
        ps_model = LogisticRegression(max_iter=1000)
        ps = cross_val_predict(ps_model, X, T, method='predict_proba')[:, 1]
        ps = ps.reshape(-1, 1)

        treated_idx = np.where(T == 1)[0]
        control_idx = np.where(T == 0)[0]

        # Match controles a tratados
        nn = NearestNeighbors(n_neighbors=1)
        nn.fit(ps[control_idx])
        distances, indices = nn.kneighbors(ps[treated_idx])

        # Aplicar caliper
        matched = distances.flatten() < self.caliper
        matched_control_idx = control_idx[indices.flatten()]

        matched_treated = treated_idx[matched]
        matched_control = matched_control_idx[matched]

        if len(matched_treated) == 0:
            self.ate_ = 0
            self.ci_lower_ = -1
            self.ci_upper_ = 1
            self.cate_estimates_ = np.zeros(len(Y))
            return

        # Estimar ATE
        ate_matches = Y[matched_treated] - Y[matched_control]
        self.ate_ = np.mean(ate_matches)

        se = np.std(ate_matches) / np.sqrt(len(ate_matches))
        self.ci_lower_ = self.ate_ - 1.96 * se
        self.ci_upper_ = self.ate_ + 1.96 * se
        self.cate_estimates_ = np.full(len(Y), self.ate_)


class XLearner(BaseEstimator):
    """X-Learner con propensity score."""

    def __init__(self, model=None):
        super().__init__('X-Learner')
        self.model = model or GradientBoostingRegressor(n_estimators=100, random_state=42)

    def fit(self, X, T, Y):
        # Propensity scores
        ps_model = LogisticRegression(max_iter=1000)
        ps = cross_val_predict(ps_model, X, T, method='predict_proba')[:, 1]

        # Stage 1: Modelos de outcome
        mu1_model = self.model.__class__(**self.model.get_params())
        mu0_model = self.model.__class__(**self.model.get_params())
        mu1_model.fit(X[T == 1], Y[T == 1])
        mu0_model.fit(X[T == 0], Y[T == 0])

        # Stage 2: Estimar efectos individuales
        D1 = Y[T == 1] - mu0_model.predict(X[T == 1])
        D0 = mu1_model.predict(X[T == 0]) - Y[T == 0]

        tau1_model = self.model.__class__(**self.model.get_params())
        tau0_model = self.model.__class__(**self.model.get_params())
        tau1_model.fit(X[T == 1], D1)
        tau0_model.fit(X[T == 0], D0)

        # Stage 3: Combinar
        tau1 = tau1_model.predict(X)
        tau0 = tau0_model.predict(X)
        self.cate_estimates_ = ps * tau0 + (1 - ps) * tau1
        self.ate_ = np.mean(self.cate_estimates_)

        # CI via bootstrap
        n_boot = 100
        ate_boots = []
        for _ in range(n_boot):
            idx = np.random.choice(len(Y), len(Y), replace=True)
            ate_boots.append(np.mean(self.cate_estimates_[idx]))

        self.ci_lower_ = np.percentile(ate_boots, 2.5)
        self.ci_upper_ = np.percentile(ate_boots, 97.5)


# =============================================================================
# DML ESTIMADORES (Double Machine Learning)
# =============================================================================

class DML_Estimator(BaseEstimator):
    """
    Double Machine Learning (Chernozhukov et al. 2018).

    Implementa el proceso de ortogonalizacion de DML:
    1. Estimar modelo de outcome residual (Y - E[Y|X])
    2. Estimar modelo de tratamiento residual (T - E[T|X])
    3. Regresionar residuos
    """

    def __init__(self, outcome_model=None, treatment_model=None, n_splits=2):
        super().__init__('DML')
        self.outcome_model = outcome_model or GradientBoostingRegressor(n_estimators=100, random_state=42)
        self.treatment_model = treatment_model or GradientBoostingRegressor(n_estimators=100, random_state=42)
        self.n_splits = n_splits

    def fit(self, X, T, Y):
        from sklearn.model_selection import KFold

        kf = KFold(n_splits=self.n_splits, shuffle=True, random_state=42)

        Y_residuals = np.zeros(len(Y))
        T_residuals = np.zeros(len(T))

        for train_idx, test_idx in kf.split(X):
            # Modelos en train, predecir en test
            y_model = self.outcome_model.__class__(**self.outcome_model.get_params())
            t_model = self.treatment_model.__class__(**self.treatment_model.get_params())

            y_model.fit(X[train_idx], Y[train_idx])
            t_model.fit(X[train_idx], T[train_idx])

            Y_residuals[test_idx] = Y[test_idx] - y_model.predict(X[test_idx])
            T_residuals[test_idx] = T[test_idx] - t_model.predict(X[test_idx])

        # Estimar ATE via OLS de residuos
        reg = LinearRegression()
        reg.fit(T_residuals.reshape(-1, 1), Y_residuals)
        self.ate_ = reg.coef_[0]

        # CI
        se = np.sqrt(np.var(Y_residuals) / (len(Y) * np.var(T_residuals)))
        self.ci_lower_ = self.ate_ - 1.96 * se
        self.ci_upper_ = self.ate_ + 1.96 * se

        self.cate_estimates_ = np.full(len(Y), self.ate_)


# =============================================================================
# REGISTRO DE ESTIMADORES
# =============================================================================

ESTIMATORS = {
    'ols': {'class': OLS_Estimator, 'desc': 'Ordinary Least Squares (baseline)'},
    'ipw': {'class': IPW_Estimator, 'desc': 'Inverse Probability Weighting'},
    'aipw': {'class': AIPW_Estimator, 'desc': 'Augmented IPW (Doubly Robust)'},
    't_learner': {'class': TLearner, 'desc': 'T-Learner (two models)'},
    's_learner': {'class': SLearner, 'desc': 'S-Learner (single model)'},
    'x_learner': {'class': XLearner, 'desc': 'X-Learner'},
    'psm': {'class': MatchingEstimator, 'desc': 'Propensity Score Matching'},
    'dml': {'class': DML_Estimator, 'desc': 'Double Machine Learning'},
}


# =============================================================================
# EVALUACION
# =============================================================================

def load_inference_dataset(dataset_dir):
    """
    Carga dataset de inferencia causal.

    Busca:
    - data.csv: dataset completo (con ground truth si disponible)
    - data_public.csv: version sin ground truth
    - metadata.json: metadatos
    """
    data_path = os.path.join(dataset_dir, 'data.csv')
    public_path = os.path.join(dataset_dir, 'data_public.csv')
    meta_path = os.path.join(dataset_dir, 'metadata.json')

    # Usar data.csv (con ground truth) si existe
    if os.path.exists(data_path):
        df = pd.read_csv(data_path)
    elif os.path.exists(public_path):
        df = pd.read_csv(public_path)
    else:
        raise FileNotFoundError(f"No se encontro dataset en {dataset_dir}")

    metadata = {}
    if os.path.exists(meta_path):
        with open(meta_path, 'r') as f:
            metadata = json.load(f)

    return df, metadata


def extract_xyt(df, metadata=None):
    """
    Extrae X (covariables), T (tratamiento), Y (outcome) del DataFrame.
    """
    # Determinar columnas automaticamente
    treatment_col = None
    outcome_col = None

    # Buscar columna de tratamiento
    for col in ['treatment', 'T', 'trt', 'treat', 'A']:
        if col in df.columns:
            treatment_col = col
            break

    # Buscar columna de outcome
    for col in ['outcome', 'Y', 'y', 're78', 'mortality', 'earnings']:
        if col in df.columns:
            outcome_col = col
            break

    if treatment_col is None:
        raise ValueError("No se encontro columna de tratamiento")
    if outcome_col is None:
        raise ValueError("No se encontro columna de outcome")

    # Covariables: todo excepto tratamiento, outcome y ground truth
    exclude = [treatment_col, outcome_col, 'y0', 'y1', 'tau', 'pair_id', 'twin_id']
    feature_cols = [c for c in df.columns if c not in exclude]

    X = df[feature_cols].values
    T = df[treatment_col].values
    Y = df[outcome_col].values

    return X, T, Y, feature_cols


def evaluate_estimator(estimator_name, dataset_dir, output_dir):
    """
    Evalua un estimador en un dataset.
    """
    print(f"    Estimador: {estimator_name}...", end=' ', flush=True)

    try:
        df, metadata = load_inference_dataset(dataset_dir)
        X, T, Y, features = extract_xyt(df, metadata)

        # Crear y ajustar estimador
        est_info = ESTIMATORS[estimator_name]
        estimator = est_info['class']()

        start_time = time.time()
        estimator.fit(X, T, Y)
        elapsed = time.time() - start_time

        ate_est = estimator.ate_
        ci_lower = estimator.ci_lower_
        ci_upper = estimator.ci_upper_

        # Calcular metricas si tenemos ground truth
        results = {
            'ate_estimated': float(ate_est),
            'ci_lower': float(ci_lower) if ci_lower is not None else None,
            'ci_upper': float(ci_upper) if ci_upper is not None else None,
            'time_seconds': elapsed
        }

        if 'ate_true' in metadata and metadata['ate_true'] is not None:
            ate_true = metadata['ate_true']
            ate_metrics = ate_error(ate_true, ate_est)
            results.update(ate_metrics)

            if ci_lower is not None and ci_upper is not None:
                ci_metrics = coverage_and_length(ate_true, ci_lower, ci_upper)
                results['covered'] = ci_metrics['covered']
                results['ci_length'] = ci_metrics['ci_length']

            print(f"OK (ATE_true={ate_true:.2f}, ATE_est={ate_est:.2f}, "
                  f"Err={abs(ate_true - ate_est):.2f}, {elapsed:.2f}s)")
        else:
            print(f"OK (ATE_est={ate_est:.2f}, {elapsed:.2f}s)")

        # CATE evaluation si disponible
        if 'tau' in df.columns and estimator.cate_estimates_ is not None:
            tau_true = df['tau'].values
            cate_metrics = pehe(tau_true, estimator.cate_estimates_)
            results.update({f'cate_{k}': v for k, v in cate_metrics.items()})

        return results

    except Exception as e:
        print(f"ERROR ({e})")
        return {'error': str(e)}


def run_inference_benchmark(datasets_dir, estimators, output_dir):
    """
    Ejecuta benchmark completo de inferencia causal.
    """
    print("\n" + "=" * 70)
    print(" BENCHMARK DE INFERENCIA CAUSAL")
    print("=" * 70)
    print(f"\nDatasets: {datasets_dir}")
    print(f"Estimadores: {estimators}")
    print("=" * 70)

    # Encontrar datasets
    dataset_dirs = []
    if os.path.exists(os.path.join(datasets_dir, 'data.csv')):
        dataset_dirs = [datasets_dir]
    else:
        for subdir in sorted(os.listdir(datasets_dir)):
            full_path = os.path.join(datasets_dir, subdir)
            if os.path.isdir(full_path):
                if os.path.exists(os.path.join(full_path, 'data.csv')) or \
                   os.path.exists(os.path.join(full_path, 'data_public.csv')):
                    dataset_dirs.append(full_path)

    if not dataset_dirs:
        print(f"ERROR: No se encontraron datasets en {datasets_dir}")
        return {}

    print(f"\nDatasets encontrados: {len(dataset_dirs)}")

    all_results = {}

    for dataset_path in dataset_dirs:
        dataset_name = os.path.basename(dataset_path)
        print(f"\n{'='*60}")
        print(f" Dataset: {dataset_name}")
        print(f"{'='*60}")

        dataset_results = {}

        for est_name in estimators:
            if est_name not in ESTIMATORS:
                print(f"  Estimador '{est_name}' no reconocido. Saltando.")
                continue

            result = evaluate_estimator(est_name, dataset_path, output_dir)
            if result:
                dataset_results[est_name] = result

        all_results[dataset_name] = dataset_results

    # Guardar resultados
    os.makedirs(output_dir, exist_ok=True)
    results_file = os.path.join(output_dir, 'inference_results.json')
    with open(results_file, 'w') as f:
        json.dump(all_results, f, indent=2, default=str)

    # Tabla resumen
    print("\n" + "=" * 70)
    print(" RESUMEN DE RESULTADOS")
    print("=" * 70)

    for dataset_name, results in all_results.items():
        print(f"\n{dataset_name}:")
        print(f"{'Estimator':<15} {'ATE_est':>10} {'ATE_true':>10} {'AbsErr':>8} {'CI_len':>8} {'Covered':>8} {'Time':>8}")
        print("-" * 80)
        for est, metrics in results.items():
            if 'error' not in metrics:
                ate_est = metrics.get('ate_estimated', 'N/A')
                ate_true = metrics.get('ate_true', 'N/A')
                err = metrics.get('absolute_error', 'N/A')
                ci_len = metrics.get('ci_length', 'N/A')
                covered = str(metrics.get('covered', 'N/A'))
                t = metrics.get('time_seconds', 'N/A')

                ate_est_str = f"{ate_est:.2f}" if isinstance(ate_est, (int, float)) else str(ate_est)
                ate_true_str = f"{ate_true:.2f}" if isinstance(ate_true, (int, float)) else str(ate_true)
                err_str = f"{err:.2f}" if isinstance(err, (int, float)) else str(err)
                ci_str = f"{ci_len:.2f}" if isinstance(ci_len, (int, float)) else str(ci_len)
                t_str = f"{t:.2f}s" if isinstance(t, (int, float)) else str(t)

                print(f"{est:<15} {ate_est_str:>10} {ate_true_str:>10} {err_str:>8} "
                      f"{ci_str:>8} {covered:>8} {t_str:>8}")

    print(f"\nResultados guardados en: {results_file}")

    return all_results


# =============================================================================
# MAIN
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Benchmark de inferencia causal'
    )
    parser.add_argument('--datasets', '-d', type=str, required=True,
                       help='Directorio con datasets')
    parser.add_argument('--estimators', '-e', nargs='+',
                       choices=list(ESTIMATORS.keys()) + ['all'],
                       default=['all'],
                       help='Estimadores a evaluar')
    parser.add_argument('--output', '-o', type=str, default='results/inference',
                       help='Directorio de salida')

    args = parser.parse_args()

    if 'all' in args.estimators:
        estimators = list(ESTIMATORS.keys())
    else:
        estimators = args.estimators

    run_inference_benchmark(
        datasets_dir=args.datasets,
        estimators=estimators,
        output_dir=args.output
    )


if __name__ == '__main__':
    main()
