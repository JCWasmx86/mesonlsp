import IOUtils
import MesonAnalyze
import MesonAST

public class DotVisitor: ExtendedCodeVisitor {
  private var tree: MesonTree
  private var depth: Int = 0
  private var rootFile: String = ""
  private var filemappings: [String: String] = [:]
  private var moves: [String: [String]] = [:]

  public func visitSubdirCall(node: SubdirCall) {
    node.visitChildren(visitor: self)
    let newPath =
      Path(node.file.file).absolute().parent().description + Path.separator + node.subdirname
      + "\(Path.separator)meson.build"
    let subtree = self.tree.findSubdirTree(file: newPath)
    if let st = subtree {
      self.filemappings[Path(newPath).absolute().normalize().description] = node.subdirname
      let f = Path(node.file.file).absolute().normalize().description
      self.moves[f] = (self.moves[f] ?? []) + [Path(newPath).absolute().normalize().description]
      self.depth += 1
      let tmptree = self.tree
      st.ast?.visit(visitor: self)
      self.tree = tmptree
      self.depth -= 1
    }
  }

  public func visitMultiSubdirCall(node: MultiSubdirCall) {
    node.visitChildren(visitor: self)
    let base = Path(node.file.file).absolute().parent().description
    for subdirname in node.subdirnames {
      if subdirname.isEmpty { continue }
      let newPath = base + Path.separator + subdirname + "\(Path.separator)meson.build"
      let subtree = self.tree.findSubdirTree(file: newPath)
      if let st = subtree {
        self.filemappings[Path(newPath).absolute().normalize().description] = subdirname
        let f = Path(node.file.file).absolute().normalize().description
        self.moves[f] = (self.moves[f] ?? []) + [Path(newPath).absolute().normalize().description]
        self.depth += 1
        let tmptree = self.tree
        st.ast?.visit(visitor: self)
        self.tree = tmptree
        self.depth -= 1
      }
    }
  }

  public init(tree: MesonTree) { self.tree = tree }

  public func visitSourceFile(file: SourceFile) {
    if self.depth == 0 {
      let f = Path(file.file.file).absolute().normalize().description
      self.rootFile = f
      self.filemappings[f] = "/"
    }
    file.visitChildren(visitor: self)
  }

  public func visitBuildDefinition(node: BuildDefinition) { node.visitChildren(visitor: self) }

  public func visitErrorNode(node: ErrorNode) { node.visitChildren(visitor: self) }

  public func visitSelectionStatement(node: SelectionStatement) {
    node.visitChildren(visitor: self)
  }

  public func visitBreakStatement(node: BreakNode) { node.visitChildren(visitor: self) }

  public func visitContinueStatement(node: ContinueNode) { node.visitChildren(visitor: self) }

  public func visitIterationStatement(node: IterationStatement) {
    node.visitChildren(visitor: self)
  }

  public func visitAssignmentStatement(node: AssignmentStatement) {
    node.visitChildren(visitor: self)
  }

  public func visitFunctionExpression(node: FunctionExpression) {
    node.visitChildren(visitor: self)
  }

  public func visitArgumentList(node: ArgumentList) { node.visitChildren(visitor: self) }

  public func visitKeywordItem(node: KeywordItem) { node.visitChildren(visitor: self) }

  public func visitConditionalExpression(node: ConditionalExpression) {
    node.visitChildren(visitor: self)
  }

  public func visitUnaryExpression(node: UnaryExpression) { node.visitChildren(visitor: self) }

  public func visitSubscriptExpression(node: SubscriptExpression) {
    node.visitChildren(visitor: self)
  }

  public func visitMethodExpression(node: MethodExpression) { node.visitChildren(visitor: self) }

  public func visitIdExpression(node: IdExpression) { node.visitChildren(visitor: self) }

  public func visitBinaryExpression(node: BinaryExpression) { node.visitChildren(visitor: self) }

  public func visitStringLiteral(node: StringLiteral) { node.visitChildren(visitor: self) }

  public func visitArrayLiteral(node: ArrayLiteral) { node.visitChildren(visitor: self) }

  public func visitBooleanLiteral(node: BooleanLiteral) { node.visitChildren(visitor: self) }

  public func visitIntegerLiteral(node: IntegerLiteral) { node.visitChildren(visitor: self) }

  public func visitDictionaryLiteral(node: DictionaryLiteral) { node.visitChildren(visitor: self) }

  public func visitKeyValueItem(node: KeyValueItem) { node.visitChildren(visitor: self) }

  internal func generateDot() -> String {
    var str = "digraph G {\n"
    for k in self.filemappings.keys {
      let nodeName = "n\(k.hash)".replacingOccurrences(of: "-", with: "_")
      let label = "[label=\"\(self.filemappings[k]!)\"]"
      str += "  \(nodeName) \(label);\n"
    }
    for k in self.moves.keys {
      for v in self.moves[k]! {
        let kName = "n\(k.hash)".replacingOccurrences(of: "-", with: "_")
        let vName = "n\(v.hash)".replacingOccurrences(of: "-", with: "_")
        str += "  \(kName) -> \(vName);\n"
      }
    }
    str += "}\n"
    return str
  }
}
