# Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.19 FATAL_ERROR)

project(CuTeMacaExamples LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

get_filename_component(CUTEX_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)

set(CUTE_MACA_ROOT "" CACHE PATH "MACA toolkit root, e.g. /opt/maca-3.5.3.")
set(CUTE_MACA_OFFLOAD_ARCH "" CACHE STRING "Optional MACA offload architecture.")
set(CUTE_MACA_EXTRA_COMPILE_OPTIONS "" CACHE STRING "Additional options for the MACA compiler.")
set(CUTE_MACA_EXTRA_LINK_OPTIONS "" CACHE STRING "Additional link options for the MACA compiler.")

add_library(cute_maca_headers INTERFACE)
target_include_directories(cute_maca_headers INTERFACE "${CUTEX_ROOT}/include")

set(CUTE_MACA_DEVICE_OPTIONS -x maca)
set(CUTE_MACA_LINK_DRIVER_OPTIONS)

if(CUTE_MACA_ROOT)
  target_include_directories(cute_maca_headers INTERFACE
    "${CUTE_MACA_ROOT}/include"
    "${CUTE_MACA_ROOT}/tools/cu-bridge/include"
    "${CUTE_MACA_ROOT}/tools/cu-bridge/include/cuda")
  list(APPEND CUTE_MACA_DEVICE_OPTIONS "--maca-path=${CUTE_MACA_ROOT}")
  list(APPEND CUTE_MACA_LINK_DRIVER_OPTIONS "--maca-path=${CUTE_MACA_ROOT}")
endif()

if(CUTE_MACA_OFFLOAD_ARCH)
  list(APPEND CUTE_MACA_DEVICE_OPTIONS "--offload-arch=${CUTE_MACA_OFFLOAD_ARCH}")
  list(APPEND CUTE_MACA_LINK_DRIVER_OPTIONS "--offload-arch=${CUTE_MACA_OFFLOAD_ARCH}")
endif()

if(CUTE_MACA_EXTRA_COMPILE_OPTIONS)
  separate_arguments(CUTE_MACA_EXTRA_COMPILE_OPTIONS_LIST NATIVE_COMMAND "${CUTE_MACA_EXTRA_COMPILE_OPTIONS}")
  list(APPEND CUTE_MACA_DEVICE_OPTIONS ${CUTE_MACA_EXTRA_COMPILE_OPTIONS_LIST})
endif()

set(CUTE_MACA_LINK_OPTIONS)
if(CUTE_MACA_EXTRA_LINK_OPTIONS)
  separate_arguments(CUTE_MACA_EXTRA_LINK_OPTIONS_LIST NATIVE_COMMAND "${CUTE_MACA_EXTRA_LINK_OPTIONS}")
  list(APPEND CUTE_MACA_LINK_OPTIONS ${CUTE_MACA_EXTRA_LINK_OPTIONS_LIST})
endif()

add_executable(cute_maca_sgemm_1 sgemm_1.maca)
set_source_files_properties(sgemm_1.maca PROPERTIES LANGUAGE CXX)
target_link_libraries(cute_maca_sgemm_1 PRIVATE cute_maca_headers)
target_compile_options(cute_maca_sgemm_1 PRIVATE ${CUTE_MACA_DEVICE_OPTIONS})
target_link_options(cute_maca_sgemm_1 PRIVATE ${CUTE_MACA_LINK_DRIVER_OPTIONS} ${CUTE_MACA_LINK_OPTIONS})
