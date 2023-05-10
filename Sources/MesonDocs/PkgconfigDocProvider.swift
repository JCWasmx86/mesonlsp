class PkgconfigDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["pkgconfig_module.generate"] =
      "This function generates a pkgconfig file for the given library"
  }
}
