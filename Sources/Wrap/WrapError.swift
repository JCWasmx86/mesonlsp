import Foundation

public enum WrapError: Error {
  case noWrapSectionFound(String)
  case unknownWrapType(String)
}
