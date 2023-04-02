import Foundation
import SWCompression

internal enum ArchiveType {
  case zip
  case tarxz
  case targz
  case tarbz2
}

internal func extractArchive(type: ArchiveType, file: String, outputDir: String) throws {
  switch type {
  case .tarbz2:
    var fileData = try Data(contentsOf: URL(fileURLWithPath: file), options: .mappedIfSafe)
    fileData = try BZip2.decompress(data: fileData)
    let entries = try TarContainer.open(container: fileData)
    try writeEntries(entries, outputDir)
  case .targz:
    var fileData = try Data(contentsOf: URL(fileURLWithPath: file), options: .mappedIfSafe)
    fileData = try GzipArchive.unarchive(archive: fileData)
    let entries = try TarContainer.open(container: fileData)
    try writeEntries(entries, outputDir)
  case .tarxz:
    var fileData = try Data(contentsOf: URL(fileURLWithPath: file), options: .mappedIfSafe)
    fileData = try XZArchive.unarchive(archive: fileData)
    let entries = try TarContainer.open(container: fileData)
    try writeEntries(entries, outputDir)
  case .zip:
    let fileData = try Data(contentsOf: URL(fileURLWithPath: file), options: .mappedIfSafe)
    let entries = try ZipContainer.open(container: fileData)
    try writeEntries(entries, outputDir)
  }
}

// Taken from: https://github.com/tsolomko/SWCompression/blob/1e7393dc54c2ec0a698e6eb1d6b9989624104447/Sources/swcomp/Containers/CommonFunctions.swift
func writeEntries<T: ContainerEntry>(_ entries: [T], _ outputPath: String) throws {
  let fileManager = FileManager.default
  let outputURL = URL(fileURLWithPath: outputPath)
  var directoryAttributes = [(attributes: [FileAttributeKey: Any], path: String)]()

  // First, we create directories.
  for entry in entries where entry.info.type == .directory {
    directoryAttributes.append(try writeDirectory(entry, outputURL))
  }

  // Now, we create the rest of files.
  for entry in entries where entry.info.type != .directory { try writeFile(entry, outputURL) }

  for tuple in directoryAttributes {
    try fileManager.setAttributes(tuple.attributes, ofItemAtPath: tuple.path)
  }
}

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable legacy_objc_type
private func writeDirectory<T: ContainerEntry>(_ entry: T, _ outputURL: URL) throws -> (
  [FileAttributeKey: Any], String
) {
  let fileManager = FileManager.default
  let entryName = entry.info.name
  let entryFullURL = outputURL.appendingPathComponent(entryName, isDirectory: true)

  try fileManager.createDirectory(at: entryFullURL, withIntermediateDirectories: true)

  var attributes = [FileAttributeKey: Any]()

  #if !os(Linux)  // On linux only permissions attribute is supported.
    if let mtime = entry.info.modificationTime {
      attributes[FileAttributeKey.modificationDate] = mtime
    }

    if let ctime = entry.info.creationTime { attributes[FileAttributeKey.creationDate] = ctime }
  #endif

  if let permissions = entry.info.permissions?.rawValue, permissions > 0 {
    attributes[FileAttributeKey.posixPermissions] = NSNumber(value: permissions)
  }

  // We apply attributes to directories later, because extracting files into them changes mtime.
  return (attributes, entryFullURL.path)
}

private func writeFile<T: ContainerEntry>(_ entry: T, _ outputURL: URL) throws {
  let fileManager = FileManager.default
  let entryName = entry.info.name
  let entryFullURL = outputURL.appendingPathComponent(entryName, isDirectory: false)

  if entry.info.type == .symbolicLink {
    let destinationPath: String?
    if let tarEntry = entry as? TarEntry {
      destinationPath = tarEntry.info.linkName
    } else {
      guard let entryData = entry.data else {
        throw WrapError.unarchiveFailed(
          "Unable to get destination path for symbolic link \(entryName)."
        )
      }
      destinationPath = String(data: entryData, encoding: .utf8)
    }
    guard destinationPath != nil else {
      throw WrapError.unarchiveFailed(
        "Unable to get destination path for symbolic link \(entryName)."
      )
    }
    try fileManager.createSymbolicLink(
      atPath: entryFullURL.path,
      withDestinationPath: destinationPath!
    )
    // We cannot apply attributes to symbolic links.
    return
  } else if entry.info.type == .hardLink {
    guard let destinationPath = (entry as? TarEntry)?.info.linkName else {
      throw WrapError.unarchiveFailed("Unable to get destination path for hard link \(entryName).")
    }
    // Note that the order of parameters is inversed for hard links.
    try fileManager.linkItem(atPath: destinationPath, toPath: entryFullURL.path)
    // We cannot apply attributes to hard links.
    return
  } else if entry.info.type == .regular {
    guard let entryData = entry.data else {
      throw WrapError.unarchiveFailed("Unable to get data for the entry \(entryName).")
    }
    let parentURL = URL(fileURLWithPath: entryFullURL.path).deletingLastPathComponent()
    try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true)
    try entryData.write(to: entryFullURL)
  } else {
    print(
      "WARNING: Unknown file type \(entry.info.type) for entry \(entryName). Skipping this entry."
    )
    return
  }

  var attributes = [FileAttributeKey: Any]()

  #if !os(Linux)  // On linux only permissions attribute is supported.
    if let mtime = entry.info.modificationTime {
      attributes[FileAttributeKey.modificationDate] = mtime
    }

    if let ctime = entry.info.creationTime { attributes[FileAttributeKey.creationDate] = ctime }
  #endif

  if let permissions = entry.info.permissions?.rawValue, permissions > 0 {
    attributes[FileAttributeKey.posixPermissions] = NSNumber(value: permissions)
  }

  try fileManager.setAttributes(attributes, ofItemAtPath: entryFullURL.path)
}  // swiftlint:enable cyclomatic_complexity
// swiftlint:enable legacy_objc_type
