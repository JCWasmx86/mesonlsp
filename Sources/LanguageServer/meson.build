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
    'CodeActions/CodeActionProvider.swift',
    'CodeActions/CodeActionState.swift',
    'CodeActions/CodeActionVisitor.swift',
    'CodeActions/IntegerToBase.swift',
    'CodeActions/LibraryToGeneric.swift',
    'CodeActions/SharedLibraryToModule.swift',
    'CodeActions/SharedModuleToLibrary.swift',
    'CodeActions/SortFilenamesSAICodeActionProvider.swift',
    'CodeActions/SortFilenamesIASCodeActionProvider.swift',
    'DeclarationFinder.swift',
    'DefinitionFinder.swift',
    'DocumentSymbolCollector.swift',
    'FileMapper.swift',
    'Formatting.swift',
    'Highlighter.swift',
    'HoverInformationCollector.swift',
    'InlayHints.swift',
    'InlayHintsCollector.swift',
    'MesonServer.swift',
    'NodeCounter.swift',
    'StatsCollector.swift',
    c,
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
