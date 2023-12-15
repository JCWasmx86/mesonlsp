project('sha256', 'c')

sha256_inc = include_directories('.')
sha256_lib = library('sha256', 'sha-256.c', include_directories: sha256_inc)

sha256_dep = declare_dependency(
    link_with: sha256_lib,
    include_directories: sha256_inc,
)
