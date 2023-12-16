jsonrpc_inc = include_directories('.')
jsonrpc_deps = [nlohmann_json_dep]
jsonrpc_lib = static_library(
    'jsonrpc',
    'jsonrpc.cpp',
    include_directories: jsonrpc_inc,
    dependencies: jsonrpc_deps,
)
jsonrpc_dep = declare_dependency(
    include_directories: jsonrpc_inc,
    link_with: [jsonrpc_lib],
    dependencies: jsonrpc_deps,
)
