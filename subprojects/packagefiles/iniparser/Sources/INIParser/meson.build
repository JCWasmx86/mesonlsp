c = configure_file(
    copy: true,
    input: 'INIParser.swift',
    output: '_INIParser.swift',
)
iniparser_lib = static_library(
    'INIParser',
    c,
)
iniparser_dep = declare_dependency(
    link_with: iniparser_lib,
)

