class ExternalProjectDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["external_project_module.add_project"] =
      "This function should be called at the root directory of a project using another build system. Usually in a meson.build file placed in the top directory of a subproject, but could be also in any subdir.\n\nIts first positional argument is the name of the configure script to be executed (e.g. configure), that file must be in the current directory and executable. Note that if a bootstrap script is required (e.g. autogen.sh when building from git instead of tarball), it can be done using `run_command()` before calling `add_project()` method."
    dict["external_project.dependency"] =
      "Return a dependency object that can be used to build targets against a library from the external project."

  }
}
