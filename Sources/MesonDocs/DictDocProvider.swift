class DictDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["dict.get"] =
      "Returns the value for the key given as first argument if it is present in the dictionary, or the optional fallback value given as the second argument. If a single argument was given and the key was not found, causes a fatal error"
    dict["dict.has_key"] =
      "Returns true if the dictionary contains the key given as argument, false otherwise."
    dict["dict.keys"] = "Returns an array of keys in the dictionary."
  }
}
