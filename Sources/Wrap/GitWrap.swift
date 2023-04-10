import Foundation
import IOUtils

public class GitWrap: VcsWrap {
  public private(set) var depth: Int
  public private(set) var pushURL: String?
  public private(set) var cloneRecursive: Bool

  internal init(
    wrapHash: String,
    directory: String?,
    patchURL: String?,
    patchFallbackURL: String?,
    patchFilename: String?,
    patchHash: String?,
    patchDirectory: String?,
    diffFiles: [String],
    url: String?,
    revision: String?,
    depth: Int,
    pushURL: String?,
    cloneRecursive: Bool
  ) {
    self.depth = depth
    self.pushURL = pushURL
    self.cloneRecursive = cloneRecursive
    super.init(
      wrapHash: wrapHash,
      directory: directory,
      patchURL: patchURL,
      patchFallbackURL: patchFallbackURL,
      patchFilename: patchFilename,
      patchHash: patchHash,
      patchDirectory: patchDirectory,
      diffFiles: diffFiles,
      url: url,
      revision: revision
    )
  }

  public override func setupDirectory(path: String, packagefilesPath: String) throws {
    try self.assertRequired("git")
    guard let urlAsString = self.url else { throw WrapError.genericError("Expected URL to clone") }
    if let url = URL(string: urlAsString) {
      guard let rev = self.revision else { throw WrapError.genericError("Missing revision") }
      // Do something like https://github.com/mesonbuild/meson/blob/3e7c08f358e9bd91808c8ff3b76c11aedeb82f85/mesonbuild/wrap/wrap.py#L549
      let targetDirectory =
        self.directory ?? url.lastPathComponent.replacingOccurrences(of: ".git", with: "")
      let fullPath = "\(path)\(Path.separator)\(targetDirectory)"
      let isShallow = self.depth != 0 && self.depth != Int.max
      let depthOptions = isShallow ? ["--depth", self.depth.description] : []
      if isShallow && self.isValidCommitId(rev) {
        try self.executeCommand([
          "git", "-c", "init.defaultBranch=mesonlsp-dummy-branch", "init", fullPath,
        ])
        try self.executeCommand(["git", "-C", fullPath, "remote", "add", "origin", urlAsString])
        try self.executeCommand(["git", "-C", fullPath, "fetch"] + depthOptions + ["origin", rev])
        try self.executeCommand([
          "git", "-C", fullPath, "-c", "advice.detachedHead=false", "checkout", rev, "--",
        ])
      } else {
        if !isShallow {
          try self.executeCommand(["git", "clone", urlAsString, fullPath])
          if rev.lowercased() != "head" {
            do {
              try self.executeCommand([
                "git", "-C", fullPath, "-c", "advice.detachedHead=false", "checkout", rev, "--",
              ])
            } catch {
              try self.executeCommand(["git", "-C", fullPath, "fetch", urlAsString, rev])
              try self.executeCommand([
                "git", "-C", fullPath, "-c", "advice.detachedHead=false", "checkout", rev, "--",
              ])
            }
          }
        } else {
          var args = ["-c", "advice.detachedHead=false", "clone"] + depthOptions
          if rev.lowercased() != "head" { args += ["--branch", rev] }
          args += [urlAsString, fullPath]
          try self.executeCommand(["git"] + args)
        }
      }
      if self.cloneRecursive {
        try self.executeCommand(
          ["git", "-C", fullPath, "submodule", "update", "--init", "--checkout", "--recursive"]
            + depthOptions
        )
      }
      if let pl = self.pushURL {
        try self.executeCommand([
          "git", "-C", fullPath, "remote", "set-url", "--push", "origin", pl,
        ])
      }
      try self.postSetup(path: fullPath, packagesfilesPath: packagefilesPath)
    } else {
      throw WrapError.genericError("Malformed URL: \(String(describing: self.url))")
    }
  }

  private func isValidCommitId(_ id: String) -> Bool {
    if id.count != 40 && id.count != 64 { return false }
    return id.filter { $0.isHexDigit }.count == id.count
  }
}
