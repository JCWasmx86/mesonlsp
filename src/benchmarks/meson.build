benchmark_dep = dependency('benchmark')
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
    ],
    cpp_args: ['-U_GLIBCXX_DEBUG'],
)
