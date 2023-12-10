typenamespace_inc = include_directories('.')
genfunctions_cpp = configure_file(
    command: [files('genfunctions.py'), '@INPUT0@', '@OUTPUT0@'],
    input: ['functions.def'],
    output: 'genfunctions.cpp',
)
genmethods_cpp = configure_file(
    command: [files('genmethods.py'), '@INPUT0@', '@OUTPUT0@'],
    input: ['methods.def'],
    output: 'genmethods.cpp',
)
typenamespace_lib = static_library(
    'typenamespace',
    'typenamespace.cpp',
    genfunctions_cpp,
    genmethods_cpp,
    include_directories: typenamespace_inc,
    dependencies: [objects_dep],
)
typenamespace_dep = declare_dependency(
    dependencies: [objects_dep],
    include_directories: typenamespace_inc,
    link_with: [typenamespace_lib],
)
