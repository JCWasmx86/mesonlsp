jsonrpc_inc = include_directories('.')
jsonrpc_lib = static_library(
    'jsonrpc',
    'jsonrpc.cpp',
    include_directories: jsonrpc_inc,
    dependencies: [nlohmann_json_dep],
)
jsonrpc_dep = declare_dependency(
    include_directories: jsonrpc_inc,
    link_with: [jsonrpc_lib],
    dependencies: [nlohmann_json_dep],
)
