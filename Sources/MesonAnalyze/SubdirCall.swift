import MesonAST
import SwiftTreeSitter

public class SubdirCall: FunctionExpression {

  init(file: MesonSourceFile, node: FunctionExpression) {
    super.init()
    self.file = file
    self.id = node.id
    self.argumentList = node.argumentList
  }
  public override func visit(visitor: CodeVisitor) {
    visitor.visitFunctionExpression(node: self)
  }
  public override func visitChildren(visitor: CodeVisitor) {
    super.visitChildren(visitor: visitor)
  }
}
