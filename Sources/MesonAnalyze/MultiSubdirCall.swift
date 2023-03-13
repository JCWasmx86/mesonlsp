import MesonAST
import SwiftTreeSitter

public class MultiSubdirCall: FunctionExpression {
  public var subdirnames: [String]
  public var fullFiles: [String]

  init(file: MesonSourceFile, node: FunctionExpression) {
    self.subdirnames = []
    self.fullFiles = []
    super.init()
    self.file = file
    self.id = node.id
    self.location = node.location
    self.argumentList = node.argumentList
  }
  public override func visit(visitor: CodeVisitor) {
    if let ev = visitor as? ExtendedCodeVisitor {
      ev.visitMultiSubdirCall(node: self)
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

  public func heuristics() -> [String] { return MesonAnalyze.guessSetVariable(fe: self) }
}
