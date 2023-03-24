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
// swiftlint:disable todo
// swiftlint:disable nesting
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

  internal let fileSystemInfo: FileSystemInfo

  // MARK: Init

  public init() { self.init("") }

  /// Create a Path from a given String
  public init(_ path: String) { self.init(path, fileSystemInfo: DefaultFileSystemInfo()) }

  internal init(_ path: String, fileSystemInfo: FileSystemInfo) {
    self.path = path
    self.fileSystemInfo = fileSystemInfo
  }

  internal init(fileSystemInfo: FileSystemInfo) { self.init("", fileSystemInfo: fileSystemInfo) }

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
  public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
  public typealias UnicodeScalarLiteralType = StringLiteralType

  public init(extendedGraphemeClusterLiteral path: StringLiteralType) {
    self.init(stringLiteral: path)
  }

  public init(unicodeScalarLiteral path: StringLiteralType) { self.init(stringLiteral: path) }

  public init(stringLiteral value: StringLiteralType) { self.init(value) }
}

// MARK: CustomStringConvertible

extension Path: CustomStringConvertible { public var description: String { return self.path } }

// MARK: Conversion

extension Path {
  public var string: String { return self.path }

  public var url: URL { return URL(fileURLWithPath: path) }
}

// MARK: Hashable

extension Path: Hashable {
  public func hash(into hasher: inout Hasher) { hasher.combine(self.path.hashValue) }
}

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

  /// Test whether a path is relative.
  ///
  /// - Returns: `true` iff a path is relative (not absolute)
  ///
  public var isRelative: Bool { return !isAbsolute }

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

  /// De-normalizes the path, by replacing the current user home directory with "~".
  ///
  /// - Returns: a new path made by removing extraneous path components from the underlying String
  ///   representation.
  ///
  public func abbreviate() -> Path {
    let rangeOptions: String.CompareOptions =
      fileSystemInfo.isFSCaseSensitiveAt(path: self) ? [.anchored] : [.anchored, .caseInsensitive]
    let home = Path.home.string
    guard let homeRange = self.path.range(of: home, options: rangeOptions) else { return self }
    let withoutHome = Path(self.path.replacingCharacters(in: homeRange, with: ""))

    if withoutHome.path.isEmpty || withoutHome.path == Path.separator {
      return Path("~")
    } else if withoutHome.isAbsolute {
      return Path("~" + withoutHome.path)
    } else {
      return Path("~") + withoutHome.path
    }
  }

  /// Returns the path of the item pointed to by a symbolic link.
  ///
  /// - Returns: the path of directory or file to which the symbolic link refers
  ///
  public func symlinkDestination() throws -> Path {
    let symlinkDestination = try Path.fileManager.destinationOfSymbolicLink(atPath: path)
    let symlinkPath = Path(symlinkDestination)
    if symlinkPath.isRelative { return self + ".." + symlinkPath } else { return symlinkPath }
  }
}

internal protocol FileSystemInfo { func isFSCaseSensitiveAt(path: Path) -> Bool }

internal struct DefaultFileSystemInfo: FileSystemInfo {
  func isFSCaseSensitiveAt(path: Path) -> Bool {
    #if os(Linux)
      // URL resourceValues(forKeys:) is not supported on non-darwin platforms...
      // But we can (fairly?) safely assume for now that the Linux FS is case sensitive.
      // TODO: refactor when/if resourceValues is available, or look into using something
      // like stat or pathconf to determine if the mountpoint is case sensitive.
      return true
    #else
      var isCaseSensitive = false
      // Calling resourceValues will fail if the path does not exist on the filesystem, which
      // makes sense, but means we can only guarantee the return value is correct if the
      // path actually exists.
      if let resourceValues = try? path.url.resourceValues(forKeys: [
        .volumeSupportsCaseSensitiveNamesKey
      ]) {
        isCaseSensitive = resourceValues.volumeSupportsCaseSensitiveNames ?? isCaseSensitive
      }
      return isCaseSensitive
    #endif
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

  /// Splits the string representation on the directory separator.
  /// Absolute paths remain the leading slash as first component.
  ///
  /// - Returns: all path components
  ///
  public var components: [String] { return NSString(string: path).pathComponents }

  /// The file extension behind the last dot of the last component.
  ///
  /// - Returns: the file extension
  ///
  public var `extension`: String? {
    let pathExtension = NSString(string: path).pathExtension
    if pathExtension.isEmpty { return nil }

    return pathExtension
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

  /// Test whether a path is a symbolic link.
  ///
  /// - Returns: `true` if the path is a symbolic link; `false` if the path doesn't exist on disk
  ///   or its existence could not be determined
  ///
  public var isSymlink: Bool {
    do {
      _ = try Path.fileManager.destinationOfSymbolicLink(atPath: path)
      return true
    } catch { return false }
  }

  /// Test whether a path is readable
  ///
  /// - Returns: `true` if the current process has read privileges for the file at path;
  ///   otherwise `false` if the process does not have read privileges or the existence of the
  ///   file could not be determined.
  ///
  public var isReadable: Bool { return Path.fileManager.isReadableFile(atPath: self.path) }

  /// Test whether a path is writeable
  ///
  /// - Returns: `true` if the current process has write privileges for the file at path;
  ///   otherwise `false` if the process does not have write privileges or the existence of the
  ///   file could not be determined.
  ///
  public var isWritable: Bool { return Path.fileManager.isWritableFile(atPath: self.path) }

  /// Test whether a path is executable
  ///
  /// - Returns: `true` if the current process has execute privileges for the file at path;
  ///   otherwise `false` if the process does not have execute privileges or the existence of the
  ///   file could not be determined.
  ///
  public var isExecutable: Bool { return Path.fileManager.isExecutableFile(atPath: self.path) }

  /// Test whether a path is deletable
  ///
  /// - Returns: `true` if the current process has delete privileges for the file at path;
  ///   otherwise `false` if the process does not have delete privileges or the existence of the
  ///   file could not be determined.
  ///
  public var isDeletable: Bool { return Path.fileManager.isDeletableFile(atPath: self.path) }
}

// MARK: File Manipulation

extension Path {
  /// Create the directory.
  ///
  /// - Note: This method fails if any of the intermediate parent directories does not exist.
  ///   This method also fails if any of the intermediate path elements corresponds to a file and
  ///   not a directory.
  ///
  public func mkdir() throws {
    try Path.fileManager.createDirectory(
      atPath: self.path,
      withIntermediateDirectories: false,
      attributes: nil
    )
  }

  /// Create the directory and any intermediate parent directories that do not exist.
  ///
  /// - Note: This method fails if any of the intermediate path elements corresponds to a file and
  ///   not a directory.
  ///
  public func mkpath() throws {
    try Path.fileManager.createDirectory(
      atPath: self.path,
      withIntermediateDirectories: true,
      attributes: nil
    )
  }

  /// Delete the file or directory.
  ///
  /// - Note: If the path specifies a directory, the contents of that directory are recursively
  ///   removed.
  ///
  public func delete() throws { try Path.fileManager.removeItem(atPath: self.path) }

  /// Move the file or directory to a new location synchronously.
  ///
  /// - Parameter destination: The new path. This path must include the name of the file or
  ///   directory in its new location.
  ///
  public func move(_ destination: Path) throws {
    try Path.fileManager.moveItem(atPath: self.path, toPath: destination.path)
  }

  /// Copy the file or directory to a new location synchronously.
  ///
  /// - Parameter destination: The new path. This path must include the name of the file or
  ///   directory in its new location.
  ///
  public func copy(_ destination: Path) throws {
    try Path.fileManager.copyItem(atPath: self.path, toPath: destination.path)
  }

  /// Creates a hard link at a new destination.
  ///
  /// - Parameter destination: The location where the link will be created.
  ///
  public func link(_ destination: Path) throws {
    try Path.fileManager.linkItem(atPath: self.path, toPath: destination.path)
  }

  /// Creates a symbolic link at a new destination.
  ///
  /// - Parameter destintation: The location where the link will be created.
  ///
  public func symlink(_ destination: Path) throws {
    try Path.fileManager.createSymbolicLink(
      atPath: self.path,
      withDestinationPath: destination.path
    )
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

  /// Changes the current working directory of the process to the path during the execution of the
  /// given block.
  ///
  /// - Note: The original working directory is restored when the block returns or throws.
  /// - Parameter closure: A closure to be executed while the current directory is configured to
  ///   the path.
  ///
  public func chdir(closure: () throws -> Void) rethrows {
    let previous = Path.current
    Path.current = self
    defer { Path.current = previous }
    try closure()
  }
}

// MARK: Temporary

extension Path {
  /// - Returns: the path to either the user’s or application’s home directory,
  ///   depending on the platform.
  ///
  public static var home: Path { return Path(NSHomeDirectory()) }

  /// - Returns: the path of the temporary directory for the current user.
  ///
  public static var temporary: Path { return Path(NSTemporaryDirectory()) }

  /// - Returns: the path of a temporary directory unique for the process.
  /// - Note: Based on `NSProcessInfo.globallyUniqueString`.
  ///
  public static func processUniqueTemporary() throws -> Path {
    let path = temporary + ProcessInfo.processInfo.globallyUniqueString
    if !path.exists { try path.mkdir() }
    return path
  }

  /// - Returns: the path of a temporary directory unique for each call.
  /// - Note: Based on `NSUUID`.
  ///
  public static func uniqueTemporary() throws -> Path {
    let path = try processUniqueTemporary() + UUID().uuidString
    try path.mkdir()
    return path
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

  /// Reads the file.
  ///
  /// - Note: Works atomically: the data is written to a backup file, and then — assuming no
  ///   errors occur — the backup file is renamed to the name specified by path.
  ///
  /// - Parameter string: the string to write to file.
  ///
  /// - Parameter encoding: the encoding which should be used to represent the string as bytes.
  ///   (by default: `NSUTF8StringEncoding`)
  ///
  /// - Returns: the contents of the file at the specified path as string.
  ///
  public func write(_ string: String, encoding: String.Encoding = String.Encoding.utf8) throws {
    try string.write(toFile: normalize().path, atomically: true, encoding: encoding)
  }
}

// MARK: Traversing

extension Path {
  /// Get the parent directory
  ///
  /// - Returns: the normalized path of the parent directory
  ///
  public func parent() -> Path { return self + ".." }

  /// Performs a shallow enumeration in a directory
  ///
  /// - Returns: paths to all files, directories and symbolic links contained in the directory
  ///
  public func children() throws -> [Path] {
    return try Path.fileManager.contentsOfDirectory(atPath: path).map { self + Path($0) }
  }

  /// Performs a deep enumeration in a directory
  ///
  /// - Returns: paths to all files, directories and symbolic links contained in the directory or
  ///   any subdirectory.
  ///
  public func recursiveChildren() throws -> [Path] {
    return try Path.fileManager.subpathsOfDirectory(atPath: path).map { self + Path($0) }
  }
}

// MARK: SequenceType

extension Path: Sequence {
  public struct DirectoryEnumerationOptions: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static var skipsSubdirectoryDescendants = Self(
      rawValue: FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants.rawValue
    )
    public static var skipsPackageDescendants = Self(
      rawValue: FileManager.DirectoryEnumerationOptions.skipsPackageDescendants.rawValue
    )
    public static var skipsHiddenFiles = Self(
      rawValue: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles.rawValue
    )
  }

  /// Represents a path sequence with specific enumeration options
  public struct PathSequence: Sequence {
    private var path: Path
    private var options: DirectoryEnumerationOptions

    init(path: Path, options: DirectoryEnumerationOptions) {
      self.path = path
      self.options = options
    }

    public func makeIterator() -> DirectoryEnumerator {
      return DirectoryEnumerator(path: path, options: options)
    }
  }

  /// Enumerates the contents of a directory, returning the paths of all files and directories
  /// contained within that directory. These paths are relative to the directory.
  public struct DirectoryEnumerator: IteratorProtocol {
    public typealias Element = Path

    let path: Path
    let directoryEnumerator: FileManager.DirectoryEnumerator?

    init(path: Path, options mask: DirectoryEnumerationOptions = []) {
      let options = FileManager.DirectoryEnumerationOptions(rawValue: mask.rawValue)
      self.path = path
      self.directoryEnumerator = Path.fileManager.enumerator(
        at: path.url,
        includingPropertiesForKeys: nil,
        options: options
      )
    }

    public func next() -> Path? {
      let next = directoryEnumerator?.nextObject()

      if let next = next as? URL { return Path(next.path) }
      return nil
    }

    /// Skip recursion into the most recently obtained subdirectory.
    public func skipDescendants() { directoryEnumerator?.skipDescendants() }
  }

  /// Perform a deep enumeration of a directory.
  ///
  /// - Returns: a directory enumerator that can be used to perform a deep enumeration of the
  ///   directory.
  ///
  public func makeIterator() -> DirectoryEnumerator { return DirectoryEnumerator(path: self) }

  /// Perform a deep enumeration of a directory.
  ///
  /// - Parameter options: FileManager directory enumerator options.
  ///
  /// - Returns: a path sequence that can be used to perform a deep enumeration of the
  ///   directory.
  ///
  public func iterateChildren(options: DirectoryEnumerationOptions = []) -> PathSequence {
    return PathSequence(path: self, options: options)
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

// MARK: Pattern Matching

/// Implements pattern-matching for paths.
///
/// - Returns: `true` iff one of the following conditions is true:
///     - the paths are equal (based on `Path`'s `Equatable` implementation)
///     - the paths can be normalized to equal Paths.
///
public func ~= (lhs: Path, rhs: Path) -> Bool {
  return lhs == rhs || lhs.normalize() == rhs.normalize()
}

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

// swiftlint:enable todo
// swiftlint:enable nesting
// swiftlint:enable legacy_objc_type
