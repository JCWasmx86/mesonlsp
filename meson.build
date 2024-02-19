project(
    'mesonlsp',
    'c',
    'cpp',
    default_options: [
        'cpp_std=gnu++23',
        'warning_level=3',
    ],
    version: 'v4.0.0',
)

if get_option('buildtype') == 'release'
    add_global_arguments(['-D_FORTIFY_SOURCE=3', '-DNDEBUG'], language: 'c')
    add_global_arguments(['-D_FORTIFY_SOURCE=3', '-DNDEBUG'], language: 'cpp')
else
    add_global_arguments(
        ['-D_GLIBCXX_ASSERTIONS=1', '-D_GLIBCXX_DEBUG=1'],
        language: 'cpp',
    )
endif
extra_flags = [
    '-fstack-protector-strong',
    '-fstack-clash-protection',
    '-g3',
    '-Wshadow=local',
]

if host_machine.system() == 'linux'
    extra_flags += ['-fcf-protection=full', '-mshstk', '-frecord-gcc-switches']
endif

cc = meson.get_compiler('c')
cxx = meson.get_compiler('cpp')

global_link_args = ['-rdynamic']
if host_machine.system() == 'linux'
    global_link_args += ['-Wl,-z,relro,-z,now']
endif

add_global_link_arguments(global_link_args, language: 'c')
add_global_link_arguments(global_link_args, language: 'cpp')
add_global_arguments(extra_flags, language: 'c')
add_global_arguments(extra_flags, language: 'cpp')

if not get_option('use_own_tree_sitter')
    tree_sitter_dep = dependency(
        'tree-sitter',
        required: false,
        static: true,
        fallback: [],
    )
else
    tree_sitter_proj = subproject(
        'tree-sitter',
        default_options: ['default_library=static'],
    )
    tree_sitter_dep = tree_sitter_proj.get_variable('tree_sitter_dep')
    meson.override_dependency('tree-sitter', tree_sitter_dep)
endif

tree_sitter_meson_proj = subproject(
    'tree-sitter-meson',
    default_options: ['default_library=static'],
)
tree_sitter_meson_dep = tree_sitter_meson_proj.get_variable(
    'tree_sitter_meson_dep',
)

tree_sitter_ini_proj = subproject(
    'tree-sitter-ini',
    default_options: ['default_library=static'],
)
tree_sitter_ini_dep = tree_sitter_ini_proj.get_variable('tree_sitter_ini_dep')
sha256_proj = subproject('sha256', default_options: ['default_library=static'])
sha256_dep = sha256_proj.get_variable('sha256_dep')

ada_proj = subproject('ada', default_options: ['default_library=static'])
ada_dep = ada_proj.get_variable('ada_dep')

muon_proj = subproject('muon')
muon_dep = muon_proj.get_variable('muon_dep')

nlohmann_json_dep = dependency('nlohmann_json')
curl_dep = dependency('libcurl')
archive_dep = dependency('libarchive')
uuid_dep = dependency('uuid')
pkgconf_dep = dependency('libpkgconf')

cc_id = cc.get_id()
if cc_id != 'gcc' and cc_id != 'clang'
    warning(f'Unknown compiler: @cc_id@')
endif
system_id = target_machine.system()
if system_id != 'linux'
    warning(f'Untested OS: @system_id@')
endif

args = []

if get_option('static_build')
    extra_deps = [
        dependency('libbrotlicommon'),
        dependency('libbrotlidec'),
        dependency('libbrotlienc'),
    ]
    jemalloc_dep = dependency('jemalloc', static: true, required: false)
    if jemalloc_dep.found()
        extra_deps += jemalloc_dep
    else
        warning('jemalloc wasn\'t found')
    endif
    extra_libs = [cxx.find_library('c'), cxx.find_library('unistring')]
    extra_link_args = ['-static', '-Wl,-wrap=__cxa_throw']
else
    extra_deps = []
    extra_libs = []
    extra_link_args = []
    if get_option('use_jemalloc')
        extra_deps += dependency('jemalloc', static: true)
        args += '-DUSE_MIMALLOC'
    elif get_option('use_mimalloc')
        if get_option('use_mimalloc_wrap')
            mimalloc_proj = subproject('mimalloc')
            extra_deps += mimalloc_proj.get_variable('mimalloc_dep')
        else
            extra_deps += dependency('mimalloc', static: true)
        endif
        args += '-DUSE_MIMALLOC'
    endif
endif

fmt_dep = []
if system_id == 'darwin'
    fmt_dep = [dependency('fmt')]
    extra_deps += fmt_dep
endif

gtest_dep = dependency('gtest', main: true, required: false)

subdir('src')

if not gtest_dep.found()
    gtest_proj = subproject('gtest')
    gtest_dep = gtest_proj.get_variable('gtest_dep')
endif

if gtest_dep.found() and get_option('tests')
    subdir('tests')
endif
