class ListDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["list.contains"] =
      "Returns true if the array contains the object given as argument, false otherwise"
    dict["list.get"] =
      "Returns the object at the given index, negative indices count from the back of the array, indexing out of bounds returns the fallback value or, if it is not specified, causes a fatal error"
    dict["list.length"] = "Returns the value of the number as a string."
  }
}
