from causal_benchmark_zoo import load_benchmark

# lalonde_nsw is the only registered benchmark with processed tabular data
# available today; bnlearn_asia/bnlearn_alarm only ship a reference graph
# (see examples/evaluate_graph_bnlearn.py) and csuite_lingauss is pending
# manual download.
bench = load_benchmark("lalonde_nsw")
print(bench.name, bench.data.shape)
print(bench.ground_truth)
