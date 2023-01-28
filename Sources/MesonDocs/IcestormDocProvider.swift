class IcestormDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["icestorm_module.project"] =
      "Takes a set of Verilog files and a constraint file, produces outputfiles and run targets for running timing analysis and a target for uploading the bistream to an FGPA device"
  }
}
