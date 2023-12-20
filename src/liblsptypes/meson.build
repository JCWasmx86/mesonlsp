lsptypes_inc = include_directories('.')
lsptypes_deps = [nlohmann_json_dep]
lsptypes_lib = static_library(
    'lsptypes',
    include_directories: lsptypes_inc,
    dependencies: lsptypes_deps,
)
lsptypes_dep = declare_dependency(
    dependencies: lsptypes_deps,
    include_directories: lsptypes_inc,
    link_with: [lsptypes_lib],
)
