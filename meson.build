project(
    'mesonlsp',
    'c',
    'cpp',
    default_options: ['cpp_std=gnu++23', 'warning_level=3'],
    version: 'v4.0.0',
)

if get_option('buildtype') == 'release'
    add_global_arguments(['-D_FORTIFY_SOURCE=3'], language: 'c')
    add_global_arguments(['-D_FORTIFY_SOURCE=3'], language: 'cpp')
else
    add_global_arguments(['-D_GLIBCXX_ASSERTIONS=1', '-D_GLIBCXX_DEBUG=1', '-D_GLIBCXX_DEBUG_BACKTRACE=1'], language: 'cpp')
endif
hardening_flags = ['-fstack-protector-strong', '-fstack-clash-protection', '-fcf-protection']
add_global_arguments(hardening_flags, language: 'c')
add_global_arguments(hardening_flags, language: 'cpp')

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

tree_sitter_ini_proj = subproject(
    'tree-sitter-ini',
    default_options: ['default_library=static'],
)
tree_sitter_ini_dep = tree_sitter_ini_proj.get_variable('tree_sitter_ini_dep')
sha256_proj = subproject('sha256', default_options: ['default_library=static'])
sha256_dep = sha256_proj.get_variable('sha256_dep')

nlohmann_json_dep = dependency('nlohmann_json')
curl_dep = dependency('libcurl')
archive_dep = dependency('libarchive')
uuid_dep = dependency('uuid')

subdir('src')
subdir('tests')
