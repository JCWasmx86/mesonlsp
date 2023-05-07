sk_proj = subproject('sourcekit-lsp')
swifter_dep = subproject('swifter').get_variable('swifter_dep')
lsp_dep = sk_proj.get_variable('lsp_dep')
lsplogging_dep = sk_proj.get_variable('lsplogging_dep')

c = configure_file(
    copy: true,
    input: 'LanguageServer.swift',
    output: '_LanguageServer.swift',
)
ls_lib = static_library(
    'LanguageServer',
    'StatsCollector.swift',
    'Formatting.swift',
    'DocumentSymbolCollector.swift',
    'DeclarationFinder.swift',
    'DefinitionFinder.swift',
    'FileMapper.swift',
    'HoverInformationCollector.swift',
    'Highlighter.swift',
    c,
    'InlayHints.swift',
    'InlayHintsCollector.swift',
    'NodeCounter.swift',
    'CodeActions/CodeActionProvider.swift',
    'CodeActions/CodeActionState.swift',
    'CodeActions/CodeActionVisitor.swift',
    'CodeActions/IntegerToBase.swift',
    'MesonServer.swift',
    dependencies: [
        cmem_dep,
        lsp_dep,
        mesonanalyze_dep,
        lsplogging_dep,
        swifter_dep,
    ],
    link_with: [ioutils_lib, mesondocs_lib],
)
ls_dep = declare_dependency(
    dependencies: [
        cmem_dep,
        lsp_dep,
        mesonanalyze_dep,
        lsplogging_dep,
        swifter_dep,
    ],
    link_with: [ioutils_lib, mesondocs_lib, ls_lib],
)
