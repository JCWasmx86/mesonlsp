import SwiftTreeSitter

public class ArgumentList: Expression {
  public let file: MesonSourceFile
  public var args: [Node]
  public var types: [Type] = []
  public let location: Location
  public weak var parent: Node?

  init(file: MesonSourceFile, node: SwiftTreeSitter.Node) {
    self.file = file
    self.location = Location(node: node)
    var bb: [Node] = []
    node.enumerateNamedChildren(block: { bb.append(from_tree(file: file, tree: $0)!) })
    self.args = bb
  }
  public func visit(visitor: CodeVisitor) { visitor.visitArgumentList(node: self) }
  public func visitChildren(visitor: CodeVisitor) {
    for arg in self.args { arg.visit(visitor: visitor) }
  }

  public func setParents() {
    for var arg in self.args {
      arg.parent = self
      arg.setParents()
    }
  }

  public func getPositionalArg(idx: Int) -> Node? {
    var cnter = 0
    var idx1 = idx
    while idx >= 0 {
      if cnter == args.count { return nil }
      if args[cnter] is KeywordItem {
        cnter += 1
        continue
      }
      if idx1 == 0 { return args[cnter] }
      idx1 -= 1
      cnter += 1
    }
    return nil
  }

  public func getKwarg(name: String) -> Node? {
    for a in self.args {
      if let b = a as? KeywordItem {
        if (b.key is IdExpression) && (b.key as! IdExpression).id == name { return b.value }
      }
    }
    return nil
  }
}
