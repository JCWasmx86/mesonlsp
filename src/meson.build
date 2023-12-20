subdir('liblog')
subdir('libutils')
subdir('libobjects')
subdir('libast')
subdir('libtypenamespace')
subdir('libwrap')
subdir('libanalyze')
subdir('libjsonrpc')
subdir('liblsptypes')
subdir('libls')

version = meson.project_version()

cc = meson.get_compiler('c')
cxx = meson.get_compiler('cpp')
cxx_version = cxx.get_id() + ' ' + cxx.version()
cc_version = cc.get_id() + ' ' + cc.version()
assert(cc.get_linker_id() == cxx.get_linker_id())

executable(
    'Swift-MesonLSP',
    'main.cpp',
    cpp_args: [
        '-DVERSION="' + version + '"',
        '-DCC_VERSION="' + cc_version + '"',
        '-DCXX_VERSION="' + cxx_version + '"',
        '-DLINKER_ID="' + cc.get_linker_id() + '"',
    ],
    dependencies: [
        analyze_dep,
        ast_dep,
        jsonrpc_dep,
        log_dep,
        objects_dep,
        tree_sitter_dep,
        tree_sitter_meson_dep,
        wrap_dep,
    ],
)
