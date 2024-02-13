// This file was used for Swift package management but is now deprecated due to the project's transition to C++.
// For C++ dependency management, refer to CMakeLists.txt.
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
