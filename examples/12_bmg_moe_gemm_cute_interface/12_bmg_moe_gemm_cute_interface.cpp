/***************************************************************************************************
 * Copyright (c) 2025 Intel Corporation. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *this list of conditions and the following disclaimer.
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
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 *LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief CUTLASS Intel BMG MoE API example based on sycl-tla Group GEMM

*/

#include "cutlass/util/GPU_Clock.hpp"

#include <cute/tensor.hpp>
#include <random>

#include <cute/util/compat.hpp>
#include <sycl/ext/intel/experimental/grf_size_properties.hpp>
#include <sycl/sycl.hpp>

#include <cute/tensor.hpp>

#include "cutlass/kernel_hardware_info.h"
#include "cutlass/platform/platform.h"
#include "cutlass/tensor_ref.h"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/initialize_block.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/sycl_event_manager.hpp"

#include "moe_grouped_gemm.hpp"
#include "moe_tile_scheduler.hpp"

#pragma clang diagnostic ignored "-Wpass-failed"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

using namespace cute;
using namespace MoE;

using ElementAccumulator = float; // <- data type of accumulator

struct VerificationHelper {

  bool error = false;
  bool help = false;

  float alpha = 1.f;
  float beta = 0.f;
  int iterations;
  int m = 0, n = 0, k = 0, groups;
  int *num_rows_per_expert = nullptr;
  std::vector<typename MoE::ProblemShape::UnderlyingProblemShape>
      problem_sizes_host;

  VerificationHelper()
      : error(false), help(false), alpha(1.f), beta(0.f), iterations(100) {}

  void parse(const int num_experts, const int *num_tokens_per_expert_host,
             int moe_n, int moe_k,
             const int *num_tokens_per_expert_device = nullptr) {
    n = moe_n;
    k = moe_k;
    groups = num_experts;
    iterations = 2;
    num_rows_per_expert = const_cast<int *>(num_tokens_per_expert_device);
    assert(groups > 0);
    problem_sizes_host.clear();
    problem_sizes_host.reserve(groups);
    for (int i = 0; i < groups; i++) {
      problem_sizes_host.push_back({num_tokens_per_expert_host[i], n, k});
      m += num_tokens_per_expert_host[i];
    }
  }

  /// Compute performance in GFLOP/s
  std::tuple<double, double, double>
  gflops(double runtime_s,
         std::vector<typename MoE::ProblemShape::UnderlyingProblemShape>
             problem_sizes_host) const {
    // Number of real-valued multiply-adds
    uint64_t fmas = uint64_t();
    uint64_t bytes_loaded = 0;

    for (auto const &problem : problem_sizes_host) {
      auto M = static_cast<uint64_t>(get<0>(problem));
      auto N = static_cast<uint64_t>(get<1>(problem));
      auto K = static_cast<uint64_t>(get<2>(problem));
      fmas += M * N * K;
      bytes_loaded +=
          /* sizeof(cutlass::bfloat16_t) */ 2 * (2 * M * N + N * K + M * K);
    }
    // Two flops per multiply-add
    uint64_t flop = uint64_t(2) * uint64_t(fmas);
    double gflop = double(flop) / double(1.0e9);
    double arithmetic_intensity = double(flop) / double(bytes_loaded);
    double peak_mwm_bw = 456.0;
    double gflops_attainable = std::min<double>(
        117 * double(1.0e12),
        arithmetic_intensity * (peak_mwm_bw * 1024 * 1024 * 1024));
    double projected_time = flop / gflops_attainable;
    return std::make_tuple(gflop / runtime_s,
                           double(bytes_loaded) / 1024 / 1024 / 1024 /
                               runtime_s,
                           projected_time * 1000);
  }

  template <class ElementA, class ElementB, class ElementD,
            class = std::enable_if_t<
                is_any_of_v<ElementA, cute::bfloat16_t, cute::half_t> &&
                is_any_of_v<ElementB, cute::bfloat16_t, cute::half_t> &&
                is_any_of_v<ElementD, cute::bfloat16_t, cute::half_t>>>
  bool verify(const ElementA *activations, const ElementB *weights,
              ElementD *outputs) {
    cutlass::DeviceAllocation<ElementD> output_ref;
    cutlass::DeviceAllocation<ElementD> unused_c_matrix;
    output_ref.reset(m * n);
    unused_c_matrix.reset(m * n);
    using LayoutA = cutlass::layout::RowMajor;
    using LayoutB = cutlass::layout::RowMajor;
    using LayoutC = cutlass::layout::RowMajor;
    using LayoutD = cutlass::layout::RowMajor;
    bool passed = true;
    // Verify against individual reference GEMMs
    int cumulative_sum = 0;
    for (int32_t i = 0; i < groups; ++i) {
      auto problem = problem_sizes_host.at(i);
      auto M = get<0>(problem);
      cutlass::TensorRef ref_A(activations + cumulative_sum * k,
                               LayoutA::packed({M, k}));
      cutlass::TensorRef ref_B(weights + i * n * k, LayoutB::packed({k, n}));
      cutlass::TensorRef ref_C(unused_c_matrix.get() + cumulative_sum * n,
                               LayoutC::packed({M, n}));
      cutlass::TensorRef ref_D(output_ref.get() + cumulative_sum * n,
                               LayoutD::packed({M, n}));

      //
      // Compute reference output
      //
      cutlass::reference::device::GemmComplex(
          {M, n, k}, 1.0, ref_A, cutlass::ComplexTransform::kNone, ref_B,
          cutlass::ComplexTransform::kNone, 0.0, ref_C, ref_D,
          ElementAccumulator(0),
          1,     // batch_count
          M * k, // batch_stride_A
          k * n, // batch_stride_B
          M * n, // batch_stride_C
          M * n  // batch_stride_D
      );

      // Wait for kernel to finish
      compat::wait();

      // Check if output from CUTLASS kernel and reference kernel are equal or
      // not
      passed &= cutlass::reference::device::BlockCompareEqual(
          output_ref.get() + cumulative_sum * n, outputs + cumulative_sum * n,
          M * n);
      if (!passed) {
        break;
      }
      cumulative_sum += M;
    }
    return passed;
  }
};
///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename T, size_t = 0> struct is_complete : std::false_type {};

template <typename T> struct is_complete<T, 0 * sizeof(T)> : std::true_type {};

template <typename T>
static constexpr bool is_complete_v = is_complete<T>::value;

template <class TA, class TB> auto choose_tiled_mma(TA *A, TB *B) {
  using TA_non_CV = cutlass::platform::remove_cv_t<TA>;
  using TB_non_CV = cutlass::platform::remove_cv_t<TB>;
  auto op = XE_DPAS_TT<8, float, TA_non_CV, TB_non_CV>{};

  using WGTile = Shape<_256, _128, _32>; // 256x128 WG tile size
  using SGLayout =
      Layout<Shape<_8, _2, _1>, Stride<_2, _1, _0>>; // 8x2 SG tiling, n-major

  using MMA = typename TiledMMAHelper<MMA_Atom<decltype(op)>, Layout<WGTile>,
                                      SGLayout>::TiledMMA;

  return MMA{};
}

// type tag to define a unique sycl kernel name
template <typename, typename, typename, char, char> class GemmCuteName;

template <char layoutA, char layoutB, typename ElementA, typename ElementB,
          typename ElementS, typename ElementD>
void MoEGEMMLauncher(const ElementA *activations, const ElementB *weights,
                     const ElementS *scales, ElementD *outputs,
                     const int gemm_n, const int gemm_k,
                     const int *num_rows_per_expert_device,
                     const int *num_tokens_per_expert_host,
                     const int num_experts) {
  // Change device_id to another value if you are running on a machine with
  // multiple GPUs and wish to use a GPU other than that with device ID 0.
  // For example, in a framework, you could query device ID.
  int sm_count =
      cutlass::KernelHardwareInfo::query_device_multiprocessor_count(0);
  cutlass::KernelHardwareInfo hw_info{0, sm_count};
  auto dummy_problem_shape = cute::Shape<int, int, int>{1, gemm_k, gemm_n};
  // The GroupedGEMM API requires creation of  a vector of ProblemShape objects
  // for each GEMM problem, which is used in the GroupedGEMM tile-scheduler. If
  // there are 32 groups, then a vector of 32 `ProblemShape` objects is created.
  // Since these would not be known at compile time for a framework, they would
  // have to be created at run-time instead. However, for MoEGEMM, I just
  // provide one dummy shape, and then the custom code in tile scheduler can
  // derive the shape of each GEMM problem.
  auto dummy_group_problem_shape =
      cutlass::gemm::GroupProblemShape<Shape<int, int, int>>{
          1, &dummy_problem_shape, nullptr};
  using TileShape = Shape<_256, _128, _32>;
  using ClusterShape = Shape<_1, _1, _1>;
  auto scheduler_params =
      PersistentTileSchedulerXeMoE<ProblemShape>::to_underlying_arguments(
          dummy_group_problem_shape, TileShape{}, ClusterShape{}, hw_info,
          PersistentTileSchedulerXeMoE<ProblemShape>::Arguments{
              1, RasterOrderOptions::AlongN});
  auto group_distribution =
      PersistentTileSchedulerXeMoE<ProblemShape>::get_grid_shape(
          scheduler_params, dummy_group_problem_shape, TileShape{},
          ClusterShape{}, hw_info,
          PersistentTileSchedulerXeMoE<ProblemShape>::Arguments{
              1, RasterOrderOptions::AlongN});
  auto mma = choose_tiled_mma(activations, weights);
  auto MaxThreadsPerWorkgroup = size(mma);
  dim3 local_range{MaxThreadsPerWorkgroup, 1, 1};

  sycl::range<3> local = {local_range.z, local_range.y, local_range.x};
  sycl::range<3> groups = {group_distribution.z, group_distribution.y,
                           group_distribution.x};
  sycl::range<3> global = {local[0] * groups[0], local[1] * groups[1],
                           local[2] * groups[2]};

  namespace syclex = sycl::ext::oneapi::experimental;
  namespace intelex = sycl::ext::intel::experimental;

  syclex::properties kernel_props{syclex::sub_group_size<16>,
                                  intelex::grf_size<256>};
  sycl::queue Q = compat::get_default_queue();

  GPU_Clock timer;
  timer.start();
  auto event = Q.parallel_for<
      GemmCuteName<ElementA, ElementB, ElementD, layoutA, layoutB>>(
      sycl::nd_range<3>(global, local), kernel_props, [=](auto) {
        // Can also use void for copy atoms.
        // In that case, they will be chosen automatically.
        MoE::MoEGEMM<XE_LOAD_2D<16, 32, 32, 16>,
                     XE_LOAD_2D_VNNI<16, 32, 16, 16>, XE_STORE_2D<16, 8, 32>,
                     'R', 'R', 'R'>(activations, weights, scales, outputs, mma,
                                    num_rows_per_expert_device, num_experts,
                                    gemm_n, gemm_k, scheduler_params);
      });
  EventManager::getInstance().addEvent(event);
  Q.wait_and_throw();
  float cute_time = timer.seconds() * 1000;
  double cute_average_time = double(cute_time);

  VerificationHelper helper;
  helper.parse(num_experts, num_tokens_per_expert_host, gemm_n, gemm_k);
  if (helper.verify(activations, weights, outputs) == false) {
    std::cout << "\n\nFailed accuracy verification :(\n\n";
  }

  auto [gflops, mem_bw_util, projected_time] =
      helper.gflops(cute_average_time / 1000.0, helper.problem_sizes_host);

  std::cout << "  Problem Sizes" << std::endl;
  for (int32_t i = 0; i < num_experts; ++i) {
    std::cout << "    " << num_tokens_per_expert_host[i] << std::endl;
  }
  std::cout << "  N      : " << gemm_n << std::endl;
  std::cout << "  K      : " << gemm_k << std::endl;
  std::cout << "  Groups      : " << num_experts << std::endl;
  std::cout << "  Avg runtime : " << cute_average_time << " ms" << std::endl;
  std::cout << "  GFLOPS      : " << gflops << std::endl;
  std::cout << "  Memory BW utilization : " << mem_bw_util << "  GBPs"
            << std::endl;
}

void launcher(int *M_per_expert, int N, int K, const int &num_experts) {
  int n_moe = N;
  int k_moe = K;
  int num_tokens_incl_duplicated = 0;
  for (int i = 0; i < num_experts; i++) {
    num_tokens_incl_duplicated += M_per_expert[i];
  }

  float M_occupancy = 0.f;
  float actual_num_units = 0.f;
  int total_num_M_tiles = 0;
  for (int i = 0; i < num_experts; i++) {
    total_num_M_tiles += (M_per_expert[i] + 255) / 256;
    actual_num_units += M_per_expert[i] / 256.0;
  }
  M_occupancy = actual_num_units / total_num_M_tiles;
  std::cout << "\n\n M-occupancy is " << M_occupancy << std::endl;
  cutlass::DeviceAllocation<int32_t> num_rows_per_expert_device;
  cutlass::DeviceAllocation<bfloat16_t> activations_data;
  cutlass::DeviceAllocation<bfloat16_t> weights_data;
  cutlass::DeviceAllocation<bfloat16_t> output_data;
  size_t A_size = num_tokens_incl_duplicated * k_moe;
  size_t B_size = num_experts * n_moe * k_moe;
  size_t D_size = num_tokens_incl_duplicated * n_moe;
  num_rows_per_expert_device.reset(num_experts);
  num_rows_per_expert_device.copy_from_host(M_per_expert);
  activations_data.reset(A_size);
  weights_data.reset(B_size);
  output_data.reset(D_size);
  uint64_t seed = 2023;
  initialize_block(activations_data, seed + 2023);
  initialize_block(weights_data, seed + 2022);
  initialize_block(output_data, seed + 2021);

  MoEGEMMLauncher<'R', 'R'>(activations_data.get(), weights_data.get(),
                            static_cast<void *>(nullptr), output_data.get(),
                            n_moe, k_moe, num_rows_per_expert_device.get(),
                            M_per_expert, num_experts);
}

int main(int argc, const char **argv) {
  constexpr int num_experts = 32;
  constexpr int num_layers = 24;

  int total_rows_for_each_expert[num_layers][num_experts] = {
      {148, 231, 404, 180, 127, 244, 224, 244, 110, 617, 289,
       845, 191, 424, 30,  97,  57,  324, 62,  77,  75,  144,
       250, 287, 629, 370, 161, 101, 215, 113, 224, 35},
      {666, 214, 448, 87, 4,   28,  48,  13,  74,  40,  546,
       397, 487, 350, 26, 95,  517, 487, 295, 58,  637, 97,
       139, 33,  126, 15, 352, 311, 995, 193, 135, 135},
      {1016, 30,  36, 452, 469, 473, 232, 0,   493, 14,  954,
       6,    4,   6,  279, 3,   94,  106, 96,  48,  49,  113,
       142,  169, 75, 99,  25,  220, 249, 289, 4,   1803},
      {350, 229,  703, 154,  8,  64,  80, 339, 2,   56,  5,
       312, 1005, 29,  9,    11, 23,  0,  23,  431, 48,  129,
       496, 476,  8,   1234, 7,  130, 34, 58,  41,  1554},
      {39, 10,  6,    2,   110, 1,  894, 8,    53,  0,   275,
       6,  506, 421,  700, 178, 0,  530, 1623, 15,  231, 74,
       6,  222, 1246, 116, 35,  20, 0,   6,    381, 334},
      {399, 5,  201, 6,   134, 93,  1748, 1,   51,  4,   38,
       336, 53, 88,  328, 724, 15,  388,  706, 52,  19,  55,
       52,  33, 623, 1,   222, 215, 69,   45,  308, 1036},
      {11,  8,   407, 571, 458, 275,  197, 211, 13,  564, 462,
       114, 15,  13,  132, 24,  514,  2,   71,  13,  694, 47,
       16,  203, 610, 40,  0,   1587, 66,  23,  196, 491},
      {0,  230, 116, 136, 315,  643, 6,   183, 37,  26,  960,
       1,  8,   258, 21,  1602, 213, 198, 6,   196, 455, 557,
       47, 282, 493, 18,  101,  11,  616, 45,  268, 0},
      {392, 305,  179, 14, 227, 98,  114, 39, 64,  1456, 465,
       0,   18,   372, 0,  0,   189, 257, 25, 290, 486,  0,
       12,  1534, 468, 4,  555, 35,  146, 0,  161, 143},
      {4,  107, 20,   125, 236,  898,  0, 0,   375, 2,  125,
       0,  0,   1429, 36,  195,  1660, 0, 127, 454, 73, 358,
       47, 79,  32,   20,  1465, 0,    0, 6,   109, 66},
      {19, 0, 0,  0,    2, 1638, 75, 135, 392, 2,   1494, 3, 23,  5,  4,   58,
       0,  0, 71, 1285, 8, 441,  0,  145, 209, 408, 450,  2, 824, 13, 326, 16},
      {4,  2, 14,  0, 30,  206, 41, 131, 0,   429,  16, 895, 35, 21, 44,   128,
       12, 0, 417, 0, 838, 917, 42, 115, 109, 1759, 0,  36,  17, 0,  1790, 0},
      {6, 483, 241, 1327, 17,  11, 480, 9,  880, 58, 4,
       0, 61,  30,  16,   176, 9,  309, 26, 0,   0,  1882,
       4, 281, 475, 783,  197, 0,  19,  15, 6,   243},
      {370,  1222, 0, 6,   108, 929,  2, 7, 157, 348, 149, 106, 2, 5,  25, 33,
       1569, 8,    6, 106, 69,  1298, 0, 2, 529, 520, 0,   421, 0, 25, 26, 0},
      {59,  89,   0,  26,  25,  40,   1873, 141, 527, 371, 262,
       62,  16,   0,  127, 234, 1637, 64,   132, 8,   0,   7,
       161, 1005, 22, 1,   49,  6,    83,   925, 80,  16},
      {269,  617, 30,  4,   90,  26,  0,   16,  154, 212, 21,
       269,  379, 174, 129, 32,  8,   121, 344, 15,  0,   591,
       1494, 6,   737, 50,  112, 856, 483, 25,  454, 330},
      {0,   98,  1488, 22,  73, 0,    0, 343, 77,  4,   0,
       612, 165, 268,  4,   10, 43,   0, 598, 271, 2,   73,
       185, 0,   112,  779, 24, 1626, 0, 0,   0,   1171},
      {0,   0,  0, 189, 266, 1743, 0, 462, 20,   7, 668, 310, 40, 0, 10,  236,
       423, 18, 0, 0,   0,   999,  0, 139, 1754, 8, 619, 3,   23, 0, 102, 9},
      {131, 1753, 0,   113,  24,  94, 2,    12,  108, 0,  0,
       252, 97,   0,   1319, 233, 93, 1254, 195, 152, 14, 413,
       4,   2,    220, 67,   20,  4,  34,   559, 837, 42},
      {55, 76, 0,  8,   0, 3,  1557, 975, 135, 271, 4,   0, 0,   666, 207, 152,
       5,  2,  97, 364, 0, 13, 1423, 771, 159, 31,  223, 0, 431, 7,   409, 4},
      {4,  1026, 1799, 166, 694, 753, 0,  16, 0,  240, 1119, 19, 6,  0, 46, 659,
       10, 0,    112,  808, 181, 0,   28, 22, 90, 0,   176,  0,  37, 5, 10, 22},
      {44, 0, 4, 153, 299, 1357, 6, 23,   0,    12, 4,   419, 73, 24, 16,  24,
       1,  4, 4, 102, 16,  4,    0, 1953, 1850, 0,  908, 4,   0,  13, 708, 23},
      {6, 13, 123, 28, 197,  0, 202, 69,   0, 6,  0,  21, 1434, 1582, 11, 0, 6,
       0, 7,  190, 4,  1700, 6, 434, 1886, 0, 14, 28, 8,  30,   25,   18},
      {5,  27, 1442, 18, 0,  6, 0, 73,  6,    781, 0,  1915, 291, 649, 98,  4,
       33, 77, 6,    22, 73, 9, 8, 587, 1486, 32,  10, 244,  37,  0,   100, 9}
       };

  for (int i = 0; i < num_layers; i++) {
    launcher(total_rows_for_each_expert[i], 5760, 2880, num_experts);
    launcher(total_rows_for_each_expert[i], 2880, 2880, num_experts);
  }

  return 0;
}
