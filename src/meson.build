subdir('polyfill')
subdir('liblog')
subdir('libcxathrow')
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

source_root = meson.project_source_root()
version_h = vcs_tag(
    command: [
        'git',
        '--git-dir=' + join_paths(source_root, '.git'),
        '--work-tree=' + source_root,
        'describe',
        '--always',
        '--tags',
        '--dirty',
    ],
    input: 'vcs_version.h.in',
    output: 'vcs_version.h',
    replace_string: '@VCS_VERSION@',
)

mesonlsp = executable(
    'mesonlsp',
    'main.cpp',
    version_h,
    link_args: extra_link_args,
    cpp_args: [
        '-DVERSION="' + version + '"',
        '-DCC_VERSION="' + cc_version + '"',
        '-DCXX_VERSION="' + cxx_version + '"',
        '-DLINKER_ID="' + cc.get_linker_id() + '"',
    ]
    + args,
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
        cxathrow_dep,
    ]
    + extra_deps
    + extra_libs,
    install: true,
    pie: host_machine.system() == 'linux',
)

install_dir = get_option('prefix') / get_option('bindir')
install_symlink(
    'Swift-MesonLSP',
    install_dir: install_dir,
    pointing_to: install_dir / (host_machine.system() == 'windows' ? 'mesonlsp.exe' : 'mesonlsp'),
)

subdir('benchmarks')
subdir('lint')
