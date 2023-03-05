import PathKit
import Glibc
func collectStats() -> (UInt64, UInt64, UInt64) {
  let pid = getpid()
  let path = "/proc/\(pid)/maps"
  let p = Path(path)
  let contents: String = try! p.read()
  let maps = contents.split(separator: "\n")
  var heapUsage: UInt64 = 0
  var stackUsage: UInt64 = 0
  var total: UInt64 = 0
  for map in maps {
    let parts = map.split(separator: " ")
    let range = parts[0]
    let addrs = range.split(separator: "-").map({ UInt64($0, radix: 16)! })
    total += addrs[1] - addrs[0]
    if map.hasSuffix("[heap]") {
      heapUsage = addrs[1] - addrs[0]
    } else if map.hasSuffix("[stack]") {
      stackUsage = addrs[1] - addrs[0]
    }
  }
  return (heapUsage, stackUsage, total)
}

func formatWithUnits(_ bytes: UInt64) -> String {
  if bytes < 1024 {
    return "\(bytes)B"
  } else if bytes < 1024 * 1024 {
    return "\(Double(bytes) / 1024.0)KiB"
  } else if bytes < 1024 * 1024 * 1024 {
    return "\(Double(bytes) / (1024.0 * 1024.0))MiB"
  }
  return "\(Double(bytes) / (1024.0 * 1024.0 * 1024.0))GiB"
}
