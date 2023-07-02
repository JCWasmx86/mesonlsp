# Swift-MesonLSP
[![Copr build status](https://copr.fedorainfracloud.org/coprs/jcwasmx86/Swift-MesonLSP/package/Swift-MesonLSP/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/jcwasmx86/Swift-MesonLSP/package/Swift-MesonLSP/)
[![AUR Version](https://img.shields.io/aur/version/swift-mesonlsp)](https://aur.archlinux.org/packages/swift-mesonlsp/)
[![codecov](https://codecov.io/github/JCWasmx86/Swift-MesonLSP/branch/main/graph/badge.svg?token=5OV4WH5DL1)](https://codecov.io/github/JCWasmx86/Swift-MesonLSP)

A reimplementation of my Meson language server in Swift.

## Current feature set
- Hovering (Documentation often copied verbatim/minimally modified from mesonbuild, CC BY-SA 4.0, same for the entire `Sources/MesonDocs` directory due to ShareAlike)
- Symbol resolving
- Jump-To-Definition
- Jump-To-Subdir
- A basic set of diagnostics
- Formatting
- Document symbols
- Autocompletion
- Inlay hints
- Highlighting
- Automatic subproject/wrap downloads
- Code actions
- Renaming

## Limitations
- `set_variable`/`get_variable` with non-constant variable name will fail in more complex cases. [See here for working patterns](https://github.com/JCWasmx86/Swift-MesonLSP/blob/main/TestCases/ComputeSetVariable/meson.build)
- `subdir` with non-constant subdir name will fail in more complex cases. [See here for working patterns](https://github.com/JCWasmx86/Swift-MesonLSP/blob/main/TestCases/ComputeSubdirs/meson.build)
- Type deduction is not 100% correct yet
- Type definitions may have minor errors regarding:
  - Is this argument optional?
  - What is the type of the argument?

## Why a reimplementation?
The first version, written in Vala, had some code maintenance problems because basically everything was done in one file.
I had the choice between untangling that mess or rewriting it as cleanly as possible.
I have chosen the latter because I wanted to learn Swift.

## Installation
### Install the language server
#### Easy way
- For Fedora, a COPR is provided: https://copr.fedorainfracloud.org/coprs/jcwasmx86/Swift-MesonLSP/
- For Arch, you can use the repo from [AUR](https://aur.archlinux.org/packages/swift-mesonlsp)
- For Ubuntu 18.04,20.04,22.04 and Debian Bullseye, Bookworm, Sid you can use: https://github.com/JCWasmx86/swift-mesonlsp-apt-repo
- For Ubuntu 22.04, MacOS 12 and Windows, you can download binaries from the release section: https://github.com/JCWasmx86/Swift-MesonLSP/releases/latest
#### Compile from source
```
git clone https://github.com/JCWasmx86/Swift-MesonLSP
cd Swift-MesonLSP
swift build -c release --static-swift-stdlib
sudo cp .build/release/Swift-MesonLSP /usr/local/bin
```
Or you can use podman (Maybe even docker, but only podman is tested):
```
DOCKER_BUILDKIT=1 podman build --file docker/Dockerfile --output out --no-cache .
# If you want to use Ubuntu 22.04 as docker image
DOCKER_BUILDKIT=1 podman build --file docker/Dockerfile.ubuntu --output out --no-cache .
# If you want to use Ubuntu 18.04 as docker image
DOCKER_BUILDKIT=1 podman build --file docker/Dockerfile.ubuntu1804 --output out --no-cache .
# If you want to use Ubuntu 20.04 as docker image
DOCKER_BUILDKIT=1 podman build --file docker/Dockerfile.ubuntu2004 --output out --no-cache .
```
This will place a file "Fedora37.zip" (Or Ubuntu22.04.zip) in the directory `out`. It contains
two statically linked binaries. Copy `Swift-MesonLSP` to `/usr/local/bin`.

A debug build is provided, too. Just rename it from `Swift-MesonLSP.debug`
to `Swift-MesonLSP` and copy it to the right destination.

### Connect with your editor
#### VSCode
Install this fork of vscode-meson: https://github.com/JCWasmx86/vscode-meson
#### GNOME Builder Nightly
- Dependencies for Fedora: `sudo dnf install git vala meson gcc libgee-devel json-glib-devel gtk4-devel gtksourceview5-devel libadwaita-devel libpeas-devel template-glib-devel g++ libsoup3-devel`
```
git clone https://github.com/JCWasmx86/GNOME-Builder-Plugins
cd GNOME-Builder-Plugins
# The other plugins in the repo
# get disabled
meson -Dplugin_clangd=disabled \
      -Dplugin_gitgui=disabled \
      -Dplugin_icon_installer=disabled \
      -Dplugin_scriptdir=disabled \
      -Dplugin_shfmt=disabled \
      -Dplugin_swift_templates=disabled \
      -Dplugin_texlab=disabled \
      -Dplugin_callhierarchy=disabled \
      -Dplugin_gtkcsslanguageserver=disabled \
      _build
cd _build
# Don't do "sudo ninja install"
ninja -j $(nproc) install
```
#### Kate
Add this JSON to `~/.config/kate/lspclient/settings.json`:
```
{
  "servers": {
    "meson": {
      "command": [
        "Swift-MesonLSP",
        "--lsp"
      ],
      "rootIndicationFileNames": [
        "meson.build",
        "meson_options.txt"
      ],
      "url": "https://github.com/JCWasmx86/Swift-MesonLSP",
      "highlightingModeRegex": "^Meson$"
    }
  }
}
```
After that, a dialog should be shown asking you to confirm that the language server may be started.

#### neovim
Add this JSON to `:CocConfig`:
```
{
    "languageserver": {
        "meson": {
            "command": "Swift-MesonLSP",
            "args": ["--lsp"],
            "rootPatterns": ["meson.build"],
            "filetypes": ["meson"]
        }
    }
}
```

## Want to contribute?
Take an item from the TODO list in [PROGRESS.md](PROGRESS.md) and work on it. Feel
free to join the matrix channel [#mesonlsp:matrix.org](https://matrix.to/#/#mesonlsp:matrix.org)

## References
- [gnome-builder#629](https://gitlab.gnome.org/GNOME/gnome-builder/-/issues/629) An issue somewhat related to this project.
### Dependencies
- [ConsoleKit](https://github.com/vapor/console-kit.git) - APIs for creating interactive CLI tools. (Used the loghandler from there to have nice logs)
- [Perfect-INIParser](https://github.com/PerfectlySoft/Perfect-INIParser) - A lightweight INI file parser in Server Side Swift 
- [sourcekit-lsp](https://github.com/apple/sourcekit-lsp) - Language Server Protocol implementation for Swift and C-based languages. (I used the JSONRPC definitions from them)
- [SWCompression](https://github.com/tsolomko/SWCompression) - A Swift framework for working with compression, archives and containers. 
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - Straightforward, type-safe argument parsing for Swift
- [swift-crypto](https://github.com/apple/swift-crypto) - Open-source implementation of a substantial portion of the API of Apple CryptoKit suitable for use on Linux platforms.
- [Swifter](https://github.com/httpswift/swifter) - Tiny http server engine written in Swift programming language.
- [swift-log](https://github.com/apple/swift-log) - A Logging API for Swift
- [swift-backtrace](https://github.com/swift-server/swift-backtrace) - Backtraces for Swift on Linux and Windows 
- [SwiftTreeSitter](https://github.com/ChimeHQ/SwiftTreeSitter) - Swift API for the tree-sitter incremental parsing system
- [tree-sitter-meson](https://github.com/JCWasmx86/tree-sitter-meson) - A tree-sitter grammar for meson.build files. Forked and enhanced by me.

### Projects I tested the language server with
- Working fine:
  - [Fractal](https://gitlab.gnome.org/GNOME/fractal)
  - [GitG](https://gitlab.gnome.org/GNOME/gitg)
  - [GLib](https://gitlab.gnome.org/GNOME/glib)
  - [GNOME Builder](https://gitlab.gnome.org/GNOME/gnome-builder)
  - [GNOME Builder Plugins](https://github.com/JCWasmx86/GNOME-Builder-Plugins)
  - [GTK](https://gitlab.gnome.org/GNOME/gtk)
  - [libswiftdemangle](https://github.com/JCWasmx86/libswiftdemangle)
  - [Mesa](https://gitlab.freedesktop.org/mesa/mesa)
  - [QEMU](https://gitlab.com/qemu-project/qemu)
  - [rustc-demangle](https://github.com/JCWasmx86/rustc-demangle)
  - [Systemd](https://github.com/systemd/systemd)
  - [GStreamer](https://gitlab.freedesktop.org/gstreamer/gstreamer)
- Somewhat flaky to unusable
  - [HelenOS](http://www.helenos.org/)
  - [picolibc](https://github.com/picolibc/picolibc)
  - [DPDK](https://www.dpdk.org/)

