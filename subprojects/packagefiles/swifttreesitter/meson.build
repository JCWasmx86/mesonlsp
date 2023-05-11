project('SwiftTreeSitter', 'swift', 'c')
# From the git submodule
tree_sitter_inc = include_directories('tree-sitter/lib/include')
tree_sitter_lib = static_library(
    'tree_sitter',
    'tree-sitter/lib/src/lib.c',
    include_directories: tree_sitter_inc,
    generate_umbrella: true,
    umbrella_path: 'tree-sitter/lib/include',
)
tree_sitter_dep = declare_dependency(
    link_with: tree_sitter_lib,
    include_directories: tree_sitter_inc,
)
subdir('Sources/SwiftTreeSitter')
