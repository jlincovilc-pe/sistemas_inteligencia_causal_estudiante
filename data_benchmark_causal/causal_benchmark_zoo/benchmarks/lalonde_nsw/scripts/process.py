from __future__ import annotations

import hashlib
import json
from pathlib import Path

import pandas as pd
import yaml
from scipy import stats

COLUMNS = ['treat', 'age', 'educ', 'black', 'hispan', 'married', 'nodegree', 're74', 're75', 're78']
RAW_FILES = ['raw/nswre74_treated.txt', 'raw/nswre74_control.txt']


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def load_manifest(root: Path) -> dict:
    with (root / 'manifest.yaml').open('r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def save_manifest(root: Path, manifest: dict) -> None:
    with (root / 'manifest.yaml').open('w', encoding='utf-8') as f:
        yaml.safe_dump(manifest, f, sort_keys=False, allow_unicode=True)


def read_raw(root: Path) -> pd.DataFrame:
    frames = []
    for rel in RAW_FILES:
        path = root / rel
        if not path.exists():
            raise FileNotFoundError(f'Missing raw file: {path}')
        frame = pd.read_csv(path, sep=r'\s+', header=None, names=COLUMNS)
        frames.append(frame)
    df = pd.concat(frames, ignore_index=True)
    # Normalize binary fields to int and numeric outcomes/covariates to float/int as appropriate.
    for col in ['treat', 'black', 'hispan', 'married', 'nodegree']:
        df[col] = df[col].astype(int)
    df['age'] = df['age'].astype(int)
    df['educ'] = df['educ'].astype(int)
    for col in ['re74', 're75', 're78']:
        df[col] = df[col].astype(float)
    return df


def write_expert_dag(root: Path) -> None:
    covariates = ['age', 'educ', 'black', 'hispan', 'married', 'nodegree', 're74', 're75']
    nodes = [{'id': c, 'type': 'pre_treatment_covariate', 'observed': True} for c in covariates]
    nodes += [{'id': 'treat', 'type': 'treatment', 'observed': True}, {'id': 're78', 'type': 'outcome', 'observed': True}]
    edges = []
    for c in covariates:
        edges.append([c, 'treat'])
        edges.append([c, 're78'])
    edges.append(['treat', 're78'])
    payload = {
        'nodes': nodes,
        'edges': edges,
        'metadata': {
            'benchmark_id': 'lalonde_nsw',
            'source': 'Expert adjustment DAG based on documented pre-treatment covariates on the NBER/Dehejia-Wahba page.',
            'edge_semantics': 'maintained expert DAG, not learned from data',
            'node_count': len(nodes),
            'edge_count': len(edges),
        },
    }
    graph_path = root / 'graphs/expert_dag.json'
    graph_path.parent.mkdir(parents=True, exist_ok=True)
    graph_path.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
    dot_lines = ['digraph G {']
    for node in payload['nodes']:
        dot_lines.append(f'  "{node["id"]}";')
    for src, dst in edges:
        dot_lines.append(f'  "{src}" -> "{dst}";')
    dot_lines.append('}')
    (root / 'graphs/expert_dag.dot').write_text('\n'.join(dot_lines) + '\n', encoding='utf-8')


def compute_reference(df: pd.DataFrame) -> dict:
    treated = df.loc[df['treat'] == 1, 're78']
    control = df.loc[df['treat'] == 0, 're78']
    n_t, n_c = len(treated), len(control)
    mean_t, mean_c = treated.mean(), control.mean()
    ate = mean_t - mean_c
    var_t, var_c = treated.var(ddof=1), control.var(ddof=1)
    se = (var_t / n_t + var_c / n_c) ** 0.5
    df_num = (var_t / n_t + var_c / n_c) ** 2
    df_den = ((var_t / n_t) ** 2 / (n_t - 1)) + ((var_c / n_c) ** 2 / (n_c - 1))
    dof = df_num / df_den
    tcrit = stats.t.ppf(0.975, dof)
    ci = [ate - tcrit * se, ate + tcrit * se]
    t_stat = ate / se
    p_value = 2 * stats.t.sf(abs(t_stat), dof)
    return {
        'type': 'experimental_reference_estimate',
        'status': 'available',
        'estimand': 'ATE',
        'treatment': 'treat',
        'outcome': 're78',
        'scale': 'difference_in_means_usd_1978_earnings',
        'value': float(ate),
        'treated_mean': float(mean_t),
        'control_mean': float(mean_c),
        'standard_error': float(se),
        'confidence_interval_95': [float(ci[0]), float(ci[1])],
        't_statistic': float(t_stat),
        'degrees_of_freedom_welch': float(dof),
        'p_value_two_sided': float(p_value),
        'n_treated': int(n_t),
        'n_control': int(n_c),
        'source': 'Computed from public NBER nswre74_treated.txt and nswre74_control.txt files.',
        'notes': 'Experimental reference estimate from randomized NSW sample. It has sampling uncertainty and is not a mathematical constant.',
    }


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    df = read_raw(root)
    expected = {'treat', 'age', 'educ', 'black', 'hispan', 'married', 'nodegree', 're74', 're75', 're78'}
    if set(df.columns) != expected:
        raise ValueError(f'Unexpected columns: {df.columns.tolist()}')
    if sorted(df['treat'].unique().tolist()) != [0, 1]:
        raise ValueError('treat must be binary with values 0 and 1')

    processed_dir = root / 'processed'
    processed_dir.mkdir(parents=True, exist_ok=True)
    parquet_path = processed_dir / 'lalonde_nsw.parquet'
    csv_path = processed_dir / 'lalonde_nsw.csv'
    df.to_parquet(parquet_path, index=False)
    df.to_csv(csv_path, index=False)

    write_expert_dag(root)
    gt = compute_reference(df)
    gt_path = root / 'ground_truth/ate_reference.yaml'
    gt_path.parent.mkdir(parents=True, exist_ok=True)
    gt_path.write_text(yaml.safe_dump(gt, sort_keys=False, allow_unicode=True) + '\n', encoding='utf-8')

    manifest = load_manifest(root)
    for item in manifest['files']['processed']:
        if item['path'] in {'processed/lalonde_nsw.parquet', 'processed/lalonde_nsw.csv'}:
            full = root / item['path']
            item['status'] = 'available'
            item['sha256'] = sha256_file(full)
    manifest['graph']['available'] = True
    manifest['graph']['format'] = 'json'
    manifest['graph']['path'] = 'graphs/expert_dag.json'
    manifest['graph']['status'] = 'available'
    manifest['ground_truth']['type'] = 'experimental_reference_estimate'
    manifest['ground_truth']['path'] = 'ground_truth/ate_reference.yaml'
    manifest['ground_truth']['status'] = 'available'
    save_manifest(root, manifest)

    print({'rows': int(len(df)), 'columns': df.columns.tolist(), 'ate': gt['value'], 'se': gt['standard_error'], 'ci95': gt['confidence_interval_95']})
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
