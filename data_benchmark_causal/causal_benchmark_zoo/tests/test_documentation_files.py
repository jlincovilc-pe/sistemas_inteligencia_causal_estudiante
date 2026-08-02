from pathlib import Path


def test_core_documentation_files_exist():
    root = Path(__file__).resolve().parents[1]
    required = [
        "README.md",
        "DATASETS.md",
        "LIMITATIONS.md",
        "CONTRIBUTING.md",
        "docs/quickstart.md",
        "docs/adding_a_dataset.md",
        "docs/dowhy_econml_integration.md",
        "docs/ground_truth_taxonomy.md",
    ]
    for rel in required:
        path = root / rel
        assert path.exists(), rel
        assert path.stat().st_size > 100, rel
