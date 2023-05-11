csystem_inc = include_directories('.', 'include')
csystem_lib = static_library(
    'CSystem',
    'shims.c',
    include_directories: csystem_inc,
)
csystem_dep = declare_dependency(
    link_with: csystem_lib,
    include_directories: csystem_inc,
)
