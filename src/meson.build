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
subdir('liblangserver')

version = meson.project_version()

cxx_version = cxx.get_id() + ' ' + cxx.version()
cc_version = cc.get_id() + ' ' + cc.version()
assert(cc.get_linker_id() == cxx.get_linker_id())

executable(
    'mesonlsp',
    'main.cpp',
    link_args: extra_link_args,
    cpp_args: [
        '-DVERSION="' + version + '"',
        '-DCC_VERSION="' + cc_version + '"',
        '-DCXX_VERSION="' + cxx_version + '"',
        '-DLINKER_ID="' + cc.get_linker_id() + '"',
    ] + args,
    dependencies: [
        analyze_dep,
        ast_dep,
        jsonrpc_dep,
        log_dep,
        objects_dep,
        tree_sitter_dep,
        tree_sitter_meson_dep,
        wrap_dep,
        langserver_dep,
    ] + extra_deps + extra_libs,
    install: true,
)

install_dir = get_option('prefix') / get_option('bindir')
install_symlink(
    'Swift-MesonLSP',
    install_dir: install_dir,
    pointing_to: install_dir / 'mesonlsp',
)

subdir('benchmarks')