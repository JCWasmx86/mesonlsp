class BuiltinKwargDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["both_libraries<c_args>"] = "Compiler flags for C"
    dict["both_libraries<cpp_args>"] = "Compiler flags for C++"
    dict["both_libraries<cs_args>"] = "Compiler flags for C#"
    dict["both_libraries<d_args>"] = "Compiler flags for D"
    dict["both_libraries<fortran_args>"] = "Compiler flags for Fortran"
    dict["both_libraries<java_args>"] = "Compiler flags for Java"
    dict["both_libraries<objc_args>"] = "Compiler flags for Objective-C"
    dict["both_libraries<objcpp_args>"] = "Compiler flags for Objective-C++"
    dict["both_libraries<rust_args>"] = "Compiler flags for Rust"
    dict["both_libraries<vala_args>"] = "Compiler flags for Vala"
    dict["both_libraries<cython_args>"] = "Compiler flags for Cython"
    dict["both_libraries<nasm_args>"] = "Compiler flags for NASM"
    dict["both_libraries<masm_args>"] = "Compiler flags for MASM"
    dict["both_libraries<c_pch>"] = "Precompiled header file to use for C"
    dict["both_libraries<cpp_pch>"] = "Precompiled header file to use for C++"
    dict["both_libraries<build_by_default>"] =
      "Causes, when set to true, to have this target be built by default. This means it will be built when meson compile is called without any arguments. The default value is true for all built target types."
    dict["both_libraries<build_rpath>"] =
      "A string to add to target's rpath definition in the build dir, but which will be removed on install"
    dict["both_libraries<d_debug>"] =
      "The D version identifiers to add during the compilation of D source files."
    dict["both_libraries<d_import_dirs>"] =
      "List of directories to look in for string imports used in the D programming language."
    dict["both_libraries<d_module_versions>"] =
      "List of module version identifiers set when compiling D sources."
    dict["both_libraries<d_unittest>"] =
      "When set to true, the D modules are compiled in debug mode."
    dict["both_libraries<darwin_versions>"] =
      "Defines the compatibility version and current version for the dylib on macOS. If a list is specified, it must be either zero, one, or two elements. If only one element is specified or if it's not a list, the specified value will be used for setting both compatibility version and current version. If unspecified, the soversion will be used as per the aforementioned rules."
    dict["both_libraries<dependencies>"] = "One or more dependency objects"
    dict["both_libraries<extra_files>"] =
      "Not used for the build itself but are shown as source files in IDEs that group files by targets (such as Visual Studio)"
    dict["both_libraries<gnu_symbol_visibility>"] =
      "Specifies how symbols should be exported: default/internal/hidden/protected/inlineshidden"
    dict["both_libraries<gui_app>"] =
      "When set to true flags this target as a GUI application on platforms where this makes a differerence, deprecated since 0.56.0, use win_subsystem instead."
    dict["both_libraries<implicit_include_directories>"] =
      "Controls whether Meson adds the current source and build directories to the include path"
    dict["both_libraries<include_directories>"] =
      "One or more objects created with the include_directories() function, or (since 0.50.0) strings, which will be transparently expanded to include directory objects"
    dict["both_libraries<install>"] = "When set to true, this executable should be installed."
    dict["both_libraries<install_dir>"] =
      "Override install directory for this file. If the value is a relative path, it will be considered relative the prefix option"
    dict["both_libraries<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["both_libraries<install_rpath>"] =
      "A string to set the target's rpath to after install (but not before that). On Windows, this argument has no effect."
    dict["both_libraries<install_tag>"] =
      "A string used by the `meson install --tags` command to install only a subset of the files. By default all build targets have the tag runtime except for static libraries that have the devel tag."
    dict["both_libraries<link_args>"] =
      "Flags to use during linking. You can use UNIX-style flags here for all platforms."
    dict["both_libraries<link_depends>"] =
      "Strings, files, or custom targets the link step depends on such as a symbol visibility map. The purpose is to automatically trigger a re-link (but not a re-compile) of the target when this file changes."
    dict["both_libraries<link_language>"] =
      "Makes the linker for this target be for the specified language. It is generally unnecessary to set this, as Meson will detect the right linker to use in most cases. There are only two cases where this is needed. One, your main function in an executable is not in the language Meson picked, or second you want to force a library to use only one ABI."
    dict["both_libraries<link_whole>"] =
      "Links all contents of the given static libraries whether they are used by not, equivalent to the -Wl,--whole-archive argument flag of GCC."
    dict["both_libraries<link_with>"] =
      "One or more shared or static libraries (built by this project) that this target should be linked with. (since 0.41.0) If passed a list this list will be flattened. (since 0.51.0) The arguments can also be custom targets. In this case Meson will assume that merely adding the output file in the linker command line is sufficient to make linking work. If this is not sufficient, then the build system writer must write all other steps manually."
    dict["both_libraries<name_prefix>"] =
      "The string that will be used as the prefix for the target output filename by overriding the default (only used for libraries). By default this is lib on all platforms and compilers, except for MSVC shared libraries where it is omitted to follow convention, and Cygwin shared libraries where it is cyg."
    dict["both_libraries<name_suffix>"] =
      "The string that will be used as the extension for the target by overriding the default. By default on Windows this is exe for executables and on other platforms it is omitted."
    dict["both_libraries<native>"] =
      "Controls whether the target is compiled for the build or host machines."
    dict["both_libraries<objects>"] = "List of object files that should be linked in this target."
    dict["both_libraries<pic>"] =
      "Builds the library as positional independent code (so it can be linked into a shared library). This option has no effect on Windows and OS X since it doesn't make sense on Windows and PIC cannot be disabled on OS X."
    dict["both_libraries<prelink>"] =
      "If true the object files in the target will be prelinked, meaning that it will contain only one prelinked object file rather than the individual object files."
    dict["both_libraries<rust_crate_type>"] =
      "Set the specific type of rust crate to compile (when compiling rust)."
    dict["both_libraries<sources>"] = "Additional source files. Same as the source varargs."
    dict["both_libraries<soversion>"] =
      "A string or integer specifying the soversion of this shared library, such as 0. On Linux and Windows this is used to set the soversion (or equivalent) in the filename. For example, if soversion is 4, a Windows DLL will be called foo-4.dll and one of the aliases of the Linux shared library would be libfoo.so.4. If this is not specified, the first part of version is used instead (see below). For example, if version is 3.6.0 and soversion is not defined, it is set to 3."
    dict["both_libraries<version>"] =
      "A string specifying the version of this shared library, such as 1.1.0. On Linux and OS X, this is used to set the shared library version in the filename, such as libfoo.so.1.1.0 and libfoo.1.1.0.dylib. If this is not specified, soversion is used instead."
    dict["both_libraries<vs_module_defs>"] =
      "Specify a Microsoft module definition file for controlling symbol exports, etc., on platforms where that is possible (e.g. Windows)."
    dict["both_libraries<win_subsystem>"] =
      "Specifies the subsystem type to use on the Windows platform. Typical values include console for text mode programs and windows for gui apps. The value can also contain version specification such as windows,6.0"
    dict["build_target<c_args>"] = "Compiler flags for C"
    dict["build_target<cpp_args>"] = "Compiler flags for C++"
    dict["build_target<cs_args>"] = "Compiler flags for C#"
    dict["build_target<d_args>"] = "Compiler flags for D"
    dict["build_target<fortran_args>"] = "Compiler flags for Fortran"
    dict["build_target<java_args>"] = "Compiler flags for Java"
    dict["build_target<objc_args>"] = "Compiler flags for Objective-C"
    dict["build_target<objcpp_args>"] = "Compiler flags for Objective-C++"
    dict["build_target<rust_args>"] = "Compiler flags for Rust"
    dict["build_target<vala_args>"] = "Compiler flags for Vala"
    dict["build_target<cython_args>"] = "Compiler flags for Cython"
    dict["build_target<nasm_args>"] = "Compiler flags for NASM"
    dict["build_target<masm_args>"] = "Compiler flags for MASM"
    dict["build_target<c_pch>"] = "Precompiled header file to use for C"
    dict["build_target<cpp_pch>"] = "Precompiled header file to use for C++"
    dict["build_target<build_by_default>"] =
      "Causes, when set to true, to have this target be built by default. This means it will be built when meson compile is called without any arguments. The default value is true for all built target types."
    dict["build_target<build_rpath>"] =
      "A string to add to target's rpath definition in the build dir, but which will be removed on install"
    dict["build_target<d_debug>"] =
      "The D version identifiers to add during the compilation of D source files."
    dict["build_target<d_import_dirs>"] =
      "List of directories to look in for string imports used in the D programming language."
    dict["build_target<d_module_versions>"] =
      "List of module version identifiers set when compiling D sources."
    dict["build_target<d_unittest>"] = "When set to true, the D modules are compiled in debug mode."
    dict["build_target<darwin_versions>"] =
      "Defines the compatibility version and current version for the dylib on macOS. If a list is specified, it must be either zero, one, or two elements. If only one element is specified or if it's not a list, the specified value will be used for setting both compatibility version and current version. If unspecified, the soversion will be used as per the aforementioned rules."
    dict["build_target<dependencies>"] = "One or more dependency objects"
    dict["build_target<export_dynamic>"] =
      "when set to true causes the target's symbols to be dynamically exported, allowing modules built using the `shared_module()` function to refer to functions, variables and other symbols defined in the executable itself. Implies the implib argument."
    dict["build_target<extra_files>"] =
      "Not used for the build itself but are shown as source files in IDEs that group files by targets (such as Visual Studio)"
    dict["build_target<gnu_symbol_visibility>"] =
      "Specifies how symbols should be exported: default/internal/hidden/protected/inlineshidden"
    dict["build_target<gui_app>"] =
      "When set to true flags this target as a GUI application on platforms where this makes a differerence, deprecated since 0.56.0, use win_subsystem instead."
    dict["build_target<implib>"] =
      "When set to true, an import library is generated for the executable (the name of the import library is based on exe_name). Alternatively, when set to a string, that gives the base name for the import library. The import library is used when the returned build target object appears in link_with: elsewhere. Only has any effect on platforms where that is meaningful (e.g. Windows). Implies the export_dynamic argument."
    dict["build_target<implicit_include_directories>"] =
      "Controls whether Meson adds the current source and build directories to the include path"
    dict["build_target<include_directories>"] =
      "One or more objects created with the include_directories() function, or (since 0.50.0) strings, which will be transparently expanded to include directory objects"
    dict["build_target<install>"] = "When set to true, this executable should be installed."
    dict["build_target<install_dir>"] =
      "Override install directory for this file. If the value is a relative path, it will be considered relative the prefix option"
    dict["build_target<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["build_target<install_rpath>"] =
      "A string to set the target's rpath to after install (but not before that). On Windows, this argument has no effect."
    dict["build_target<install_tag>"] =
      "A string used by the `meson install --tags` command to install only a subset of the files. By default all build targets have the tag runtime except for static libraries that have the devel tag."
    dict["build_target<java_resources>"] = "Resources to be added to the jar"
    dict["build_target<link_args>"] =
      "Flags to use during linking. You can use UNIX-style flags here for all platforms."
    dict["build_target<link_depends>"] =
      "Strings, files, or custom targets the link step depends on such as a symbol visibility map. The purpose is to automatically trigger a re-link (but not a re-compile) of the target when this file changes."
    dict["build_target<link_language>"] =
      "Makes the linker for this target be for the specified language. It is generally unnecessary to set this, as Meson will detect the right linker to use in most cases. There are only two cases where this is needed. One, your main function in an executable is not in the language Meson picked, or second you want to force a library to use only one ABI."
    dict["build_target<link_whole>"] =
      "Links all contents of the given static libraries whether they are used by not, equivalent to the -Wl,--whole-archive argument flag of GCC."
    dict["build_target<link_with>"] =
      "One or more shared or static libraries (built by this project) that this target should be linked with. (since 0.41.0) If passed a list this list will be flattened. (since 0.51.0) The arguments can also be custom targets. In this case Meson will assume that merely adding the output file in the linker command line is sufficient to make linking work. If this is not sufficient, then the build system writer must write all other steps manually."
    dict["build_target<main_class>"] = "Main class for running the built jar"
    dict["build_target<name_prefix>"] =
      "The string that will be used as the prefix for the target output filename by overriding the default (only used for libraries). By default this is lib on all platforms and compilers, except for MSVC shared libraries where it is omitted to follow convention, and Cygwin shared libraries where it is cyg."
    dict["build_target<name_suffix>"] =
      "The string that will be used as the extension for the target by overriding the default. By default on Windows this is exe for executables and on other platforms it is omitted."
    dict["build_target<native>"] =
      "Controls whether the target is compiled for the build or host machines."
    dict["build_target<objects>"] = "List of object files that should be linked in this target."
    dict["build_target<override_options>"] =
      "takes an array of strings in the same format as project's `default_options` overriding the values of these options for this target only."
    dict["build_target<pic>"] =
      "Builds the library as positional independent code (so it can be linked into a shared library). This option has no effect on Windows and OS X since it doesn't make sense on Windows and PIC cannot be disabled on OS X."
    dict["build_target<pie>"] = "Build a position-independent executable."
    dict["build_target<prelink>"] =
      "If true the object files in the target will be prelinked, meaning that it will contain only one prelinked object file rather than the individual object files."
    dict["build_target<rust_crate_type>"] =
      "Set the specific type of rust crate to compile (when compiling rust)."
    dict["build_target<sources>"] = "Additional source files. Same as the source varargs."
    dict["build_target<soversion>"] =
      "A string or integer specifying the soversion of this shared library, such as 0. On Linux and Windows this is used to set the soversion (or equivalent) in the filename. For example, if soversion is 4, a Windows DLL will be called foo-4.dll and one of the aliases of the Linux shared library would be libfoo.so.4. If this is not specified, the first part of version is used instead (see below). For example, if version is 3.6.0 and soversion is not defined, it is set to 3."
    dict["build_target<target_type>"] = "The actual target to build"
    dict["build_target<version>"] =
      "A string specifying the version of this shared library, such as 1.1.0. On Linux and OS X, this is used to set the shared library version in the filename, such as libfoo.so.1.1.0 and libfoo.1.1.0.dylib. If this is not specified, soversion is used instead."
    dict["build_target<vs_module_defs>"] =
      "Specify a Microsoft module definition file for controlling symbol exports, etc., on platforms where that is possible (e.g. Windows)."
    dict["build_target<win_subsystem>"] =
      "Specifies the subsystem type to use on the Windows platform. Typical values include console for text mode programs and windows for gui apps. The value can also contain version specification such as windows,6.0"
    dict["executable<c_args>"] = "Compiler flags for C"
    dict["executable<cpp_args>"] = "Compiler flags for C++"
    dict["executable<cs_args>"] = "Compiler flags for C#"
    dict["executable<d_args>"] = "Compiler flags for D"
    dict["executable<fortran_args>"] = "Compiler flags for Fortran"
    dict["executable<java_args>"] = "Compiler flags for Java"
    dict["executable<objc_args>"] = "Compiler flags for Objective-C"
    dict["executable<objcpp_args>"] = "Compiler flags for Objective-C++"
    dict["executable<rust_args>"] = "Compiler flags for Rust"
    dict["executable<vala_args>"] = "Compiler flags for Vala"
    dict["executable<cython_args>"] = "Compiler flags for Cython"
    dict["executable<nasm_args>"] = "Compiler flags for NASM"
    dict["executable<masm_args>"] = "Compiler flags for MASM"
    dict["executable<c_pch>"] = "Precompiled header file to use for C"
    dict["executable<cpp_pch>"] = "Precompiled header file to use for C++"
    dict["executable<build_by_default>"] =
      "Causes, when set to true, to have this target be built by default. This means it will be built when meson compile is called without any arguments. The default value is true for all built target types."
    dict["executable<build_rpath>"] =
      "A string to add to target's rpath definition in the build dir, but which will be removed on install"
    dict["executable<d_debug>"] =
      "The D version identifiers to add during the compilation of D source files."
    dict["executable<d_import_dirs>"] =
      "List of directories to look in for string imports used in the D programming language."
    dict["executable<d_module_versions>"] =
      "List of module version identifiers set when compiling D sources."
    dict["executable<d_unittest>"] = "When set to true, the D modules are compiled in debug mode."
    dict["executable<dependencies>"] = "One or more dependency objects"
    dict["executable<export_dynamic>"] =
      "when set to true causes the target's symbols to be dynamically exported, allowing modules built using the `shared_module()` function to refer to functions, variables and other symbols defined in the executable itself. Implies the implib argument."
    dict["executable<extra_files>"] =
      "Not used for the build itself but are shown as source files in IDEs that group files by targets (such as Visual Studio)"
    dict["executable<gnu_symbol_visibility>"] =
      "Specifies how symbols should be exported: default/internal/hidden/protected/inlineshidden"
    dict["executable<gui_app>"] =
      "When set to true flags this target as a GUI application on platforms where this makes a differerence, deprecated since 0.56.0, use win_subsystem instead."
    dict["executable<implib>"] =
      "When set to true, an import library is generated for the executable (the name of the import library is based on exe_name). Alternatively, when set to a string, that gives the base name for the import library. The import library is used when the returned build target object appears in link_with: elsewhere. Only has any effect on platforms where that is meaningful (e.g. Windows). Implies the export_dynamic argument."
    dict["executable<implicit_include_directories>"] =
      "Controls whether Meson adds the current source and build directories to the include path"
    dict["executable<include_directories>"] =
      "One or more objects created with the include_directories() function, or (since 0.50.0) strings, which will be transparently expanded to include directory objects"
    dict["executable<install>"] = "When set to true, this executable should be installed."
    dict["executable<install_dir>"] =
      "Override install directory for this file. If the value is a relative path, it will be considered relative the prefix option"
    dict["executable<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["executable<install_rpath>"] =
      "A string to set the target's rpath to after install (but not before that). On Windows, this argument has no effect."
    dict["executable<install_tag>"] =
      "A string used by the `meson install --tags` command to install only a subset of the files. By default all build targets have the tag runtime except for static libraries that have the devel tag."
    dict["executable<link_args>"] =
      "Flags to use during linking. You can use UNIX-style flags here for all platforms."
    dict["executable<link_depends>"] =
      "Strings, files, or custom targets the link step depends on such as a symbol visibility map. The purpose is to automatically trigger a re-link (but not a re-compile) of the target when this file changes."
    dict["executable<link_language>"] =
      "Makes the linker for this target be for the specified language. It is generally unnecessary to set this, as Meson will detect the right linker to use in most cases. There are only two cases where this is needed. One, your main function in an executable is not in the language Meson picked, or second you want to force a library to use only one ABI."
    dict["executable<link_whole>"] =
      "Links all contents of the given static libraries whether they are used by not, equivalent to the -Wl,--whole-archive argument flag of GCC."
    dict["executable<link_with>"] =
      "One or more shared or static libraries (built by this project) that this target should be linked with. (since 0.41.0) If passed a list this list will be flattened. (since 0.51.0) The arguments can also be custom targets. In this case Meson will assume that merely adding the output file in the linker command line is sufficient to make linking work. If this is not sufficient, then the build system writer must write all other steps manually."
    dict["executable<name_prefix>"] =
      "The string that will be used as the prefix for the target output filename by overriding the default (only used for libraries). By default this is lib on all platforms and compilers, except for MSVC shared libraries where it is omitted to follow convention, and Cygwin shared libraries where it is cyg."
    dict["executable<name_suffix>"] =
      "The string that will be used as the extension for the target by overriding the default. By default on Windows this is exe for executables and on other platforms it is omitted."
    dict["executable<native>"] =
      "Controls whether the target is compiled for the build or host machines."
    dict["executable<objects>"] = "List of object files that should be linked in this target."
    dict["executable<override_options>"] =
      "takes an array of strings in the same format as project's `default_options` overriding the values of these options for this target only."
    dict["executable<pie>"] = "Build a position-independent executable."
    dict["executable<rust_crate_type>"] =
      "Set the specific type of rust crate to compile (when compiling rust)."
    dict["executable<sources>"] = "Additional source files. Same as the source varargs."
    dict["executable<win_subsystem>"] =
      "Specifies the subsystem type to use on the Windows platform. Typical values include console for text mode programs and windows for gui apps. The value can also contain version specification such as windows,6.0"
    dict["jar<c_args>"] = "Compiler flags for C"
    dict["jar<cpp_args>"] = "Compiler flags for C++"
    dict["jar<cs_args>"] = "Compiler flags for C#"
    dict["jar<d_args>"] = "Compiler flags for D"
    dict["jar<fortran_args>"] = "Compiler flags for Fortran"
    dict["jar<java_args>"] = "Compiler flags for Java"
    dict["jar<objc_args>"] = "Compiler flags for Objective-C"
    dict["jar<objcpp_args>"] = "Compiler flags for Objective-C++"
    dict["jar<rust_args>"] = "Compiler flags for Rust"
    dict["jar<vala_args>"] = "Compiler flags for Vala"
    dict["jar<cython_args>"] = "Compiler flags for Cython"
    dict["jar<nasm_args>"] = "Compiler flags for NASM"
    dict["jar<masm_args>"] = "Compiler flags for MASM"
    dict["jar<c_pch>"] = "Precompiled header file to use for C"
    dict["jar<cpp_pch>"] = "Precompiled header file to use for C++"
    dict["jar<build_by_default>"] =
      "Causes, when set to true, to have this target be built by default. This means it will be built when meson compile is called without any arguments. The default value is true for all built target types."
    dict["jar<build_rpath>"] =
      "A string to add to target's rpath definition in the build dir, but which will be removed on install"
    dict["jar<d_debug>"] =
      "The D version identifiers to add during the compilation of D source files."
    dict["jar<d_import_dirs>"] =
      "List of directories to look in for string imports used in the D programming language."
    dict["jar<d_module_versions>"] =
      "List of module version identifiers set when compiling D sources."
    dict["jar<d_unittest>"] = "When set to true, the D modules are compiled in debug mode."
    dict["jar<dependencies>"] = "One or more dependency objects"
    dict["jar<extra_files>"] =
      "Not used for the build itself but are shown as source files in IDEs that group files by targets (such as Visual Studio)"
    dict["jar<gnu_symbol_visibility>"] =
      "Specifies how symbols should be exported: default/internal/hidden/protected/inlineshidden"
    dict["jar<gui_app>"] =
      "When set to true flags this target as a GUI application on platforms where this makes a differerence, deprecated since 0.56.0, use win_subsystem instead."
    dict["jar<implicit_include_directories>"] =
      "Controls whether Meson adds the current source and build directories to the include path"
    dict["jar<include_directories>"] =
      "One or more objects created with the include_directories() function, or (since 0.50.0) strings, which will be transparently expanded to include directory objects"
    dict["jar<install>"] = "When set to true, this executable should be installed."
    dict["jar<install_dir>"] =
      "Override install directory for this file. If the value is a relative path, it will be considered relative the prefix option"
    dict["jar<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["jar<install_rpath>"] =
      "A string to set the target's rpath to after install (but not before that). On Windows, this argument has no effect."
    dict["jar<install_tag>"] =
      "A string used by the `meson install --tags` command to install only a subset of the files. By default all build targets have the tag runtime except for static libraries that have the devel tag."
    dict["jar<java_resources>"] = "Resources to be added to the jar"
    dict["jar<link_args>"] =
      "Flags to use during linking. You can use UNIX-style flags here for all platforms."
    dict["jar<link_depends>"] =
      "Strings, files, or custom targets the link step depends on such as a symbol visibility map. The purpose is to automatically trigger a re-link (but not a re-compile) of the target when this file changes."
    dict["jar<link_language>"] =
      "Makes the linker for this target be for the specified language. It is generally unnecessary to set this, as Meson will detect the right linker to use in most cases. There are only two cases where this is needed. One, your main function in an executable is not in the language Meson picked, or second you want to force a library to use only one ABI."
    dict["jar<link_whole>"] =
      "Links all contents of the given static libraries whether they are used by not, equivalent to the -Wl,--whole-archive argument flag of GCC."
    dict["jar<link_with>"] =
      "One or more shared or static libraries (built by this project) that this target should be linked with. (since 0.41.0) If passed a list this list will be flattened. (since 0.51.0) The arguments can also be custom targets. In this case Meson will assume that merely adding the output file in the linker command line is sufficient to make linking work. If this is not sufficient, then the build system writer must write all other steps manually."
    dict["jar<main_class>"] = "Main class for running the built jar"
    dict["jar<name_prefix>"] =
      "The string that will be used as the prefix for the target output filename by overriding the default (only used for libraries). By default this is lib on all platforms and compilers, except for MSVC shared libraries where it is omitted to follow convention, and Cygwin shared libraries where it is cyg."
    dict["jar<name_suffix>"] =
      "The string that will be used as the extension for the target by overriding the default. By default on Windows this is exe for executables and on other platforms it is omitted."
    dict["jar<native>"] = "Controls whether the target is compiled for the build or host machines."
    dict["jar<objects>"] = "List of object files that should be linked in this target."
    dict["jar<override_options>"] =
      "takes an array of strings in the same format as project's `default_options` overriding the values of these options for this target only."
    dict["jar<rust_crate_type>"] =
      "Set the specific type of rust crate to compile (when compiling rust)."
    dict["jar<sources>"] = "Additional source files. Same as the source varargs."
    dict["jar<soversion>"] =
      "A string or integer specifying the soversion of this shared library, such as 0. On Linux and Windows this is used to set the soversion (or equivalent) in the filename. For example, if soversion is 4, a Windows DLL will be called foo-4.dll and one of the aliases of the Linux shared library would be libfoo.so.4. If this is not specified, the first part of version is used instead (see below). For example, if version is 3.6.0 and soversion is not defined, it is set to 3."
    dict["jar<win_subsystem>"] =
      "Specifies the subsystem type to use on the Windows platform. Typical values include console for text mode programs and windows for gui apps. The value can also contain version specification such as windows,6.0"
    dict["library<c_args>"] = "Compiler flags for C"
    dict["library<cpp_args>"] = "Compiler flags for C++"
    dict["library<cs_args>"] = "Compiler flags for C#"
    dict["library<d_args>"] = "Compiler flags for D"
    dict["library<fortran_args>"] = "Compiler flags for Fortran"
    dict["library<java_args>"] = "Compiler flags for Java"
    dict["library<objc_args>"] = "Compiler flags for Objective-C"
    dict["library<objcpp_args>"] = "Compiler flags for Objective-C++"
    dict["library<rust_args>"] = "Compiler flags for Rust"
    dict["library<vala_args>"] = "Compiler flags for Vala"
    dict["library<cython_args>"] = "Compiler flags for Cython"
    dict["library<nasm_args>"] = "Compiler flags for NASM"
    dict["library<masm_args>"] = "Compiler flags for MASM"
    dict["library<c_pch>"] = "Precompiled header file to use for C"
    dict["library<cpp_pch>"] = "Precompiled header file to use for C++"
    dict["library<build_by_default>"] =
      "Causes, when set to true, to have this target be built by default. This means it will be built when meson compile is called without any arguments. The default value is true for all built target types."
    dict["library<build_rpath>"] =
      "A string to add to target's rpath definition in the build dir, but which will be removed on install"
    dict["library<d_debug>"] =
      "The D version identifiers to add during the compilation of D source files."
    dict["library<d_import_dirs>"] =
      "List of directories to look in for string imports used in the D programming language."
    dict["library<d_module_versions>"] =
      "List of module version identifiers set when compiling D sources."
    dict["library<d_unittest>"] = "When set to true, the D modules are compiled in debug mode."
    dict["library<darwin_versions>"] =
      "Defines the compatibility version and current version for the dylib on macOS. If a list is specified, it must be either zero, one, or two elements. If only one element is specified or if it's not a list, the specified value will be used for setting both compatibility version and current version. If unspecified, the soversion will be used as per the aforementioned rules."
    dict["library<dependencies>"] = "One or more dependency objects"
    dict["library<extra_files>"] =
      "Not used for the build itself but are shown as source files in IDEs that group files by targets (such as Visual Studio)"
    dict["library<gnu_symbol_visibility>"] =
      "Specifies how symbols should be exported: default/internal/hidden/protected/inlineshidden"
    dict["library<gui_app>"] =
      "When set to true flags this target as a GUI application on platforms where this makes a differerence, deprecated since 0.56.0, use win_subsystem instead."
    dict["library<implicit_include_directories>"] =
      "Controls whether Meson adds the current source and build directories to the include path"
    dict["library<include_directories>"] =
      "One or more objects created with the include_directories() function, or (since 0.50.0) strings, which will be transparently expanded to include directory objects"
    dict["library<install>"] = "When set to true, this executable should be installed."
    dict["library<install_dir>"] =
      "Override install directory for this file. If the value is a relative path, it will be considered relative the prefix option"
    dict["library<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["library<install_rpath>"] =
      "A string to set the target's rpath to after install (but not before that). On Windows, this argument has no effect."
    dict["library<install_tag>"] =
      "A string used by the `meson install --tags` command to install only a subset of the files. By default all build targets have the tag runtime except for static libraries that have the devel tag."
    dict["library<link_args>"] =
      "Flags to use during linking. You can use UNIX-style flags here for all platforms."
    dict["library<link_depends>"] =
      "Strings, files, or custom targets the link step depends on such as a symbol visibility map. The purpose is to automatically trigger a re-link (but not a re-compile) of the target when this file changes."
    dict["library<link_language>"] =
      "Makes the linker for this target be for the specified language. It is generally unnecessary to set this, as Meson will detect the right linker to use in most cases. There are only two cases where this is needed. One, your main function in an executable is not in the language Meson picked, or second you want to force a library to use only one ABI."
    dict["library<link_whole>"] =
      "Links all contents of the given static libraries whether they are used by not, equivalent to the -Wl,--whole-archive argument flag of GCC."
    dict["library<link_with>"] =
      "One or more shared or static libraries (built by this project) that this target should be linked with. (since 0.41.0) If passed a list this list will be flattened. (since 0.51.0) The arguments can also be custom targets. In this case Meson will assume that merely adding the output file in the linker command line is sufficient to make linking work. If this is not sufficient, then the build system writer must write all other steps manually."
    dict["library<name_prefix>"] =
      "The string that will be used as the prefix for the target output filename by overriding the default (only used for libraries). By default this is lib on all platforms and compilers, except for MSVC shared libraries where it is omitted to follow convention, and Cygwin shared libraries where it is cyg."
    dict["library<name_suffix>"] =
      "The string that will be used as the extension for the target by overriding the default. By default on Windows this is exe for executables and on other platforms it is omitted."
    dict["library<native>"] =
      "Controls whether the target is compiled for the build or host machines."
    dict["library<objects>"] = "List of object files that should be linked in this target."
    dict["library<pic>"] =
      "Builds the library as positional independent code (so it can be linked into a shared library). This option has no effect on Windows and OS X since it doesn't make sense on Windows and PIC cannot be disabled on OS X."
    dict["library<prelink>"] =
      "If true the object files in the target will be prelinked, meaning that it will contain only one prelinked object file rather than the individual object files."
    dict["library<override_options>"] =
      "takes an array of strings in the same format as project's `default_options` overriding the values of these options for this target only."
    dict["library<rust_crate_type>"] =
      "Set the specific type of rust crate to compile (when compiling rust)."
    dict["library<sources>"] = "Additional source files. Same as the source varargs."
    dict["library<soversion>"] =
      "A string or integer specifying the soversion of this shared library, such as 0. On Linux and Windows this is used to set the soversion (or equivalent) in the filename. For example, if soversion is 4, a Windows DLL will be called foo-4.dll and one of the aliases of the Linux shared library would be libfoo.so.4. If this is not specified, the first part of version is used instead (see below). For example, if version is 3.6.0 and soversion is not defined, it is set to 3."
    dict["library<version>"] =
      "A string specifying the version of this shared library, such as 1.1.0. On Linux and OS X, this is used to set the shared library version in the filename, such as libfoo.so.1.1.0 and libfoo.1.1.0.dylib. If this is not specified, soversion is used instead."
    dict["library<vs_module_defs>"] =
      "Specify a Microsoft module definition file for controlling symbol exports, etc., on platforms where that is possible (e.g. Windows)."
    dict["library<win_subsystem>"] =
      "Specifies the subsystem type to use on the Windows platform. Typical values include console for text mode programs and windows for gui apps. The value can also contain version specification such as windows,6.0"
    dict["shared_library<c_args>"] = "Compiler flags for C"
    dict["shared_library<cpp_args>"] = "Compiler flags for C++"
    dict["shared_library<cs_args>"] = "Compiler flags for C#"
    dict["shared_library<d_args>"] = "Compiler flags for D"
    dict["shared_library<fortran_args>"] = "Compiler flags for Fortran"
    dict["shared_library<java_args>"] = "Compiler flags for Java"
    dict["shared_library<objc_args>"] = "Compiler flags for Objective-C"
    dict["shared_library<objcpp_args>"] = "Compiler flags for Objective-C++"
    dict["shared_library<rust_args>"] = "Compiler flags for Rust"
    dict["shared_library<vala_args>"] = "Compiler flags for Vala"
    dict["shared_library<cython_args>"] = "Compiler flags for Cython"
    dict["shared_library<nasm_args>"] = "Compiler flags for NASM"
    dict["shared_library<masm_args>"] = "Compiler flags for MASM"
    dict["shared_library<c_pch>"] = "Precompiled header file to use for C"
    dict["shared_library<cpp_pch>"] = "Precompiled header file to use for C++"
    dict["shared_library<build_by_default>"] =
      "Causes, when set to true, to have this target be built by default. This means it will be built when meson compile is called without any arguments. The default value is true for all built target types."
    dict["shared_library<build_rpath>"] =
      "A string to add to target's rpath definition in the build dir, but which will be removed on install"
    dict["shared_library<d_debug>"] =
      "The D version identifiers to add during the compilation of D source files."
    dict["shared_library<d_import_dirs>"] =
      "List of directories to look in for string imports used in the D programming language."
    dict["shared_library<d_module_versions>"] =
      "List of module version identifiers set when compiling D sources."
    dict["shared_library<d_unittest>"] =
      "When set to true, the D modules are compiled in debug mode."
    dict["shared_library<darwin_versions>"] =
      "Defines the compatibility version and current version for the dylib on macOS. If a list is specified, it must be either zero, one, or two elements. If only one element is specified or if it's not a list, the specified value will be used for setting both compatibility version and current version. If unspecified, the soversion will be used as per the aforementioned rules."
    dict["shared_library<dependencies>"] = "One or more dependency objects"
    dict["shared_library<extra_files>"] =
      "Not used for the build itself but are shown as source files in IDEs that group files by targets (such as Visual Studio)"
    dict["shared_library<gnu_symbol_visibility>"] =
      "Specifies how symbols should be exported: default/internal/hidden/protected/inlineshidden"
    dict["shared_library<gui_app>"] =
      "When set to true flags this target as a GUI application on platforms where this makes a differerence, deprecated since 0.56.0, use win_subsystem instead."
    dict["shared_library<implicit_include_directories>"] =
      "Controls whether Meson adds the current source and build directories to the include path"
    dict["shared_library<include_directories>"] =
      "One or more objects created with the include_directories() function, or (since 0.50.0) strings, which will be transparently expanded to include directory objects"
    dict["shared_library<install>"] = "When set to true, this executable should be installed."
    dict["shared_library<install_dir>"] =
      "Override install directory for this file. If the value is a relative path, it will be considered relative the prefix option"
    dict["shared_library<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["shared_library<install_rpath>"] =
      "A string to set the target's rpath to after install (but not before that). On Windows, this argument has no effect."
    dict["shared_library<install_tag>"] =
      "A string used by the `meson install --tags` command to install only a subset of the files. By default all build targets have the tag runtime except for static libraries that have the devel tag."
    dict["shared_library<link_args>"] =
      "Flags to use during linking. You can use UNIX-style flags here for all platforms."
    dict["shared_library<link_depends>"] =
      "Strings, files, or custom targets the link step depends on such as a symbol visibility map. The purpose is to automatically trigger a re-link (but not a re-compile) of the target when this file changes."
    dict["shared_library<link_language>"] =
      "Makes the linker for this target be for the specified language. It is generally unnecessary to set this, as Meson will detect the right linker to use in most cases. There are only two cases where this is needed. One, your main function in an executable is not in the language Meson picked, or second you want to force a library to use only one ABI."
    dict["shared_library<link_whole>"] =
      "Links all contents of the given static libraries whether they are used by not, equivalent to the -Wl,--whole-archive argument flag of GCC."
    dict["shared_library<link_with>"] =
      "One or more shared or static libraries (built by this project) that this target should be linked with. (since 0.41.0) If passed a list this list will be flattened. (since 0.51.0) The arguments can also be custom targets. In this case Meson will assume that merely adding the output file in the linker command line is sufficient to make linking work. If this is not sufficient, then the build system writer must write all other steps manually."
    dict["shared_library<name_prefix>"] =
      "The string that will be used as the prefix for the target output filename by overriding the default (only used for libraries). By default this is lib on all platforms and compilers, except for MSVC shared libraries where it is omitted to follow convention, and Cygwin shared libraries where it is cyg."
    dict["shared_library<name_suffix>"] =
      "The string that will be used as the extension for the target by overriding the default. By default on Windows this is exe for executables and on other platforms it is omitted."
    dict["shared_library<native>"] =
      "Controls whether the target is compiled for the build or host machines."
    dict["shared_library<objects>"] = "List of object files that should be linked in this target."
    dict["shared_library<override_options>"] =
      "takes an array of strings in the same format as project's `default_options` overriding the values of these options for this target only."
    dict["shared_library<rust_crate_type>"] =
      "Set the specific type of rust crate to compile (when compiling rust)."
    dict["shared_library<sources>"] = "Additional source files. Same as the source varargs."
    dict["shared_library<soversion>"] =
      "A string or integer specifying the soversion of this shared library, such as 0. On Linux and Windows this is used to set the soversion (or equivalent) in the filename. For example, if soversion is 4, a Windows DLL will be called foo-4.dll and one of the aliases of the Linux shared library would be libfoo.so.4. If this is not specified, the first part of version is used instead (see below). For example, if version is 3.6.0 and soversion is not defined, it is set to 3."
    dict["shared_library<version>"] =
      "A string specifying the version of this shared library, such as 1.1.0. On Linux and OS X, this is used to set the shared library version in the filename, such as libfoo.so.1.1.0 and libfoo.1.1.0.dylib. If this is not specified, soversion is used instead."
    dict["shared_library<vs_module_defs>"] =
      "Specify a Microsoft module definition file for controlling symbol exports, etc., on platforms where that is possible (e.g. Windows)."
    dict["shared_library<win_subsystem>"] =
      "Specifies the subsystem type to use on the Windows platform. Typical values include console for text mode programs and windows for gui apps. The value can also contain version specification such as windows,6.0"
    dict["shared_module<c_args>"] = "Compiler flags for C"
    dict["shared_module<cpp_args>"] = "Compiler flags for C++"
    dict["shared_module<cs_args>"] = "Compiler flags for C#"
    dict["shared_module<d_args>"] = "Compiler flags for D"
    dict["shared_module<fortran_args>"] = "Compiler flags for Fortran"
    dict["shared_module<java_args>"] = "Compiler flags for Java"
    dict["shared_module<objc_args>"] = "Compiler flags for Objective-C"
    dict["shared_module<objcpp_args>"] = "Compiler flags for Objective-C++"
    dict["shared_module<rust_args>"] = "Compiler flags for Rust"
    dict["shared_module<vala_args>"] = "Compiler flags for Vala"
    dict["shared_module<cython_args>"] = "Compiler flags for Cython"
    dict["shared_module<nasm_args>"] = "Compiler flags for NASM"
    dict["shared_module<masm_args>"] = "Compiler flags for MASM"
    dict["shared_module<c_pch>"] = "Precompiled header file to use for C"
    dict["shared_module<cpp_pch>"] = "Precompiled header file to use for C++"
    dict["shared_module<build_by_default>"] =
      "Causes, when set to true, to have this target be built by default. This means it will be built when meson compile is called without any arguments. The default value is true for all built target types."
    dict["shared_module<build_rpath>"] =
      "A string to add to target's rpath definition in the build dir, but which will be removed on install"
    dict["shared_module<d_debug>"] =
      "The D version identifiers to add during the compilation of D source files."
    dict["shared_module<d_import_dirs>"] =
      "List of directories to look in for string imports used in the D programming language."
    dict["shared_module<d_module_versions>"] =
      "List of module version identifiers set when compiling D sources."
    dict["shared_module<d_unittest>"] =
      "When set to true, the D modules are compiled in debug mode."
    dict["shared_module<dependencies>"] = "One or more dependency objects"
    dict["shared_module<extra_files>"] =
      "Not used for the build itself but are shown as source files in IDEs that group files by targets (such as Visual Studio)"
    dict["shared_module<gnu_symbol_visibility>"] =
      "Specifies how symbols should be exported: default/internal/hidden/protected/inlineshidden"
    dict["shared_module<gui_app>"] =
      "When set to true flags this target as a GUI application on platforms where this makes a differerence, deprecated since 0.56.0, use win_subsystem instead."
    dict["shared_module<implicit_include_directories>"] =
      "Controls whether Meson adds the current source and build directories to the include path"
    dict["shared_module<include_directories>"] =
      "One or more objects created with the include_directories() function, or (since 0.50.0) strings, which will be transparently expanded to include directory objects"
    dict["shared_module<install>"] = "When set to true, this executable should be installed."
    dict["shared_module<install_dir>"] =
      "Override install directory for this file. If the value is a relative path, it will be considered relative the prefix option"
    dict["shared_module<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["shared_module<install_rpath>"] =
      "A string to set the target's rpath to after install (but not before that). On Windows, this argument has no effect."
    dict["shared_module<install_tag>"] =
      "A string used by the `meson install --tags` command to install only a subset of the files. By default all build targets have the tag runtime except for static libraries that have the devel tag."
    dict["shared_module<link_args>"] =
      "Flags to use during linking. You can use UNIX-style flags here for all platforms."
    dict["shared_module<link_depends>"] =
      "Strings, files, or custom targets the link step depends on such as a symbol visibility map. The purpose is to automatically trigger a re-link (but not a re-compile) of the target when this file changes."
    dict["shared_module<link_language>"] =
      "Makes the linker for this target be for the specified language. It is generally unnecessary to set this, as Meson will detect the right linker to use in most cases. There are only two cases where this is needed. One, your main function in an executable is not in the language Meson picked, or second you want to force a library to use only one ABI."
    dict["shared_module<link_whole>"] =
      "Links all contents of the given static libraries whether they are used by not, equivalent to the -Wl,--whole-archive argument flag of GCC."
    dict["shared_module<link_with>"] =
      "One or more shared or static libraries (built by this project) that this target should be linked with. (since 0.41.0) If passed a list this list will be flattened. (since 0.51.0) The arguments can also be custom targets. In this case Meson will assume that merely adding the output file in the linker command line is sufficient to make linking work. If this is not sufficient, then the build system writer must write all other steps manually."
    dict["shared_module<name_prefix>"] =
      "The string that will be used as the prefix for the target output filename by overriding the default (only used for libraries). By default this is lib on all platforms and compilers, except for MSVC shared libraries where it is omitted to follow convention, and Cygwin shared libraries where it is cyg."
    dict["shared_module<name_suffix>"] =
      "The string that will be used as the extension for the target by overriding the default. By default on Windows this is exe for executables and on other platforms it is omitted."
    dict["shared_module<native>"] =
      "Controls whether the target is compiled for the build or host machines."
    dict["shared_module<objects>"] = "List of object files that should be linked in this target."
    dict["shared_module<override_options>"] =
      "takes an array of strings in the same format as project's `default_options` overriding the values of these options for this target only."
    dict["shared_module<rust_crate_type>"] =
      "Set the specific type of rust crate to compile (when compiling rust)."
    dict["shared_module<sources>"] = "Additional source files. Same as the source varargs."
    dict["shared_module<soversion>"] =
      "A string or integer specifying the soversion of this shared library, such as 0. On Linux and Windows this is used to set the soversion (or equivalent) in the filename. For example, if soversion is 4, a Windows DLL will be called foo-4.dll and one of the aliases of the Linux shared library would be libfoo.so.4. If this is not specified, the first part of version is used instead (see below). For example, if version is 3.6.0 and soversion is not defined, it is set to 3."
    dict["shared_module<version>"] =
      "A string specifying the version of this shared library, such as 1.1.0. On Linux and OS X, this is used to set the shared library version in the filename, such as libfoo.so.1.1.0 and libfoo.1.1.0.dylib. If this is not specified, soversion is used instead."
    dict["shared_module<vs_module_defs>"] =
      "Specify a Microsoft module definition file for controlling symbol exports, etc., on platforms where that is possible (e.g. Windows)."
    dict["shared_module<win_subsystem>"] =
      "Specifies the subsystem type to use on the Windows platform. Typical values include console for text mode programs and windows for gui apps. The value can also contain version specification such as windows,6.0"
    dict["static_library<c_args>"] = "Compiler flags for C"
    dict["static_library<cpp_args>"] = "Compiler flags for C++"
    dict["static_library<cs_args>"] = "Compiler flags for C#"
    dict["static_library<d_args>"] = "Compiler flags for D"
    dict["static_library<fortran_args>"] = "Compiler flags for Fortran"
    dict["static_library<java_args>"] = "Compiler flags for Java"
    dict["static_library<objc_args>"] = "Compiler flags for Objective-C"
    dict["static_library<objcpp_args>"] = "Compiler flags for Objective-C++"
    dict["static_library<rust_args>"] = "Compiler flags for Rust"
    dict["static_library<vala_args>"] = "Compiler flags for Vala"
    dict["static_library<cython_args>"] = "Compiler flags for Cython"
    dict["static_library<nasm_args>"] = "Compiler flags for NASM"
    dict["static_library<masm_args>"] = "Compiler flags for MASM"
    dict["static_library<c_pch>"] = "Precompiled header file to use for C"
    dict["static_library<cpp_pch>"] = "Precompiled header file to use for C++"
    dict["static_library<build_by_default>"] =
      "Causes, when set to true, to have this target be built by default. This means it will be built when meson compile is called without any arguments. The default value is true for all built target types."
    dict["static_library<build_rpath>"] =
      "A string to add to target's rpath definition in the build dir, but which will be removed on install"
    dict["static_library<d_debug>"] =
      "The D version identifiers to add during the compilation of D source files."
    dict["static_library<d_import_dirs>"] =
      "List of directories to look in for string imports used in the D programming language."
    dict["static_library<d_module_versions>"] =
      "List of module version identifiers set when compiling D sources."
    dict["static_library<d_unittest>"] =
      "When set to true, the D modules are compiled in debug mode."
    dict["static_library<dependencies>"] = "One or more dependency objects"
    dict["static_library<extra_files>"] =
      "Not used for the build itself but are shown as source files in IDEs that group files by targets (such as Visual Studio)"
    dict["static_library<gnu_symbol_visibility>"] =
      "Specifies how symbols should be exported: default/internal/hidden/protected/inlineshidden"
    dict["static_library<gui_app>"] =
      "When set to true flags this target as a GUI application on platforms where this makes a differerence, deprecated since 0.56.0, use win_subsystem instead."
    dict["static_library<implicit_include_directories>"] =
      "Controls whether Meson adds the current source and build directories to the include path"
    dict["static_library<include_directories>"] =
      "One or more objects created with the include_directories() function, or (since 0.50.0) strings, which will be transparently expanded to include directory objects"
    dict["static_library<install>"] = "When set to true, this executable should be installed."
    dict["static_library<install_dir>"] =
      "Override install directory for this file. If the value is a relative path, it will be considered relative the prefix option"
    dict["static_library<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["static_library<install_rpath>"] =
      "A string to set the target's rpath to after install (but not before that). On Windows, this argument has no effect."
    dict["static_library<install_tag>"] =
      "A string used by the `meson install --tags` command to install only a subset of the files. By default all build targets have the tag runtime except for static libraries that have the devel tag."
    dict["static_library<link_args>"] =
      "Flags to use during linking. You can use UNIX-style flags here for all platforms."
    dict["static_library<link_depends>"] =
      "Strings, files, or custom targets the link step depends on such as a symbol visibility map. The purpose is to automatically trigger a re-link (but not a re-compile) of the target when this file changes."
    dict["static_library<link_language>"] =
      "Makes the linker for this target be for the specified language. It is generally unnecessary to set this, as Meson will detect the right linker to use in most cases. There are only two cases where this is needed. One, your main function in an executable is not in the language Meson picked, or second you want to force a library to use only one ABI."
    dict["static_library<link_whole>"] =
      "Links all contents of the given static libraries whether they are used by not, equivalent to the -Wl,--whole-archive argument flag of GCC."
    dict["static_library<link_with>"] =
      "One or more shared or static libraries (built by this project) that this target should be linked with. (since 0.41.0) If passed a list this list will be flattened. (since 0.51.0) The arguments can also be custom targets. In this case Meson will assume that merely adding the output file in the linker command line is sufficient to make linking work. If this is not sufficient, then the build system writer must write all other steps manually."
    dict["static_library<name_prefix>"] =
      "The string that will be used as the prefix for the target output filename by overriding the default (only used for libraries). By default this is lib on all platforms and compilers, except for MSVC shared libraries where it is omitted to follow convention, and Cygwin shared libraries where it is cyg."
    dict["static_library<name_suffix>"] =
      "The string that will be used as the extension for the target by overriding the default. By default on Windows this is exe for executables and on other platforms it is omitted."
    dict["static_library<native>"] =
      "Controls whether the target is compiled for the build or host machines."
    dict["static_library<objects>"] = "List of object files that should be linked in this target."
    dict["static_library<pic>"] =
      "Builds the library as positional independent code (so it can be linked into a shared library). This option has no effect on Windows and OS X since it doesn't make sense on Windows and PIC cannot be disabled on OS X."
    dict["static_library<prelink>"] =
      "If true the object files in the target will be prelinked, meaning that it will contain only one prelinked object file rather than the individual object files."
    dict["static_library<override_options>"] =
      "takes an array of strings in the same format as project's `default_options` overriding the values of these options for this target only."
    dict["static_library<rust_crate_type>"] =
      "Set the specific type of rust crate to compile (when compiling rust)."
    dict["static_library<sources>"] = "Additional source files. Same as the source varargs."
    dict["static_library<win_subsystem>"] =
      "Specifies the subsystem type to use on the Windows platform. Typical values include console for text mode programs and windows for gui apps. The value can also contain version specification such as windows,6.0"
    dict["add_global_arguments<language>"] =
      "Specifies the language(s) that the arguments should be"
    dict["add_global_arguments<native>"] = "A boolean specifying whether the arguments should be"
    dict["add_global_link_arguments<language>"] =
      "Specifies the language(s) that the arguments should be"
    dict["add_global_link_arguments<native>"] =
      "A boolean specifying whether the arguments should be"
    dict["add_languages<native>"] =
      "If set to `true`, the language will be used to compile for the build"
    dict["add_languages<required>"] = "If set to `true`, Meson will halt if any of the languages"
    dict["add_project_arguments<language>"] =
      "Specifies the language(s) that the arguments should be"
    dict["add_project_arguments<native>"] = "A boolean specifying whether the arguments should be"
    dict["add_project_dependencies<language>"] =
      "Specifies the language(s) that the arguments should be"
    dict["add_project_dependencies<native>"] =
      "A boolean specifying whether the arguments should be"
    dict["add_project_link_arguments<language>"] =
      "Specifies the language(s) that the arguments should be"
    dict["add_project_link_arguments<native>"] =
      "A boolean specifying whether the arguments should be"
    dict["add_test_setup<env>"] = "Environment variables to set"
    dict["add_test_setup<exclude_suites>"] =
      "A list of test suites that should be excluded when using this setup"
    dict["add_test_setup<exe_wrapper>"] = "The command or script followed by the arguments to it"
    dict["add_test_setup<gdb>"] = "If `true`, the tests are also run under `gdb`"
    dict["add_test_setup<is_default>"] = "Set whether this is the default test setup"
    dict["add_test_setup<timeout_multiplier>"] = "A number to multiply the test timeout with"
    dict["benchmark<args>"] = "Arguments to pass to the executable"
    dict["benchmark<depends>"] = "Specifies that this test depends on the specified dependencies"
    dict["benchmark<env>"] = "Environment variables to set"
    dict["benchmark<priority>"] = "Specifies the priority of a test"
    dict["benchmark<protocol>"] = "Specifies how the test results are parsed"
    dict["benchmark<should_fail>"] =
      "When true the test is considered passed if the executable fails"
    dict["benchmark<suite>"] = "Label of benchmark"
    dict["benchmark<timeout>"] = "The amount of seconds the test is allowed to run"
    dict["benchmark<verbose>"] =
      "If true, forces the test results to be logged as if `--verbose` was passed"
    dict["benchmark<workdir>"] = "Absolute path that will be used as the working directory"
    dict["configure_file<capture>"] = "Capture output of command"
    dict["configure_file<command>"] = "Command to run"
    dict["configure_file<configuration>"] = "Configuration to apply to input"
    dict["configure_file<copy>"] =
      "Will copy the input to the build directory with the new name output"
    dict["configure_file<depfile>"] =
      "A dependency file that the command can write listing all the additional files this target depends on. A change in any one of these files triggers a reconfiguration."
    dict["configure_file<encoding>"] = "Set the file encoding for the input and output file"
    dict["configure_file<format>"] = "The format of defines"
    dict["configure_file<input>"] = "The input file name"
    dict["configure_file<install>"] =
      "When true, this generated file is installed during the install step"
    dict["configure_file<install_dir>"] = "The subdirectory to install the generated file to"
    dict["configure_file<install_mode>"] = "Specify the file mode in symbolic format"
    dict["configure_file<install_tag>"] = "A string used by the `meson install --tags` command"
    dict["configure_file<output>"] = "The output file name"
    dict["configure_file<output_format>"] = "The format of the output to generate when no input"
    dict["custom_target<build_always>"] =
      "If true this target is always considered out of date and is rebuilt every time. "
    dict["custom_target<build_always_stale>"] =
      "If true the target is always considered out of date. Useful for things such as build timestamps or revision control tags. The associated command is run even if the outputs are up to date."
    dict["custom_target<build_by_default>"] =
      "Causes, when set to true, to have this target be built by default. "
    dict["custom_target<capture>"] =
      "There are some compilers that can't be told to write their output to a file but instead write it to standard output. When this argument is set to true, Meson captures stdout and writes it to the target file. Note that your command argument list may not contain @OUTPUT@ when capture mode is active."
    dict["custom_target<command>"] = "Command to run to create outputs from inputs."
    dict["custom_target<console>"] =
      "Keyword argument conflicts with capture, and is meant for commands that are resource-intensive and take a long time to finish"
    dict["custom_target<depend_files>"] =
      "Files (str, file, or the return value of configure_file() that this target depends on but are not listed in the command keyword argument. Useful for adding regen dependencies."
    dict["custom_target<depends>"] =
      "Specifies that this target depends on the specified target(s), even though it does not take any of them as a command line argument. This is meant for cases where you have a tool that e.g. does globbing internally. Usually you should just put the generated sources as inputs and Meson will set up all dependencies automatically."
    dict["custom_target<depfile>"] =
      "A dependency file that the command can write listing all the additional files this target depends on, for example a C compiler would list all the header files it included, and a change in any one of these files triggers a recompilation."
    dict["custom_target<env>"] = "Environment variables to set"
    dict["custom_target<feed>"] =
      "There are some compilers that can't be told to read their input from a file and instead read it from standard input. When this argument is set to true, Meson feeds the input file to stdin. Note that your argument list may not contain @INPUT@ when feed mode is active."
    dict["custom_target<input>"] = "List of source files."
    dict["custom_target<install>"] =
      "When true, one or more files of this target are installed during the install step"
    dict["custom_target<install_dir>"] = "The subdirectory to install the output to"
    dict["custom_target<install_mode>"] =
      "The file mode and optionally the owner/uid and group/gid."
    dict["custom_target<install_tag>"] =
      "A list of strings, one per output, used by the `meson install --tags` command to install only a subset of the files."
    dict["custom_target<output>"] = "List of output files."
    dict["declare_dependency<compile_args>"] = "Compile arguments to use."
    dict["declare_dependency<d_import_dirs>"] =
      "the directories to add to the string search path (i.e. -J switch for DMD). Must be inc objects or plain strings."
    dict["declare_dependency<d_module_versions>"] =
      "The D version identifiers to add during the compilation of D source files."
    dict["declare_dependency<dependencies>"] = "Other dependencies needed to use this dependency."
    dict["declare_dependency<include_directories>"] =
      "The directories to add to header search path, must be inc objects or (since 0.50.0) plain strings."
    dict["declare_dependency<link_args>"] = "Link arguments to use."
    dict["declare_dependency<link_whole>"] = "Libraries to link fully, same as executable()."
    dict["declare_dependency<link_with>"] = "Libraries to link against."
    dict["declare_dependency<objects>"] =
      "A list of object files, to be linked directly into the targets that use the dependency."
    dict["declare_dependency<sources>"] =
      "Sources to add to targets (or generated header files that should be built before sources including them are built)"
    dict["declare_dependency<variables>"] =
      "A dictionary of arbitrary strings, this is meant to be used in subprojects where special variables would be provided via cmake or pkg-config. since 0.56.0 it can also be a list of 'key=value' strings."
    dict["declare_dependency<version>"] =
      "The version of this dependency, such as 1.2.3. Defaults to the project version."
    dict["dependency<allow_fallback>"] =
      "Specifies whether Meson should automatically pick a fallback subproject in case the dependency is not found in the system."
    dict["dependency<default_options>"] =
      "An array of default option values that override those set in the subproject's meson_options.txt"
    dict["dependency<disabler>"] =
      "Returns a disabler() object instead of a not-found dependency if this kwarg is set to true and the dependency couldn't be found."
    dict["dependency<fallback>"] =
      "Manually specifies a subproject fallback to use in case the dependency is not found in the system."
    dict["dependency<include_type>"] =
      "An enum flag, marking how the dependency flags should be converted. Supported values are 'preserve', 'system' and 'non-system'. System dependencies may be handled differently on some platforms, for instance, using -isystem instead of -I, where possible. If include_type is set to 'preserve', no additional conversion will be performed."
    dict["dependency<language>"] =
      "Defines what language-specific dependency to find if it's available for multiple languages."
    dict["dependency<method>"] =
      "Defines the way the dependency is detected, the default is auto but can be overridden to be e.g. qmake for Qt development, and different dependencies support different values for this (though auto will work on all of them)"
    dict["dependency<native>"] =
      "If set to true, causes Meson to find the dependency on the build machine system rather than the host system (i.e. where the cross compiled binary will run on), usually only needed if you build a tool to be used during compilation."
    dict["dependency<not_found_message>"] =
      "An optional string that will be printed as a message() if the dependency was not found."
    dict["dependency<required>"] =
      "When set to false, Meson will proceed with the build even if the dependency is not found.\n\nWhen set to a feature option, the feature will control if it is searched and whether to fail if not found."
    dict["dependency<static>"] =
      "Tells the dependency provider to try to get static libraries instead of dynamic ones (note that this is not supported by all dependency backends)"
    dict["dependency<version>"] =
      "Specifies the required version, a string containing a comparison operator followed by the version string"
    dict["environment<method>"] =
      "Must be one of 'set', 'prepend', or 'append' (defaults to 'set'). Controls if initial values defined in the first positional argument are prepended, appended or replace the current value of the environment variable."
    dict["environment<separator>"] =
      "The separator to use for the initial values defined in the first positional argument. If not explicitly specified, the default path separator for the host operating system will be used, i.e. ';' for Windows and ':' for UNIX/POSIX systems."
    dict["find_program<dirs>"] = "Extra list of absolute paths where to look for program names."
    dict["find_program<disabler>"] =
      "If true and the program couldn't be found, return a disabler object instead of a not-found object."
    dict["find_program<native>"] =
      "Defines how this executable should be searched. By default it is set to false, which causes Meson to first look for the executable in the cross file (when cross building) and if it is not defined there, then from the system. If set to true, the cross file is ignored and the program is only searched from the system."
    dict["find_program<required>"] = "When true, Meson will abort if no program can be found."
    dict["find_program<version>"] = "Specifies the required version"
    dict["generator<arguments>"] =
      "A list of template strings that will be the command line arguments passed to the executable."
    dict["generator<capture>"] =
      "When this argument is set to true, Meson captures stdout of the executable and writes it to the target file specified as output."
    dict["generator<depends>"] =
      "An array of build targets that must be built before this generator can be run. This is used if you have a generator that calls a second executable that is built in this project."
    dict["generator<depfile>"] =
      "A template string pointing to a dependency file that a generator can write listing all the additional files this target depends on, for example a C compiler would list all the header files it included, and a change in any one of these files triggers a recompilation,"
    dict["generator<output>"] =
      "Template string (or list of template strings) defining how an output file name is (or multiple output names are) generated from a single source file name."
    dict["import<disabler>"] = "Returns a disabler object when not found."
    dict["import<required>"] =
      "When set to false, Meson will proceed with the build even if the module is not found. When set to a feature option, the feature will control if it is searched and whether to fail if not found."
    dict["include_directories<is_system>"] =
      "If set to true, flags the specified directories as system directories. This means that they will be used with the -isystem compiler argument rather than -I on compilers that support this flag (in practice everything except Visual Studio)."
    dict["install_data<install_dir>"] =
      "The absolute or relative path to the installation directory. If this is a relative path, it is assumed to be relative to the prefix."
    dict["install_data<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["install_data<install_tag>"] =
      "A string used by the meson install --tags command to install only a subset of the files. By default these files have no install tag which means they are not being installed when --tags argument is specified."
    dict["install_data<preserve_path>"] =
      "Disable stripping child-directories from data files when installing."
    dict["install_data<rename>"] =
      "If specified renames each source file into corresponding file from rename list."
    dict["install_data<sources>"] = "Additional files to install."
    dict["install_emptydir<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["install_emptydir<install_tag>"] =
      "A string used by the meson install --tags command to install only a subset of the files. By default these files have no install tag which means they are not being installed when --tags argument is specified."
    dict["install_headers<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["install_headers<install_dir>"] =
      "The absolute or relative path to the installation directory. If this is a relative path, it is assumed to be relative to the prefix."
    dict["install_headers<preserve_path>"] =
      "Disable stripping child-direcories from header files when installing."
    dict["install_headers<subdir>"] =
      "Install to the subdir subdirectory of the default includedir."
    dict["install_man<install_dir>"] = "Where to install to."
    dict["install_man<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["install_man<locale>"] =
      "Can be used to specify the locale into which the man page will be installed within the manual page directory tree."
    dict["install_subdir<exclude_directories>"] =
      "A list of directory names that should not be installed. Names are interpreted as paths relative to the subdir_name location."
    dict["install_subdir<exclude_files>"] =
      "A list of file names that should not be installed. Names are interpreted as paths relative to the subdir_name location."
    dict["install_subdir<install_dir>"] = "Where to install to."
    dict["install_subdir<install_mode>"] =
      "Specify the file mode in symbolic format and optionally the owner/uid and group/gid for the installed files."
    dict["install_subdir<install_tag>"] =
      "A string used by the meson install --tags command to install only a subset of the files. By default these files have no install tag which means they are not being installed when --tags argument is specified."
    dict["install_subdir<strip_directory>"] =
      "Install directory contents. If strip_directory=true only the last component of the source path is used."
    dict["install_symlink<install_dir>"] =
      "The absolute or relative path to the installation directory for the links. If this is a relative path, it is assumed to be relative to the prefix."
    dict["install_symlink<install_tag>"] =
      "A string used by the meson install --tags command to install only a subset of the files. By default these files have no install tag which means they are not being installed when --tags argument is specified."
    dict["install_symlink<pointing_to>"] =
      "Target to point the link to. Can be absolute or relative and that will be respected when creating the link."
    dict["project<default_options>"] =
      "Accecpts strings in the form key=value which have the same format as options to meson configure"
    dict["project<license>"] =
      "Takes a string or array of strings describing the license(s) the code is under."
    dict["project<meson_version>"] =
      "Takes a string describing which Meson version the project requires. Usually something like `>=0.28.0`."
    dict["project<subproject_dir>"] =
      "Specifies the top level directory name that holds Meson subprojects. This is only meant as a compatibility option for existing code bases that house their embedded source code in a custom directory. All new projects should not set this but instead use the default value. It should be noted that this keyword argument is ignored inside subprojects. There can be only one subproject dir and it is set in the top level Meson file."
    dict["project<version>"] =
      "A free form string describing the version of this project. You can access the value in your Meson build files with `meson.project_version()`. This can also be a file object pointing to a file that contains exactly one line of text."
    dict["run_command<capture>"] =
      "If true, any output generated on stdout will be captured and returned by the .stdout() method. If it is false, then .stdout() will return an empty string."
    dict["run_command<check>"] =
      "If true, the exit status code of the command will be checked, and the configuration will fail if it is non-zero. Note that the default value will be true in future releases."
    dict["run_command<env>"] = "Environment variables to set"
    dict["run_target<command>"] =
      "A list containing the command to run and the arguments to pass to it."
    dict["run_target<depends>"] =
      "A list of targets that this target depends on but which are not listed in the command array (because, for example, the script does file globbing internally)"
    dict["run_target<env>"] = "Environment variables to set"
    dict["subdir<if_found>"] = "Only enter the subdir if all `dep.found()` methods return `true`."
    dict["subproject<default_options>"] =
      "An array of default option values that override those set in the subproject's meson_options.txt"
    dict["subproject<required>"] =
      "When set to false, Meson will proceed with the build even if the dependency is not found.\n\nWhen set to a feature option, the feature will control if it is searched and whether to fail if not found.\n\nThe value of a feature option can also be passed.."
    dict["subproject<version>"] =
      "Specifies the required version, a string containing a comparison operator followed by the version string."
    dict["summary<bool_yn>"] = "Convert bool values to yes and no"
    dict["summary<list_sep>"] =
      "The separator to use when printing list values in this summary. If no separator is given, each list item will be printed on its own line."
    dict["summary<section>"] =
      "The section to put this summary information under. If the section keyword argument is omitted, key/value pairs are implicitly grouped into a section with no title."
    dict["test<args>"] = "Arguments to pass to the executable"
    dict["test<depends>"] =
      "Specifies that this test depends on the specified target(s), even though it does not take any of them as a command line argument."
    dict["test<env>"] = "Environment variables to set"
    dict["test<is_parallel>"] =
      "When false, specifies that no other test must be running at the same time as this test"
    dict["test<priority>"] =
      "Specifies the priority of a test. Tests with a higher priority are started before tests with a lower priority. The starting order of tests with identical priorities is implementation-defined. The default priority is 0, negative numbers are permitted."
    dict["test<protocol>"] =
      "Specifies how the test results are parsed and can be one of exitcode, tap, or gtest"
    dict["test<should_fail>"] =
      "When true the test is considered passed if the executable returns a non-zero return value (i.e. reports an error)"
    dict["test<suite>"] = "Label attached to this test"
    dict["test<timeout>"] =
      "The amount of seconds the test is allowed to run, a test that exceeds its time limit is always considered failed"
    dict["test<verbose>"] =
      "If true, forces the test results to be logged as if --verbose was passed to meson test."
    dict["test<workdir>"] = "Absolute path that will be used as the working directory for the test"
    dict["vcs_tag<command>"] =
      "The command to execute, see custom_target() for details on how this command must be specified."
    dict["vcs_tag<fallback>"] =
      "Version number to use when no revision control information is present, such as when building from a release tarball."
    dict["vcs_tag<input>"] = "File to modify"
    dict["vcs_tag<output>"] = "File to write the results to"
    dict["vcs_tag<replace_string>"] =
      "String in the input file to substitute with the commit information."
    dict["meson.add_devenv<method>"] =
      "Must be one of 'set', 'prepend', or 'append' (defaults to 'set'). Controls if initial values defined in the first positional argument are prepended, appended or replace the current value of the environment variable."
    dict["meson.add_devenv<separator>"] =
      "The separator to use for the initial values defined in the first positional argument. If not explicitly specified, the default path separator for the host operating system will be used, i.e. ';' for Windows and ':' for UNIX/POSIX systems."
    dict["meson.add_install_script<install_tag>"] =
      "A string used by the meson install --tags command to install only a subset of the files. By default the script has no install tag which means it is not being run when meson install --tags argument is specified."
    dict["meson.add_install_script<skip_if_destdir>"] =
      "If true the script will not be run if DESTDIR is set during installation. This is useful in the case the script updates system wide cache that is only needed when copying files into final destination."
    dict["meson.get_compiler<native>"] =
      "When set to true Meson returns the compiler for the build machine (the \"native\" compiler) and when false it returns the host compiler (the \"cross\" compiler). If native is omitted, Meson returns the \"cross\" compiler if we're currently cross-compiling and the \"native\" compiler if we're not."
    dict["meson.get_external_property<native>"] =
      "Setting `native` to `true` forces retrieving a variable from the native file, even when cross-compiling."
    dict["meson.has_external_property<native>"] =
      "Setting `native` to `true` forces retrieving a variable from the native file, even when cross-compiling."
    dict["meson.override_dependency<native>"] =
      "If set to true, the dependency is always overwritten for the build machine. Otherwise, the dependency is overwritten for the host machine, which differs from the build machine when cross-compiling."
    dict["meson.override_dependency<static>"] =
      "Used to override static and/or shared dependencies separately. If not specified it is assumed `dep_object` follows `default_library` option value."
    dict["build_tgt.extract_all_objects<recursive>"] =
      "Also return objects passed to the `objects` argument of this target."
    dict["cfg_data.set<description>"] =
      "Message / Comment that will be written in the result file. The replacement assumes a file with C syntax. If your generated file is source code in some other language, you probably don't want to add a description field because it most likely will cause a syntax error."
    dict["cfg_data.set10<description>"] =
      "Message / Comment that will be written in the result file. The replacement assumes a file with C syntax. If your generated file is source code in some other language, you probably don't want to add a description field because it most likely will cause a syntax error."
    dict["cfg_data.set_quoted<description>"] =
      "Message / Comment that will be written in the result file. The replacement assumes a file with C syntax. If your generated file is source code in some other language, you probably don't want to add a description field because it most likely will cause a syntax error."
    dict["compiler.alignment<args>"] =
      "Used to pass a list of compiler arguments. Defining include paths for headers not in the default include path via -Isome/path/to/header is generally supported, however, usually not recommended."
    dict["compiler.alignment<dependencies>"] =
      "Additionally dependencies required for compiling and / or linking."
    dict["compiler.alignment<prefix>"] =
      "Used to add `#include`s and other things that are required for the symbol to be declared. Since 1.0.0 an array is accepted too. When an array is passed, the items are concatenated together separated by a newline."
    dict["compiler.check_header<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.check_header<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.check_header<include_directories>"] = "Extra directories for header searches."
    dict["compiler.check_header<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.check_header<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["compiler.check_header<required>"] =
      "When set to true, Meson will halt if the header check fails. When set to a feature option, the feature will control if it is searched and whether to fail if not found."
    dict["compiler.compiles<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.compiles<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.compiles<include_directories>"] =
      dict["compiler.check_header<include_directories>"]
    dict["compiler.compiles<name>"] =
      "The name to use for printing a message about the compiler check. If this keyword argument is not passed, no message will be printed about the check."
    dict["compiler.compiles<no_builtin_args>"] = dict["compiler.check_header<no_builtin_args>"]
    dict["compiler.compute_int<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.compute_int<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.compute_int<guess>"] = "The value to try first."
    dict["compiler.compute_int<high>"] = "The max value."
    dict["compiler.compute_int<include_directories>"] =
      dict["compiler.check_header<include_directories>"]
    dict["compiler.compute_low<high>"] = "The min value."
    dict["compiler.compute_int<name>"] =
      "The name to use for printing a message about the compiler check. If this keyword argument is not passed, no message will be printed about the check."
    dict["compiler.compute_int<no_builtin_args>"] = dict["compiler.check_header<no_builtin_args>"]
    dict["compiler.compute_int<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["compiler.find_library<dirs>"] = "Additional directories to search in."
    dict["compiler.find_library<disabler>"] =
      "If true, this method will return a disabler on a failed check."
    dict["compiler.find_library<has_headers>"] =
      "List of headers that must be found as well. This check is equivalent to checking each header with a compiler.has_header() call."
    dict["compiler.find_library<header_args>"] =
      "When the `has_headers` kwarg is also used, this argument is passed to `compiler.has_header()` as args."
    dict["compiler.find_library<header_dependencies>"] =
      "When the `has_headers` kwarg is also used, this argument is passed to `compiler.has_header()` as dependencies."
    dict["compiler.find_library<header_include_directories>"] =
      "When the `has_headers` kwarg is also used, this argument is passed to `compiler.has_header()` as include_directories."
    dict["compiler.find_library<header_prefix>"] =
      "When the `has_headers` kwarg is also used, this argument is passed to `compiler.has_header()` as prefix."
    dict["compiler.find_library<required>"] =
      "If set true, Meson will abort with an error if the library could not be found. Otherwise, Meson will continue and the found method of the returned object will return false."
    dict["compiler.find_library<static>"] =
      "If true, the search is limited to static libraries only. Setting this value to false (the default) will search for both shared and static libraries."
    dict["compiler.get_define<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.get_define<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.get_define<include_directories>"] = "Extra directories for header searches."
    dict["compiler.get_define<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.get_define<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["compiler.get_supported_arguments<checked>"] = "off/warn/require"
    dict["compiler.has_function<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.has_function<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.has_function<include_directories>"] = "Extra directories for header searches."
    dict["compiler.has_function<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.has_function<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["compiler.has_header<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.has_header<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.has_header<include_directories>"] = "Extra directories for header searches."
    dict["compiler.has_header<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.has_header<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["compiler.has_header<required>"] =
      "When set to true, Meson will halt if the header check fails. When set to a feature option, the feature will control if it is searched and whether to fail if not found."
    dict["compiler.has_header_symbol<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.has_header_symbol<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.has_header_symbol<include_directories>"] =
      "Extra directories for header searches."
    dict["compiler.has_header_symbol<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.has_header_symbol<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["compiler.has_header_symbol<required>"] =
      "When set to true, Meson will halt if the header check fails. When set to a feature option, the feature will control if it is searched and whether to fail if not found."
    dict["compiler.has_member<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.has_member<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.has_member<include_directories>"] = "Extra directories for header searches."
    dict["compiler.has_member<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.has_member<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["compiler.has_members<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.has_members<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.has_members<include_directories>"] = "Extra directories for header searches."
    dict["compiler.has_members<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.has_members<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["compiler.has_type<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.has_type<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.has_type<include_directories>"] = "Extra directories for header searches."
    dict["compiler.has_type<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.has_type<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["compiler.links<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.links<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.links<include_directories>"] = "Extra directories for header searches."
    dict["compiler.links<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.links<name>"] =
      "The name to use for printing a message about the compiler check. If this keyword argument is not passed, no message will be printed about the check."
    dict["compiler.preprocess<compile_args>"] = "Extra flags to pass to the preprocessor"
    dict["compiler.preprocess<include_directories>"] = "Extra directories for header searches."
    dict["compiler.preprocess<output>"] =
      "Template for name of preprocessed files: @PLAINNAME@ is replaced by the source filename and @BASENAME@ is replaced by the source filename without its extension."
    dict["compiler.run<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.run<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.run<include_directories>"] = "Extra directories for header searches."
    dict["compiler.run<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.run<name>"] =
      "The name to use for printing a message about the compiler check. If this keyword argument is not passed, no message will be printed about the check."
    dict["compiler.sizeof<args>"] = dict["compiler.alignment<args>"]
    dict["compiler.sizeof<dependencies>"] = dict["compiler.alignment<dependencies>"]
    dict["compiler.sizeof<include_directories>"] = "Extra directories for header searches."
    dict["compiler.sizeof<no_builtin_args>"] =
      "When set to true, the compiler arguments controlled by built-in configuration options are not added."
    dict["compiler.sizeof<prefix>"] = dict["compiler.alignment<prefix>"]
    dict["dep.get_pkgconfig_variable<default>"] =
      "The value to return if the variable was not found. A warning is issued if the variable is not defined and this kwarg is not set."
    dict["dep.get_pkgconfig_variable<define_variable>"] =
      "You can also redefine a variable by passing a list to this kwarg that can affect the retrieved variable: `['prefix', '/'])`."
    dict["dep.get_variable<cmake>"] = "The CMake variable name"
    dict["dep.get_variable<configtool>"] = "The configtool variable name"
    dict["dep.get_variable<default_value>"] =
      "The default value to return when the variable does not exist"
    dict["dep.get_variable<internal>"] = "The internal variable name"
    dict["dep.get_variable<pkgconfig>"] = "The pkgconfig variable name"
    dict["dep.get_variable<pkgconfig_define>"] =
      "You can also redefine a variable by passing a list to this kwarg that can affect the retrieved variable: `['prefix', '/'])`."
    dict["dep.partial_dependency<compile_args>"] = "Whether to include compile_args"
    dict["dep.partial_dependency<includes>"] = "Whether to include includes"
    dict["dep.partial_dependency<link_args>"] = "Whether to include link_args"
    dict["dep.partial_dependency<links>"] = "Whether to include links"
    dict["dep.partial_dependency<sources>"] = "Whether to include sources"
    dict["env.append<separator>"] =
      "The separator to use. If not explicitly specified, the default path separator for the host operating system will be used, i.e. ';' for Windows and ':' for UNIX/POSIX systems."
    dict["env.prepend<separator>"] =
      "The separator to use. If not explicitly specified, the default path separator for the host operating system will be used, i.e. ';' for Windows and ':' for UNIX/POSIX systems."
    dict["env.set<separator>"] =
      "The separator to use. If not explicitly specified, the default path separator for the host operating system will be used, i.e. ';' for Windows and ':' for UNIX/POSIX systems."
    dict["feature.require<error_message>"] = "The error Message to print if the check fails"
    dict["generator.process<extra_args>"] =
      "If present, will be used to replace an entry @EXTRA_ARGS@ in the argument list."
    dict["generator.process<preserve_path_from>"] =
      "If given, specifies that the output files need to maintain their directory structure inside the target temporary directory."
  }
}
