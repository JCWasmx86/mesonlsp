c = configure_file(
    copy: true,
    input: 'Backtrace.swift',
    output: '_Backtrace.swift',
)
backtrace_lib = static_library(
    'Backtrace',
    c,
    'Demangle.swift',
    dependencies: dep,
)

backtrace_dep = declare_dependency(
    link_with: backtrace_lib,
    dependencies: dep,
)

