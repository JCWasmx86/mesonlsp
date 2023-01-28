class WaylandDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["wayland_module.find_protocol"] =
      "Find an XML file for the protocol with the given state and version"
    dict["wayland_module.scan_xml"] = "Generate C code based on the given XML file"
  }
}
