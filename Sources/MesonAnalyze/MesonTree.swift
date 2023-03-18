import Foundation
import Logging
import MesonAST
import PathKit
import SwiftTreeSitter
import Timing
import TreeSitterMeson

public final class MesonTree: Hashable {
  static let LOG = Logger(label: "MesonAnalyze::MesonTree")
  public let file: String
  public var ast: MesonAST.Node?
  public var subfiles: [MesonTree] = []
  public var scope: Scope?
  var depth: Int
  var options: OptionState?
  public let ns: TypeNamespace
  public var metadata: MesonMetadata?
  public var multiCallSubfiles: [MultiSubdirCall] = []

  public init(
    file: String,
    ns: TypeNamespace,
    depth: Int = 0,
    dontCache: Set<String>,
    cache: inout [String: MesonAST.Node],
    memfiles: [String: String] = [:]
  ) {
    self.ns = ns
    let pkp = Path(file).absolute().normalize()
    self.file = pkp.description
    self.ast = nil
    self.depth = depth
    let p = Parser()
    do { try p.setLanguage(tree_sitter_meson()) } catch { fatalError("Unable to set language") }
    if dontCache.contains(self.file) || cache[self.file] == nil {
      if memfiles[self.file] == nil && pkp.exists {
        if let text = try? NSString(
          contentsOfFile: self.file as String,
          encoding: String.Encoding.utf8.rawValue
        ) {
          let beginParsing = clock()
          let tree = p.parse(text.description)
          let endParsing = clock()
          Timing.INSTANCE.registerMeasurement(
            name: "parsing",
            begin: Int(beginParsing),
            end: Int(endParsing)
          )
          let root = tree!.rootNode
          self.ast = from_tree(file: MesonSourceFile(file: self.file), tree: root)
          let endBuildingAst = clock()
          Timing.INSTANCE.registerMeasurement(
            name: "buildingAST",
            begin: Int(endParsing),
            end: Int(endBuildingAst)
          )
        }
      } else if memfiles[self.file] != nil {
        let beginParsing = clock()
        let tree = p.parse(memfiles[self.file]!.description)
        let endParsing = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "parsing",
          begin: Int(beginParsing),
          end: Int(endParsing)
        )
        let root = tree!.rootNode
        self.ast = from_tree(
          file: MemoryFile(file: self.file, contents: memfiles[self.file]!.description),
          tree: root
        )
        let endBuildingAst = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "buildingAST",
          begin: Int(endParsing),
          end: Int(endBuildingAst)
        )
      } else {
        Self.LOG.warning("No file found: \(self.file)")
      }
      if self.ast != nil && !dontCache.contains(self.file) {
        let beginCloning = clock()
        cache[self.file] = self.ast!.clone()
        let endCloning = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "initalCloning",
          begin: Int(beginCloning),
          end: Int(endCloning)
        )
      }
    } else {
      let beginCloning = clock()
      self.ast = cache[self.file]!.clone()
      let endCloning = clock()
      Timing.INSTANCE.registerMeasurement(
        name: "cacheCloning",
        begin: Int(beginCloning),
        end: Int(endCloning)
      )
    }
    let beginPatching = clock()
    let astPatcher = ASTPatcher()
    self.ast?.visit(visitor: astPatcher)
    Timing.INSTANCE.registerMeasurement(
      name: "patchingAST",
      begin: Int(beginPatching),
      end: Int(clock())
    )
    var idx = 0
    for sd in astPatcher.subdirs {
      let sd1 = sd[1..<sd.count - 1]
      Self.LOG.debug("Subtree: \(sd1)")
      let f = Path(Path(self.file).absolute().parent().description + "/" + sd1 + "/meson.build")
        .normalize().description
      let tree = Self(
        file: f,
        ns: ns,
        depth: depth + 1,
        dontCache: dontCache,
        cache: &cache,
        memfiles: memfiles
      )
      if tree.ast != nil {
        tree.ast!.parent = astPatcher.subdirNodes[idx]
        tree.ast!.setParents()
        assert(tree.ast!.parent != nil)
      }
      self.subfiles.append(tree)
      idx += 1
    }
    for i in astPatcher.multiSubdirNodes { self.multiCallSubfiles.append(i) }

    for i in 0..<astPatcher.subdirs.count {
      let sd = astPatcher.subdirs[i]
      astPatcher.subdirNodes[i].fullFile =
        Path(Path(self.file).parent().description + "/" + sd[1..<sd.count - 1] + "/meson.build")
        .description
    }
    self.parseOptions(parser: p)
  }

  func parseOptions(parser p: Parser) {
    if self.depth != 0 { return }
    let f = Path(Path(self.file).parent().description + "/meson_options.txt").normalize()
    if !f.exists { self.options = nil }
    if let text = try? NSString(
      contentsOfFile: f.description as String,
      encoding: String.Encoding.utf8.rawValue
    ) {
      let tree = p.parse(text.description)
      let root = tree!.rootNode
      let visitor = OptionsExtractor()
      from_tree(file: MesonSourceFile(file: f.description), tree: root)!.visit(visitor: visitor)
      self.options = OptionState(options: visitor.options)
    }
  }

  public func analyzeTypes(
    ns: TypeNamespace,
    depth: Int = 0,
    dontCache: Set<String>,
    cache: inout [String: MesonAST.Node],
    memfiles: [String: String] = [:]
  ) {
    if self.ast == nil { return }
    let root = Scope()
    root.variables.updateValue([self.ns.types["meson"]!], forKey: "meson")
    root.variables.updateValue([self.ns.types["build_machine"]!], forKey: "build_machine")
    root.variables.updateValue([self.ns.types["host_machine"]!], forKey: "host_machine")
    root.variables.updateValue([self.ns.types["target_machine"]!], forKey: "target_machine")
    var options: [MesonOption] = []
    if let o = self.options { options = Array(o.opts.values) }
    let t = TypeAnalyzer(parent: root, tree: self, options: options)
    self.ast!.setParents()
    self.heuristics(ns: ns, depth: depth, dontCache: dontCache, cache: &cache, memfiles: memfiles)
    self.ast!.visit(visitor: t)
    if self.depth == 0 { self.scope = t.scope }
    self.metadata = t.metadata
    for s in self.subfiles where s.ast != nil {
      assert(s.ast!.parent is SubdirCall || s.ast!.parent is MultiSubdirCall)
    }
  }

  func heuristics(
    ns: TypeNamespace,
    depth: Int = 0,
    dontCache: Set<String>,
    cache: inout [String: MesonAST.Node],
    memfiles: [String: String] = [:]
  ) {
    var idx = 0
    var s: Set<String> = []
    for msc in self.multiCallSubfiles {
      let heuristics = msc.heuristics()
      msc.subdirnames = heuristics
      for heuristic in heuristics {
        if heuristic.isEmpty || s.contains(heuristic) { continue }
        s.insert(heuristic)
        Self.LOG.info("Found subdir call using heuristics: \(heuristic)")
        let f = Path(
          Path(self.file).absolute().parent().description + "/" + heuristic + "/meson.build"
        ).normalize().description
        let tree = Self(
          file: f,
          ns: ns,
          depth: depth + 1,
          dontCache: dontCache,
          cache: &cache,
          memfiles: memfiles
        )
        if tree.ast != nil {
          tree.ast!.parent = self.multiCallSubfiles[idx]
          tree.ast!.setParents()
          assert(tree.ast!.parent != nil)
        }
        self.subfiles.append(tree)
      }
      idx += 1
    }
    for s in self.subfiles where s.ast != nil {
      s.heuristics(ns: ns, depth: depth, dontCache: dontCache, cache: &cache, memfiles: memfiles)
    }
  }

  public func findSubdirTree(file: String) -> MesonTree? {
    let p = Path(file).normalize().absolute().description
    if p == self.file { return self }
    for t in self.subfiles where t.file == p { return t }
    for t in self.subfiles { if let m = t.findSubdirTree(file: p) { return m } }
    return nil
  }

  public func hash(into hasher: inout Hasher) { hasher.combine(self.file) }

  public static func == (lhs: MesonTree, rhs: MesonTree) -> Bool { return lhs.file == rhs.file }
}

extension String {
  subscript(_ range: CountableRange<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    let end = index(
      start,
      offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound)
    )
    return String(self[start..<end])
  }

  subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    return String(self[start...])
  }
}
