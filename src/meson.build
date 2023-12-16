subdir('liblog')
subdir('libutils')
subdir('libobjects')
subdir('libast')
subdir('libtypenamespace')
subdir('libwrap')
subdir('libanalyze')
subdir('libjsonrpc')
subdir('liblsptypes')

version = meson.project_version()

executable(
    'Swift-MesonLSP',
    'main.cpp',
    cpp_args: ['-DVERSION="' + version + '"'],
    dependencies: [
        log_dep,
        objects_dep,
        tree_sitter_dep,
        tree_sitter_meson_dep,
        ast_dep,
        jsonrpc_dep,
        wrap_dep,
        analyze_dep,
    ],
)
