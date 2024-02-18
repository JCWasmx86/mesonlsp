subdir('liblog')
subdir('libutils')
subdir('libobjects')
subdir('libast')
subdir('libparsing')
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
extra_defines = []

if cxx.get_id() == 'gcc'
    backtrace_dep = cxx.find_library('stdc++_libbacktrace', required: false)
    if backtrace_dep.found()
        backtrace_lib = [backtrace_dep]
    else
        backtrace_lib = []
        # Should only happen in crappy distributions....
        extra_defines += ['-DNO_BACKTRACE']
    endif
else
    backtrace_lib = []
endif

executable(
    'mesonlsp',
    'main.cpp',
    link_args: extra_link_args,
    cpp_args: [
        '-DVERSION="' + version + '"',
        '-DCC_VERSION="' + cc_version + '"',
        '-DCXX_VERSION="' + cxx_version + '"',
        '-DLINKER_ID="' + cc.get_linker_id() + '"',
    ] + args + extra_defines,
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
    ] + extra_deps + extra_libs + backtrace_lib,
    install: true,
    pie: true,
)

install_dir = get_option('prefix') / get_option('bindir')
install_symlink(
    'Swift-MesonLSP',
    install_dir: install_dir,
    pointing_to: install_dir / 'mesonlsp',
)

subdir('benchmarks')
