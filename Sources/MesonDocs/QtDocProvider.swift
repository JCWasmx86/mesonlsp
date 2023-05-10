class QtDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["qt4_module.compile_resources"] =
      "Compiles Qt's resources collection files (.qrc) into c++ files for compilation."
    dict["qt4_module.compile_ui"] = "Compiles Qt's ui files (.ui) into header files."
    dict["qt4_module.compile_moc"] =
      "Compiles Qt's moc files (.moc) into header and/or source files."
    dict["qt4_module.preprocess"] =
      "Takes sources for moc, uic, and rcc, and converts them into c++ files for compilation."
    dict["qt4_module.compile_translations"] =
      "This method generates the necessary targets to build translation files with lrelease."
    dict["qt4_module.has_tools"] =
      "This method returns true if all tools used by this module are found, false otherwise. It should be used to compile optional Qt code"
    dict["qt5_module.compile_resources"] =
      "Compiles Qt's resources collection files (.qrc) into c++ files for compilation."
    dict["qt5_module.compile_ui"] = "Compiles Qt's ui files (.ui) into header files."
    dict["qt5_module.compile_moc"] =
      "Compiles Qt's moc files (.moc) into header and/or source files."
    dict["qt5_module.preprocess"] =
      "Takes sources for moc, uic, and rcc, and converts them into c++ files for compilation."
    dict["qt5_module.compile_translations"] =
      "This method generates the necessary targets to build translation files with lrelease."
    dict["qt5_module.has_tools"] =
      "This method returns true if all tools used by this module are found, false otherwise. It should be used to compile optional Qt code"
    dict["qt6_module.compile_resources"] =
      "Compiles Qt's resources collection files (.qrc) into c++ files for compilation."
    dict["qt6_module.compile_ui"] = "Compiles Qt's ui files (.ui) into header files."
    dict["qt6_module.compile_moc"] =
      "Compiles Qt's moc files (.moc) into header and/or source files."
    dict["qt6_module.preprocess"] =
      "Takes sources for moc, uic, and rcc, and converts them into c++ files for compilation."
    dict["qt6_module.compile_translations"] =
      "This method generates the necessary targets to build translation files with lrelease."
    dict["qt6_module.has_tools"] =
      "This method returns true if all tools used by this module are found, false otherwise. It should be used to compile optional Qt code"
  }
}
