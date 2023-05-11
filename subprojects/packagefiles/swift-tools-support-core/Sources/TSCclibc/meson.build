tscclibc_inc = include_directories('include')
tscclibc_lib = static_library(
    'TSCclibc',
    'libc.c',
    'process.c',
    include_directories: tscclibc_inc,
)
tscclibc_dep = declare_dependency(
    link_with: tscclibc_lib,
    include_directories: tscclibc_inc,
)
