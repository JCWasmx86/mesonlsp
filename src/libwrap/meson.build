wrap_inc = include_directories('.')
wrap_lib = static_library(
    'wrap',
    'filewrap.cpp',
    'gitwrap.cpp',
    'hgwrap.cpp',
    'svnwrap.cpp',
    'vcswrap.cpp',
    'wrap.cpp',
    include_directories: wrap_inc,
    dependencies: [tree_sitter_dep, tree_sitter_ini_dep, ast_dep, archive_dep, curl_dep, utils_dep],
)
wrap_dep = declare_dependency(
    dependencies: [tree_sitter_dep, tree_sitter_ini_dep, ast_dep, archive_dep, curl_dep, utils_dep],
    include_directories: wrap_inc,
    link_with: [wrap_lib],
)
