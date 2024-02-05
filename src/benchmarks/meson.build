if not get_option('benchmarks')
    subdir_done()
endif
benchmark_dep = subproject('google-benchmark').get_variable(
    'google_benchmark_dep',
)
if not benchmark_dep.found() or not get_option('benchmarks')
    subdir_done()
endif
executable(
    'parsingbenchmark',
    'parsing.cpp',
    dependencies: [
        benchmark_dep,
        tree_sitter_dep,
        tree_sitter_meson_dep,
        utils_dep,
        ast_dep,
        muon_dep,
        parsing_dep,
    ] + extra_deps + extra_libs,
)
