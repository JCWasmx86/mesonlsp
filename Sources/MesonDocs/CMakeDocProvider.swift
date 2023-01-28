class CMakeDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["cmake_module.subproject"] =
      "The subproject method is almost identical to the normal Meson subproject() function. The only difference is that a CMake project instead of a Meson project is configured."
    dict["cmake_module.subproject_options"] =
      "Use this method to obtain a `subproject_options` object that allows to configure a CMake subproject"
    dict["cmake_module.write_basic_package_version_file"] =
      "This method is the equivalent of the corresponding CMake function, it generates a `name` package version file."
    dict["cmake_module.configure_package_config_file"] =
      "This method is the equivalent of the corresponding CMake function, it generates a `name` package configuration file from the `input` template file."
    dict["cmake_subproject.dependency"] = "Returns a dependency object for any CMake target"
    dict["cmake_subproject.include_directories"] =
      "Returns a meson `inc` object for the specified target. Using this method is not necessary if the dependency object is used."
    dict["cmake_subproject.target"] = "Returns the raw build target"
    dict["cmake_subproject.target_type"] = "Returns the type of the target as string"
    dict["cmake_subproject.target_list"] = "Returns a list of all target names"
    dict["cmake_subproject.get_variable"] =
      "Fetches the specified variable from inside the subproject"
    dict["cmake_subproject.found"] = "Returns true if the subproject is available, otherwise false"
    dict["cmake_subprojectoptions.add_cmake_defines"] = "Add additional CMake commandline defines"
    dict["cmake_subprojectoptions.set_override_option"] = "Set specific build options for targets"
    dict["cmake_subprojectoptions.set_install"] =
      "Override whether targets should be installed or not"
    dict["cmake_subprojectoptions.append_compile_args"] =
      "Append comile flags for a specific language to the targets"
    dict["cmake_subprojectoptions.append_link_args"] = "Append linker args to the targets"
    dict["cmake_subprojectoptions.clear"] = "Resets all data in the object"
  }
}
