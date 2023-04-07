import Foundation
import MesonAnalyze
import MesonAST
import Wrap

public class WrapBasedSubproject: Subproject {
  private let wrap: Wrap
  private let destDir: String

  public init(
    wrapName: String,
    wrap: Wrap,
    packagefiles: String,
    parent: Subproject?,
    destDir: String
  ) throws {
    self.wrap = wrap
    self.destDir = destDir
    try super.init(name: wrapName, parent: parent)
    try self.wrap.setupDirectory(path: self.destDir, packagefilesPath: packagefiles)
  }

  public override func parse(_ ns: TypeNamespace) {
    var cache: [String: MesonAST.Node] = [:]
    let t = MesonTree(
      file: self.destDir + "/" + self.wrap.directoryNameAfterSetup + "/meson.build",
      ns: ns,
      dontCache: [],
      cache: &cache
    )
    t.analyzeTypes(ns: ns, dontCache: [], cache: &cache)
    self.tree = t
  }

  public override var description: String {
    return "WrapSubproject(\(name),\(realpath),\(self.wrap.directoryNameAfterSetup))"
  }
}
