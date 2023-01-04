// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Swift-MesonLSP",
  products: [
    .library(name: "MesonAnalyze", targets: ["MesonAnalyze"]),
    .library(name: "MesonAST", targets: ["MesonAST"])
  ],
  dependencies: [
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.7.1"),
    .package(url: "https://github.com/JCWasmx86/tree-sitter-meson", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    .package(url: "https://github.com/kylef/PathKit", from: "1.0.1")
  ],
  targets: [
    .target(name: "MesonAnalyze", dependencies: ["SwiftTreeSitter", "MesonAST", "PathKit"]),
    .target(name: "MesonAST", dependencies: ["SwiftTreeSitter"]),
    .executableTarget(
      name: "Swift-MesonLSP",
      dependencies: [
        "SwiftTreeSitter", "MesonAnalyze", "MesonAST",
        .product(name: "TreeSitterMeson", package: "tree-sitter-meson"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]),
    .testTarget(
      name: "Swift-MesonLSPTests",
      dependencies: ["Swift-MesonLSP"])
  ]
)
