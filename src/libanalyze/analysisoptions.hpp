#pragma once

class AnalysisOptions {
public:
  bool disableNameLinting;
  bool disableAllIdLinting;
  bool disableCompilerIdLinting;
  bool disableCompilerArgumentIdLinting;
  bool disableLinkerIdLinting;
  bool disableCpuFamilyLinting;
  bool disableOsFamilyLinting;
  bool disableUnusedVariableCheck;
  bool disableArgTypeChecking;
  bool disableIterationVariableShadowingLint;
  bool enableIterationVariableLint;

  // This should be a better API somehow
  explicit AnalysisOptions(bool disableNameLinting = false,
                           bool disableAllIdLinting = false,
                           bool disableCompilerIdLinting = false,
                           bool disableCompilerArgumentIdLinting = false,
                           bool disableLinkerIdLinting = false,
                           bool disableCpuFamilyLinting = false,
                           bool disableOsFamilyLinting = false,
                           bool disableUnusedVariableCheck = false,
                           bool disableArgTypeChecking = false,
                           bool disableIterationVariableShadowingLint = false,
                           bool enableIterationVariableLint = false)
      : disableNameLinting(disableNameLinting),
        disableAllIdLinting(disableAllIdLinting),
        disableCompilerIdLinting(disableCompilerIdLinting),
        disableCompilerArgumentIdLinting(disableCompilerArgumentIdLinting),
        disableLinkerIdLinting(disableLinkerIdLinting),
        disableCpuFamilyLinting(disableCpuFamilyLinting),
        disableOsFamilyLinting(disableOsFamilyLinting),
        disableUnusedVariableCheck(disableUnusedVariableCheck),
        disableArgTypeChecking(disableArgTypeChecking),
        disableIterationVariableShadowingLint(
            disableIterationVariableShadowingLint),
        enableIterationVariableLint(enableIterationVariableLint) {}
};
