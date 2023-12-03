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

Depends on: libtypes

### libwrap
Provides capabilities to download/extract wraps
### libanalyze
Provides capabilities to analyse meson code.

Depends on: libtypenamespace, libwrap, libast
### libjsonrpc
Implements the JSON-RPC protocol.
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