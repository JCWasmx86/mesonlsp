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
  	if visitor is ExtendedCodeVisitor {
  		(visitor as! ExtendedCodeVisitor).visitSubdirCall(node: self)
  	} else {
    	visitor.visitFunctionExpression(node: self)
    }
  }
  public override func visitChildren(visitor: CodeVisitor) {
    super.visitChildren(visitor: visitor)
  }
}
