class BuildMachineDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["build_machine.cpu"] = "Returns a more specific CPU name, such as i686, amd64, etc."
    dict["build_machine.cpu_family"] = "Returns the CPU family name."
    dict["build_machine.endian"] =
      "Returns 'big' on big-endian systems and 'little' on little-endian systems."
    dict["build_machine.system"] = "Returns the operating system name."
  }
}
