import SwiftTreeSitter

public class SelectionStatement: Statement {
  public let file: MesonSourceFile
  public let ifCondition: Node
  public let conditions: [Node]
  public var blocks: [[Node]]

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    var idx = 0
    var tmp: [Node] = []
    var bb: [[Node]] = []
    var cs: [Node] = []
    var sI: Node?
    while idx < node.childCount {
      let c = node.child(at: idx)!
      let sv = string_value(file: file, node: c)
      if (sv == "if" || c.nodeType != nil && c.nodeType! == "if") && sI == nil {
        while string_value(file: file, node: node.child(at: idx + 1)!) == "comment" {
          idx += 1
        }
        let condition = from_tree(file: file, tree: node.child(at: idx + 1))
        sI = condition!
        idx += 1
      } else if sv == "else if" {
        bb.append(tmp)
        while string_value(file: file, node: node.child(at: idx + 1)!) == "comment" {
          idx += 1
        }
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
        if let d = ccc {
          tmp.append(d)
        }
      }
      idx += 1
    }
    bb.append(tmp)
    self.conditions = cs
    self.blocks = bb
    self.ifCondition = sI!
  }
  public func visit(visitor: CodeVisitor) {
    visitor.visitSelectionStatement(node: self)
  }

  public func visitChildren(visitor: CodeVisitor) {
    self.ifCondition.visit(visitor: visitor)
    for c in self.conditions {
      c.visit(visitor: visitor)
    }
    for b in self.blocks {
      for bb in b {
        bb.visit(visitor: visitor)
      }
    }
  }
}
