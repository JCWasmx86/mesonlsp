class HotdocDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["hotdoc_module.generate_doc"] =
      "Generates documentation using hotdoc and installs it into `$prefix/share/doc/html`."
    dict["hotdoc_module.has_extensions"] =
      "Returns true if all the extensions where found, false otherwise."
  }
}
