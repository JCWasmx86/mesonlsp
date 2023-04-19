public class Provides {
  public private(set) var programNames: [String]
  public private(set) var dependencyNames: [String: String]

  internal init() {
    self.programNames = []
    self.dependencyNames = [:]
  }

  internal func updateProgramNames(names: [String]) { self.programNames += names }

  internal func updateDependencyNames(names: [String]) {
    for n in names { self.dependencyNames[n] = ("") }
  }

  internal func updateDependencies(name: String, varname: String) {
    self.dependencyNames[name] = varname
  }
}
