from causal_benchmark_zoo.validation import validate_all_manifests


def test_all_manifests_validate():
    validated = validate_all_manifests()
    assert set(validated) == {"csuite_lingauss", "bnlearn_asia", "bnlearn_alarm", "lalonde_nsw"}
