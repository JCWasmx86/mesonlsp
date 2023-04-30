caching_lib = static_library(
    'Caching',
    'Cache.swift',
    dependencies: [crypto_dep, logging_dep],
    link_with: ioutils_lib,
)
caching_dep = declare_dependency(
    link_with: [caching_lib, ioutils_lib],
    dependencies: [crypto_dep, logging_dep],
)
