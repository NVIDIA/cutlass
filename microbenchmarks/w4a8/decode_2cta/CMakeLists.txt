# Standalone build for the W4A8 grouped GEMM "decode 2 CTAs/SM" experiment (Hopper SM90a).
#
# Three translation units:
#   w4a8_2cta_ref.cu   -- reference C1 schedule, NO macro overrides ("stock C1").
#   w4a8_2cta_test.cu  -- experimental schedule, WITH the three CUTLASS_W4A8_*
#                         macros that force 2 CTAs/SM and reduced register
#                         requirements.
#   w4a8_2cta_main.cu  -- driver: parses CLI, owns shared inputs, runs both
#                         runners, executes the bf16 equality check.
#
# Per-source COMPILE_DEFINITIONS are used to keep the macro overrides scoped
# to the test TU only, so the reference C1 timing is the genuine CUTLASS
# default (__launch_bounds__(384, 1), setmaxnreg.dec/inc(40, 232)).
cmake_minimum_required(VERSION 3.19)
project(w4a8_microbench_decode_2cta LANGUAGES CXX CUDA)

find_package(CUDAToolkit REQUIRED)

# Locate CUTLASS three levels up by default: <CUTLASS_DIR>/microbenchmarks/w4a8/decode_2cta -> CUTLASS_DIR.
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

add_executable(w4a8_2cta
  w4a8_2cta_main.cu
  w4a8_2cta_ref.cu
  w4a8_2cta_test.cu
)

target_include_directories(w4a8_2cta PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/.."   # for #include "common/..."
  ${CUTLASS_INCLUDES}
)

# The CUTLASS_W4A8_* macros are kernel-class-scoped (templated on KernelSchedule
# and read in the GemmUniversal kernel header). Defining them at the target level
# would leak into the ref TU as well and contaminate its "stock C1" timing.
# Apply them ONLY to the test source.
#
# Why (40, 88) and not the originally planned (40, 108):
#   * PTX requires the operand to be a multiple of 8.
#   * Empirically (40, 104) deadlocks the kernel under 2 CTAs/SM: the producer
#     setmaxnreg.dec releases too few regs for two consumer warpgroups (per CTA)
#     to satisfy their setmaxnreg.inc when 2 CTAs/SM are co-resident, and the
#     HW reg-pool arbitration stalls forever.
#   * (40, 88) ptxas-allocates REG=80 with STACK=0 (no spills, no deadlock).
# Register accounting at (40, 88) with MinBlocks=2:
#   per-CTA = 128 * 40 + 256 * 88 = 27 648 regs
#   per-SM  = 2 * 27 648         = 55 296 regs  (slack = 10 240 below 65 536)
set_source_files_properties(w4a8_2cta_test.cu PROPERTIES
  COMPILE_DEFINITIONS
    "INT4FP8_GROUPED_SUPPORTED;CUTLASS_W4A8_MIN_BLOCKS_PER_SM=2;CUTLASS_W4A8_MMA_REG_REQUIREMENT=88;CUTLASS_W4A8_LOAD_REG_REQUIREMENT=40;CUTLASS_W4A8_SM_COUNT_OVERRIDE=264"
)
# CUTLASS_W4A8_SM_COUNT_OVERRIDE=264:
#   The cooperative grouped-GEMM scheduler launches exactly `sm_count` CTAs
#   (persistent grid). At sm_count=132 (the actual H200 SM count) the runtime
#   places 1 CTA per SM regardless of resource budget, so the 2-CTA launch
#   bounds + Stages=9 fix is wasted (Block Limit SMEM = 2 but Achieved
#   Occupancy stays at 17%). Setting sm_count=264 grows the persistent grid to
#   2x SM count, letting the runtime block scheduler co-locate two CTAs per
#   SM. The ref TU keeps the device-queried 132 (no macro), so its launch
#   characteristics match stock CUTLASS exactly.

# Ref + driver TUs: only INT4FP8_GROUPED_SUPPORTED, no kernel-constant overrides.
set_source_files_properties(w4a8_2cta_ref.cu w4a8_2cta_main.cu PROPERTIES
  COMPILE_DEFINITIONS "INT4FP8_GROUPED_SUPPORTED"
)

target_compile_options(w4a8_2cta PRIVATE
  $<$<COMPILE_LANGUAGE:CUDA>:--expt-relaxed-constexpr>
  $<$<COMPILE_LANGUAGE:CUDA>:-ftemplate-backtrace-limit=0>
)
target_link_libraries(w4a8_2cta PRIVATE CUDA::cudart)
