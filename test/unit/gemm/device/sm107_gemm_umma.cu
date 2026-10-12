/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

/*! \file
    \brief Tests for SM107 GEMM UMMA builders
*/

#include <iostream>

#include "cutlass/cutlass.h"
#include "cute/tensor.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cutlass/numeric_types.h"
#include "cutlass/arch/mma_sm100.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cute/atom/mma_traits_sm100.hpp"
#include "../../common/cutlass_unit_test.h"
#include "gemm_testbed_3x.hpp"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM107_SUPPORTED)


////////////////////////////////////////////////////////////////////////////////
// Test for 9xBF16 GEMM
////////////////////////////////////////////////////////////////////////////////

TEST(SM107_Device_9xBF16_GEMM, 256x128x32_2x1x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;

  using MmaTileShape = Shape<_256,_128,_32>;
  using ClusterShape = Shape<_2,_1,_1>;
  using ElementA = float;
  using ElementB = float;
  using ElementAMma = cutlass::bfloat16_t;
  using ElementBMma = cutlass::bfloat16_t;
  using ElementAccumulator = float;
  using ElementCompute = float;
  using ElementD = float;
  int constexpr AlignmentD = 4;
  int constexpr AlignmentAB = 4;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm107, cutlass::arch::OpClassTensorOp,
      MmaTileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementCompute,
      ElementD, LayoutC, AlignmentD,
      ElementD, LayoutC, AlignmentD,
      cutlass::epilogue::FastF32NoSmemWarpSpecialized2Sm
  >::CollectiveOp;

  using MainloopSchedule = cutlass::gemm::KernelTmaWarpSpecialized2SmFastFP32Sm100;
  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm107, cutlass::arch::OpClassTensorOp,
      ElementA, LayoutA, AlignmentAB,
      ElementB, LayoutB, AlignmentAB,
      ElementAccumulator,
      MmaTileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      MainloopSchedule
      >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  bool passed = test::gemm::device::TestSmall<Gemm, true>(1.0, 1.0);
  EXPECT_TRUE(passed);
}

//////////////////////////////////////////////////////////////////////////////
// Test for 9xBF16 interleaved complex GEMM
//////////////////////////////////////////////////////////////////////////////

TEST(SM107_Device_9xBF16_InterleavedComplex_GEMM, 256x64x16_2x1x1) {
  using ElementA = cutlass::complex<float>;
  using TransformA = cute::identity;
  using ElementPairA = cute::tuple<ElementA, TransformA>;
  using LayoutA = cutlass::layout::RowMajor;

  using ElementB = cutlass::complex<float>;
  using TransformB = cute::identity;
  using ElementPairB = cute::tuple<ElementB, TransformA>;
  using LayoutB = cutlass::layout::ColumnMajor;

  using ElementAccumulator = cutlass::complex<float>;
  using LayoutC = cutlass::layout::ColumnMajor;

  using ElementCompute = cutlass::complex<float>;
  using ElementD = cutlass::complex<float>;
  using MmaTileShape = Shape<_256,_64,_16>;
  using ClusterShape = Shape<_2,_1,_1>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm107, cutlass::arch::OpClassTensorOp,
    MmaTileShape, ClusterShape,
    cutlass::epilogue::collective::EpilogueTileAuto,
    ElementAccumulator, ElementCompute,
    ElementD, LayoutC, 16 / sizeof(ElementD),
    ElementD, LayoutC, 16 / sizeof(ElementD),
    cutlass::epilogue::FastF32NoSmemWarpSpecialized2Sm
  >::CollectiveOp;

  using MainloopSchedule = cutlass::gemm::KernelTmaWarpSpecialized2SmFastFP32Sm100;
  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    cutlass::arch::Sm107, cutlass::arch::OpClassTensorOp,
    ElementPairA, LayoutA, 16 / sizeof(ElementA),
    ElementPairB, LayoutB, 16 / sizeof(ElementB),
    ElementAccumulator,
    MmaTileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
    MainloopSchedule
  >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>,
    CollectiveMainloop,
    CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  bool passed = test::gemm::device::TestSmall<Gemm, true>(1.0, 0.0);
  EXPECT_TRUE(passed);
}

////////////////////////////////////////////////////////////////////////////////
// Test for Dense GEMM
////////////////////////////////////////////////////////////////////////////////
  
TEST(SM107_Device_Dense_GEMM, 128x128x128_1x1x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using ElementA = cutlass::float_e4m3_t;
  using ElementB = cutlass::float_e4m3_t;
  using ElementC = cutlass::float_e4m3_t;
  using ElementD = cutlass::float_e4m3_t;
  using ElementAccumulator = float;
  using ElementCompute = float;
  using ElementBias = cutlass::half_t;
  using MmaTileShape = cute::Shape<_128,_128,Int<128 / sizeof(ElementA)>>;
  using ClusterShape = Shape<_1,_1,_1>;

  using EpilogueSchedule = cutlass::epilogue::TmaWarpSpecialized1Sm;
  using FusionOperation = cutlass::epilogue::fusion::ScaledLinCombPerRowBiasEltAct<
      cutlass::epilogue::thread::ScaledGELU_taylor, ElementD, ElementCompute, ElementBias>;
  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm107, cutlass::arch::OpClassTensorOp,
    MmaTileShape, ClusterShape,
    cutlass::epilogue::collective::EpilogueTileAuto,
    ElementAccumulator, ElementCompute,
    ElementC, LayoutC, 16 / sizeof(ElementC),
    ElementD, LayoutC, 16 / sizeof(ElementD),
    EpilogueSchedule,
    FusionOperation
  >::CollectiveOp;

  using MainloopSchedule = cutlass::gemm::KernelTmaWarpSpecialized1SmSm100;
  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    cutlass::arch::Sm107, cutlass::arch::OpClassTensorOp,
    ElementA, LayoutA, 16 / sizeof(ElementA),
    ElementB, LayoutB, 16 / sizeof(ElementB),
    ElementAccumulator,
    MmaTileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
    MainloopSchedule
  >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>,
    CollectiveMainloop,
    CollectiveEpilogue
  >;

  using namespace test::gemm::device;
  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  auto pass = TestSmallFusion<Gemm, false /*force_legacy_epilogue*/, false /*apply_alignment_offset*/>(1.0, 0.5, CheckEquality::RELATIVE);
  EXPECT_TRUE(pass);
}

////////////////////////////////////////////////////////////////////////////////
// Test for Blockscaled GEMM
////////////////////////////////////////////////////////////////////////////////
TEST(SM107_Device_Blockscaled_GEMM, 128x128x128_4x4x1) {
  using ElementPairA = cutlass::mx_float6_t<cutlass::float_e2m3_t>;
  constexpr int AlignA = 128;
  using GmemLayoutA = cutlass::layout::ColumnMajor;
  using ElementPairB = cutlass::mx_float8_t<cutlass::float_e5m2_t>;
  constexpr int AlignB = 16;
  using GmemLayoutB = cutlass::layout::RowMajor;
  using ElementC = void;
  constexpr int AlignC = 4;
  using GmemLayoutC = cutlass::layout::RowMajor;
  using ElementD = float;
  constexpr int AlignD = 4;
  using GmemLayoutD = cutlass::layout::RowMajor;
  using ElementAccumulator = float;
  using ElementCompute = float;
  using MmaTileShape_MNK = Shape<_128,_128,_128>;
  using ClusterShape_MNK = Shape<_4,_4,_1>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm107, cutlass::arch::OpClassBlockScaledTensorOp,      // Arch and Tensorop spec
    MmaTileShape_MNK, ClusterShape_MNK,                                   // Mma instruction tile shape, cluster shape
    cutlass::epilogue::collective::EpilogueTileAuto,                      // Epilogue subtile shape. Auto will find a suitable tile shape
    ElementAccumulator, ElementCompute,                                   // Mma instr's accumulator type and compute precision for epilogue
    ElementC, GmemLayoutC, AlignC,                                        // C tensor description
    ElementD, GmemLayoutD, AlignD,                                        // D tensor description
    cutlass::epilogue::TmaWarpSpecialized1Sm                              // Epilogue schedule policy
  >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    cutlass::arch::Sm107, cutlass::arch::OpClassBlockScaledTensorOp,      // Arch and Tensorop spec
    ElementPairA, GmemLayoutA, AlignA,                                        // A tensor elem type, layout and alignment requirement
    ElementPairB, GmemLayoutB, AlignB,                                        // B tensor elem type, layout and alignment requirement
    ElementAccumulator,                                                   // Mma instruction accumulator type
    MmaTileShape_MNK, ClusterShape_MNK,                                   // Mma instruction tile shape, cluster shape
    cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
    cutlass::gemm::KernelTmaWarpSpecialized1SmBlockScaledSm100
  >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>,
    CollectiveMainloop,
    CollectiveEpilogue
  >;
  
  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  // Run tests
  auto pass = test::gemm::device::TestSmall<Gemm>();
  // Check results
  EXPECT_TRUE(pass);
}

#endif // #if defined(CUTLASS_ARCH_MMA_SM107_SUPPORTED)
