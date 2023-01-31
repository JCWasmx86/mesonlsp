# Swift-MesonLSP

A reimplementation of my Meson language server in Swift.

## Limitations
- Only very partial for anything regarding `set_variable`/`get_variable`
- No wrap/subproject support
- Non constant `subdir`-calls are not supported
- Type deduction is not 100% correct yet

```
some_var = foo
set_variable('foo' + some_var, 1)
x = foo_foo # Unknown identifier 'foo_foo'
foreach backend : backends
  # The file backend-$backend/meson.build
  # won't be parsed
  subdir('backend-' + backend)
endforeach
```

## Why a reimplementation?
The first version, written in Vala, had some code maintenance problems because basically everything was done in one file.
I had the choice between untangling that mess or rewriting it as cleanly as possible.
I have chosen the latter because I wanted to learn Swift.

## Installation
### Requirements
- Language Server: `sudo dnf install swift-lang`
- GNOME-Builder plugin: `sudo dnf install git vala meson gcc libgee-devel json-glib-devel gtk4-devel gtksourceview5-devel libadwaita-devel libpeas-devel template-glib-devel g++ libsoup3-devel`
### Installation
#### Language Server
```
git clone https://github.com/JCWasmx86/Swift-MesonLSP
cd Swift-MesonLSP
swift build -c release --static-swift-stdlib
sudo cp .build/release/Swift-MesonLSP /usr/local/bin
```
#### GNOME Builder plugin (Requires GNOME Builder Nightly)
```
git clone https://github.com/JCWasmx86/GNOME-Builder-Plugins
cd GNOME-Builder-Plugins
# The other plugins in the repo
# get disabled
meson -Dplugin_cabal=disabled \
      -Dplugin_clangd=disabled \
      -Dplugin_gitgui=disabled \
      -Dplugin_hadolint=disabled \
      -Dplugin_hls=disabled \
      -Dplugin_icon_installer=disabled \
      -Dplugin_markdown=disabled \
      -Dplugin_muon=disabled \
      -Dplugin_pylint=disabled \
      -Dplugin_shfmt=disabled \
      -Dplugin_sqls=disabled \
      -Dplugin_stack=disabled \
      -Dplugin_swift=disabled \
      -Dplugin_swift_format=disabled \
      -Dplugin_swift_lint=disabled \
      -Dplugin_swift_templates=disabled \
      -Dplugin_sourcekit=disabled \
      -Dplugin_texlab=disabled \
      -Dplugin_xmlfmt=disabled \
      -Dplugin_xmlfmt=disabled \
      -Duse_swift_meson_lsp=true \
      _build
cd _build
# Don't do "sudo ninja install"
ninja -j $(nproc) install
```

## Expected feature set
### Version 1.0
- Hovering
- Symbol resolving
- Diagnostics
- A limited set of diagnostics

### Version 2.0
- Autocompletion
- More diagnostics
- Inlay Hints (*)
- Full Wrap/Subproject support
- Formatting

### Version 3.0
- Renaming
- Code actions
- Inlay Hints (*)

(*) Depending on the progress of inlay hints in GNOME-Builder (See [here](https://gitlab.gnome.org/GNOME/gnome-builder/-/issues/1317) for progress)

## Debugging performance problems
The language server is measuring the duration needed by certain operations and exposes it using a HTTP-Server on `http://localhost:65000` (Or any bigger port, if 65000 is already used)

![Timing](img/timings.png)
This picture shows an example of the rendered timing information. The project used is mesa and it
got fully parsed 35 times.

- `analyzingTypes` is the section in which all nodes of the AST are annotated with their possible type(s)
- `sendingDiagnostics` is the section, where all diagnostics are sent back to the editor/client
- `rebuildTree` is responsible for clearing all diagnostics, parsing all meson files, annotating the types, sending the newdiagnostics
- `parsingEntireTree` is the section for parsing the entire project, patching the ASTs, etc.
- `SelectionStatementTypeMerge` is part of the type analyzer. It is responsible for merging the possible types after different branches.
- `patchingAST` is the section in which all `subdir('foo')` calls are replaced by nodes referencing the corresponding source files.
- `buildingAST` is the section in which the tree sitter nodes are converted to easier to use objects
- `parsing` is the section for just parsing a file using tree-sitter
- `checkCall` is for checking the arguments of the call (Except type checking at the moment)
- `clearingDiagnostics` is the section in that all diagnostics are cleared before rebuilding the tree.
- `checkIdentifier` checks, if an identifier follows `snake_case`
- `guessingMethod` is a method that attempts to deduce the possible methods that are called on an `any` object.
- `evalStack` is responsible for getting types of variables that were overwritten in previous branches of selection statements.

In this example, it took around half-second to parse the entire mesa meson files, deduce the types and emit diagnostics.
