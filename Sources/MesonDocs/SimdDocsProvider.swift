class SimdDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["simd_module.check"] =
      "This module is designed for the use case where you have an algorithm with one or more SIMD implementation and you choose which one to use at runtime."
  }
}
