class DlangDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["dlang_module.generate_dub_file"] =
      "Used to automatically generate Dub configuration files."
  }
}
