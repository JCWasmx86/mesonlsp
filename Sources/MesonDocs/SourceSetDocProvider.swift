class SourceSetDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["sourceset_module.source_set"] = "Create and return a new source set object."
    dict["sourceset.add"] =
      "Add a rule to a source set. A rule determines the conditions under which some source files or dependency objects are included in a build configuration."
    dict["sourceset.add_all"] = "Add one or more source sets to another."
    dict["sourceset.all_sources"] =
      "Returns a list of all sources that were placed in the source set using `add` (including nested source sets) and that do not have a not-found dependency. If a rule has a not-found dependency, only the `if_false` sources are included (if any)."
    dict["sourceset.all_dependencies"] =
      "Returns a list of all dependencies that were placed in the source set using `add` (including nested source sets) and that were found."
    dict["sourceset.apply"] =
      "Match the source set against a dictionary or a `configuration_data` object and return a source configuration object. A source configuration object allows you to retrieve the sources and dependencies for a specific configuration."
    dict["sourcefiles.sources"] =
      "Return the source files corresponding to the applied configuration."
    dict["sourcesfiles.dependencies"] =
      "Return the dependencies corresponding to the applied configuration."
  }
}
