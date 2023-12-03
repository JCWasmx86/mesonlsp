# C++-Rewrite

## Structure
### liblog
Provides a logging implementation
### libtypes
Provides the data model for each type.
### libobjects
Provides the data model for everything callable (Functions/Methods).

Depends on: libtypes
### libtypenamespace
Provides a "TypeNamespace" instance containing everything like arguments, return types, docs

Depends on: libtypes, libobjects
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
