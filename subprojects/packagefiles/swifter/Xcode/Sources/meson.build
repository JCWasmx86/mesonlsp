swifter_inc = include_directories('.')
swifter_lib = static_library(
    'Swifter',
    'DemoServer.swift',
    'Errno.swift',
    'Files.swift',
    'HttpParser.swift',
    'HttpRequest.swift',
    'HttpResponse.swift',
    'HttpRouter.swift',
    'HttpServer.swift',
    'HttpServerIO.swift',
    'MimeTypes.swift',
    'Process.swift',
    'Scopes.swift',
    'Socket+File.swift',
    'Socket+Server.swift',
    'Socket.swift',
    'String+BASE64.swift',
    'String+File.swift',
    'String+Misc.swift',
    'String+SHA1.swift',
    'WebSockets.swift',
    include_directories: swifter_inc,
)
swifter_dep = declare_dependency(
    include_directories: swifter_inc,
    link_with: swifter_lib,
)
