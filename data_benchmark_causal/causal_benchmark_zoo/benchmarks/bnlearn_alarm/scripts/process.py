from __future__ import annotations

import csv
import gzip
import hashlib
import json
import re
from pathlib import Path

import yaml

RAW_GZ = 'raw/alarm.bif.gz'
EXPECTED_NODES = 37
BENCHMARK_ID = 'bnlearn_alarm'
SOURCE_URL = 'https://www.bnlearn.com/bnrepository/alarm/alarm.bif.gz'


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def read_bif(path: Path) -> str:
    with gzip.open(path, 'rt', encoding='utf-8', errors='replace') as f:
        return f.read()


def parse_bif(text: str) -> tuple[list[str], list[tuple[str, str]]]:
    nodes = re.findall(r'variable\s+([^\s\{]+)\s*\{', text)
    node_set = set(nodes)
    edges: list[tuple[str, str]] = []
    pattern = re.compile(r'probability\s*\(\s*([^\|\)\s]+)\s*(?:\|\s*([^\)]*?))?\)\s*\{', re.MULTILINE)
    for match in pattern.finditer(text):
        child = match.group(1).strip()
        parents_text = match.group(2)
        if parents_text:
            parents = [p.strip() for p in parents_text.split(',') if p.strip()]
            for parent in parents:
                if parent not in node_set:
                    raise ValueError(f'Parent {parent!r} not declared as a variable')
                if child not in node_set:
                    raise ValueError(f'Child {child!r} not declared as a variable')
                edges.append((parent, child))
    return nodes, edges


def write_graph_json(path: Path, nodes: list[str], edges: list[tuple[str, str]], raw_sha: str) -> None:
    payload = {
        'nodes': [{'id': node, 'observed': True, 'type': 'variable'} for node in nodes],
        'edges': [[src, dst] for src, dst in edges],
        'metadata': {
            'benchmark_id': BENCHMARK_ID,
            'source_format': 'bif.gz',
            'source_url': SOURCE_URL,
            'raw_sha256': raw_sha,
            'node_count': len(nodes),
            'edge_count': len(edges),
        },
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')


def write_dot(path: Path, nodes: list[str], edges: list[tuple[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = ['digraph G {']
    for node in nodes:
        lines.append(f'  "{node}";')
    for src, dst in edges:
        lines.append(f'  "{src}" -> "{dst}";')
    lines.append('}')
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')


def write_adjacency(path: Path, nodes: list[str], edges: list[tuple[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    edge_set = set(edges)
    with path.open('w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow([''] + nodes)
        for src in nodes:
            writer.writerow([src] + [1 if (src, dst) in edge_set else 0 for dst in nodes])


def load_manifest(root: Path) -> dict:
    with (root / 'manifest.yaml').open('r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def save_manifest(root: Path, manifest: dict) -> None:
    with (root / 'manifest.yaml').open('w', encoding='utf-8') as f:
        yaml.safe_dump(manifest, f, sort_keys=False, allow_unicode=True)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    raw_path = root / RAW_GZ
    if not raw_path.exists():
        raise FileNotFoundError(f'Missing raw BIF file: {raw_path}')
    raw_sha = sha256_file(raw_path)
    text = read_bif(raw_path)
    nodes, edges = parse_bif(text)
    if len(nodes) != EXPECTED_NODES:
        raise ValueError(f'Expected {EXPECTED_NODES} nodes, parsed {len(nodes)} nodes')

    graph_json = root / 'graphs/graph.json'
    graph_dot = root / 'graphs/graph.dot'
    adjacency = root / 'graphs/adjacency.csv'
    gt_path = root / 'ground_truth/graph_reference.yaml'

    write_graph_json(graph_json, nodes, edges, raw_sha)
    write_dot(graph_dot, nodes, edges)
    write_adjacency(adjacency, nodes, edges)

    gt = {
        'type': 'graph',
        'status': 'available',
        'source': SOURCE_URL,
        'node_count': len(nodes),
        'edge_count': len(edges),
        'raw_sha256': raw_sha,
        'graph_json': 'graphs/graph.json',
        'graph_dot': 'graphs/graph.dot',
        'adjacency_csv': 'graphs/adjacency.csv',
        'notes': 'Reference graph parsed from the original bnlearn BIF file. No ATE/CATE is implied by this graph-only benchmark.',
    }
    gt_path.parent.mkdir(parents=True, exist_ok=True)
    gt_path.write_text(yaml.safe_dump(gt, sort_keys=False, allow_unicode=True) + '\n', encoding='utf-8')

    manifest = load_manifest(root)
    manifest['graph']['available'] = True
    manifest['graph']['format'] = 'json'
    manifest['graph']['path'] = 'graphs/graph.json'
    manifest['graph']['status'] = 'available'
    manifest['graph']['description'] = f'Reference graph parsed from raw BIF; {len(nodes)} nodes and {len(edges)} directed edges.'
    manifest['ground_truth']['type'] = 'graph'
    manifest['ground_truth']['path'] = 'ground_truth/graph_reference.yaml'
    manifest['ground_truth']['status'] = 'available'
    manifest['ground_truth']['description'] = f'Reference graph metadata; {len(nodes)} nodes and {len(edges)} directed edges.'
    save_manifest(root, manifest)

    print({'benchmark_id': BENCHMARK_ID, 'nodes': len(nodes), 'edges': len(edges), 'graph_json': str(graph_json), 'graph_dot': str(graph_dot), 'adjacency': str(adjacency)})
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
