class JavaDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["java_module.generate_native_header"] =
      "This function will generate a header file for use in Java native module development by reading the supplied Java file for native method declarations."
    dict["java_module.generate_native_headers"] =
      "This function will generate native header files for use in Java native module development by reading the supplied Java files for native method declarations."
    dict["java_module.native_headers"] =
      "This function will generate native header files for use in Java native module development by reading the supplied Java files for native method declarations."
  }
}
