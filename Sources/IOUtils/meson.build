c = configure_file(copy: true, input: 'IOUtils.swift', output: '_IOUtils.swift')
ioutils_lib = static_library(
    'IOUtils',
    c,
    'Processes.swift',
    dependencies: [logging_dep],
)
ioutils_dep = declare_dependency(
    dependencies: [logging_dep],
    link_with: [ioutils_lib],
)

