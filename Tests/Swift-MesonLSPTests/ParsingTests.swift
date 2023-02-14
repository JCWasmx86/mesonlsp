import MesonAnalyze
import MesonAST
import SwiftTreeSitter
import TreeSitterMeson
import XCTest

class ParsingTests: XCTestCase {
  func testStringLiterals() {
    let str = "x = 'Foo'\ny = f'Foo'\nz = '''\nx\n'''\nw = f'''\nfoo\n'''\n"
    let ast = parseString(s: str)
    let assignments = ((ast as! SourceFile).build_definition as! BuildDefinition).stmts
    for assignment in assignments { assert(assignment is AssignmentStatement) }
  }

  func parseString(s: String) -> MesonAST.Node {
    let p = Parser()
    try! p.setLanguage(tree_sitter_meson())
    let tree = p.parse(s)
    let root = tree!.rootNode
    let file = "/tmp/meson.build"
    let ast = from_tree(file: MemoryFile(file: file, contents: s), tree: root)!
    assert(ast is SourceFile)
    assert((ast as! SourceFile).build_definition is BuildDefinition)
    return ast
  }
}
