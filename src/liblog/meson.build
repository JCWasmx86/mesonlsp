log_inc = include_directories('.')
log_lib = static_library(
    'log',
    'log.cpp',
    include_directories: log_inc,
    dependencies: polyfill_dep,
)
log_dep = declare_dependency(
    include_directories: log_inc,
    link_with: [log_lib],
    dependencies: polyfill_dep,
)
