executable(
    'mesonlint',
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
        log_dep,
        objects_dep,
        cxathrow_dep,
    ] + extra_deps + extra_libs,
    install: true,
    pie: host_machine.system() == 'linux',
)
