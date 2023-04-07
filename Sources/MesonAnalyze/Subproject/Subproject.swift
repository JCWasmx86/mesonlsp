import Foundation
import IOUtils
import Logging
import MesonAST
import Wrap

public class Subproject: CustomStringConvertible {
  internal static let LOG: Logger = Logger(label: "Subproject::Subproject")

  public let name: String
  public let realpath: String
  public let parent: Subproject?
  public internal(set) var tree: MesonTree?

  internal init(name: String, parent: Subproject? = nil) throws {
    self.name = name
    self.parent = parent
    if let p = self.parent {
      self.realpath = p.realpath + "subprojects/" + name + Path.separator
    } else {
      self.realpath = "subprojects\(Path.separator)" + name + Path.separator
    }
    Self.LOG.info("Found subproject \(name) with the real path \(self.realpath)")
  }

  internal func discoverMore(state: SubprojectState) throws {

  }

  public func parse(_ ns: TypeNamespace) {
    var cache: [String: MesonAST.Node] = [:]
    let t = MesonTree(
      file: self.realpath + "\(Path.separator)meson.build",
      ns: ns,
      dontCache: [],
      cache: &cache
    )
    t.analyzeTypes(ns: ns, dontCache: [], cache: &cache)
    self.tree = t
  }

  public var description: String { return "Subproject(\(name),\(realpath))" }
}
