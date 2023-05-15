import LanguageServer
import MesonAnalyze
import MesonAST
import SwiftTreeSitter
import TreeSitterMeson
import XCTest

class SharedTests: XCTestCase {
  func testStringValueExtraction() {
    let str = "x = 'Foo'\ny = [\n  foo\n]\nz = [\n  foo]\nw =\n[\nfoo]a = [\nfoo]"
    let ast = parseString(s: str)
    let assignments = ((ast as! SourceFile).build_definition as! BuildDefinition).stmts.map {
      $0 as! AssignmentStatement
    }
    let oneline = assignments[0]
    var sValue = Shared.stringValue(node: oneline.rhs)
    XCTAssertEqual(sValue, "'Foo'")
    let simplelist = assignments[1]
    sValue = Shared.stringValue(node: simplelist.rhs)
    XCTAssertEqual(sValue, "[\n  foo\n]")
    let weirdlist = assignments[2]
    sValue = Shared.stringValue(node: weirdlist.rhs)
    XCTAssertEqual(sValue, "[\n\n  foo]")
    let weirdlist2 = assignments[3]
    sValue = Shared.stringValue(node: weirdlist2.rhs)
    XCTAssertEqual(sValue, "[\n\nfoo]")
    let weirdlist3 = assignments[4]
    sValue = Shared.stringValue(node: weirdlist3.rhs)
    XCTAssertEqual(sValue, "[\n\nfoo]")
  }

  func parseString(s: String) -> MesonAST.Node {
    let p = Parser()
    do { try p.setLanguage(tree_sitter_meson()) } catch { fatalError("Unable to set language") }
    let tree = p.parse(s)
    let root = tree!.rootNode
    let file = "/tmp/meson.build"
    let ast = from_tree(file: MemoryFile(file: file, contents: s), tree: root)!
    assert(ast is SourceFile)
    assert((ast as! SourceFile).build_definition is BuildDefinition)
    return ast
  }
}
