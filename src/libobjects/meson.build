objects_inc = include_directories('.')
objects_dep = [utils_dep]
objects_lib = static_library(
    'objects',
    'function.cpp',
    include_directories: objects_inc,
    dependencies: objects_dep,
)
objects_dep = declare_dependency(
    include_directories: objects_inc,
    link_with: [objects_lib],
    dependencies: objects_dep,
)
