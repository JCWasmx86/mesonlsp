typenamespace_inc = include_directories('.')
typenamespace_deps = [objects_dep]

genfunctions_cpp = configure_file(
    command: [
        files('genfunctions.py'),
        '@INPUT0@',
        '@OUTPUT0@',
        '@INPUT1@',
        '@INPUT2@',
        '@INPUT3@',
    ],
    input: [
        'functions.def',
        'functiondocs.def',
        'deprecations.csv',
        'addedData.csv',
    ],
    output: 'genfunctions.cpp',
)
genmethods_cpp = configure_file(
    command: [
        files('genmethods.py'),
        '@INPUT0@',
        '@OUTPUT0@',
        '@INPUT1@',
        '@INPUT2@',
        '@INPUT3@',
    ],
    input: [
        'methods.def',
        'methoddocs.def',
        'deprecations.csv',
        'addedData.csv',
    ],
    output: 'genmethods.cpp',
)
genobjectdocs_cpp = configure_file(
    command: [files('genobjectdocs.py'), '@INPUT0@', '@OUTPUT0@'],
    input: ['objectdocs.def'],
    output: 'genobjectdocs.cpp',
)

generated_lib = static_library(
    'generated_lib',
    genfunctions_cpp,
    genmethods_cpp,
    genobjectdocs_cpp,
    include_directories: typenamespace_inc,
    dependencies: typenamespace_deps,
    cpp_args: cxx.get_id() == 'clang' ? [] : ['-fno-var-tracking-assignments'],
)

typenamespace_lib = static_library(
    'typenamespace',
    'typenamespace.cpp',
    include_directories: typenamespace_inc,
    dependencies: typenamespace_deps,
)
typenamespace_dep = declare_dependency(
    dependencies: typenamespace_deps,
    include_directories: typenamespace_inc,
    link_with: [typenamespace_lib, generated_lib],
)
