langserver_inc = include_directories('.')
langserver_deps = [
    jsonrpc_dep,
    lsptypes_dep,
    log_dep,
    ls_dep,
    ada_dep,
    analyze_dep,
    uuid_dep,
    muon_dep,
    pkgconf_dep,
]
langserver_lib = static_library(
    'langserver',
    'langserver.cpp',
    'completion.cpp',
    'workspace.cpp',
    'task.cpp',
    'inlayhintvisitor.cpp',
    'foldingrangevisitor.cpp',
    'semantictokensvisitor.cpp',
    'documentsymbolvisitor.cpp',
    'codeactionvisitor.cpp',
    'hover.cpp',
    cpp_args: [
        '-DVERSION="' + meson.project_version() + '"',
    ],
    include_directories: langserver_inc,
    dependencies: langserver_deps,
)

langserver_dep = declare_dependency(
    dependencies: langserver_deps,
    include_directories: langserver_inc,
    link_with: [langserver_lib],
)
