/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "../../common/cutlass_unit_test.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#include "cutlass/cutlass.h"
#include "cutlass/conv/kernel/default_conv2d_fprop_fusion.h"
#include "cutlass/conv/kernel/default_conv3d_fprop_fusion.h"
#include "cutlass/conv/device/implicit_gemm_convolution_fusion.h"
#include "cutlass/util/host_tensor.h"

#if defined(CUTLASS_ARCH_MMA_SM80_SUPPORTED)

namespace {

using Half = cutlass::half_t;
using Algorithm = cutlass::conv::IteratorAlgorithm;
using Tile = cutlass::gemm::GemmShape<128, 128, 32>;
using Warp = cutlass::gemm::GemmShape<64, 64, 32>;
using Instruction = cutlass::gemm::GemmShape<16, 8, 16>;
using Epilogue = cutlass::epilogue::thread::LinearCombination<float, 4, float, float>;
using Swizzle = cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>;

template <int Dim, Algorithm Algo> struct Configuration;
template <Algorithm Algo> struct Configuration<2, Algo> {
  using Layout = cutlass::layout::TensorNHWC;
  using Problem = cutlass::conv::Conv2dProblemSize;
  using Kernel = typename cutlass::conv::kernel::DefaultConv2dFpropFusion<
      Half, Layout, Half, Layout, Half, cutlass::layout::RowMajor,
      float, Layout, float, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm80,
      Tile, Warp, Instruction, Epilogue, Swizzle, 4,
      cutlass::arch::OpMultiplyAdd, Algo>::Kernel;
  static Problem problem(int channels, int split, int filter) {
    return Problem({1, 5, 5, channels}, {32, filter, filter, channels},
                   {0, 0, 0, 0}, {1, 1}, {1, 1},
                   cutlass::conv::Mode::kCrossCorrelation, split);
  }
};
template <Algorithm Algo> struct Configuration<3, Algo> {
  using Layout = cutlass::layout::TensorNDHWC;
  using Problem = cutlass::conv::Conv3dProblemSize;
  using Kernel = typename cutlass::conv::kernel::DefaultConv3dFpropFusion<
      Half, Layout, Half, Layout, Half, cutlass::layout::RowMajor,
      float, Layout, float, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm80,
      Tile, Warp, Instruction, Epilogue, Swizzle, 4,
      cutlass::arch::OpMultiplyAdd, Algo>::Kernel;
  static Problem problem(int channels, int split, int filter) {
    return Problem({1, 5, 5, 5, channels}, {32, filter, filter, filter, channels},
                   cutlass::make_Coord(0, 0, 0), cutlass::make_Coord(1, 1, 1),
                   cutlass::make_Coord(1, 1, 1),
                   cutlass::conv::Mode::kCrossCorrelation, split);
  }
};

void check(cutlass::Status status) {
  if (status != cutlass::Status::kSuccess)
    throw std::runtime_error(cutlassGetStatusString(status));
}
void check(cudaError_t status) {
  if (status != cudaSuccess) throw std::runtime_error(cudaGetErrorString(status));
}

template <int Dim, Algorithm Algo>
bool run(int channels, int split, int filter) {
  using Config = Configuration<Dim, Algo>;
  using Conv = cutlass::conv::device::ImplicitGemmConvolutionFusion<typename Config::Kernel>;
  using Layout = typename Config::Layout;
  auto problem = Config::problem(channels, split, filter);
  cutlass::HostTensor<Half, Layout> a(problem.activation_extent());
  cutlass::HostTensor<Half, Layout> b(problem.filter_extent());
  cutlass::HostTensor<Half, cutlass::layout::RowMajor> scale({1, channels}), bias({1, channels});
  cutlass::HostTensor<float, Layout> c(problem.output_extent()), d(problem.output_extent());
  for (int ch = 0; ch < channels; ++ch) {
    scale.host_data()[ch] = Half(1 + (ch / 32) % 4);
    bias.host_data()[ch] = Half((ch / 32) % 7 - 3);
  }
  // Small integer operands keep the reference and half transform exactly representable.
  for (int i = 0; i < a.size(); ++i) a.host_data()[i] = Half((i * 7 + i / channels) % 9 - 4);
  for (int i = 0; i < b.size(); ++i) b.host_data()[i] = Half((i * 3 + i / channels) % 5 - 2);
  for (int i = 0; i < c.size(); ++i) { c.host_data()[i] = float(i % 7 - 3); d.host_data()[i] = -12345; }
  a.sync_device(); b.sync_device(); scale.sync_device(); bias.sync_device(); c.sync_device(); d.sync_device();
  typename Conv::Arguments args(problem, a.device_ref(), b.device_ref(), scale.device_ref(),
      bias.device_ref(), c.device_ref(), d.device_ref(), {1, 1},
      cutlass::conv::SplitKMode::kSerial);
  Conv conv;
  check(conv.can_implement(args));
  cutlass::device_memory::allocation<uint8_t> workspace(conv.get_workspace_size(args));
  check(conv.initialize(args, workspace.get()));
  check(conv()); check(cudaDeviceSynchronize());
  d.sync_host();
  // Independent direct convolution over transformed activations; no split-K index formulas.
  int depth = Dim == 3 ? 5 : 1, ft = Dim == 3 ? filter : 1;
  int out_depth = depth - ft + 1, out_hw = 6 - filter;
  int mismatches = 0; float max_error = 0, first_got = 0, first_expected = 0;
  for (int z = 0; z < out_depth; ++z)
    for (int p = 0; p < out_hw; ++p)
      for (int q = 0; q < out_hw; ++q)
        for (int k = 0; k < 32; ++k) {
          int out = ((z * out_hw + p) * out_hw + q) * 32 + k;
          float expected = c.host_data()[out];
          for (int t = 0; t < ft; ++t)
            for (int r = 0; r < filter; ++r)
              for (int s = 0; s < filter; ++s)
                for (int ch = 0; ch < channels; ++ch) {
                  int ai = (((z + t) * 5 + p + r) * 5 + q + s) * channels + ch;
                  int bi = (((k * ft + t) * filter + r) * filter + s) * channels + ch;
                  float transformed = std::max(0.0f, float(a.host_data()[ai]) *
                      float(scale.host_data()[ch]) + float(bias.host_data()[ch]));
                  expected += float(Half(transformed)) * float(b.host_data()[bi]);
                }
          float got = d.host_data()[out];
          if (got != expected) {
            if (mismatches == 0) { first_got = got; first_expected = expected; }
            ++mismatches; max_error = std::max(max_error, std::abs(got - expected));
          }
        }
  EXPECT_EQ(mismatches, 0) << "dim=" << Dim << " algorithm=" << int(Algo)
      << " C=" << channels << " split_k=" << split << " filter=" << filter
      << " first output=" << first_got << " expected=" << first_expected
      << " max error=" << max_error;
  return mismatches == 0;
}

template <int Dim, Algorithm Algo> int suite() {
  int failures = 0;
  for (auto cfg : std::vector<std::vector<int>>{{32,1,1},{256,1,3},{64,2,3},{128,4,3},
                                               {256,2,3},{256,4,3},{272,4,3},{256,4,1}})
    failures += !run<Dim, Algo>(cfg[0], cfg[1], cfg[2]);
  return failures;
}

}  // namespace

TEST(SM80_Device_Conv_FpropFusion, SplitK2dAnalytic) {
  EXPECT_EQ((suite<2, Algorithm::kAnalytic>()), 0);
}
TEST(SM80_Device_Conv_FpropFusion, SplitK2dOptimized) {
  EXPECT_EQ((suite<2, Algorithm::kOptimized>()), 0);
}
TEST(SM80_Device_Conv_FpropFusion, SplitK3dAnalytic) {
  EXPECT_EQ((suite<3, Algorithm::kAnalytic>()), 0);
}
TEST(SM80_Device_Conv_FpropFusion, SplitK3dOptimized) {
  EXPECT_EQ((suite<3, Algorithm::kOptimized>()), 0);
}

#endif  // CUTLASS_ARCH_MMA_SM80_SUPPORTED
