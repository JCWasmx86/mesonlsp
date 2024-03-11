# Notes for distributers
Thanks a lot for even considering packaging this language server for your distribution.
## Dependencies
Checkout mesonlsp.spec for a RPM manifest that contains all (runtime/build-)dependencies.

You need at least gcc 13, as mesonlsp depends on the `<format>` header.
## Patches
If there are patches needed for this language server, kindly share them with me.
Your patch doesn't have to be overly detailed.
A simple note informing me about any missing elements for distributors would suffice.
## Compilation
- Please consider using LTO (Compile with `-Db_lto=true`)
- Use the release build (Run meson with `--buildtype release`). Some options will be added if this switch is used (E.g. hardening)
- Consider linking with jemalloc or mimalloc (Configure with `-Duse_jemalloc=true` or `-Duse_mimalloc=true`). This improves performance by ~10-20%
