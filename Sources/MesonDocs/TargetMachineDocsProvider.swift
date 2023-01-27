class TargetMachineDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["target_machine"] =
      "Provides information about the target machine -- the machine on which the compiled binary's output will run."
  }
}
