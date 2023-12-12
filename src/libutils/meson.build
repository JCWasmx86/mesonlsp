utils_inc = include_directories('.')
utils_lib = static_library(
    'utils',
    'utils.cpp',
    include_directories: utils_inc,
    dependencies: [log_dep, archive_dep, curl_dep, uuid_dep],
)
utils_dep = declare_dependency(
    dependencies: [log_dep, archive_dep, curl_dep, uuid_dep],
    include_directories: utils_inc,
    link_with: [utils_lib],
)
