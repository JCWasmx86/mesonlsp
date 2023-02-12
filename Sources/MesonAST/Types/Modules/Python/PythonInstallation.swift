public struct PythonInstallation: AbstractObject {
  public let name: String = "python_installation"
  public let parent: AbstractObject? = ExternalProgram()

  public init() {}
}
