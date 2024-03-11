# Guide for contributors
- Check [PROGRESS.md] or the issues for tasks you could work on.
- Implement the task
- Submit a Pull Request.

## Code style
I use clang-format and clang-tidy for formatting and linting. Please run `ninja clang-format` before
submitting patches.


## Policies to keep in mind
Changes *must* work in GNOME Builder and *should* work in VSCode. If your patch only works in VSCode it will be rejected,
except if it is for a feature not supported by GNOME Builder.
If it works in GNOME Builder, but not in VSCode, it will be accepted, if and only if fixing VSCode requires non-trivial
changes. This means we follow the LSP client implementation in GNOME Builder.


## Contact
I made a matrix channel: [#mesonlsp:matrix.org](https://matrix.to/#/#mesonlsp:matrix.org) Feel free to join
