from __future__ import annotations

import hashlib
from pathlib import Path
from urllib.request import Request, urlopen

import yaml

FILES = [
    ('https://www.nber.org/~rdehejia/data/nswre74_treated.txt', 'raw/nswre74_treated.txt', 1000),
    ('https://www.nber.org/~rdehejia/data/nswre74_control.txt', 'raw/nswre74_control.txt', 1000),
]


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


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    manifest = load_manifest(root)
    for url, rel_path, min_bytes in FILES:
        dest = root / rel_path
        print(f'Downloading {url} -> {dest}')
        download_url(url, dest)
        size = dest.stat().st_size
        if size < min_bytes:
            raise RuntimeError(f'Downloaded file too small: {rel_path}, {size} bytes')
        sha = sha256_file(dest)
        for item in manifest['files']['raw']:
            if item['path'] == rel_path:
                item['status'] = 'available'
                item['sha256'] = sha
                item['url'] = url
                break
        print({'path': str(dest), 'bytes': size, 'sha256': sha})
    manifest['version'] = 'nber_public_nswre74_downloaded'
    save_manifest(root, manifest)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
