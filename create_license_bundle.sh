#!/usr/bin/env bash
{
	echo "ConsoleKit (https://github.com/vapor/console-kit)"
	curl https://raw.githubusercontent.com/vapor/console-kit/main/LICENSE
	echo "PerfectINI (https://github.com/PerfectlySoft/Perfect-INIParser)"
	curl https://raw.githubusercontent.com/PerfectlySoft/Perfect-INIParser/master/LICENSE
	echo "sourcekit-lsp (https://github.com/apple/sourcekit-lsp)"
	curl https://raw.githubusercontent.com/apple/sourcekit-lsp/main/LICENSE.txt
	echo "SWCompression (https://github.com/JCWasmx86/SWCompression/"
	echo "Custom changes: https://github.com/tsolomko/SWCompression/compare/develop...JCWasmx86:SWCompression:develop"
	curl https://raw.githubusercontent.com/tsolomko/SWCompression/develop/LICENSE
	echo "swift-argument-parser (https://github.com/apple/swift-argument-parser)"
	curl https://raw.githubusercontent.com/apple/swift-argument-parser/main/LICENSE.txt
	echo "swift-crypto (https://github.com/apple/swift-crypto)"
	curl https://raw.githubusercontent.com/apple/swift-crypto/main/LICENSE.txt
	echo "Swifter (https://github.com/httpswift/swifter)"
	curl https://raw.githubusercontent.com/httpswift/swifter/stable/LICENSE
	echo "Backtrace (https://github.com/swift-server/swift-backtrace)"
	curl https://raw.githubusercontent.com/swift-server/swift-backtrace/main/LICENSE.txt
	echo "swift-log (https://github.com/apple/swift-log)"
	curl https://raw.githubusercontent.com/apple/swift-log/main/LICENSE.txt
	echo "SwiftTreeSitter (https://github.com/ChimeHQ/SwiftTreeSitter)"
	curl https://raw.githubusercontent.com/ChimeHQ/SwiftTreeSitter/main/LICENSE
	echo "tree-sitter-meson (https://github.com/bearcove/tree-sitter-meson)"
	echo "Custom changes: https://github.com/bearcove/tree-sitter-meson/compare/main...JCWasmx86:tree-sitter-meson:main"
} >"3rdparty.txt"
