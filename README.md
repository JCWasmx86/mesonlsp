# Swift-MesonLSP

A reimplementation of my Meson language server in Swift.

## Why a reimplementation?
The first version (Written in Vala), had some code maintenance problems as basically everything is done in one file.
I had the choice between untangling that mess or rewriting it - as clean as possible.
I have chosen the latter, as I wanted to learn Swift.

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

(*) Depending on the progress of inlay hints in GNOME-Builder (See [here](https://gitlab.gnome.org/GNOME/gnome-builder/-/issues/1317) for progress)
