import Foundation
import LanguageServerProtocol
import Logging
import MesonAST

public class SemanticTokenVisitor: CodeVisitor {
  static let LOG = Logger(label: "LanguageServer::SemanticTokenVisitor")
  public var tokens: [[UInt32]] = []

  private func makeSemanticToken(_ id: Node, _ idx: Int, _ modifiers: UInt32) {
    if id.location.startLine != id.location.endLine { return }
    // Sync with MesonServer
    let types = [
      "substitute", "substitute_bounds", "variable", "function", "method", "keyword", "string",
      "number",
    ]
    if idx >= types.count { return }
    tokens.append([
      id.location.startLine, id.location.startColumn,
      id.location.endColumn - id.location.startColumn, UInt32(idx), modifiers,
    ])
  }

  public func finish() -> [UInt32] {
    tokens.sort { (token1, token2) in
      if token1[0] == token2[0] {
        return token1[1] < token2[1]
      } else {
        return token1[0] < token2[0]
      }
    }

    var ret: [UInt32] = []
    var prevLine = UInt32(0)
    var prevChar = UInt32(0)

    for token in tokens {
      let line = token[0]
      let startChar = line == prevLine ? (token[1] - prevChar) : token[1]
      let length = token[2]
      let tokenType = token[3]
      let tokenModifiers = token[4]

      let deltaLine = line - prevLine
      prevLine = line
      prevChar = token[1]

      ret.append(UInt32(deltaLine))
      ret.append(UInt32(startChar))
      ret.append(UInt32(length))
      ret.append(UInt32(tokenType))
      ret.append(UInt32(tokenModifiers))
    }
    Self.LOG.info("Found \(self.tokens.count) semantic tokens")
    return ret
  }

  public func visitSourceFile(file: SourceFile) { file.visitChildren(visitor: self) }

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
    self.makeSemanticToken(node.id, 3, UInt32(0))
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

  public func visitMethodExpression(node: MethodExpression) {
    self.makeSemanticToken(node.id, 4, UInt32(0))
    node.visitChildren(visitor: self)
  }

  public func visitIdExpression(node: IdExpression) {
    let id = node.id
    if id == "meson" || id == "host_machine" || id == "target_machine" || id == "build_machine" {
      self.makeSemanticToken(node, 2, UInt32(0b11))
    }
    node.visitChildren(visitor: self)
  }

  public func visitBinaryExpression(node: BinaryExpression) { node.visitChildren(visitor: self) }

  public func visitStringLiteral(node: StringLiteral) {
    // Clean+Dedup
    node.visitChildren(visitor: self)
    if node.isFormat {
      let pattern = #"@([a-zA-Z_][a-zA-Z_\d]*)@"#
      // swiftlint:disable force_try
      let regex = try! NSRegularExpression(pattern: pattern, options: [])
      // swiftlint:enable force_try
      let matches = regex.matches(
        in: node.contents(),
        options: [],
        range: NSRange(node.contents().startIndex..., in: node.contents())
      )
      for match in matches {
        let range = match.range
        tokens.append([
          node.location.startLine, node.location.startColumn + UInt32(range.location + 1),
          UInt32(1), UInt32(1), 0,
        ])
        tokens.append([
          node.location.startLine, node.location.startColumn + UInt32(range.location + 2),
          UInt32(range.length - 2), UInt32(2), 0,
        ])
        tokens.append([
          node.location.startLine,
          node.location.startColumn + UInt32(range.location + range.length), UInt32(1), UInt32(1),
          0,
        ])
      }
    }
    guard let parentMethodCall = node.parent as? MethodExpression else { return }
    guard let method = parentMethodCall.method else { return }
    if method.id() != "str.format" { return }
    if node.location.startLine != node.location.endLine { return }
    let pattern = #"@(\d+)@"#
    // swiftlint:disable force_try
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    // swiftlint:enable force_try
    let matches = regex.matches(
      in: node.contents(),
      options: [],
      range: NSRange(node.contents().startIndex..., in: node.contents())
    )
    for match in matches {
      let range = match.range
      tokens.append([
        node.location.startLine, node.location.startColumn + UInt32(range.location + 1), UInt32(1),
        UInt32(1), 0,
      ])
      tokens.append([
        node.location.startLine, node.location.startColumn + UInt32(range.location + 2),
        UInt32(range.length - 2), UInt32(7), 0,
      ])
      tokens.append([
        node.location.startLine, node.location.startColumn + UInt32(range.location + range.length),
        UInt32(1), UInt32(1), 0,
      ])
    }
  }

  public func visitArrayLiteral(node: ArrayLiteral) { node.visitChildren(visitor: self) }

  public func visitBooleanLiteral(node: BooleanLiteral) { node.visitChildren(visitor: self) }

  public func visitIntegerLiteral(node: IntegerLiteral) { node.visitChildren(visitor: self) }

  public func visitDictionaryLiteral(node: DictionaryLiteral) { node.visitChildren(visitor: self) }

  public func visitKeyValueItem(node: KeyValueItem) { node.visitChildren(visitor: self) }
}
