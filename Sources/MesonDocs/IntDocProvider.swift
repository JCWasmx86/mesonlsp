class IntDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["int.is_even"] = "Returns true if the number is even."
    dict["int.is_odd"] = "Returns true if the number is odd."
    dict["int.to_string"] = "Returns the value of the number as a string."
  }
}
