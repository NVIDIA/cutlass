/***************************************************************************************************
 * Copyright (c) 2024 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <iostream>

#include "cutlass/cutlass.h"
#include "cute/tensor.hpp"
#include "cute/atom/mma_atom.hpp"

#include "cutlass/numeric_types.h"

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"

#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"

#include "cutlass/epilogue/thread/activation.h"
#include "../../../common/cutlass_unit_test.h"

#include "../gemm_testbed_3x.hpp"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

namespace test {
namespace gemm {
namespace device {

template <
  typename Gemm,
  template <class T> class ActivationFunctor = cutlass::epilogue::thread::Identity
>
bool TestFusion(double alpha = 1.0, double beta = cute::is_same_v<typename Gemm::GemmKernel::ElementC, void> ? 0.0 : 1.0, CheckEquality check_relative_equality = CheckEquality::RELATIVE) {
  using ElementScalar = typename Gemm::EpilogueOutputOp::ElementScalar;
  using ProblemShapeType = typename Gemm::GemmKernel::ProblemShape;

  Testbed3x<Gemm, ActivationFunctor> testbed(check_relative_equality, ScalarLoc::ON_HOST, VectorScale::DISABLED);

  int max_alignment_m = std::max({Gemm::kAlignmentA, Gemm::kAlignmentC, Gemm::kAlignmentD});
  int max_alignment_n = std::max({Gemm::kAlignmentB, Gemm::kAlignmentC, Gemm::kAlignmentD});

  if constexpr (std::is_base_of_v<cutlass::epilogue::fusion::FusionOperation, typename Gemm::EpilogueOutputOp>) {
    max_alignment_m = std::max(max_alignment_m, Gemm::EpilogueOutputOp::AlignmentAux);
    max_alignment_n = std::max(max_alignment_n, Gemm::EpilogueOutputOp::AlignmentAux);
  }

  std::vector<int> problem_size_m = {max_alignment_m, 512 - 3 * max_alignment_m};
  std::vector<int> problem_size_n = {max_alignment_n, 512 - 2 * max_alignment_n};
  if(max_alignment_n % Gemm::EpilogueOutputOp::SFVecSize != 0) {
    max_alignment_n = Gemm::EpilogueOutputOp::SFVecSize;
    problem_size_n = {max_alignment_n, 4 * max_alignment_n};
  }
 
  //printf("Problem Shape Setup : Gemm::EpilogueOutputOp::AlignmentAux : %d, Gemm::kAlignmentD %d, max_alignment_m : %d, problem_size_m : %d\n", Gemm::EpilogueOutputOp::AlignmentAux, Gemm::kAlignmentD, max_alignment_m, problem_size_m);
  //printf("Problem Shape Setup : Gemm::EpilogueOutputOp::AlignmentAux : %d, Gemm::kAlignmentD %d, max_alignment_n : %d, problem_size_n : %d\n", Gemm::EpilogueOutputOp::AlignmentAux, Gemm::kAlignmentD,  max_alignment_n, problem_size_n);

  constexpr int Stages = Gemm::GemmKernel::DispatchPolicy::Stages;
  constexpr int TileShapeK = cute::size<2>(typename Gemm::GemmKernel::TileShape{});

  int max_alignment_k = std::max(Gemm::kAlignmentA, Gemm::kAlignmentB);
  std::vector<int> problem_size_k = {max_alignment_k, TileShapeK * (Stages + 1) - max_alignment_k};

  using DecompositionMode = typename cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90StreamKParams::DecompositionMode;
  std::vector<DecompositionMode> decomposition_modes = {DecompositionMode::Heuristic};
  std::vector problem_splits = {detail::Splits{1}};
  static constexpr bool UsesStreamKScheduler = cute::is_same_v<typename Gemm::GemmKernel::TileSchedulerTag, cutlass::gemm::StreamKScheduler>;
  if constexpr (UsesStreamKScheduler) {
    problem_splits.push_back(detail::Splits{2});
    problem_splits.push_back(detail::Splits{3});

    decomposition_modes.push_back(DecompositionMode::DataParallel);
    decomposition_modes.push_back(DecompositionMode::SplitK);
    decomposition_modes.push_back(DecompositionMode::StreamK);

    // Use larger K sizes for stream-K tests
    static constexpr int min_tiles_per_sk_unit = cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90StreamKParams::min_iters_per_sk_unit_;
    problem_size_k = {TileShapeK * min_tiles_per_sk_unit, TileShapeK * 3 * min_tiles_per_sk_unit - max_alignment_k};
  }

  using RasterOrderOptions = typename cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90::RasterOrderOptions;
  std::vector<RasterOrderOptions> raster_orders = {RasterOrderOptions::AlongM, RasterOrderOptions::AlongN};
  std::vector max_swizzle_sizes{detail::MaxSwizzleSize{1}, detail::MaxSwizzleSize{4}};

  bool passed = true;

  for (int m : problem_size_m) {
    for (int n : problem_size_n) {
      for (int k : problem_size_k) {
        for (auto raster_order : raster_orders) {
          for (auto max_swizzle_size : max_swizzle_sizes) {
            for (DecompositionMode decomp_mode : decomposition_modes) {

              std::vector problem_splits = {detail::Splits{1}};
              if (decomp_mode == DecompositionMode::Heuristic || decomp_mode == DecompositionMode::SplitK) {
                auto max_splits = (k + TileShapeK - 1) / TileShapeK;
                if (max_splits > 2) {
                  problem_splits.push_back(detail::Splits{2});
                }
                if (max_splits > 3) {
                  problem_splits.push_back(detail::Splits{3});
                }

                problem_splits.push_back(detail::Splits{max_splits});

                // Test the case in which we ask for more splits than there are K tiles in the GEMM. In this
                // case, split-K will fall back to a splitting factor of `max_splits`.
                problem_splits.push_back(detail::Splits{max_splits + 1});
              }
              for (auto splits : problem_splits) {
                ProblemShapeType problem_size;
                if constexpr (cute::rank(ProblemShapeType{}) == 4) {
                  problem_size = ProblemShapeType{m, n, k, /* l */ 1};
                }
                else {
                  problem_size = ProblemShapeType{m, n, k};
                }

                try {
                  passed = testbed.run(
                    problem_size,
                    cutlass::from_real<ElementScalar>(alpha),
                    cutlass::from_real<ElementScalar>(beta),
                    raster_order,
                    max_swizzle_size,
                    splits,
                    decomp_mode
                  );
                }
                catch (std::exception const& e) {
                  EXPECT_TRUE(false) << "TestAll: testbed.run {"
                    << "m: " << m << ", n: " << n << ", k: " << k
                    << ", alpha: " << alpha << ", beta: " << beta
                    << ", raster_order: ???"
                    << ", max_swizzle_size: " << static_cast<int>(max_swizzle_size)
                    << ", splits: " << static_cast<int>(splits)
                    << ", decomp_mode: " << detail::decomp_mode_to_string(decomp_mode)
                    << "} threw an exception: " << e.what();
                  throw;
                }
                catch (...) {
                  EXPECT_TRUE(false) << "TestAll: testbed.run {"
                    << "m: " << m << ", n: " << n << ", k: " << k
                    << ", alpha: " << alpha << ", beta: " << beta
                    << ", raster_order: ???"
                    << ", max_swizzle_size: " << static_cast<int>(max_swizzle_size)
                    << ", splits: " << static_cast<int>(splits)
                    << ", decomp_mode: " << detail::decomp_mode_to_string(decomp_mode)
                    << "} threw an exception (unknown)";
                  throw;
                }

                EXPECT_TRUE(passed) << "TestAll: testbed.run {"
                  << "m: " << m << ", n: " << n << ", k: " << k
                  << ", alpha: " << alpha << ", beta: " << beta
                  << ", raster_order: ???"
                  << ", max_swizzle_size: " << static_cast<int>(max_swizzle_size)
                  << ", splits: " << static_cast<int>(splits)
                  << ", decomp_mode: " << detail::decomp_mode_to_string(decomp_mode)
                  << "} failed";

                if (!passed) {
                  std::cout << __FILE__ << ':' << __LINE__ << " : GEMM MNK " << m << " " << n << " " << k << " FAILED.\n";
                  return false;
                }
              } // splits
            } // decomposition_mode
          } // max_swizzle_size
        } // raster_order
      } // k
    } // n
  } // m

  return passed;
}
} // namespace device
} // namespace gemm
} // namespace test

TEST(SM100Only_Device_Gemm_bf16t_bf16n_ue8m0xe4m3t_outputVs32_bstensorop_1sm_f32, 128x128x64_1x1x1) {

  // Describe A and B tensors
  using ElementA = cutlass::bfloat16_t;
  constexpr int AlignA = 8;
  using GmemLayoutA = cutlass::layout::RowMajor;
  constexpr int AlignB = 8;
  using ElementB = cutlass::bfloat16_t;
  using GmemLayoutB = cutlass::layout::ColumnMajor;

  // Describe C and D tensors
  using ElementC = float;
  constexpr int AlignC = 128 / cutlass::sizeof_bits<ElementC>::value;
  using GmemLayoutC = cutlass::layout::RowMajor;

  using ElementD = cutlass::float_e4m3_t;
  constexpr int AlignD = 16;
  using GmemLayoutD = cutlass::layout::RowMajor;
  // Describe SFD tensor
  using ElementSFD = cutlass::float_ue8m0_t;
  using GmemLayoutSFD = GmemLayoutD;
  // Mma's accumulator type
  using ElementAccumulator = float;
  // Epilogue computation's precision type
  using ElementCompute = float;

  // Collective MMA takes tile shape of the MMA operation as input
  using MmaTileShape_MNK = Shape<_128,_128,_64>;
  // Cluster size for multicast
  using ClusterShape_MNK = Shape<_1,_1,_1>;

  //
  // Construct FusionOperation
  //
  constexpr int SFDVectorSize = 32;
  // Define the fusion operation applied during epilogue
  using FusionOperation = cutlass::epilogue::fusion::LinCombBlockScaleFactor<
      SFDVectorSize,
      ElementD, ElementCompute, 
      ElementSFD, GmemLayoutSFD,
      ElementC
    >;
  
  //
  // Construct CollectiveEpilogue
  //

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,      // Arch and Tensorop spec
      MmaTileShape_MNK, ClusterShape_MNK,                                   // Mma instruction tile shape, cluster shape
      Shape<_128,_128>,                      // Epilogue subtile shape. Auto will find a suitable tile shape
      ElementAccumulator, ElementCompute,                                   // Mma instr's accumulator type and compute precision for epilogue
      ElementC, GmemLayoutC, AlignC,                                        // C tensor description
      ElementD, GmemLayoutD, AlignD,                                        // D tensor description
      cutlass::epilogue::TmaWarpSpecialized1Sm,                   // Epilogue schedule policy
      FusionOperation
    >::CollectiveOp;

  //
  // Construct CollectiveMainloop
  //

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,      // Arch and Tensorop spec
      ElementA, GmemLayoutA, AlignA,                                        // A tensor elem type, layout and alignment requirement
      ElementB, GmemLayoutB, AlignB,                                        // B tensor elem type, layout and alignment requirement
      ElementAccumulator,                                                   // Mma instruction accumulator type
      MmaTileShape_MNK, ClusterShape_MNK,                                   // Mma instruction tile shape, cluster shape
      // Epilogue's SMEM usage that needs to be subtracted from overall SMEM capacity 
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      cutlass::gemm::collective::KernelScheduleAuto    // Kernel schedule policy. Auto or using targeted scheduling policy
    >::CollectiveOp;

  // Create Gemm Kernel using CollectiveEpilogue and CollectiveMainloop created by the builders
  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue
    >;
  
  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  // Run tests
  auto pass = test::gemm::device::TestFusion<Gemm>();
  // Check results
  EXPECT_TRUE(pass); 
}

#endif // #if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
