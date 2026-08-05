# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

function(declare_base_dsl_python_extension name)
  cmake_parse_arguments(ARG
    ""
    "ROOT_DIR;PARENT_MODULE"
    ""
    ${ARGN})

  declare_mlir_python_extension(${name}
    MODULE_NAME _base_dsl
    ROOT_DIR    "${ARG_ROOT_DIR}"
    ADD_TO_PARENT ${ARG_PARENT_MODULE}
    SOURCES
      DSLBindingAPIs.cpp
  )
  if(CUTLASS_IR_DEFAULT_PTX_VERSION STREQUAL "+ptx88")
    message(STATUS "CUTLASS_IR_DEFAULT_PTX_VERSION is set to +ptx88, defining CUDA_VERSION=12.9")
    set_source_files_properties(
      ${ARG_ROOT_DIR}/DSLBindingAPIs.cpp
      PROPERTIES COMPILE_DEFINITIONS "CUDA_VERSION=12.9"
    )
  else()
    # Define CUDA_VERSION at compile time
    set_source_files_properties(
      ${ARG_ROOT_DIR}/DSLBindingAPIs.cpp
      PROPERTIES COMPILE_DEFINITIONS "CUDA_VERSION=${CUDA_VERSION}"
    )
  endif()
endfunction()
