import Foundation
import IOUtils
import MesonAST
import Wrap

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
    memfiles: [String: String],
    analysisOptions: AnalysisOptions
  ) {
    if let fp = self.fullPath() {
      let t = MesonTree(
        file: fp + "\(Path.separator)meson.build",
        ns: ns,
        dontCache: dontCache,
        cache: &cache,
        memfiles: memfiles
      )
      t.analyzeTypes(
        ns: ns,
        dontCache: dontCache,
        cache: &cache,
        memfiles: memfiles,
        analysisOptions: analysisOptions
      )
      self.tree = t
    }
  }

  public override func update() throws {
    if let fp = self.fullPath() {
      let pullable = fp + "\(Path.separator).git_pullable"
      if !Path(pullable).exists { return }
      Self.LOG.info("Updating \(self)")
      let exitCode = try Processes.executeCommand([
        "git", "-C", Path(pullable).parent().description, "pull", "origin",
      ])
      if exitCode != 0 {
        throw SubprojectError.genericError("Updating subproject failed: \(exitCode)")
      }
      Self.LOG.info("Was successful updating \(self)")
    }
  }

  public override var description: String {
    return "CachedSubproject(\(name),\(realpath),\(cachedPath))"
  }

  private func fullPath() -> String? {
    if let children = try? Path(self.cachedPath).children(),
      let firstDirectory = children.first(where: { $0.isDirectory })
    {
      return self.cachedPath + Path.separator + firstDirectory.lastComponent
    }
    return nil
  }
}
