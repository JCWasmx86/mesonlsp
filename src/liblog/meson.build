log_inc = include_directories('.')
log_lib = static_library(
    'log',
    'log.cpp',
    include_directories: [log_inc, polyfill_inc],
)
log_dep = declare_dependency(
    include_directories: log_inc,
    link_with: [log_lib],
)
