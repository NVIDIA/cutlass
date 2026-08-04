// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// Use of this software is governed by the terms and conditions of the
// NVIDIA End User License Agreement (EULA), available at:
// https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
//
// Any use, reproduction, disclosure, or distribution of this software
// and related documentation outside the scope permitted by the EULA
// is strictly prohibited.

#include <nanobind/nanobind.h>
#include <nanobind/stl/string.h>
#include <string>

namespace nb = nanobind;

#ifndef CUDA_VERSION
#error "CUDA_VERSION must be defined at compile time"
#endif

#define STRINGIFY(x) #x
#define TO_STRING(x) STRINGIFY(x)

std::string GetCudaVersion() {
  return TO_STRING(CUDA_VERSION);
}

void populateBaseDSLBindingAPISubmodule(nb::module_ &m) {
  m.doc() = "Base DSL binding APIs";
  
  m.def("get_cuda_version", &GetCudaVersion,
        "Get the CUDA version string that was used to build DSL");
}
