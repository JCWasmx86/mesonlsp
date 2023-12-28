analyze_inc = include_directories('.', 'options', 'subprojects', 'typeanalyzer')
analyze_deps = [ast_dep, tree_sitter_dep, objects_dep, typenamespace_dep, wrap_dep]
analyze_lib = static_library(
    'analyze',
    'options/optionstate.cpp',
    'options/optionextractor.cpp',
    'options/optiondiagnosticvisitor.cpp',
    'typeanalyzer/typeanalyzer.cpp',
    'subprojects/subprojectstate.cpp',
    'typeanalyzer/partialinterpreter.cpp',
    'subprojects/subproject.cpp',
    'mesonmetadata.cpp',
    'mesontree.cpp',
    include_directories: analyze_inc,
    dependencies: analyze_deps,
)
analyze_dep = declare_dependency(
    dependencies: analyze_deps,
    include_directories: analyze_inc,
    link_with: [analyze_lib],
)
