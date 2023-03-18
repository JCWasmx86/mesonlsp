import SwiftTreeSitter

public final class SelectionStatement: Statement {
  public let file: MesonSourceFile
  public let conditions: [Node]
  public var blocks: [[Node]]
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    var idx = 0
    var tmp: [Node] = []
    var bb: [[Node]] = []
    var cs: [Node] = []
    var sI: Node?
    while idx < node.childCount {
      let c = node.child(at: idx)!
      let sv = string_value(file: file, node: c)
      if (sv == "if" || c.nodeType != nil && c.nodeType! == "if") && sI == nil {
        while string_value(file: file, node: node.child(at: idx + 1)!) == "comment" { idx += 1 }
        let condition = from_tree(file: file, tree: node.child(at: idx + 1))
        sI = condition!
        idx += 1
      } else if sv == "elif" {
        bb.append(tmp)
        while string_value(file: file, node: node.child(at: idx + 1)!) == "comment" { idx += 1 }
        tmp = []
        cs.append(from_tree(file: file, tree: node.child(at: idx + 1))!)
        idx += 1
      } else if sv == "else" {
        bb.append(tmp)
        tmp = []
      } else if c.nodeType! != "comment"
        && (c.namedChildCount == 1 && c.namedChild(at: 0)!.nodeType! != "comment")
      {
        let ccc = from_tree(file: file, tree: c)
        if let d = ccc { tmp.append(d) }
      }
      idx += 1
    }
    bb.append(tmp)
    self.conditions = [sI!] + cs
    self.blocks = bb
  }
  fileprivate init(file: MesonSourceFile, location: Location, conditions: [Node], blocks: [[Node]])
  {
    self.file = file
    self.location = location
    self.conditions = conditions
    self.blocks = blocks
  }
  public func clone() -> Node {
    let location = self.location.clone()
    var arrs: [[Node]] = []
    for blk in self.blocks { arrs.append(Array(blk.map { $0.clone() })) }
    return Self(
      file: file,
      location: location,
      conditions: Array(self.conditions.map { $0.clone() }),
      blocks: blocks
    )
  }
  public func visit(visitor: CodeVisitor) { visitor.visitSelectionStatement(node: self) }

  public func visitChildren(visitor: CodeVisitor) {
    for c in self.conditions { c.visit(visitor: visitor) }
    for b in self.blocks { for bb in b { bb.visit(visitor: visitor) } }
  }

  public func setParents() {
    for c in self.conditions {
      c.parent = self
      c.setParents()
    }
    for b in self.blocks {
      for bb in b {
        bb.parent = self
        bb.setParents()
      }
    }
  }
}
