import Foundation

public func parseAssertions(name: String) -> [AssertionCheck] {
  var ret: [AssertionCheck] = []
  if let content = try? String(contentsOfFile: name) {
    let lines = content.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    var idx = 0
    for line in lines {
      if line.contains("# ana:") {
        let splitted = line.components(separatedBy: "# ana:")[1]
        let args = splitted.split(separator: ":", maxSplits: 1)
        let type = args[0]
        let arguments = Array(args[1...].map { $0.description })
        switch type {
        case "var": ret.append(VariableTypeAssertionCheck(file: name, line: idx, args: arguments))
        case "warn": ret.append(WarningAssertionCheck(file: name, line: idx, args: arguments))
        case "error": ret.append(ErrorAssertionCheck(file: name, line: idx, args: arguments))
        default: _ = 1
        }
      }
      idx += 1
    }
  }
  return ret
}
