tf_lib = static_library(
    'TestingFramework',
    'AssertionCheck.swift',
    'ErrorAssertionCheck.swift',
    'FileParser.swift',
    'TestRunner.swift',
    'VariableTypeAssertionCheck.swift',
    'WarningAssertionCheck.swift',
    dependencies: mesonanalyze_dep,
)
tf_dep = declare_dependency(link_with: tf_lib, dependencies: mesonanalyze_dep)
