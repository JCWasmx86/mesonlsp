swcompression_dep = subproject(
    'swcompression',
).get_variable('swcompression_dep')
iniparser_dep = subproject('iniparser').get_variable('iniparser_dep')

c = configure_file(copy: true, input: 'Wrap.swift', output: '_Wrap.swift')
wrap_lib = static_library(
    'Wrap',
    c,
    'Decompression.swift',
    'FileWrap.swift',
    'GitWrap.swift',
    'HgWrap.swift',
    'Provides.swift',
    'SvnWrap.swift',
    'VcsWrap.swift',
    'WrapDB.swift',
    'WrapError.swift',
    'WrapFileParser.swift',
    dependencies: [
        caching_dep,
        swcompression_dep,
        iniparser_dep,
    ],
    link_with: ioutils_lib,
)
wrap_dep = declare_dependency(
    link_with: [wrap_lib, ioutils_lib],
    dependencies: [
        caching_dep,
        swcompression_dep,
        iniparser_dep,
    ],
)
