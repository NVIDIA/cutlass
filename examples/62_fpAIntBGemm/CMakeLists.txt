set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CXX_STANDARD 14)


include_directories(
  ./cutlass_extensions/include
)

cutlass_example_add_executable(
  62_fpAIntBGemm
  run_gemm.cu
)