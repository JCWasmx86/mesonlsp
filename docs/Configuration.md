# Configuration
These options have to be sent to the language server with the `initializationOptions` and `workspace/didChangeConfiguration`.
The format is:
```
{
  "others": {
    "ignoreDiagnosticsFromSubprojects": false,
    "neverDownloadAutomatically": false,
    "disableInlayHints": true
  },
  "linting": {
    "disableNameLinting": false,
    "disableAllIdLinting": false,
    "disableCompilerIdLinting": false
    "disableCompilerArgumentIdLinting": false,
    "disableLinkerIdLinting": false,
    "disableCpuFamilyLinting": false,
    "disableOsFamilyLinting": false
  }
}
```
- `others.ignoreDiagnosticsFromSubprojects`: If true, no diagnostics from subprojects will be shown. If it is an array of strings, the diagnostics from these subprojects will be ignored.
- `others.neverDownloadAutomatically`: If true, no subprojects/wraps are downloaded automatically.
- `others.disableInlayHints`: If true, no inlay hints will be shown.
- `linting.disableNameLinting`: Disable checking, whether the variable names are snake case
- `linting.disableAllIdLinting`: Disables checking of all following options.
- `linting.disableCompilerIdLinting`: Disables the comparison of string literals with the results of `compiler.get_id()` and emitting a warning, if unknown string.
- `linting.disableCompilerArgumentIdLinting`: Like above, just for `compiler.get_argument_syntax()`
- `linting.disableLinkerIdLinting`: Like above, just for `compiler.get_linker_id()`
- `linting.disableCpuFamilyLinting`: Like above, just for `host/target/build_machine.cpu_family()`
- `linting.disableOsFamilyLinting`: Like above, just for `host/target/build_machine.system()`
