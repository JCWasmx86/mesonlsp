lspjsonrpc_lib = static_library(
    'LanguageServerProtocolJSONRPC',
    'DisableSigpipe.swift',
    'JSONRPCConnection.swift',
    'MessageCoding.swift',
    'MessageSplitting.swift',
    dependencies: [lsp_dep, lsplogging_dep],
)
lspjsonrpc_dep = declare_dependency(
    link_with: lspjsonrpc_lib,
    dependencies: [lsp_dep, lsplogging_dep],
)
