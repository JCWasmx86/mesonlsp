import Foundation
import IOUtils
import MesonAST

public class FolderSubproject: Subproject {
  public override func parse(
    _ ns: TypeNamespace,
    dontCache: Set<String>,
    cache: inout [String: MesonAST.Node],
    memfiles: [String: String]
  ) {
    if Task.isCancelled { return }
    let t = MesonTree(
      file: self.realpath + "\(Path.separator)meson.build",
      ns: ns,
      dontCache: dontCache,
      cache: &cache,
      memfiles: memfiles
    )
    if Task.isCancelled { return }
    t.analyzeTypes(ns: ns, dontCache: dontCache, cache: &cache, memfiles: memfiles)
    if Task.isCancelled { return }
    self.tree = t
  }

  public override var description: String { return "FolderSubproject(\(name),\(realpath))" }
}
