import Foundation
import IOUtils
import Logging
import MesonAST
import SwiftTreeSitter
import Timing
import TreeSitterMeson

public final class MesonTree: Hashable {
  static let LOG = Logger(label: "MesonAnalyze::MesonTree")
  static let PARSER = {
    let p = Parser()
    do { try p.setLanguage(tree_sitter_meson()) } catch { fatalError("Unable to set language") }
    return p
  }
  public let file: String
  public var ast: MesonAST.Node?
  public var subfiles: [MesonTree] = []
  public private(set) var scope: Scope?
  var depth: Int
  public private(set) var options: OptionState
  public let ns: TypeNamespace
  public var metadata: MesonMetadata?
  public var multiCallSubfiles: [MultiSubdirCall] = []
  public var visitedFiles: [String] = []
  public var foundVariables: [[String]] = []
  public var subproject: Subproject?

  public init(
    file: String,
    ns: TypeNamespace,
    depth: Int = 0,
    dontCache: Set<String>,
    cache: inout [String: MesonAST.Node],
    memfiles: [String: String],
    subproject: Subproject? = nil
  ) {
    self.ns = ns
    self.subproject = subproject
    self.options = OptionState(options: [])
    let pkp = Path(file).absolute().normalize()
    self.file = pkp.description
    self.ast = nil
    self.depth = depth
    if dontCache.contains(self.file) || cache[self.file] == nil {
      let memfile = memfiles[self.file]
      if memfile == nil && pkp.exists {
        let text = self.readFile(self.file)
        guard let text = text else { return }
        let beginParsing = clock()
        let tree = Self.PARSER().parse(text)
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
      } else if memfile != nil {
        let beginParsing = clock()
        let tree = Self.PARSER().parse(memfile!.description)
        let endParsing = clock()
        Timing.INSTANCE.registerMeasurement(
          name: "parsing",
          begin: Int(beginParsing),
          end: Int(endParsing)
        )
        let root = tree!.rootNode
        self.ast = from_tree(
          file: MemoryFile(file: self.file, contents: memfile!.description),
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
      let f = Path(
        Path(self.file).absolute().parent().description + Path.separator + sd1
          + "\(Path.separator)meson.build"
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
        Path(
          Path(self.file).parent().description + Path.separator + sd[1..<sd.count - 1]
            + "\(Path.separator)meson.build"
        ).description
    }
    self.parseOptions()
  }

  private func readFile(_ name: String) -> String? {
    #if os(Windows)
      do { return try Path(name).read().replacingOccurrences(of: "\r\n", with: "\n") } catch {
        return nil
      }
    #else
      do { return try Path(name).read() } catch { return nil }
    #endif
  }

  private func parseOptions() {
    if self.depth != 0 { return }
    var f = Path(Path(self.file).parent().description + "\(Path.separator)meson.options")
      .normalize()
    if !f.exists {
      f = Path(Path(self.file).parent().description + "\(Path.separator)meson_options.txt")
        .normalize()
      if !f.exists { return }
    }
    let text = self.readFile(f.description)
    guard let text = text else { return }
    let tree = Self.PARSER().parse(text)
    let root = tree!.rootNode
    let visitor = OptionsExtractor()
    from_tree(file: MesonSourceFile(file: f.description), tree: root)!.visit(visitor: visitor)
    self.options = OptionState(options: visitor.options)
  }

  public func analyzeTypes(
    ns: TypeNamespace,
    depth: Int = 0,
    dontCache: Set<String>,
    cache: inout [String: MesonAST.Node],
    memfiles: [String: String] = [:],
    subprojectState: SubprojectState? = nil,
    analysisOptions: AnalysisOptions = AnalysisOptions()
  ) {
    if self.ast == nil { return }
    let root = Scope()
    root.variables.updateValue([self.ns.types["meson"]!], forKey: "meson")
    root.variables.updateValue([self.ns.types["build_machine"]!], forKey: "build_machine")
    root.variables.updateValue([self.ns.types["host_machine"]!], forKey: "host_machine")
    root.variables.updateValue([self.ns.types["target_machine"]!], forKey: "target_machine")
    let options = Array(self.options.opts.values)
    let t = TypeAnalyzer(
      parent: root,
      tree: self,
      options: options,
      subprojectState: subprojectState,
      subproject: self.subproject,
      analysisOptions: analysisOptions
    )
    self.ast!.setParents()
    self.heuristics(ns: ns, depth: depth, dontCache: dontCache, cache: &cache, memfiles: memfiles)
    self.ast!.visit(visitor: t)
    if self.depth == 0 { self.scope = t.scope }
    self.metadata = t.metadata
    self.visitedFiles = t.visitedFiles
    self.foundVariables = t.foundVariables
    for s in self.subfiles where s.ast != nil {
      assert(s.ast!.parent is SubdirCall || s.ast!.parent is MultiSubdirCall)
    }
  }

  private func heuristics(
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
      if heuristics.isEmpty {
        Self.LOG.warning("Failed to find heuristics at \(msc.file.file):\(msc.location.format())")
        continue
      }
      msc.subdirnames = heuristics
      for heuristic in heuristics {
        if s.contains(heuristic) { continue }
        s.insert(heuristic)
        Self.LOG.info("Found subdir call using heuristics: \(heuristic)")
        let f = Path(
          Path(self.file).absolute().parent().description + Path.separator + heuristic
            + "\(Path.separator)meson.build"
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

  public func findSubdirTree(file: String) -> Self? {
    let p = Path(file).normalize().absolute().description
    if p == self.file { return self }
    for t in self.subfiles where t.file == p { return t as? Self }
    for t in self.subfiles { if let m = t.findSubdirTree(file: p) { return m as? Self } }
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
