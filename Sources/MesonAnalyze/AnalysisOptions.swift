public class AnalysisOptions {
  public var disableNameLinting: Bool
  public var disableAllIdLinting: Bool
  public var disableCompilerIdLinting: Bool
  public var disableCompilerArgumentIdLinting: Bool
  public var disableLinkerIdLinting: Bool
  public var disableCpuFamilyLinting: Bool
  public var disableOsFamilyLinting: Bool

  public init(
    disableNameLinting: Bool = false,
    disableAllIdLinting: Bool = false,
    disableCompilerIdLinting: Bool = false,
    disableCompilerArgumentIdLinting: Bool = false,
    disableLinkerIdLinting: Bool = false,
    disableCpuFamilyLinting: Bool = false,
    disableOsFamilyLinting: Bool = false
  ) {
    self.disableNameLinting = disableNameLinting
    self.disableAllIdLinting = disableAllIdLinting
    self.disableCompilerIdLinting = disableCompilerIdLinting
    self.disableCompilerArgumentIdLinting = disableCompilerArgumentIdLinting
    self.disableLinkerIdLinting = disableLinkerIdLinting
    self.disableCpuFamilyLinting = disableCpuFamilyLinting
    self.disableOsFamilyLinting = disableOsFamilyLinting
  }
}
