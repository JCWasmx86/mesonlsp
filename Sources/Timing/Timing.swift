#if os(Windows)
  import CRT
#else
  import Glibc
#endif

public class Timing {
  public static let INSTANCE = Timing()
  static let MILLISECONDS_IN_SECOND: Double = 1000
  private var _timings: [String: TimingInformation] = [:]

  private init() {

  }

  public func registerMeasurement(name: String, diff: Double) {
    if self._timings[name] == nil { self._timings[name] = TimingInformation(name: name) }
    self._timings[name]!.append(value: diff)
  }
  public func registerMeasurement(name: String, begin: Int, end: Int) {
    let diff = Double(end - begin) / (Double(CLOCKS_PER_SEC) / Self.MILLISECONDS_IN_SECOND)
    self.registerMeasurement(name: name, diff: diff)
  }

  public func timings() -> [TimingInformation] { return Array(self._timings.values) }
}

public class TimingInformation {
  static let MAX_VALUES = 50000
  static let FALLBACK_VALUE_COUNT = 20000

  public let name: String
  internal var values: [Double] = []

  internal init(name: String) {
    self.values.reserveCapacity(Self.MAX_VALUES + 1)
    self.name = name
  }

  internal func append(value: Double) {
    self.values.append(value)
    if self.values.count > Self.MAX_VALUES {
      self.values.removeFirst(Self.MAX_VALUES - Self.FALLBACK_VALUE_COUNT)
    }
  }

  public func min() -> Double { return self.values.sorted().first! }

  public func max() -> Double { return self.values.sorted().last! }

  public func average() -> Double { return self.values.avg() }

  public func median() -> Double { return self.values.median() }

  public func stddev() -> Double { return self.values.std() }

  public func sum() -> Double { return self.values.sum() }

  public func hits() -> Int { return self.values.count }
}

// swiftlint:disable no_magic_numbers
extension Array where Element == Double {
  func median() -> Double {
    let sortedArray = sorted()
    let middle = count / 2
    if count % 2 != 0 {
      return Double(sortedArray[middle])
    } else {
      return Double(sortedArray[middle] + sortedArray[middle - 1]) / 2.0
    }
  }
  func sum() -> Double { return self.reduce(0, +) }

  func avg() -> Double { return self.sum() / Double(self.count) }

  func std() -> Double {
    let mean = self.avg()
    let v = self.reduce(0) { result, element in result + (element - mean) * (element - mean) }
    return sqrt(v / (Double(self.count) - 1))
  }
}  // swiftlint:enable no_magic_numbers
