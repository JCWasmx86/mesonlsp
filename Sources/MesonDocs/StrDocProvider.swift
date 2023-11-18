class StrDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["str.contains"] = "Returns true if string contains the string specified as the argument."
    dict["str.format"] = "Strings can be built using the string formatting functionality."
    dict["str.join"] =
      "The opposite of split, for example `'.'.join(['a', 'b', 'c']` yields `a.b.c`."
    dict["str.replace"] = "Search all occurrences of `old` and and replace it with `new`"
    dict["str.split"] =
      "Splits the string at the specified character (or whitespace if not set) and returns the parts in an array."
    dict["str.startswith"] =
      "Returns true if string starts with the string specified as the argument."
    dict["str.strip"] = "Removes leading/ending spaces and newlines from the string."
    dict["str.substring"] =
      "Returns a substring specified from `start` to `end`. The method accepts negative values."
    dict["str.to_int"] = "Converts the string to an int and throws an error if it can't be"
    dict["str.to_lower"] = "Converts all characters to lower case"
    dict["str.to_upper"] = "Converts all characters to upper case"
    dict["str.splitlines"] = "Splits the string into an array of lines. Unlike `.split('\\n')`, the empty string produced an empty array, and if the string ends in a newline, `splitlines()` doesn't split on that last newline. `'\\n'`, `'\\r'` and `'\\r\\n'` are all considered newlines."
    dict["str.underscorify"] =
      "Creates a string where every non-alphabetical non-number character is replaced with _."
    dict["version_compare"] = "Does semantic version comparison."
  }
}
