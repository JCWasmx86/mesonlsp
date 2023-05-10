class RustDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["rust_module.test"] =
      "This function creates a new rust unittest target from an existing rust based target, which may be a library or executable. It does this by copying the sources and arguments passed to the original target and adding the --test argument to the compilation, then creates a new test target which calls that executable, using the rust test protocol."
    dict["rust_module.bindgen"] =
      "This function wraps bindgen to simplify creating rust bindings around C libraries. "
  }
}
