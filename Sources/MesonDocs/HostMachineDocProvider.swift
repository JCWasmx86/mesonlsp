class HostMachineDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["host_machine"] =
      "Provides information about the host machine -- the machine on which the compiled binary will run."
  }
}
