import MesonAnalyze

public enum AssertionResult {
  case success
  case failure
}

public protocol AssertionCheck {
  func appliesToLine(line: Int) -> Bool
  func isPostCheck() -> Bool
  func check(metadata: MesonMetadata, scope: Scope) -> AssertionResult
  func postCheck(metadata: MesonMetadata, scope: Scope) -> AssertionResult
  func formatMessage() -> String
}
