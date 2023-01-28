class I18nDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["i18n_module.gettext"] =
      "Sets up gettext localisation so that translations are built and placed into their proper locations during install. Takes one positional argument which is the name of the gettext module."
    dict["i18n_module.merge_file"] = "This merges translations into a text file using msgfmt."
    dict["i18n_module.itstool_join"] = "This joins translations into a XML file using itstool."
  }
}
