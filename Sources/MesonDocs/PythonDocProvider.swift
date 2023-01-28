class PythonDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["python3_module.find_python"] =
      "This is a cross platform way of finding the Python 3 executable, which may have a different name on different operating systems. Returns an `external_program` object."
    dict["python3_module.extension_module"] =
      "Creates a `shared_module` target that is named according to the naming conventions of the target platform."
    dict["python3_module.language_version"] =
      "Returns a string with the Python language version such as `3.5`."
    dict["python3_module.sysconfig_path"] =
      "Returns the Python sysconfig path without prefix, such as `lib/python3.6/site-packages`."
    dict["python_module.find_installation"] =
      "Find a python installation matching `name_or_path`. That argument is optional, if not provided then the returned python installation will be the one used to run Meson."
    dict["python_installation.path"] =
      "Works like the path method of other `ExternalProgram` objects."
    dict["python_installation.extension_module"] =
      "Create a `shared_module()` target that is named according to the naming conventions of the target platform."
    dict["python_installation.dependency"] =
      "This method accepts no positional arguments, and the same keyword arguments as the standard dependency() function. Returns a dependency"
    dict["python_installation.install_sources"] = "Install actual python sources (.py)"
    dict["python_installation.get_install_dir"] =
      "Retrieve the directory `install_sources()` will install to."
    dict["python_installation.language_version"] = "Get the major.minor python version, eg `2.7`."
    dict["python_installation.get_path"] = "Get a path as defined by the sysconfig module."
    dict["python_installation.has_path"] = "True if the given path can be retrived with `get_path`"
    dict["python_installation.get_variable"] = "Get a variable as defined by the sysconfig module."
    dict["python_installation.has_variable"] =
      "True if the given variable can be retrived with `get_variable`"
  }
}
