cbacktrace_inc = include_directories('.')
lib = static_library(
    'CBacktrace',
    'atomic.c',
    'backtrace.c',
    'dwarf.c',
    'elf.c',
    'fileline.c',
    'mmap.c',
    'mmapio.c',
    'posix.c',
    'print.c',
    'sort.c',
    'state.c',
    generate_umbrella: true,
)
dep = declare_dependency(include_directories: cbacktrace_inc, link_with: lib)
