utils_inc = include_directories('.')
utils_deps = [log_dep, archive_dep, curl_dep, sha256_dep]
utils_lib = static_library(
    'utils',
    'utils.cpp',
    include_directories: utils_inc,
    dependencies: utils_deps,
)
utils_dep = declare_dependency(
    dependencies: utils_deps,
    include_directories: utils_inc,
    link_with: [utils_lib],
)
