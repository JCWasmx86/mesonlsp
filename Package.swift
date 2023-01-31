// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Swift-MesonLSP",
  products: [
    .library(name: "MesonAnalyze", targets: ["MesonAnalyze"]),
    .library(name: "MesonAST", targets: ["MesonAST"]),
    .library(name: "LanguageServer", targets: ["LanguageServer"]),
    .library(name: "Timing", targets: ["Timing"]),
    .library(name: "MesonDocs", targets: ["MesonDocs"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.7.1"),
    .package(url: "https://github.com/JCWasmx86/tree-sitter-meson", from: "1.0.1"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.3"),
    .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),
    .package(url: "https://github.com/apple/sourcekit-lsp", branch: "main"),
    .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.5.0")),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2"),
    .package(url: "https://github.com/vapor/console-kit.git", from: "4.6.0"),
  ],
  targets: [
    .target(
      name: "MesonAnalyze",
      dependencies: ["Timing", "SwiftTreeSitter", "MesonAST", "PathKit"]
    ), .target(name: "Timing", dependencies: []), .target(name: "MesonDocs", dependencies: []),
    .target(name: "MesonAST", dependencies: ["SwiftTreeSitter", "Timing"]),
    .target(
      name: "LanguageServer",
      dependencies: [
        "Timing", .product(name: "Swifter", package: "swifter"), "MesonDocs",
        .product(name: "LSPBindings", package: "sourcekit-lsp"),
      ]
    ),
    .executableTarget(
      name: "Swift-MesonLSP",
      dependencies: [
        "SwiftTreeSitter", "MesonAnalyze", "MesonAST", "LanguageServer", "Timing",
        .product(name: "ConsoleKit", package: "console-kit"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "TreeSitterMeson", package: "tree-sitter-meson"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "LSPBindings", package: "sourcekit-lsp"),
      ]
    ), .testTarget(name: "Swift-MesonLSPTests", dependencies: ["Swift-MesonLSP"]),
  ]
)
