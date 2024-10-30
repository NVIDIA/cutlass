/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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
    \brief Tests for Xe bf16t_bf16t_f32 with EVT epilogue
    LinCombEltAct
*/

#include <iostream>

#include "cutlass/cutlass.h"

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"

#include "gemm_testbed_3x.hpp"

using namespace cute;

// D = activation(alpha * acc + beta * C)
TEST(XE_Device_Gemm_bf16t_bf16t_f32t_tensor_op_gmma_f32_epilogue, 256x256x32_LinCombEltAct) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using TileShape_MNK = Shape<_256, _256, _32>;
  using ClusterShape_MNK = Shape<_1,_1,_1>;

  using EpilogueSchedule = cutlass::epilogue::collective::EpilogueScheduleAuto;
  using ElementAccumulator = float;
  using ElementComputeEpilogue = float;
  using ElementInputA = bfloat16_t;
  using ElementInputB = bfloat16_t;
  using ElementOutput = float;

  constexpr int AlignmentA = sizeof(ElementInputA);
  constexpr int AlignmentB = sizeof(ElementInputB);
  constexpr int AlignmentC = sizeof(ElementAccumulator);
  constexpr int AlignmentD = sizeof(ElementOutput);

  using FusionCallbacks = cutlass::epilogue::fusion::LinCombEltAct<cutlass::epilogue::thread::ReLu, 
          ElementOutput, ElementComputeEpilogue, ElementAccumulator, 
          ElementAccumulator, cutlass::FloatRoundStyle::round_to_nearest>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::IntelPVC, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementComputeEpilogue, ElementAccumulator,
      ElementAccumulator, LayoutC, AlignmentC,
      ElementOutput, LayoutD, AlignmentD,
      EpilogueSchedule,
      FusionCallbacks
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::IntelPVC, cutlass::arch::OpClassTensorOp,
      ElementInputA, LayoutA, AlignmentA,
      ElementInputB, LayoutB, AlignmentB,
      ElementAccumulator,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::collective::KernelScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  bool passed = test::gemm::device::TestXe<Gemm, cutlass::epilogue::thread::ReLu>(1.0, 1.0);
  EXPECT_TRUE(passed);
}

TEST(Xe_Gemm_bf16t_bf16t_f32_tensor_op_gmma_f32_epilogue_drelu, 64x128x64) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;
  using LayoutAux = cutlass::layout::RowMajor;

  using TileShape_MNK = Shape<_256, _256, _32>;
  using ClusterShape_MNK = Shape<_1,_1,_1>;
  using EpilogueSchedule = cutlass::epilogue::collective::EpilogueScheduleAuto;
  using ElementAccumulator = float;
  using ElementComputeEpilogue = float;
  using ElementInputA = bfloat16_t;
  using ElementInputB = bfloat16_t;
  using ElementOutput = float;

  constexpr int AlignmentA = sizeof(ElementInputA);
  constexpr int AlignmentB = sizeof(ElementInputB);
  constexpr int AlignmentC = sizeof(ElementAccumulator);
  constexpr int AlignmentD = sizeof(ElementOutput);

  using FusionCallbacks = cutlass::epilogue::fusion::LinCombDeEltAct<
    LayoutC,
    cutlass::epilogue::thread::dReLU,
    ElementOutput,
    ElementComputeEpilogue>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::IntelPVC, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementComputeEpilogue, ElementAccumulator,
      ElementAccumulator, LayoutC, AlignmentC,
      ElementOutput, LayoutD, AlignmentD,
      EpilogueSchedule,
      FusionCallbacks
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::IntelPVC, cutlass::arch::OpClassTensorOp,
      ElementInputA, LayoutA, AlignmentA,
      ElementInputB, LayoutB, AlignmentB,
      ElementAccumulator,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::collective::KernelScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  bool passed = test::gemm::device::TestXe<Gemm, cutlass::epilogue::thread::dReLU>(1.0, 1.0);
  EXPECT_TRUE(passed);
}

