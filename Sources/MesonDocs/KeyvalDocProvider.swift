class KeyvalDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["keyval_module.load"] =
      "This function loads a file consisting of a series of `key=value` lines and returns a dictionary object."
  }
}
