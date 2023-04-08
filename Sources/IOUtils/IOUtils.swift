// PathKit - Effortless path operations
// Copyright (c) 2014, Kyle Fuller
// All rights reserved.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// Copied from here: https://raw.githubusercontent.com/kylef/PathKit/master/Sources/PathKit.swift
// swiftlint:disable legacy_objc_type
import Foundation

/// Represents a filesystem path.
public struct Path {
  /// The character used by the OS to separate two path elements
  #if !os(Windows)
    public static let separator = "/"
  #else
    public static let separator = "\\"
  #endif

  /// The underlying string representation
  internal let path: String

  internal static let fileManager = FileManager.default

  // MARK: Init

  /// Create a Path from a given String
  public init(_ path: String) { self.path = path }

  /// Create a Path by joining multiple path components together
  public init<S: Collection>(components: S) where S.Iterator.Element == String {
    let path: String
    if components.isEmpty {
      path = "."
    } else if components.first == Self.separator && components.count > 1 {
      let p = components.joined(separator: Self.separator)
      path = String(p[p.index(after: p.startIndex)...])
    } else {
      path = components.joined(separator: Self.separator)
    }
    self.init(path)
  }
}

// MARK: StringLiteralConvertible

extension Path: ExpressibleByStringLiteral {
  public init(stringLiteral value: StringLiteralType) { self.init(value) }
}

// MARK: CustomStringConvertible

extension Path: CustomStringConvertible { public var description: String { return self.path } }

// MARK: Conversion

extension Path { public var url: URL { return URL(fileURLWithPath: path) } }
// MARK: Path Info

extension Path {
  /// Test whether a path is absolute.
  ///
  /// - Returns: `true` iff the path begins with a slash
  ///
  public var isAbsolute: Bool {
    #if !os(Windows)
      return path.hasPrefix(Path.separator)
    #else
      if self.path.count < 3 { return false }
      return self.path[0].isLetter && self.path[1] == ":" && self.path[2] == "\\"
    #endif
  }

  /// Concatenates relative paths to the current directory and derives the normalized path
  ///
  /// - Returns: the absolute path in the actual filesystem
  ///
  public func absolute() -> Path {
    #if os(Windows)
      return Path(URL(fileURLWithPath: self.path).absoluteURL.standardizedFileURL.path)
    #else
      if isAbsolute { return normalize() }

      let expandedPath = Path(NSString(string: self.path).expandingTildeInPath)
      if expandedPath.isAbsolute { return expandedPath.normalize() }
      return (Path.current + self).normalize()
    #endif
  }

  /// Normalizes the path, this cleans up redundant ".." and ".", double slashes
  /// and resolves "~".
  ///
  /// - Returns: a new path made by removing extraneous path components from the underlying String
  ///   representation.
  ///
  public func normalize() -> Path {
    let r = Path(NSString(string: self.path).standardizingPath)
    return r
  }
}

// MARK: Path Components

extension Path {
  /// The last path component
  ///
  /// - Returns: the last path component
  ///
  public var lastComponent: String { return NSString(string: path).lastPathComponent }

  /// The last path component without file extension
  ///
  /// - Note: This returns "." for ".." on Linux, and ".." on Apple platforms.
  ///
  /// - Returns: the last path component without file extension
  ///
  public var lastComponentWithoutExtension: String {
    return NSString(string: lastComponent).deletingPathExtension
  }
}

// MARK: File Info

extension Path {
  /// Test whether a file or directory exists at a specified path
  ///
  /// - Returns: `false` iff the path doesn't exist on disk or its existence could not be
  ///   determined
  ///
  public var exists: Bool { return Path.fileManager.fileExists(atPath: self.path) }

  /// Test whether a path is a directory.
  ///
  /// - Returns: `true` if the path is a directory or a symbolic link that points to a directory;
  ///   `false` if the path is not a directory or the path doesn't exist on disk or its existence
  ///   could not be determined
  ///
  public var isDirectory: Bool {
    var directory = ObjCBool(false)
    guard Path.fileManager.fileExists(atPath: normalize().path, isDirectory: &directory) else {
      return false
    }
    return directory.boolValue
  }

  /// Test whether a path is a regular file.
  ///
  /// - Returns: `true` if the path is neither a directory nor a symbolic link that points to a
  ///   directory; `false` if the path is a directory or a symbolic link that points to a
  ///   directory or the path doesn't exist on disk or its existence
  ///   could not be determined
  ///
  public var isFile: Bool {
    var directory = ObjCBool(false)
    guard Path.fileManager.fileExists(atPath: normalize().path, isDirectory: &directory) else {
      return false
    }
    return !directory.boolValue
  }
}

// MARK: Current Directory

extension Path {
  /// The current working directory of the process
  ///
  /// - Returns: the current working directory of the process
  ///
  public static var current: Path {
    get { return self.init(Path.fileManager.currentDirectoryPath) }
    set { _ = Path.fileManager.changeCurrentDirectoryPath(newValue.description) }
  }
}

// MARK: Contents

extension Path {
  /// Reads the file.
  ///
  /// - Returns: the contents of the file at the specified path.
  ///
  public func read() throws -> Data {
    return try Data(contentsOf: self.url, options: NSData.ReadingOptions(rawValue: 0))
  }

  /// Reads the file contents and encoded its bytes to string applying the given encoding.
  ///
  /// - Parameter encoding: the encoding which should be used to decode the data.
  ///   (by default: `NSUTF8StringEncoding`)
  ///
  /// - Returns: the contents of the file at the specified path as string.
  ///
  public func read(_ encoding: String.Encoding = String.Encoding.utf8) throws -> String {
    return try NSString(contentsOfFile: path, encoding: encoding.rawValue).substring(from: 0)
      as String
  }

  /// Write a file.
  ///
  /// - Note: Works atomically: the data is written to a backup file, and then — assuming no
  ///   errors occur — the backup file is renamed to the name specified by path.
  ///
  /// - Parameter data: the contents to write to file.
  ///
  public func write(_ data: Data) throws { try data.write(to: normalize().url, options: .atomic) }
}

// MARK: Traversing

extension Path {
  /// Get the parent directory
  ///
  /// - Returns: the normalized path of the parent directory
  ///
  public func parent() -> Path {
    #if !os(Windows)
      return self + ".."
    #else
      return Path(URL(fileURLWithPath: self.path).deletingLastPathComponent().path).normalize()
    #endif
  }

  /// Performs a shallow enumeration in a directory
  ///
  /// - Returns: paths to all files, directories and symbolic links contained in the directory
  ///
  public func children() throws -> [Path] {
    return try Path.fileManager.contentsOfDirectory(atPath: path).map { self + Path($0) }
  }
}

// MARK: Equatable

extension Path: Equatable {}

/// Determines if two paths are identical
///
/// - Note: The comparison is string-based. Be aware that two different paths (foo.txt and
///   ./foo.txt) can refer to the same file.
///
public func == (lhs: Path, rhs: Path) -> Bool { return lhs.path == rhs.path }

// MARK: Comparable

extension Path: Comparable {}

/// Defines a strict total order over Paths based on their underlying string representation.
public func < (lhs: Path, rhs: Path) -> Bool { return lhs.path < rhs.path }

// MARK: Operators

/// Appends a Path fragment to another Path to produce a new Path
public func + (lhs: Path, rhs: Path) -> Path { return lhs.path + rhs.path }

/// Appends a String fragment to another Path to produce a new Path
public func + (lhs: Path, rhs: String) -> Path { return lhs.path + rhs }

/// Appends a String fragment to another String to produce a new Path
internal func + (lhs: String, rhs: String) -> Path {
  let rhsPath = Path(rhs)
  if rhsPath.isAbsolute {
    // Absolute paths replace relative paths
    return rhsPath
  } else {
    var lSlice = NSString(string: lhs).pathComponents.fullSlice
    var rSlice = NSString(string: rhs).pathComponents.fullSlice

    // Get rid of trailing "/" at the left side
    #if !os(Windows)
      if lSlice.count > 1 && lSlice.last == Path.separator { lSlice.removeLast() }
    #else
      if lSlice.count > 3 && lSlice.last == Path.separator { lSlice.removeLast() }
    #endif

    // Advance after the first relevant "."
    lSlice = lSlice.filter { $0 != "." }.fullSlice
    rSlice = rSlice.filter { $0 != "." }.fullSlice

    // Eats up trailing components of the left and leading ".." of the right side
    while lSlice.last != ".." && !lSlice.isEmpty && rSlice.first == ".." {
      #if !os(Windows)
        if lSlice.count > 1 || lSlice.first != Path.separator {
          // A leading "/" is never popped
          lSlice.removeLast()
        }
      #else
        if lSlice.count > 3 || !Path(components: lSlice).isAbsolute { lSlice.removeLast() }
      #endif
      if !rSlice.isEmpty { rSlice.removeFirst() }

      switch (lSlice.isEmpty, rSlice.isEmpty) {
      case (true, _): break
      case (_, true): break
      default: continue
      }
    }

    return Path(components: lSlice + rSlice)
  }
}

extension Array { var fullSlice: ArraySlice<Element> { return self[self.indices.suffix(from: 0)] } }

#if os(Windows)
  extension StringProtocol {
    subscript(offset: Int) -> Character { return self[index(startIndex, offsetBy: offset)] }
  }
#endif

// swiftlint:enable legacy_objc_type
