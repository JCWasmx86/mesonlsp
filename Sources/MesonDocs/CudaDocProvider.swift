class CudaDocProvider: DocProvider {
  func addToDict(dict: inout [String: String]) {
    dict["cuda_module.nvcc_arch_flags"] =
      "Returns a list of `-gencode` flags that should be passed to `cuda_args:` in order to compile a \"fat binary\" for the architectures/compute capabilities enumerated in the positional argument(s). The flags shall be acceptable to an NVCC with CUDA Toolkit version string `cuda_version_string`."
    dict["cuda_module.nvcc_arch_readable"] =
      "Has precisely the same interface as `nvcc_arch_flags()`, but rather than returning a list of flags, it returns a \"readable\" list of architectures that will be compiled for. The output of this function is solely intended for informative message printing."
    dict["cuda_module.min_driver_version"] =
      "Returns the minimum NVIDIA proprietary driver version required, on the host system, by kernels compiled with a CUDA Toolkit with the given version string.\nThe output of this function is generally intended for informative message printing, but could be used for assertions or to conditionally enable features known to exist within the minimum NVIDIA driver required."
  }
}
