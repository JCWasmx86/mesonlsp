ls_inc = include_directories('.')
ls_deps = [jsonrpc_dep, lsptypes_dep, log_dep, polyfill_dep]
ls_lib = static_library(
    'ls',
    'ls.cpp',
    include_directories: [ls_inc],
    dependencies: ls_deps,
)

ls_dep = declare_dependency(
    dependencies: ls_deps,
    include_directories: ls_inc,
    link_with: [ls_lib],
)
