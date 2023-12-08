wrap_inc = include_directories('.')
wrap_lib = static_library(
    'wrap',
    'wrap.cpp',
    include_directories: wrap_inc,
    dependencies: [tree_sitter_dep, tree_sitter_ini_dep],
)
wrap_dep = declare_dependency(
    dependencies: [tree_sitter_dep, tree_sitter_ini_dep],
    include_directories: wrap_inc,
    link_with: [wrap_lib],
)
