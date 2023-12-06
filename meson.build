project('mesonlsp', 'c', 'cpp', default_options: ['cpp_std=gnu++23', 'warning_level=3'])

if get_option('buildtype').startswith('release')
    add_global_arguments(['-D_FORTIFY_SOURCE=3'], language: 'c')
endif
tree_sitter_dep = dependency(
    'tree-sitter',
    required: false,
    static: true,
    fallback: [],
)
if not tree_sitter_dep.found()
    tree_sitter_proj = subproject('tree-sitter', default_options: ['default_library=static'])
    tree_sitter_dep = tree_sitter_proj.get_variable('tree_sitter_dep')
    meson.override_dependency('tree-sitter', tree_sitter_dep)
endif

tree_sitter_meson_proj = subproject(
    'tree-sitter-meson',
    default_options: ['default_library=static'],
)
tree_sitter_meson_dep = tree_sitter_meson_proj.get_variable('tree_sitter_meson_dep')

nlohmann_json_dep = dependency('nlohmann_json') 

subdir('src')
subdir('tests')
