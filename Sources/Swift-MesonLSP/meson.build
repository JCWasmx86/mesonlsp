argparser_dep = subproject(
    'swift-argument-parser',
).get_variable('argumentparser_dep')
backtrace_dep = subproject('swift-backtrace').get_variable('backtrace_dep')
consolekit_dep = subproject('consolekit').get_variable('consolekit_dep')
lspjsonrpc_dep = sk_proj.get_variable('lspjsonrpc_dep')
executable(
    'Swift-MesonLSP',
    'DotVisitor.swift',
    'MesonLSP.swift',
    install: true,
    dependencies: [
        argparser_dep,
        backtrace_dep,
        consolekit_dep,
        ls_dep,
        lspjsonrpc_dep,
        tf_dep,
    ],
    link_with: ioutils_lib,
)
