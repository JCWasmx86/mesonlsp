class MesonDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["meson"] = "The meson object allows you to introspect various properties of the system."
    dict["meson.add_devenv"] =
      "Add an `env` object to the list of environments that will be applied when using `meson devenv` command line."
    dict["meson.add_dist_script"] =
      "Causes the script given as argument to run during dist operation after the distribution source has been generated but before it is archived."
    dict["meson.add_install_script"] =
      "Causes the script given as an argument to be run during the install step, this script will have the environment variables `MESON_SOURCE_ROOT`, `MESON_BUILD_ROOT`, `MESON_INSTALL_PREFIX`, `MESON_INSTALL_DESTDIR_PREFIX`, and `MESONINTROSPECT` set. All positional arguments are passed as parameters."
    dict["meson.add_postconf_script"] =
      "Runs the given command after all project files have been generated. This script will have the environment variables `MESON_SOURCE_ROOT` and `MESON_BUILD_ROOT` set."
    dict["meson.backend"] = "Returns a string representing the current backend."
    dict["meson.build_root"] =
      "Returns a string with the absolute path to the build root directory."
    dict["meson.can_run_host_binaries"] =
      "Returns true if the build machine can run binaries compiled for the host."
    dict["meson.current_build_dir"] =
      "Returns a string with the absolute path to the current build directory."
    dict["meson.current_source_dir"] = "Returns a string to the current source directory."
    dict["meson.get_compiler"] = "Returns a `compiler` object describing a compiler."
    dict["meson.get_cross_property"] =
      "Returns the given property from a cross file, the optional `fallback_value` is returned if not cross compiling or the given property is not found."
    dict["meson.get_external_property"] =
      "Returns the given property from a native or cross file. The optional `fallback_value` is returned if the given property is not found."
    dict["meson.global_build_root"] =
      "Returns a string with the absolute path to the build root directory. This function will return the build root of the main project if called from a subproject, which is usually not what you want."
    dict["meson.global_source_root"] =
      "Returns a string with the absolute path to the source root directory This function will return the source root of the main project if called from a subproject, which is usually not what you want."
    dict["meson.has_exe_wrapper"] = "Use `meson.can_run_host_binaries()` instead."
    dict["meson.has_external_property"] =
      "Checks whether the given property exist in a native or cross file."
    dict["meson.install_dependency_manifest"] =
      "Installs a manifest file containing a list of all subprojects, their versions and license names to the file name given as the argument."
    dict["meson.is_cross_build"] =
      "Returns true if the current build is a cross build and false otherwise."
    dict["meson.is_subproject"] =
      "Returns true if the current project is being built as a subproject of some other project and false otherwise."
    dict["meson.is_unity"] =
      "Returns true when doing a unity build (multiple sources are combined before compilation to reduce build time) and false otherwise."
    dict["meson.override_dependency"] =
      "Specifies that whenever `dependency()` with `name` is used, Meson should not look it up on the system but instead return `dep_object`, which may either be the result of `dependency()` or `declare_dependency()`."
    dict["meson.override_find_program"] =
      "specifies that whenever `find_program()` is used to find a program named `progname`, Meson should not look it up on the system but instead return `program`, which may either be the result of `find_program()`, `configure_file()` or `executable()`."
    dict["meson.project_build_root"] =
      "Returns a string with the absolute path to the build root directory of the current (sub)project."
    dict["meson.project_license"] =
      "Returns the array of licenses specified in project() function call."
    dict["meson.project_license_files"] =
      "Returns the array of license files specified in the project() function call."
    dict["meson.project_name"] =
      "Returns the project name specified in the project() function call."
    dict["meson.project_source_root"] =
      "Returns a string with the absolute path to the source root directory of the current (sub)project."
    dict["meson.project_version"] =
      "Returns the version string specified in project() function call."
    dict["meson.source_root"] =
      "Returns a string with the absolute path to the source root directory."
    dict["meson.version"] = "Return a string with the version of Meson."
  }
}
