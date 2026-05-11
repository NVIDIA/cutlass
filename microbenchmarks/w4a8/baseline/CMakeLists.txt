# Standalone build for the W4A8 grouped GEMM tile/schedule sweep (Hopper SM90a).
cmake_minimum_required(VERSION 3.19)
project(w4a8_microbench_sweep LANGUAGES CXX CUDA)

find_package(CUDAToolkit REQUIRED)

# Locate CUTLASS three levels up by default: <CUTLASS_DIR>/microbenchmarks/w4a8/baseline -> CUTLASS_DIR.
get_filename_component(_default_cutlass_dir "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(CUTLASS_DIR "${_default_cutlass_dir}" CACHE PATH "CUTLASS tree")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# sm_90a: arch-conditional MMA and full Hopper ISA (H100/H200).
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
  set(CMAKE_CUDA_ARCHITECTURES 90a)
endif()

set(CUTLASS_INCLUDES
  "${CUTLASS_DIR}/include"
  "${CUTLASS_DIR}/tools/util/include"
  "${CUTLASS_DIR}/examples/common"
  "${CUTLASS_DIR}/examples/55_hopper_mixed_dtype_gemm"
)

add_executable(w4a8_baseline_sweep w4a8_baseline_sweep.cu)
target_include_directories(w4a8_baseline_sweep PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  ${CUTLASS_INCLUDES}
)
target_compile_definitions(w4a8_baseline_sweep PRIVATE INT4FP8_GROUPED_SUPPORTED)
target_compile_options(w4a8_baseline_sweep PRIVATE
  $<$<COMPILE_LANGUAGE:CUDA>:--expt-relaxed-constexpr>
  $<$<COMPILE_LANGUAGE:CUDA>:-ftemplate-backtrace-limit=0>
)
target_link_libraries(w4a8_baseline_sweep PRIVATE CUDA::cudart)
