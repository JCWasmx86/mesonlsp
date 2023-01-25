import Foundation
import MesonAST
import PathKit
import SwiftTreeSitter
import Timing
import TreeSitterMeson

public class MesonTree {
  public let file: String
  public var ast: MesonAST.Node?
  var subfiles: [MesonTree] = []
  var depth: Int
  var options: OptionState?
  public let ns: TypeNamespace
  public var metadata: MesonMetadata?

  public init(file: String, ns: TypeNamespace, depth: Int = 0, memfiles: [String: String] = [:])
    throws
  {
    self.ns = ns
    self.file = Path(file).normalize().description
    self.ast = nil
    self.depth = depth
    let p = Parser()
    try p.setLanguage(tree_sitter_meson())
    if memfiles[self.file] == nil {
      if let text = try? NSString(
        contentsOfFile: self.file as String, encoding: String.Encoding.utf8.rawValue)
      {
        let beginParsing = clock()
        let tree = p.parse(text.description)
        let endParsing = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "parsing", begin: Int(beginParsing), end: Int(endParsing))
        let root = tree!.rootNode
        self.ast = from_tree(file: MesonSourceFile(file: self.file), tree: root)
        let endBuildingAst = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "buildingAST", begin: Int(endParsing), end: Int(endBuildingAst))
      }
    } else {
      let beginParsing = clock()
      let tree = p.parse(memfiles[self.file]!.description)
      let endParsing = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "parsing", begin: Int(beginParsing), end: Int(endParsing))
      let root = tree!.rootNode
      self.ast = from_tree(
        file: MemoryFile(file: self.file, contents: memfiles[self.file]!.description), tree: root)
      let endBuildingAst = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "buildingAST", begin: Int(endParsing), end: Int(endBuildingAst))
    }
    let beginPatching = clock()
    let astPatcher = ASTPatcher()
    self.ast?.visit(visitor: astPatcher)
    Timing.INSTANCE.registerMeasurement(
      name: "patchingAST", begin: Int(beginPatching), end: Int(clock()))
    var idx = 0
    for sd in astPatcher.subdirs {
      let sd1 = sd[1..<sd.count - 1]
      print("Subtree:", sd1)
      let f = Path(Path(self.file).absolute().parent().description + "/" + sd1 + "/meson.build")
        .normalize().description
      let tree = try MesonTree(file: f, ns: ns, depth: depth + 1, memfiles: memfiles)
      tree.ast!.parent = astPatcher.subdirNodes[idx]
      tree.ast!.setParents()
      assert(tree.ast!.parent != nil)
      self.subfiles.append(tree)
      idx += 1
    }
    if self.depth != 0 { return }
    let f = Path(Path(self.file).parent().description + "/meson_options.txt").normalize()
    if !f.exists { self.options = nil }
    if let text = try? NSString(
      contentsOfFile: f.description as String, encoding: String.Encoding.utf8.rawValue)
    {
      let tree = p.parse(text.description)
      let root = tree!.rootNode
      let visitor = OptionsExtractor()
      from_tree(file: MesonSourceFile(file: f.description), tree: root)!.visit(visitor: visitor)
      self.options = OptionState(options: visitor.options)
    }
  }

  public func analyzeTypes() {
    if self.ast == nil { return }
    let root = Scope()
    root.variables.updateValue([Meson()], forKey: "meson")
    root.variables.updateValue([BuildMachine()], forKey: "build_machine")
    root.variables.updateValue([HostMachine()], forKey: "host_machine")
    root.variables.updateValue([TargetMachine()], forKey: "target_machine")
    var options: [MesonOption] = []
    if let o = self.options { options = Array(o.opts.values) }
    let t = TypeAnalyzer(parent: root, tree: self, options: options)
    self.ast!.setParents()
    self.ast!.visit(visitor: t)
    self.metadata = t.metadata
    for s in self.subfiles { assert(s.ast!.parent is SubdirCall) }
  }

  public func findSubdirTree(file: String) -> MesonTree? {
    let p = Path(file).normalize().absolute().description
    for t in self.subfiles where t.file == p { return t }
    for t in self.subfiles { if let m = t.findSubdirTree(file: p) { return m } }
    return nil
  }
}

extension String {
  subscript(_ range: CountableRange<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    let end = index(
      start, offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound))
    return String(self[start..<end])
  }

  subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    return String(self[start...])
  }
}
