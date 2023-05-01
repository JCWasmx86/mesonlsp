argparser_dep = subproject('argument-parser').get_variable('argumentparser_dep')
backtrace_dep = subproject('backtrace').get_variable('backtrace_dep')
consolekit_dep = subproject('consolekit').get_variable('consolekit_dep')
executable(
    'Swift-MesonLSP',
    'MesonLSP.swift',
    dependencies: [
        argparser_dep,
        backtrace_dep,
        consolekit_dep,
        ls_dep,
        sk_proj.get_variable('lspjsonrpc_dep'),
        tf_dep,
    ],
    link_with: ioutils_lib,
)
