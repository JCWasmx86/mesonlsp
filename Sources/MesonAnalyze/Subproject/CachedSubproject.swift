import IOUtils
import MesonAST

public class CachedSubproject: Subproject {
  public let cachedPath: String

  public init(name: String, parent: Subproject?, path: String) throws {
    self.cachedPath = path
    try super.init(name: name, parent: parent)
  }

  public override func parse(
    _ ns: TypeNamespace,
    dontCache: Set<String>,
    cache: inout [String: MesonAST.Node],
    memfiles: [String: String]
  ) {
    if let children = try? Path(self.cachedPath).children(),
      let firstDirectory = children.first { $0.isDirectory }
    {
      let t = MesonTree(
        file: self.cachedPath + Path.separator + (firstDirectory.lastComponent)
          + "\(Path.separator)meson.build",
        ns: ns,
        dontCache: dontCache,
        cache: &cache,
        memfiles: memfiles
      )
      t.analyzeTypes(ns: ns, dontCache: dontCache, cache: &cache, memfiles: memfiles)
      self.tree = t
    }
  }

  public override var description: String {
    return "CachedSubproject(\(name),\(realpath),\(cachedPath))"
  }
}
