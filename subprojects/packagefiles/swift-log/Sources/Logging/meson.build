c = configure_file(copy: true, input: 'Logging.swift', output: '_Logging.swift')
swift_log_lib = static_library(
    'Logging',
    'Locks.swift',
    'LogHandler.swift',
    c,
    'MetadataProvider.swift',
)
swift_log_dep = declare_dependency(
    link_with: swift_log_lib,
)
