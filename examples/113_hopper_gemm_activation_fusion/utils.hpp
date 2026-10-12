/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
#pragma once

#include <string>

#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/epilogue/thread/activation.h"
#include "cutlass/epilogue/collective/collective_builder.hpp"

template <class Schedule>
std::string kernel_schedule_string() {
  if constexpr (cute::is_base_of_v<cutlass::gemm::KernelTmaWarpSpecialized, Schedule>) {
    return "Non-persistent";
  }
  else if constexpr (cute::is_base_of_v<cutlass::gemm::KernelTmaWarpSpecializedPingpong, Schedule> ||
                     cute::is_base_of_v<cutlass::gemm::KernelPtrArrayTmaWarpSpecializedPingpong, Schedule>) {
    return "Pingpong";
  }
  else if constexpr (cute::is_base_of_v<cutlass::gemm::KernelTmaWarpSpecializedCooperative, Schedule> ||
                     cute::is_base_of_v<cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperative, Schedule>) {
    return "Cooperative";
  }
  else {
    return "Unknown";
  }
}

template <template <class> class ActFn>
std::string activation_func_string() {
  if constexpr (cute::is_same_v<cutlass::epilogue::thread::ReLu<float>, ActFn<float>>) {
    return "ReLU";
  }
  else if constexpr (cute::is_same_v<cutlass::epilogue::thread::SiLu<float>, ActFn<float>>) {
    return "SiLU";
  }
  else if constexpr (cute::is_same_v<cutlass::epilogue::thread::Identity<float>, ActFn<float>>) {
    return "None";
  }
  else {
    return "Unknown";
  }
}

template <class Shape>
std::string shape_string(Shape shape = {}) {
  std::stringstream ss;
  cute::for_each(shape, [&](auto s) { ss << 'x' << int(cute::size(s)); });
  return ss.str().substr(1);
}

template <class EpiTile>
std::string epilogue_tile_string(EpiTile = {}) {
  if constexpr (cute::is_same_v<cutlass::epilogue::collective::EpilogueTileAuto, EpiTile>) {
    return "Auto";
  }
  else if (cute::is_tuple_v<EpiTile>) {
    return shape_string(EpiTile{});
  }
  else {
    return "Unknown";
  }
}

template <class Element>
std::string data_type_string(Element = {}) {
  if constexpr (cute::is_same_v<cutlass::float_e4m3_t, Element> || cute::is_same_v<cutlass::float_e5m2_t, Element>) {
    return "fp8";
  }
  else if (cute::is_same_v<cutlass::half_t, Element>) {
    return "fp16";
  }
  else if (cute::is_same_v<cutlass::bfloat16_t, Element>) {
    return "bf16";
  }
  else if (cute::is_same_v<float, Element>) {
    return "fp32";
  }
  else if (cute::is_same_v<cutlass::tfloat32_t, Element>) {
    return "tf32";
  }
  else if (cute::is_same_v<cutlass::int4b_t, Element> || cute::is_same_v<cutlass::uint4b_t, Element>) {
    return "int4";
  }
  else if (cute::is_same_v<int8_t, Element> || cute::is_same_v<uint8_t, Element>) {
    return "int8";
  }
  else if (cute::is_same_v<int, Element> || cute::is_same_v<unsigned int, Element>) {
    return "int32";
  }
  else {
    return "Unknown";
  }
}

template <class ElementA, class ElementB, class ElementAcc, class ElementC, class ElementD>
std::string problem_desc_string(ElementA = {}, ElementB = {}, ElementAcc = {}, ElementC = {}, ElementD = {}) {
  return data_type_string<ElementA>() + " x " +
         data_type_string<ElementB>() + " -> " +
         data_type_string<ElementAcc>() + " + " +
         data_type_string<ElementC>() + " -> " +
         data_type_string<ElementD>();
}

// Simple wrapper that can initialize and repeatedly run a GEMM. Lives here
// rather than in examples/common/helper.h to avoid colliding with other
// examples (e.g. 62_hopper_sparse_gemm) that define their own Runner with a
// different API. Requires CUTLASS_CHECK (helper.h) and
// cutlass::device_memory::allocation (cutlass/util/device_memory.h) - all
// four 113 examples include both before this header.
template<class Gemm>
struct Runner
{
  using Arguments = typename Gemm::Arguments;

  Runner(Arguments const& args)
  : arguments(args) {
    workspace.reset(Gemm::get_workspace_size(arguments));
    CUTLASS_CHECK(gemm.can_implement(arguments));
  }

  void run() {
    CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
    CUTLASS_CHECK(gemm.run());
  }

  Gemm gemm;
  Arguments arguments;
  cutlass::device_memory::allocation<uint8_t> workspace;
};
