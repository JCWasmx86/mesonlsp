import Foundation
import MesonAST
import PathKit
import SwiftTreeSitter
import TreeSitterMeson

public class MesonTree {
  public let file: String
  public var ast: MesonAST.Node?
  var subfiles: [MesonTree] = []
  var depth: Int

  public init(file: String, depth: Int = 0) throws {
    self.file = Path(file).normalize().description
    self.ast = nil
    self.depth = depth
    let p = Parser()
    try p.setLanguage(tree_sitter_meson())
    if let text = try? NSString(
      contentsOfFile: self.file as String, encoding: String.Encoding.utf8.rawValue)
    {
      let tree = p.parse(text.description)
      let root = tree!.rootNode
      self.ast = from_tree(file: MesonSourceFile(file: self.file), tree: root)
    }
    let astPatcher = ASTPatcher()
    self.ast?.visit(visitor: astPatcher)
    for sd in astPatcher.subdirs {
      let sd1 = sd[1..<sd.count - 1]
      print("Subtree:", sd1)
      let f = Path(Path(self.file).parent().description + "/" + sd1 + "/meson.build").normalize()
        .description
      let tree = try MesonTree(file: f, depth: depth + 1)
      self.subfiles.append(tree)
    }
  }

  public func analyzeTypes() {
		let root = Scope()
		root.variables.updateValue([Meson()], forKey: "meson")
		root.variables.updateValue([BuildMachine()], forKey: "build_machine")
		root.variables.updateValue([HostMachine()], forKey: "host_machine")
		root.variables.updateValue([TargetMachine()], forKey: "target_machine")
		let flow = TypeFlow()
		if let node = self.ast {
			node.visit(visitor: flow)
		}
  }

}

extension String {
  subscript(_ range: CountableRange<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    let end = index(
      start,
      offsetBy: min(
        self.count - range.lowerBound,
        range.upperBound - range.lowerBound))
    return String(self[start..<end])
  }

  subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
    let start = index(startIndex, offsetBy: max(0, range.lowerBound))
    return String(self[start...])
  }
}
