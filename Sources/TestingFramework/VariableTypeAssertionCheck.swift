import Foundation
import Logging
import MesonAnalyze

class VariableTypeAssertionCheck: AssertionCheck {
  static let LOG = Logger(label: "TestFramework::VariableTypeAssertionCheck")
  let line: Int
  let file: String
  let args: [String]
  let varname: String
  let types: String
  init(file: String, line: Int, args: [String]) {
    self.line = line
    self.file = file
    self.args = [args[0].trimmingCharacters(in: NSCharacterSet.whitespaces)]
    // Args are <varname> = <types>
    self.varname = args[0].split(separator: " ")[0].description
    self.types = args[0].split(separator: " ")[2].description
  }
  func appliesToLine(line: Int) -> Bool { return false }
  func isPostCheck() -> Bool { return true }
  func check(metadata: MesonMetadata, scope: Scope) -> AssertionResult { return .failure }
  func postCheck(metadata: MesonMetadata, scope: Scope) -> AssertionResult {
    if let vts = scope.variables[self.varname] {
      let real = vts.map({ $0.toString() }).joined(separator: "|")
      if real == self.types {
        return .success
      } else {
        VariableTypeAssertionCheck.LOG.error(
          "Expected types \(self.types) for variable \(self.varname), but got: \(real)"
        )
        return .failure
      }
    }
    return .failure
  }
  func formatMessage() -> String { return "Checking that \(self.varname) has types \(self.types)" }
}
