subdir('liblog')
subdir('libobjects')
subdir('libast')

executable(
    'Swift-MesonLSP',
    'main.cpp',
    dependencies: [log_dep, objects_dep, tree_sitter_dep, tree_sitter_meson_dep, ast_dep],
)
