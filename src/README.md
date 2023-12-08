# C++-Rewrite

## Structure
### liblog
Provides a logging implementation

Status: Done
### libobjects
Provides the data model for everything callable (Functions/Methods)
and provides the types

Status: Partially done
### libtypenamespace
Provides a "TypeNamespace" instance containing everything like arguments, return types, docs

Depends on: libobjects
### libast
Provides the AST as C++ objects.

Depends on: libobjects
Status: Partially done
### libwrap
Provides capabilities to download/extract wraps
### libanalyze
Provides capabilities to analyse meson code.

Depends on: libtypenamespace, libwrap, libast
### libjsonrpc
Implements the JSON-RPC protocol.

Status: Largely done
### liblsptypes
Provides the types needed for a language server.
### libls
Combines libjsonrpc and liblsptypes to an abstract class

Depends on: libjsonrpc, liblsptypes
### liblangserver
Implements the language server.

Depends on: libwrap, libanalyze

## Design Aspects
- No dynamically linked dependencies
- Minimal number of dependencies
- Safety > Performance
- Drop-In binary for Swift-MesonLSP
- Split up into multiple modules/libraries
- Modern C++ => Fedora 39 as baseline

## Goals/Non-Goals
### Goals
- Equal/Better performance
- Smaller binary
- gcc/clang compatibility
- Linux/macOS/Windows support
### Non-Goals
- MSVC compatibility


## Braindump
### Multi-root workspace support (https://github.com/mesonbuild/vscode-meson/issues/201)
- We will have multiple projects => One for each workspace
- Each project will have nested projects for its subprojects
- Each project will have a wrapfile state that will be used for doing LSP stuff with wrap files and knowing when to update the wraps.
- If no project is passed, the root project will be one project (With subprojects)