# C++-Rewrite

## Structure
### liblog
Provides a logging implementation

Status: Done
### libobjects
Provides the data model for everything callable (Functions/Methods)
and provides the types

Status: Mostly done (Preparations for docs are missing)
### libtypenamespace
Provides a "TypeNamespace" instance containing everything like arguments, return types, docs

Depends on: libobjects
Status: Mostly done (Docs are missing)
### libast
Provides the AST as C++ objects.

Depends on: libobjects
Status: Done
### libwrap
Provides capabilities to download/extract wraps

Status: Mostly done
### libanalyze
Provides capabilities to analyse meson code.

Depends on: libtypenamespace, libwrap, libast
Status: Mostly done
### libjsonrpc
Implements the JSON-RPC protocol.

Status: Done
### liblsptypes
Provides the types needed for a language server.

Status: In Progress
### libls
Combines libjsonrpc and liblsptypes to an abstract class

Depends on: libjsonrpc, liblsptypes
Status: In Progress
### liblangserver
Implements the language server.

Depends on: libwrap, libanalyze
Status: In Progress
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
### Ownership
- Each project will claim the ownership over its meson files.
- This will either work directly (`subdir` calls) or indirectly (Using subprojects)
- If there's a LSP request/notification that is not owned by any project, just stub information gatherers are executed. This may be the case for e.g. files of
  newly created subdirectories that weren't included by the parent directory yet.

## Before merging
- Fix all compiler warnings
- Fix all clang-tidy warnings as far as possible.
- Write new docs
- Write doc section for distributions
- Port scripts


## TODO
- Pass AnalysisOptions from LanguageServer to MesonTree
- Auto-completion
- Create namespaces
- Better analysis of conditions, whether they trigger
