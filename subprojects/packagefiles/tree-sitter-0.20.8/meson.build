project('tree-sitter', 'c')
# Based on
# https://github.com/rizinorg/rizin/blob/dev/subprojects/packagefiles/tree-sitter-0.20.7/meson.build
tree_sitter_files = ['lib/src/lib.c']
tree_sitter_inc = [include_directories('lib/src'), include_directories('lib/include')]

libtree_sitter = static_library(
    'tree_sitter',
    tree_sitter_files,
    include_directories: tree_sitter_inc,
    implicit_include_directories: false,
    install: not meson.is_subproject(),
    # Horrible hack, but that's how we can
    # avoid the overhead from atomics in this
    # case
    c_args: ['-D__TINYC__=1']
)

tree_sitter_dep = declare_dependency(
    link_with: libtree_sitter,
    include_directories: tree_sitter_inc,
)
