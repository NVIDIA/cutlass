/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 *modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *this list of conditions and the following disclaimer in the documentation
 *and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *may be used to endorse or promote products derived from this software without
 *specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 *FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **************************************************************************************************/

#include <cuda_runtime.h>

#include "cutlass/float_subbyte.h"
#include "cutlass/gemm/device/sm120_nvfp4_w4a16_gemm.h"
#include "cutlass/half.h"
#include "cutlass/layout/nvfp4_w4a16.h"

#include "../../../common/cutlass_unit_test.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

#if defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED) ||                               \
    defined(CUTLASS_ARCH_MMA_SM121_SUPPORTED)

namespace {

using ElementA = cutlass::half_t;
using ElementB = cutlass::float_e2m1_t;
using ElementScale = cutlass::float_ue4m3_t;
using ElementD = float;
using WeightLayout = cutlass::layout::Nvfp4W4a16Weight;

template <class T> class DeviceAllocation {
public:
  DeviceAllocation() = default;
  DeviceAllocation(DeviceAllocation const &) = delete;
  DeviceAllocation &operator=(DeviceAllocation const &) = delete;

  ~DeviceAllocation() {
    if (pointer_ != nullptr) {
      cudaFree(pointer_);
    }
  }

  bool allocate(size_t count) {
    count_ = count;
    return cudaMalloc(reinterpret_cast<void **>(&pointer_),
                      count * sizeof(T)) == cudaSuccess;
  }

  bool copy_from(std::vector<T> const &source) {
    return source.size() == count_ &&
           cudaMemcpy(pointer_, source.data(), count_ * sizeof(T),
                      cudaMemcpyHostToDevice) == cudaSuccess;
  }

  bool copy_to(std::vector<T> &destination) const {
    return destination.size() == count_ &&
           cudaMemcpy(destination.data(), pointer_, count_ * sizeof(T),
                      cudaMemcpyDeviceToHost) == cudaSuccess;
  }

  T *get() const { return pointer_; }

private:
  T *pointer_ = nullptr;
  size_t count_ = 0;
};

struct Problem {
  int m;
  int n;
  int k;
};

float fp16_product(float lhs, float rhs) {
  return static_cast<float>(ElementA(lhs) * ElementA(rhs));
}

ElementB e2m1_from_bits(uint8_t bits) {
  ElementB value;
  value.raw() = bits & 0x0f;
  return value;
}

void initialize_problem(Problem problem, std::vector<ElementA> &activations,
                        std::vector<uint8_t> &packed_weights,
                        std::vector<ElementScale> &scales,
                        std::vector<float> &logical_weights) {
  for (int row = 0; row < problem.m; ++row) {
    for (int k_value = 0; k_value < problem.k; ++k_value) {
      int const centered = (row * 17 + k_value * 13 + 3) % 23 - 11;
      activations[static_cast<size_t>(row) * problem.k + k_value] =
          ElementA(static_cast<float>(centered) / 16.0f);
    }
  }

  constexpr float scale_candidates[] = {0.5f, 0.75f, 1.0f, 1.5f, 2.0f};
  int const scale_blocks =
      static_cast<int>(WeightLayout::scale_blocks(problem.k));
  auto scale_layout = WeightLayout::make_scale_layout(problem.n, problem.k);
  for (int column = 0; column < problem.n; ++column) {
    for (int scale_block = 0; scale_block < scale_blocks; ++scale_block) {
      scales[WeightLayout::scale_offset(scale_layout, column, scale_block)] =
          ElementScale(scale_candidates[(column * 3 + scale_block * 7) % 5]);
    }
  }

  for (int column = 0; column < problem.n; ++column) {
    for (int k_value = 0; k_value < problem.k; k_value += 2) {
      // Exercise every raw E2M1 encoding and make the two nibbles
      // coordinate-dependent.
      ElementB const low =
          e2m1_from_bits(static_cast<uint8_t>(column * 5 + k_value * 3));
      ElementB const high =
          e2m1_from_bits(static_cast<uint8_t>(column * 11 + (k_value + 1) * 7));
      packed_weights[WeightLayout::packed_value_offset(column, k_value,
                                                       problem.k)] =
          static_cast<uint8_t>((low.raw() & 0x0f) | ((high.raw() & 0x0f) << 4));

      int const scale_block = k_value / WeightLayout::kScaleGranularityK;
      float const scale = static_cast<float>(scales[WeightLayout::scale_offset(
          scale_layout, column, scale_block)]);
      logical_weights[static_cast<size_t>(k_value) * problem.n + column] =
          fp16_product(static_cast<float>(low), scale);
      logical_weights[static_cast<size_t>(k_value + 1) * problem.n + column] =
          fp16_product(static_cast<float>(high), scale);
    }
  }
}

std::vector<float> reference_gemm(Problem problem,
                                  std::vector<ElementA> const &activations,
                                  std::vector<float> const &weights) {
  std::vector<float> reference(static_cast<size_t>(problem.m) * problem.n,
                               0.0f);
  for (int row = 0; row < problem.m; ++row) {
    for (int column = 0; column < problem.n; ++column) {
      float accumulator = 0.0f;
      for (int k_value = 0; k_value < problem.k; ++k_value) {
        accumulator +=
            static_cast<float>(
                activations[static_cast<size_t>(row) * problem.k + k_value]) *
            weights[static_cast<size_t>(k_value) * problem.n + column];
      }
      reference[static_cast<size_t>(row) * problem.n + column] = accumulator;
    }
  }
  return reference;
}

template <int TileM>
typename cutlass::gemm::device::Sm120Nvfp4W4a16Gemm<TileM>::Arguments
make_arguments(Problem problem, ElementA const *activations,
               uint8_t const *packed_weights, ElementScale const *scales,
               ElementD *output) {
  using Gemm = cutlass::gemm::device::Sm120Nvfp4W4a16Gemm<TileM>;
  using Mainloop = typename Gemm::CollectiveMainloop;
  typename Mainloop::StrideA stride_a{int64_t(problem.k), cute::_1{},
                                      int64_t(problem.m) * problem.k};
  typename Mainloop::StrideB stride_b{int64_t(problem.k), cute::_1{},
                                      int64_t(problem.n) * problem.k};
  typename Gemm::GemmKernel::StrideC stride_c{int64_t(problem.n), cute::_1{},
                                              int64_t(problem.m) * problem.n};
  typename Gemm::GemmKernel::StrideD stride_d{int64_t(problem.n), cute::_1{},
                                              int64_t(problem.m) * problem.n};
  return typename Gemm::Arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      {problem.m, problem.n, problem.k, 1},
      {activations, stride_a,
       reinterpret_cast<typename Mainloop::ElementB const *>(packed_weights),
       stride_b, scales, WeightLayout::make_scale_layout(problem.n, problem.k)},
      {{1.0f, 0.0f}, nullptr, stride_c, output, stride_d},
      {}};
}

template <int TileM> bool run_case(Problem problem) {
  using Gemm = cutlass::gemm::device::Sm120Nvfp4W4a16Gemm<TileM>;
  std::vector<ElementA> activations(static_cast<size_t>(problem.m) * problem.k);
  std::vector<uint8_t> packed_weights(
      WeightLayout::packed_values_bytes(problem.n, problem.k));
  std::vector<ElementScale> scales(
      WeightLayout::scales_bytes(problem.n, problem.k));
  std::vector<float> logical_weights(static_cast<size_t>(problem.k) *
                                     problem.n);
  std::vector<ElementD> output(static_cast<size_t>(problem.m) * problem.n);
  initialize_problem(problem, activations, packed_weights, scales,
                     logical_weights);
  std::vector<float> const reference =
      reference_gemm(problem, activations, logical_weights);

  DeviceAllocation<ElementA> device_activations;
  DeviceAllocation<uint8_t> device_packed_weights;
  DeviceAllocation<ElementScale> device_scales;
  DeviceAllocation<ElementD> device_output;
  if (!device_activations.allocate(activations.size()) ||
      !device_packed_weights.allocate(packed_weights.size()) ||
      !device_scales.allocate(scales.size()) ||
      !device_output.allocate(output.size()) ||
      !device_activations.copy_from(activations) ||
      !device_packed_weights.copy_from(packed_weights) ||
      !device_scales.copy_from(scales)) {
    return false;
  }

  auto arguments = make_arguments<TileM>(
      problem, device_activations.get(), device_packed_weights.get(),
      device_scales.get(), device_output.get());
  if (Gemm::can_implement(arguments) != cutlass::Status::kSuccess ||
      Gemm{}(arguments) != cutlass::Status::kSuccess ||
      cudaDeviceSynchronize() != cudaSuccess ||
      !device_output.copy_to(output)) {
    return false;
  }

  constexpr float absolute_tolerance = 0.05f;
  constexpr float relative_tolerance = 0.002f;
  for (size_t index = 0; index < output.size(); ++index) {
    float const absolute_error = std::abs(output[index] - reference[index]);
    if (absolute_error >
        absolute_tolerance + relative_tolerance * std::abs(reference[index])) {
      return false;
    }
  }
  return true;
}

bool running_on_supported_device() {
  cudaDeviceProp properties{};
  return cudaGetDeviceProperties(&properties, 0) == cudaSuccess &&
         properties.major == 12 &&
         (properties.minor == 0 || properties.minor == 1);
}

} // namespace

TEST(SM120_Nvfp4W4a16_Layout, PackedValuesAndScalesAreBijective) {
  constexpr int n = 12;
  constexpr int k = 128;
  constexpr int scale_blocks = k / WeightLayout::kScaleGranularityK;
  auto layout = WeightLayout::make_scale_layout(n, k, 2);

  std::vector<bool> seen_scales(static_cast<size_t>(n) * scale_blocks * 2,
                                false);
  for (int batch = 0; batch < 2; ++batch) {
    for (int column = 0; column < n; ++column) {
      for (int block = 0; block < scale_blocks; ++block) {
        int64_t const offset =
            WeightLayout::scale_offset(layout, column, block, batch);
        int64_t const expected =
            int64_t(batch) * n * scale_blocks +
            WeightLayout::scale_offset(column, block, scale_blocks);
        EXPECT_EQ(offset, expected);
        ASSERT_GE(offset, 0);
        ASSERT_LT(static_cast<size_t>(offset), seen_scales.size());
        EXPECT_FALSE(seen_scales[static_cast<size_t>(offset)]);
        seen_scales[static_cast<size_t>(offset)] = true;
      }
    }
  }
  EXPECT_TRUE(std::all_of(seen_scales.begin(), seen_scales.end(),
                          [](bool value) { return value; }));

  std::vector<bool> seen_values(WeightLayout::packed_values_bytes(n, k), false);
  for (int column = 0; column < n; ++column) {
    for (int k_value = 0; k_value < k; k_value += 2) {
      size_t const offset = static_cast<size_t>(
          WeightLayout::packed_value_offset(column, k_value, k));
      EXPECT_FALSE(seen_values[offset]);
      seen_values[offset] = true;
    }
  }
  EXPECT_TRUE(std::all_of(seen_values.begin(), seen_values.end(),
                          [](bool value) { return value; }));
}

TEST(SM120_Nvfp4W4a16_Device, RejectsUnsupportedContracts) {
  using Gemm = cutlass::gemm::device::Sm120Nvfp4W4a16Gemm<64>;
  auto *activations = reinterpret_cast<ElementA const *>(uintptr_t{0x1000});
  auto *weights = reinterpret_cast<uint8_t const *>(uintptr_t{0x2000});
  auto *scales = reinterpret_cast<ElementScale const *>(uintptr_t{0x3000});
  auto *output = reinterpret_cast<ElementD *>(uintptr_t{0x4000});
  auto arguments =
      make_arguments<64>({64, 128, 5120}, activations, weights, scales, output);
  EXPECT_EQ(Gemm::can_implement(arguments), cutlass::Status::kSuccess);

  auto invalid = arguments;
  invalid.problem_shape = {63, 128, 5120, 1};
  EXPECT_EQ(Gemm::can_implement(invalid), cutlass::Status::kInvalid);
  invalid = arguments;
  invalid.problem_shape = {64, 192, 5120, 1};
  EXPECT_EQ(Gemm::can_implement(invalid), cutlass::Status::kInvalid);
  invalid = arguments;
  invalid.problem_shape = {64, 128, 5152, 1};
  EXPECT_EQ(Gemm::can_implement(invalid), cutlass::Status::kInvalid);
  invalid = arguments;
  invalid.mainloop.ptr_A = nullptr;
  EXPECT_EQ(Gemm::can_implement(invalid), cutlass::Status::kInvalid);
}

TEST(SM120_Nvfp4W4a16_Device, M16_K64_AllBitPatterns) {
  if (!running_on_supported_device()) {
    GTEST_SKIP();
  }
  EXPECT_TRUE((run_case<16>({16, 128, 64})));
}

TEST(SM120_Nvfp4W4a16_Device, M64_MultipleNTiles) {
  if (!running_on_supported_device()) {
    GTEST_SKIP();
  }
  EXPECT_TRUE((run_case<64>({64, 256, 128})));
}

TEST(SM120_Nvfp4W4a16_Device, LlamaDenseK5120) {
  if (!running_on_supported_device()) {
    GTEST_SKIP();
  }
  EXPECT_TRUE((run_case<64>({64, 128, 5120})));
}

TEST(SM120_Nvfp4W4a16_Device, LlamaDenseK17408) {
  if (!running_on_supported_device()) {
    GTEST_SKIP();
  }
  EXPECT_TRUE((run_case<16>({16, 128, 17408})));
}

#endif
