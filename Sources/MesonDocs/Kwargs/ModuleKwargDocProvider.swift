class ModuleKwargDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["cmake_module.write_basic_package_version_file<name>"] = "The name of the package"
    dict["cmake_module.write_basic_package_version_file<version>"] =
      "The version of the generated package file"
    dict["cmake_module.write_basic_package_version_file<compatibility>"] =
      "A string indicating the kind of compatibility, the accepted values are `AnyNewerVersion`, `SameMajorVersion`, `SameMinorVersion` or `ExactVersion`. It defaults to AnyNewerVersion. Depending on your cmake installation some kind of compatibility may not be available."
    dict["cmake_module.write_basic_package_version_file<arch_independent>"] =
      "If true the generated package file will skip architecture checks. Useful for header-only libraries."
    dict["cmake_module.write_basic_package_version_file<install_dir>"] =
      "Optional installation directory, it defaults to `$(libdir)/cmake/$(name)`"
    dict["cmake_module.configure_package_config_file<name>"] = "The name of the package"
    dict["cmake_module.configure_package_config_file<input>"] =
      "The template file where that will be trated for variable substitutions contained in `configuration`"
    dict["cmake_module.configure_package_config_file<install_dir>"] =
      "Optional installation directory, it defaults to `$(libdir)/cmake/$(name)`"
    dict["cmake_module.configure_package_config_file<configuration>"] =
      "A a configuration_data object that will be used for variable substitution in the template file. Since 0.62.0 it can take a dictionary instead."
  }
}
