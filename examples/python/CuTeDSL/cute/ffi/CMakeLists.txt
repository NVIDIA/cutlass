# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

cmake_minimum_required(VERSION 3.15)
project(tensor)

# Find Python
find_package(Python COMPONENTS Interpreter Development REQUIRED)
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

# Get Python site-packages directory using Python
execute_process(
    COMMAND ${Python3_EXECUTABLE} -c "import sys, sysconfig; print(';'.join([sysconfig.get_paths()['purelib'],sysconfig.get_paths(vars={'base': sys.base_prefix, 'platbase': sys.base_prefix})['purelib']]))"
    OUTPUT_VARIABLE Python_SITE_PACKAGES_PATHS
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

message(STATUS "Python site-packages directories: ${Python_SITE_PACKAGES_PATHS}")

# Add nanobind path to CMAKE_PREFIX_PATH
foreach(path IN LISTS Python_SITE_PACKAGES_PATHS)
    if(EXISTS "${path}/nanobind/cmake")
        message(STATUS "Adding nanobind cmake path: ${path}/nanobind/cmake")
        list(APPEND CMAKE_PREFIX_PATH "${path}/nanobind/cmake")
        break()
    endif()
endforeach()

# Find nanobind
find_package(nanobind)
if(NOT nanobind_FOUND)
    message(FATAL_ERROR
        "nanobind not found!\n"
        "Please install nanobind with: pip install nanobind\n"
    )
endif()

# Add the module
nanobind_add_module(tensor tensor.cpp)
