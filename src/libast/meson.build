ast_inc = include_directories('.')
ast_lib = static_library(
    'ast',
    'location.cpp',
    'node.cpp',
    'sourcefile.cpp',
    include_directories: ast_inc,
    dependencies: [tree_sitter_dep, objects_dep],
)
ast_dep = declare_dependency(
    include_directories: ast_inc,
    link_with: [ast_lib],
)
