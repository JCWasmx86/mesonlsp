ast_inc = include_directories('.')
ast_deps = [tree_sitter_dep, objects_dep, utils_dep]
ast_lib = static_library(
    'ast',
    'sourcefile.cpp',
    'ini.cpp',
    'node.cpp',
    include_directories: ast_inc,
    dependencies: ast_deps,
)
ast_dep = declare_dependency(
    dependencies: ast_deps,
    include_directories: ast_inc,
    link_with: [ast_lib],
)
