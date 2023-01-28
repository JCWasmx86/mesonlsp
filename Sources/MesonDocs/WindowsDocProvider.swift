class WindowsDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["windows_module.generate"] = "Compiles Windows `rc` files"
  }
}
