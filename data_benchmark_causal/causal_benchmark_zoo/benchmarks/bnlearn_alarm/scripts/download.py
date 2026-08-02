from __future__ import annotations

import hashlib
from pathlib import Path
from urllib.request import Request, urlopen

import yaml


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def download_url(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = Request(url, headers={'User-Agent': 'causal-benchmark-zoo/0.1'})
    with urlopen(req, timeout=60) as resp:
        status = getattr(resp, 'status', None)
        if status is not None and status >= 400:
            raise RuntimeError(f'HTTP status {status} for {url}')
        with dest.open('wb') as f:
            while True:
                chunk = resp.read(1024 * 1024)
                if not chunk:
                    break
                f.write(chunk)


def load_manifest(root: Path) -> dict:
    with (root / 'manifest.yaml').open('r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def save_manifest(root: Path, manifest: dict) -> None:
    with (root / 'manifest.yaml').open('w', encoding='utf-8') as f:
        yaml.safe_dump(manifest, f, sort_keys=False, allow_unicode=True)


def mark_raw_available(root: Path, expected_path: str, sha: str) -> None:
    manifest = load_manifest(root)
    for item in manifest['files']['raw']:
        if item['path'] == expected_path:
            item['status'] = 'available'
            item['sha256'] = sha
            break
    else:
        raise KeyError(f'{expected_path} not found in manifest files.raw')
    manifest['version'] = f"downloaded_sha256_{sha[:12]}"
    save_manifest(root, manifest)


URL = 'https://www.bnlearn.com/bnrepository/alarm/alarm.bif.gz'
REL_PATH = 'raw/alarm.bif.gz'
MIN_BYTES = 500


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    dest = root / REL_PATH
    print(f'Downloading {URL} -> {dest}')
    download_url(URL, dest)
    size = dest.stat().st_size
    if size < MIN_BYTES:
        raise RuntimeError(f'Downloaded file too small: {size} bytes < {MIN_BYTES} bytes')
    sha = sha256_file(dest)
    mark_raw_available(root, REL_PATH, sha)
    print({'path': str(dest), 'bytes': size, 'sha256': sha})
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
