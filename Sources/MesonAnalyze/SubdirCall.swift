import MesonAST
import SwiftTreeSitter

public class SubdirCall: FunctionExpression {
  public var subdirname: String
  public var fullFile: String
  init(file: MesonSourceFile, node: FunctionExpression) {
    if let al = node.argumentList as? ArgumentList, !al.args.isEmpty,
      let sl = al.args[0] as? StringLiteral
    {
      self.subdirname = sl.contents()
    } else {
      self.subdirname = "<<>>"
    }
    self.fullFile = "/dev/null"
    super.init()
    self.file = file
    self.id = node.id
    self.location = node.location
    self.argumentList = node.argumentList
  }
  public override func visit(visitor: CodeVisitor) {
    if let ev = visitor as? ExtendedCodeVisitor {
      ev.visitSubdirCall(node: self)
    } else {
      visitor.visitFunctionExpression(node: self)
    }
  }
  public override func visitChildren(visitor: CodeVisitor) { super.visitChildren(visitor: visitor) }

  public override func setParents() {
    self.id.parent = self
    self.id.setParents()
    self.argumentList?.parent = self
    self.argumentList?.setParents()
  }
}
