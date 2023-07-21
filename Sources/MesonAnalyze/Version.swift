public enum VersionCompareOperator {
  case eq
  case neq
  case le
  case lt
  case ge
  case gt
}

public class Version {
  public let versionString: String
  public let cmpop: VersionCompareOperator

  private init(_ string: String, _ op: VersionCompareOperator) {
    self.versionString = string
    self.cmpop = op
  }

  public class func parseVersion(s: String) -> Version {
    var op: VersionCompareOperator = .eq
    var len = 0
    if s.hasPrefix(">=") {
      op = .ge
      len = 2
    } else if s.hasPrefix("<=") {
      op = .le
      len = 2
    } else if s.hasPrefix(">") {
      op = .gt
      len = 1
    } else if s.hasPrefix("<") {
      op = .lt
      len = 1
    } else if s.hasPrefix("==") {
      op = .eq
      len = 2
    } else if s.hasPrefix("!=") {
      op = .neq
      len = 2
    }
    let substring = s[len...]
    return Version(substring, op)
  }

  public func before(_ other: Version) -> Bool { return self.versionString < other.versionString }
}
