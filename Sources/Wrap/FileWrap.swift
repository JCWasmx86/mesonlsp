public class FileWrap: Wrap {
  public private(set) var sourceURL: String?
  public private(set) var sourceFallbackURL: String?
  public private(set) var sourceFilename: String?
  public private(set) var sourceHash: String?
  public private(set) var leadDirectoryMissing: Bool

  internal init(
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
      directory: directory,
      patchURL: patchURL,
      patchFallbackURL: patchFallbackURL,
      patchFilename: patchFilename,
      patchHash: patchHash,
      patchDirectory: patchDirectory,
      diffFiles: diffFiles
    )
  }
}
