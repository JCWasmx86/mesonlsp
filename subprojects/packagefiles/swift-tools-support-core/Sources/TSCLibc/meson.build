tsclibc_lib = static_library(
    'TSCLibc',
    'libc.swift',
    dependencies: tscclibc_dep,
)
tsclibc_dep = declare_dependency(
    link_with: tsclibc_lib,
    dependencies: tscclibc_dep,
)
