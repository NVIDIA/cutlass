# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Build glue for the CuTe + Hopper/Blackwell study plan exercises.
# Enabled with `-DCUTLASS_ENABLE_STUDY=ON`.
#
# Each exercise registers itself with `cutlass_study_add_executable`, which
# wires it up like a CUTLASS example (CUTLASS deps, util includes) and tags it
# with the global target `study_all` for one-shot builds.

set(CUTLASS_STUDY_COMMON_DIR ${CMAKE_CURRENT_SOURCE_DIR}/common)
set(CUTLASS_STUDY_EXAMPLES_UTILS_DIR ${CMAKE_SOURCE_DIR}/examples/common)

add_custom_target(study_all)

function(cutlass_study_add_executable NAME)
  set(options)
  set(oneValueArgs)
  set(multiValueArgs)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  cutlass_add_executable(${NAME} ${__UNPARSED_ARGUMENTS} BATCH_SOURCES OFF)

  add_dependencies(study_all ${NAME})

  target_link_libraries(
    ${NAME}
    PRIVATE
    CUTLASS
    cutlass_tools_util_includes
    $<$<BOOL:${CUTLASS_ENABLE_CUBLAS}>:nvidia::cublas>
    cuda
  )

  target_include_directories(
    ${NAME}
    PRIVATE
    ${CUTLASS_STUDY_COMMON_DIR}
    ${CUTLASS_STUDY_EXAMPLES_UTILS_DIR}
  )
endfunction()

# Each stage owns its own CMakeLists.txt so progress is local.
add_subdirectory(stage1_cute_algebra)
# add_subdirectory(stage2_primitives)        # uncomment as exercises land
add_subdirectory(stage3_gemm)
# add_subdirectory(stage4_flashattn)
# add_subdirectory(stage5_moe)
