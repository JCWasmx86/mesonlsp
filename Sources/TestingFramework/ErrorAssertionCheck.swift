import Foundation
import MesonAnalyze

class ErrorAssertionCheck: AssertionCheck {
  let line: Int
  let file: String
  let args: [String]
  init(file: String, line: Int, args: [String]) {
    self.line = line
    self.file = file
    self.args = [args[0].trimmingCharacters(in: NSCharacterSet.whitespaces)]
  }
  func appliesToLine(line: Int) -> Bool { return false }
  func isPostCheck() -> Bool { return true }
  func check(metadata: MesonMetadata, scope: Scope) -> AssertionResult { return .failure }
  func postCheck(metadata: MesonMetadata, scope: Scope) -> AssertionResult {
    if let diags = metadata.diagnostics[self.file] {
      for diag in diags
      where diag.startLine == self.line && diag.message == self.args[0] && diag.severity == .error {
        return .success
      }
    }
    return .failure
  }
  func formatMessage() -> String {
    return "Checking that there is an error `\(self.args[0])` on \(self.file):\(self.line)"
  }
}
