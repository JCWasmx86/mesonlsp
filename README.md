# Swift-MesonLSP

A reimplementation of my Meson language server in Swift.

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
- Inlay Hints (*)
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
