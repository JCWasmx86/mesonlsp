tf_lib = static_library(
    'TestingFramework',
    'AssertionCheck.swift',
    'ErrorAssertionCheck.swift',
    'WarningAssertionCheck.swift',
    'FileParser.swift',
    'VariableTypeAssertionCheck.swift',
    'TestRunner.swift',
    dependencies: mesonanalyze_dep,
)
tf_dep = declare_dependency(link_with: tf_lib, dependencies: mesonanalyze_dep)
