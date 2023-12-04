project('tree-sitter-c', 'c', default_options: ['werror=false'])

ts_meson_files = ['src/parser.c']

tree_sitter_dep = dependency('tree-sitter')

libtsc = static_library(
    'tree-sitter-meson',
    ts_meson_files,
    include_directories: ['src'],
    implicit_include_directories: false,
    dependencies: tree_sitter_dep.partial_dependency(includes: true),
)

tree_sitter_meson_dep = declare_dependency(
    link_with: libtsc,
    include_directories: ['src/tree_sitter'],
    dependencies: tree_sitter_dep,
)
meson.override_dependency('tree-sitter-meson', tree_sitter_meson_dep)
