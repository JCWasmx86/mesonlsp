import IOUtils
import MesonAnalyze
import MesonAST

public class CachedSubproject: Subproject {
  public let cachedPath: String

  public init(name: String, parent: Subproject?, path: String) throws {
    self.cachedPath = path
    try super.init(name: name, parent: parent)
  }

  public override func parse(_ ns: TypeNamespace) {
    var cache: [String: MesonAST.Node] = [:]
    if let children = try? Path(self.cachedPath).children(), !children.isEmpty {
      let t = MesonTree(
        file: self.cachedPath + "/" + (children[0].lastComponent) + "/meson.build",
        ns: ns,
        dontCache: [],
        cache: &cache
      )
      t.analyzeTypes(ns: ns, dontCache: [], cache: &cache)
      self.tree = t
    }
  }

  public override var description: String {
    return "CachedSubproject(\(name),\(realpath),\(cachedPath))"
  }
}
