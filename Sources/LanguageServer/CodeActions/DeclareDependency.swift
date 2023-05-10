import LanguageServerProtocol
import MesonAnalyze
import MesonAST

class DeclareDependencyCodeActionProvider: CodeActionProvider {
  // swiftlint:disable cyclomatic_complexity
  func findCodeActionsForNode(uri: DocumentURI, node: Node, tree: MesonTree) -> [CodeAction] {
    if let fexpr = node as? FunctionExpression, let f = fexpr.function, self.createsLibrary(f),
      let libname = self.extractVariablename(fexpr), let al = fexpr.argumentList as? ArgumentList
    {
      let dImportDirs = al.getKwarg(name: "d_import_dirs")
      let dModuleVersions = al.getKwarg(name: "d_module_versions")
      let dependencies = al.getKwarg(name: "dependencies")
      let includeDirectories = al.getKwarg(name: "include_directories")
      let linkArgs = al.getKwarg(name: "link_args")
      let linkWhole = al.getKwarg(name: "link_whole")
      let linkWith = al.getKwarg(name: "link_with")
      let objects = al.getKwarg(name: "objects")
      let version = al.getKwarg(name: "version")
      var dependencyName = ""
      if libname.hasSuffix("_lib") {
        dependencyName = libname.replacingOccurrences(of: "_lib", with: "_dep")
      } else if libname.hasPrefix("lib_") {
        dependencyName = libname.replacingOccurrences(of: "lib_", with: "dep_")
      } else {
        dependencyName = "dep_" + libname
      }
      if let scope = tree.scope, scope.variables[dependencyName] != nil { return [] }
      let nextLine = Int(fexpr.parent!.location.endLine + 1)
      var str = "\(dependencyName) = declare_dependency(\n"
      if dImportDirs != nil {
        str += "d_import_dirs: " + self.stringValue(node: dImportDirs!) + ",\n"
      }
      if dModuleVersions != nil {
        str += "d_module_versions: " + self.stringValue(node: dModuleVersions!) + ",\n"
      }
      if dependencies != nil {
        str += "dependencies: " + self.stringValue(node: dependencies!) + ",\n"
      }
      if includeDirectories != nil {
        str += "include_directories: " + self.stringValue(node: includeDirectories!) + ",\n"
      }
      if linkArgs != nil { str += "link_args: " + self.stringValue(node: linkArgs!) + ",\n" }
      if linkWhole != nil { str += "link_whole: " + self.stringValue(node: linkWhole!) + ",\n" }
      if linkWith != nil {
        if linkWith is IdExpression {
          str += "link_with: [\((linkWith as! IdExpression).id), \(libname)],\n"
        } else if linkWith is ArrayLiteral {
          let s = self.stringValue(node: linkWith!)[1...]
          str += "link_with: [\(libname), " + s + ",\n"
        }
      } else {
        str += "link_with: [\(libname)],\n"
      }
      if objects != nil { str += "objects: " + self.stringValue(node: objects!) + ",\n" }
      if version != nil { str += "version: " + self.stringValue(node: version!) + ",\n" }
      str += ")\n"
      let range = Position(line: nextLine, utf16index: 0)..<Position(line: nextLine, utf16index: 0)
      let textEdit = TextEdit(range: range, newText: str)
      let changes = [uri: [textEdit]]
      let edit = WorkspaceEdit(changes: changes)
      return [
        CodeAction(
          title: "Declare dependency \(dependencyName) for library",
          kind: CodeActionKind.refactor,
          edit: edit
        )
      ]
    }
    return []
  }
  // swiftlint:enable cyclomatic_complexity

  private func stringValue(node: Node) -> String {
    do {
      let string = try node.file.contents()
      let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
      if node.location.startLine == node.location.endLine {
        let line = lines[Int(node.location.startLine)]
        let sI = line.index(line.startIndex, offsetBy: Int(node.location.startColumn))
        let eI = line.index(line.startIndex, offsetBy: Int(node.location.endColumn - 1))
        return String(line[sI...eI])
      }
      let firstLine = String(lines[Int(node.location.startLine - 1)])
      let sI = firstLine.index(firstLine.startIndex, offsetBy: Int(node.location.startColumn))
      let firstLine1 = String(firstLine[sI...])
      let lastLine = lines[Int(node.location.endLine - 1)]
      let eI = lastLine.index(lastLine.startIndex, offsetBy: Int(node.location.endColumn - 1))
      let lastLine1 = String(lastLine[...eI])
      let sI1 = lines.index(lines.startIndex, offsetBy: Int(node.location.startLine))
      let eI1 = lines.index(lines.startIndex, offsetBy: Int(node.location.endLine - 1))
      let concatenated: String = Array(lines[sI1..<eI1].map { String($0) }).joined(separator: "\n")
      return String(firstLine1) + "\n" + concatenated + "\n" + String(lastLine1)
    } catch { return "Something went wrong" }
  }

  private func createsLibrary(_ f: Function) -> Bool {
    let id = f.id()
    return id == "static_library" || id == "shared_library" || id == "library"
  }

  private func extractVariablename(_ fexpr: FunctionExpression) -> String? {
    guard let p = fexpr.parent else { return nil }
    guard let assS = p as? AssignmentStatement else { return nil }
    guard let idExpr = assS.lhs as? IdExpression else { return nil }
    return idExpr.id
  }
}
