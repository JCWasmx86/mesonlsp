# Codeactions
This document describes how each code action is implemented

## Integer literal to other base
If there is an integer literal in the range of the code action request, parse it to an integer value and returns three code actions out of these four:
- Convert to hexadecimal literal
- Convert to binary literal
- Convert to octal literal
- Convert to decimal literal
## Convert `static_library`/`shared_library`/`both_libraries` to `library`
- Replace the name of the function
## Convert `shared_library` to `shared_module` (And the other way around)
- Replace the name of the function
## Unpack arrays passed to variadic functions
- Check whether the range contains a function call on an allowlist
- If yes, check if the variadic argument is an array
- Remove array brackets
## Change `configure_file(copy: true)` to `fs.copyfile()`
*Only kwargs allowed are `copy`/`input`/`output`/`install*`*

- Check if an variable of type `fs_module` already exists
- If no, create one at the top of the file.
- If yes, use it
- Change `configure_file` to `fs.copyfile()`
## Create dependency from library
- Extract `include_directories`, `dependencies`, `link_with`
- Extract the library variable name
- Call `declare_dependency` with the extracted arguments and additionally link against the library variable name
- Set the name of the dependency to `$LIBNAME | sed s/_lib$/_dep/g` if it ends with `_lib`, else just append `_dep`
