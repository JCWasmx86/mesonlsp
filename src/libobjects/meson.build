objects_inc = include_directories('.')
objects_lib = static_library(
    'objects',
    'argument.cpp',
    'function.cpp',
    include_directories: objects_inc,
)
objects_dep = declare_dependency(
    include_directories: objects_inc,
    link_with: [objects_lib],
)
