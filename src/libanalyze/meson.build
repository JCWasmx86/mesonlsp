analyze_inc = include_directories('.', 'subprojects', 'options')
analyze_lib = static_library(
    'analyze',
    'options/optionstate.cpp',
    'options/optionextractor.cpp',
    'mesonmetadata.cpp',
    'mesontree.cpp',
    include_directories: analyze_inc,
    dependencies: [ast_dep, tree_sitter_dep, objects_dep],
)
analyze_dep = declare_dependency(
    dependencies: [ast_dep, tree_sitter_dep, objects_dep],
    include_directories: analyze_inc,
    link_with: [analyze_lib],
)
