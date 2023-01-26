class BoolDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["bool.to_int"] = "Returns 1 if true and 0 if false"
    dict["bool.to_string"] =
      "Returns the string 'true' if the boolean is true or 'false' otherwise. You can also pass it two strings as positional arguments to specify what to return for true/false. For instance, bool.to_string('yes', 'no') will return yes if the boolean is true and no if it is false."
  }
}
