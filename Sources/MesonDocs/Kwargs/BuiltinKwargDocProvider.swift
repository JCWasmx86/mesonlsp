class BuiltinKwargDocProvider: DocProvider {
  // TODO: both_libraries, build_target, executable, jar, library
  // shared_library, shared_module, static_library
  func addToDict(dict: inout [String: String]) {
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
    // TODO: compiler
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
