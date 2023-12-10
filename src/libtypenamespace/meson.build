typenamespace_inc = include_directories('.')
typenamespace_lib = static_library(
    'typenamespace',
    'typenamespace.cpp',
    include_directories: typenamespace_inc,
    dependencies: [objects_dep],
)
typenamespace_dep = declare_dependency(
    dependencies: [objects_dep],
    include_directories: typenamespace_inc,
    link_with: [typenamespace_lib],
)
