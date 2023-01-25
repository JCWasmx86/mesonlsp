class FunctionDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["add_global_arguments"] = "Add global arguments to the compiler command line."
    dict["add_global_link_arguments"] = "Add global arguments to the linker command line."
    dict["add_languages"] = "Add programming languages used by the project."
    dict["add_project_arguments"] = "Add project specific arguments to the compiler command line."
    dict["add_project_dependencies"] =
      "Adds arguments to the compiler and linker command line, so that the given set of dependencies is included in all build products for this project."
    dict["add_project_link_arguments"] = "Adds global arguments to the linker command line."
    dict["add_test_setup"] =
      "Add a custom test setup. This setup can be used to run the tests with a custom setup, for example under Valgrind."
    dict["alias_target"] =
      "This function creates a new top-level target. Like all top-level targets, this integrates with the selected backend. For instance, with you can run it as `meson compile target_name`. This is a dummy target that does not execute any command, but ensures that all dependencies are built. Dependencies can be any build target (e.g. return value of `executable()`, `custom_target()`, etc)"
    dict["assert"] = "Abort with an error message if condition evaluates to false."
    dict["benchmark"] =
      "Creates a benchmark item that will be run when the benchmark target is run."
    dict["both_libraries"] = "Builds both a static and shared library with the given sources"
    dict["build_target"] =
      "Creates a build target whose type can be set dynamically with the `target_type` keyword argument."
    dict["configuration_data"] = "Creates an empty configuration object."
    dict["configure_file"] = "Configure file."
    dict["custom_target"] = "Create a custom top level build target"
    dict["debug"] = "Write the argument string to the meson build log."
    dict["declare_dependency"] =
      "This function returns a `dep` object that behaves like the return value of `dependency()` but is internal to the current build. The main use case for this is in subprojects. This allows a subproject to easily specify how it should be used. This makes it interchangeable with the same dependency that is provided externally by the system."
    dict["dependency"] = "Finds an external dependency."
    dict["disabler"] = "Returns a `disabler` object"
    dict["environment"] = "Returns an empty `env` object."
    dict["error"] = "Print the argument string and halts the build process."
    dict["executable"] =
      "Creates a new executable. The first argument specifies its name and the remaining positional arguments define the input files to use."
    dict["files"] =
      "This command takes the strings given to it in arguments and returns corresponding File objects that you can use as sources for build targets. The difference is that file objects remember the subdirectory they were defined in and can be used anywhere in the source tree."
    dict["find_program"] = "Find an in `PATH` etc."
    dict["generator"] =
      "This function creates a `generator` object that can be used to run custom compilation commands."
    dict["get_option"] =
      "Obtains the value of the project build option specified in the positional argument."
    dict["get_variable"] =
      "This function can be used to dynamically obtain a variable. `res = get_variable(varname, fallback)` takes the value of varname (which must be a string) and stores the variable of that name into res. If the variable does not exist, the variable fallback is stored to resinstead. If a fallback is not specified, then attempting to read a non-existing variable will cause a fatal error."
    dict["import"] = "Imports the given extension module."
    dict["include_directories"] =
      "Returns an opaque object which contains the directories (relative to the current directory) given in the positional arguments."
    dict["install_data"] =
      "Installs files from the source tree that are listed as positional arguments."
    dict["install_emptydir"] =
      "Installs a new directory entry to the location specified by the positional argument. If the directory exists and is not empty, the contents are left in place."
    dict["install_headers"] =
      "Installs the specified header files from the source tree into the system header directory."
    dict["install_man"] =
      "Installs the specified man files from the source tree into system's man directory during the install step."
    dict["install_subdir"] =
      "Installs the entire given subdirectory and its contents from the source tree to the location specified by the keyword argument `install_dir`."
    dict["install_symlink"] =
      "Installs a symbolic link to `pointing_to` target under `install_dir`."
    dict["is_disabler"] = "Returns true if a variable is a disabler and false otherwise."
    dict["is_variable"] = "Returns true if a variable of the given name exists and false otherwise."
    dict["jar"] = "Build a jar from the specified Java source files."
    dict["join_paths"] = "Joins the given strings into a file system path segment."
    dict["library"] = "Builds a library that is either static, shared or both."
    dict["message"] = "This function prints its argument to stdout."
    dict["project"] = "The first function called in each project, to initialize Meson."
    dict["range"] = "Return an opaque object that can be only be used in foreach statements."
    dict["run_command"] = "Runs the command specified in positional arguments."
    dict["run_target"] =
      "This function creates a new top-level target that runs a specified command with the specified arguments."
    dict["set_variable"] =
      "Assigns a value to the given variable name. Calling set_variable('foo', bar) is equivalent to foo = bar."
    dict["shared_library"] = "Builds a shared library with the given sources."
    dict["shared_module"] = "Builds a shared module with the given sources."
    dict["static_library"] = "Builds a static library with the given sources."
    dict["structured_sources"] =
      "Create a StructuredSource object, which is opaque and may be passed as a source to any build_target (including static_library, shared_library, executable, etc.). This is useful for languages like Rust, which use the filesystem layout to determine import names. This is only allowed in Rust targets, and cannot be mixed with non structured inputs."
    dict["subdir"] =
      "Enters the specified subdirectory and executes the meson.build file in it. Once that is done, it returns and execution continues on the line following this subdir() command. Variables defined in that meson.build file are then available for use in later parts of the current build file and in all subsequent build files executed with subdir()."
    dict["subdir_done"] =
      "Stops further interpretation of the Meson script file from the point of the invocation. All steps executed up to this point are valid and will be executed by Meson. This means that all targets defined before the call of subdir_done() will be build."
    dict["subproject"] =
      "Takes the project specified in the positional argument and brings that in the current build specification by returning a subproject object."
    dict["summary"] =
      "This function is used to summarize build configuration at the end of the build process. This function provides a way for projects (and subprojects) to report this information in a clear way."
    dict["test"] = "Defines a test to run with the test harness."
    dict["vcs_tag"] =
      "This command detects revision control commit information at build time and places it in the specified output file. This file is guaranteed to be up to date on every build."
    dict["warning"] = "This function prints its argument to stdout prefixed with WARNING:."
  }
}
