import Foundation
import IOUtils

public class FileWrap: Wrap {
  public private(set) var sourceURL: String?
  public private(set) var sourceFallbackURL: String?
  public private(set) var sourceFilename: String?
  public private(set) var sourceHash: String?
  public private(set) var leadDirectoryMissing: Bool

  internal init(
    wrapHash: String,
    directory: String?,
    patchURL: String?,
    patchFallbackURL: String?,
    patchFilename: String?,
    patchHash: String?,
    patchDirectory: String?,
    diffFiles: [String]?,
    sourceURL: String?,
    sourceFallbackURL: String?,
    sourceFilename: String?,
    sourceHash: String?,
    leadDirectoryMissing: Bool
  ) {
    self.sourceURL = sourceURL
    self.sourceFallbackURL = sourceFallbackURL
    self.sourceFilename = sourceFilename
    self.sourceHash = sourceHash
    self.leadDirectoryMissing = leadDirectoryMissing
    super.init(
      wrapHash: wrapHash,
      directory: directory,
      patchURL: patchURL,
      patchFallbackURL: patchFallbackURL,
      patchFilename: patchFilename,
      patchHash: patchHash,
      patchDirectory: patchDirectory,
      diffFiles: diffFiles
    )
  }

  public override func setupDirectory(path: String, packagefilesPath: String) throws {
    guard let urlAsString = self.sourceURL else {
      throw WrapError.genericError("Expected URL to clone")
    }
    if let url = URL(string: urlAsString), let hash = self.sourceHash, let sfn = self.sourceFilename
    {
      // Do something like https://github.com/mesonbuild/meson/blob/3e7c08f358e9bd91808c8ff3b76c11aedeb82f85/mesonbuild/wrap/wrap.py#L549
      let targetDirectory =
        self.directory
        ?? sfn.replacingOccurrences(of: ".zip", with: "").replacingOccurrences(
          of: ".tar.xz",
          with: ""
        ).replacingOccurrences(of: ".tar.gz", with: "").replacingOccurrences(
          of: ".tar.bz2",
          with: ""
        ).replacingOccurrences(of: ".tgz", with: "")
      let fullPath = "\(path)\(Path.separator)\(targetDirectory)"
      // Alamofire does not fit in, as everything is synchronous
      // URLSession.shared comes with a FoundationNetworking dependency, that
      // can only be linked statically by linking curl statically => Won't be done
      // due to security'
      // All other libraries I tried (SwiftHTTP, Just) didn't even compile
      // So declare defeat and simply shell out to curl/wget, as one of those is always
      // installed.
      let archiveFile = try self.download(
        url: url.description,
        fallbackURL: self.sourceFallbackURL,
        expectedHash: hash
      )
      do {
        try FileManager.default.createDirectory(
          atPath: self.leadDirectoryMissing ? fullPath : path,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch let error {
        print(error)  // Ignore
      }
      let wd = self.leadDirectoryMissing ? fullPath : path
      let downloaded = url.lastPathComponent
      let type = try getArchiveType(downloaded, sfn)
      let outputdir = wd
      Wrap.LOG.info("Extracting \(archiveFile) of type \(type) into \(outputdir)")
      try extractArchive(type: type, file: archiveFile, outputDir: outputdir)
      try self.postSetup(path: fullPath, packagesfilesPath: packagefilesPath)
    } else {
      throw WrapError.genericError("Malformed URL: \(String(describing: self.sourceURL))")
    }
  }

  private func getArchiveType(_ str: String) -> ArchiveType? {
    if str.hasSuffix(".zip") {
      return .zip
    } else if str.hasSuffix("tar.xz") {
      return .tarxz
    } else if str.hasSuffix(".tar.bz2") {
      return .tarbz2
    } else if str.hasSuffix(".tgz") || str.hasSuffix(".tar.gz") {
      return .targz
    }
    return nil
  }

  private func getArchiveType(_ downloaded: String, _ sfn: String) throws -> ArchiveType {
    if let at = self.getArchiveType(downloaded) {
      return at
    } else if let at = self.getArchiveType(sfn) {
      return at
    } else {
      throw WrapError.genericError("Unable to extract archive \(sfn)")
    }
  }
}
