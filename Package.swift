// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Windows)
  #if swift(>=5.8) && swift(<5.9)
    #error("Windows builds will crash, if compiled using 5.8.")
  #endif
#endif

#if swift(<5.9) || os(Windows)
  let backtraceDeps = [
    Package.Dependency.package(
      url: "https://github.com/swift-server/swift-backtrace.git",
      from: "1.3.4"
    )
  ]
  let backtraceProducts = [Target.Dependency.product(name: "Backtrace", package: "swift-backtrace")]
#else
  let backtraceDeps: [Package.Dependency] = []
  let backtraceProducts: [Target.Dependency] = []
#endif

let package = Package(
  name: "Swift-MesonLSP",
  platforms: [.macOS("12.0")],
  products: [
    .library(name: "Caching", targets: ["Caching"]),
    .library(name: "MesonAnalyze", targets: ["MesonAnalyze"]),
    .library(name: "MesonAST", targets: ["MesonAST"]),
    .library(name: "LanguageServer", targets: ["LanguageServer"]),
    .library(name: "IOUtils", targets: ["IOUtils"]), .library(name: "Timing", targets: ["Timing"]),
    .library(name: "MesonDocs", targets: ["MesonDocs"]),
    .library(name: "TestingFramework", targets: ["TestingFramework"]),
    .library(name: "CMem", targets: ["CMem"]), .library(name: "Wrap", targets: ["Wrap"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/sourcekit-lsp",
      revision: "6e632129aa1b1b9f39f5b25d3b861fe71e0bfde9"
    ), .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    .package(url: "https://github.com/JCWasmx86/swift-log.git", branch: "main"),
    .package(url: "https://github.com/JCWasmx86/swift-tools-support-core.git", branch: "main"),
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.7.2"),
    .package(url: "https://github.com/JCWasmx86/SWCompression.git", branch: "develop"),
    .package(url: "https://github.com/JCWasmx86/tree-sitter-meson", from: "1.0.7"),
    .package(url: "https://github.com/PerfectlySoft/Perfect-INIParser.git", from: "4.0.0"),
    .package(url: "https://github.com/vapor/console-kit.git", from: "4.7.0"),
  ] + backtraceDeps,
  targets: [
    .target(
      name: "MesonAnalyze",
      dependencies: [
        "Timing", "SwiftTreeSitter", "MesonAST", "IOUtils", "Wrap",
        .product(name: "TreeSitterMeson", package: "tree-sitter-meson"),
        .product(name: "Logging", package: "swift-log"),
      ]
    ),
    .target(
      name: "Caching",
      dependencies: [
        "IOUtils", .product(name: "Logging", package: "swift-log"),
        .product(name: "Crypto", package: "swift-crypto"),
      ]
    ), .systemLibrary(name: "CMem"), .target(name: "Timing", dependencies: []),
    .target(name: "IOUtils", dependencies: [.product(name: "Logging", package: "swift-log")]),
    .target(
      name: "Wrap",
      dependencies: [
        "Caching", "IOUtils", "SWCompression", .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "INIParser", package: "Perfect-INIParser"),
        .product(name: "Logging", package: "swift-log"),
      ]
    ), .target(name: "MesonDocs", dependencies: []),
    .target(
      name: "TestingFramework",
      dependencies: ["MesonAnalyze", .product(name: "Logging", package: "swift-log")]
    ), .target(name: "MesonAST", dependencies: ["IOUtils", "SwiftTreeSitter", "Timing"]),
    .target(
      name: "LanguageServer",
      dependencies: [
        "MesonAnalyze", "Timing", "MesonDocs", "CMem", "IOUtils",
        .product(name: "LSPBindings", package: "sourcekit-lsp"),
        .product(name: "Logging", package: "swift-log"),
      ]
    ),
    .executableTarget(
      name: "Swift-MesonLSP",
      dependencies: [
        "SwiftTreeSitter", "MesonAnalyze", "MesonAST", "LanguageServer", "Timing",
        "TestingFramework", "Wrap",
        .product(
          name: "ConsoleKit",
          package: "console-kit",
          condition: .when(platforms: [.linux, .macOS])
        ), .product(name: "Logging", package: "swift-log"),
        .product(name: "TreeSitterMeson", package: "tree-sitter-meson"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "LSPBindings", package: "sourcekit-lsp"),
      ] + backtraceProducts,
      swiftSettings: [.unsafeFlags(["-parse-as-library"])]
    ),
    .testTarget(
      name: "Swift-MesonLSPTests",
      dependencies: [
        "MesonAnalyze", "MesonAST", .product(name: "TreeSitterMeson", package: "tree-sitter-meson"),
        "SwiftTreeSitter",
      ]
    ), .testTarget(name: "LanguageServerTests", dependencies: ["LanguageServer"]),
  ]
)
