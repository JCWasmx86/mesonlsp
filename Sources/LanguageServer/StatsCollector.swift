#if !os(Windows)
  import CMem
  import Glibc
  import IOUtils

  func collectStats() -> [UInt64] {
    let pid = getpid()
    let path = "/proc/\(pid)/maps"
    do {
      let contents: String = try readFile(path)
      let maps = contents.split(separator: "\n")
      var heapUsage: UInt64 = 0
      var stackUsage: UInt64 = 0
      let total: UInt64 = meminfo()
      for map in maps {
        let parts = map.split(separator: " ")
        let range = parts[0]
        let addrs = range.split(separator: "-").map { UInt64($0, radix: 16)! }
        if map.hasSuffix("[heap]") {
          heapUsage = addrs[1] - addrs[0]
        } else if map.hasSuffix("[stack]") {
          stackUsage = addrs[1] - addrs[0]
        }
      }
      return [heapUsage, stackUsage, total]
    } catch { return [0, 0, 0] }
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
#endif
