from __future__ import annotations

import hashlib
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import yaml

URL = 'https://github.com/microsoft/csuite/releases/download/v0.1/csuite_lingauss.zip'
REL_PATH = 'raw/csuite_lingauss.zip'
README = 'raw/README_manual_download.txt'
MIN_BYTES = 1000


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


def write_manual_instructions(root: Path, reason: str) -> None:
    readme = root / README
    readme.parent.mkdir(parents=True, exist_ok=True)
    readme.write_text(
        f"CSuite lingauss manual download instructions\n\n"
        f"Source URL:\n  {URL}\n\n"
        f"Automated download failed in this environment. Reason:\n  {reason}\n\n"
        f"Place the original ZIP at:\n  {root / REL_PATH}\n\n"
        f"Do not substitute, edit, or fabricate this file. After placing it, rerun validation/process steps.\n",
        encoding='utf-8',
    )
    manifest = load_manifest(root)
    for item in manifest['files']['raw']:
        if item['path'] == REL_PATH:
            item['status'] = 'manual'
            item['sha256'] = None
            break
    save_manifest(root, manifest)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    dest = root / REL_PATH
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = Request(URL, headers={'User-Agent': 'causal-benchmark-zoo/0.1'})
    try:
        with urlopen(req, timeout=60) as resp:
            with dest.open('wb') as f:
                while True:
                    chunk = resp.read(1024 * 1024)
                    if not chunk:
                        break
                    f.write(chunk)
    except (HTTPError, URLError, TimeoutError) as exc:
        write_manual_instructions(root, repr(exc))
        print(f'I cannot automatically download csuite_lingauss because the source request failed: {exc!r}. Manual instructions written to {root / README}.')
        return 0

    size = dest.stat().st_size
    if size < MIN_BYTES:
        dest.unlink(missing_ok=True)
        write_manual_instructions(root, f'downloaded file too small: {size} bytes')
        print(f'I cannot accept csuite_lingauss download because the file was too small ({size} bytes). Manual instructions written.')
        return 0

    sha = sha256_file(dest)
    manifest = load_manifest(root)
    for item in manifest['files']['raw']:
        if item['path'] == REL_PATH:
            item['status'] = 'available'
            item['sha256'] = sha
            break
    manifest['version'] = f'downloaded_sha256_{sha[:12]}'
    save_manifest(root, manifest)
    print({'path': str(dest), 'bytes': size, 'sha256': sha})
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
