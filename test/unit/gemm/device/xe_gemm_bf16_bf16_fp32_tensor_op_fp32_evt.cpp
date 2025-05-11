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

namespace cutlass {
namespace {
using namespace cute;
using LayoutA = layout::RowMajor;
using LayoutB = layout::RowMajor;
using LayoutC = layout::RowMajor;
using LayoutD = layout::RowMajor;
using EpilogueSchedule = epilogue::collective::EpilogueScheduleAuto;
using ElementAccumulator = float;
using ElementComputeEpilogue = float;
using ElementInputA = bfloat16_t;
using ElementInputB = bfloat16_t;
using ElementOutput = float;
using TileShape_MNK = Shape<_256, _256, _32>;
using ClusterShape_MNK = Shape<_1, _1, _1>;

constexpr static int AlignmentA = sizeof(ElementInputA);
constexpr static int AlignmentB = sizeof(ElementInputB);
constexpr static int AlignmentC = sizeof(ElementAccumulator);
constexpr static int AlignmentD = sizeof(ElementOutput);

using CollectiveMainloop = typename gemm::collective::CollectiveBuilder<
    arch::IntelXe, arch::OpClassTensorOp,
    ElementInputA, LayoutA, AlignmentA,
    ElementInputB, LayoutB, AlignmentB,
    ElementAccumulator,
    TileShape_MNK, ClusterShape_MNK,
    gemm::collective::StageCountAuto,
    gemm::collective::KernelScheduleAuto
  >::CollectiveOp;

template <typename CollectiveEpilogue>
struct XE_Device_Gemm_bf16_bf16_f32_tensor_op_gmma_f32_epilogue{
  using Gemm = gemm::device::GemmUniversalAdapter<
    gemm::kernel::GemmUniversal<
      Shape<int, int, int, int>,
      CollectiveMainloop,
      CollectiveEpilogue
    >>;
};

// D = activation(alpha * acc + beta * C)
TEST(XE_Device_Gemm_bf16t_bf16t_f32t_tensor_op_gmma_f32_epilogue, 256x256x32_LinCombEltAct) {

  using FusionCallbacks = epilogue::fusion::LinCombEltAct<epilogue::thread::ReLu,
          ElementOutput, ElementComputeEpilogue, ElementAccumulator,
          ElementAccumulator, FloatRoundStyle::round_to_nearest>;

  using CollectiveEpilogue = typename epilogue::collective::CollectiveBuilder<
      arch::IntelXe, arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      epilogue::collective::EpilogueTileAuto,
      ElementComputeEpilogue, ElementAccumulator,
      ElementAccumulator, LayoutC, AlignmentC,
      ElementOutput, LayoutD, AlignmentD,
      EpilogueSchedule,
      FusionCallbacks
    >::CollectiveOp;

  using Gemm = XE_Device_Gemm_bf16_bf16_f32_tensor_op_gmma_f32_epilogue<CollectiveEpilogue>::Gemm;

  bool passed = test::gemm::device::TestXe<Gemm, epilogue::thread::ReLu>(1.0, 1.0);
  EXPECT_TRUE(passed);
}

TEST(Xe_Gemm_bf16t_bf16t_f32_tensor_op_gmma_f32_epilogue_drelu, 256x256x32) {
  using LayoutAux = layout::RowMajor;

  using FusionCallbacks = epilogue::fusion::LinCombDeEltAct<
    LayoutC,
    epilogue::thread::dReLU,
    ElementOutput,
    ElementComputeEpilogue>;

  using CollectiveEpilogue = typename epilogue::collective::CollectiveBuilder<
      arch::IntelXe, arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      epilogue::collective::EpilogueTileAuto,
      ElementComputeEpilogue, ElementAccumulator,
      ElementAccumulator, LayoutC, AlignmentC,
      ElementOutput, LayoutD, AlignmentD,
      EpilogueSchedule,
      FusionCallbacks
    >::CollectiveOp;

  using Gemm = XE_Device_Gemm_bf16_bf16_f32_tensor_op_gmma_f32_epilogue<CollectiveEpilogue>::Gemm;

  // TODO(Codeplay): fix batch
  bool passed = test::gemm::device::TestXe<Gemm, epilogue::thread::dReLU>(1.0, 1.0, false);
  EXPECT_TRUE(passed);
}

TEST(XE_Device_Gemm_bf16t_bf16t_f32_tensor_op_gmma_f32_epilogue, 256x256x32_LinCombPerRowBias) {
  using ElementBias = float;

  using EpilogueDispatchPolicy = epilogue::IntelXeXMX16;
  using EpilogueOp = epilogue::fusion::LinCombPerRowBias<
      ElementOutput, ElementComputeEpilogue, ElementBias, ElementAccumulator,
      ElementAccumulator, 128 / sizeof_bits_v<ElementBias>,
      FloatRoundStyle::round_to_nearest>;
  using FusionCallBacks = epilogue::fusion::FusionCallbacks<
      EpilogueDispatchPolicy, EpilogueOp, TileShape_MNK,
      decltype(tile_shape(CollectiveMainloop::TiledMma()))>;

  using CollectiveEpilogue = epilogue::collective::CollectiveEpilogue<
          EpilogueDispatchPolicy,
          TileShape_MNK,
          ElementAccumulator,
          gemm::TagToStrideC_t<LayoutC>,
          ElementOutput,
          gemm::TagToStrideC_t<LayoutD>,
          FusionCallBacks,
          XE_2D_U32x8x16_LD_N,
          void, void,
          XE_2D_U32x8x16_ST_N,
          void, void>;

  using Gemm = XE_Device_Gemm_bf16_bf16_f32_tensor_op_gmma_f32_epilogue<CollectiveEpilogue>::Gemm;

  bool passed = test::gemm::device::TestXe<Gemm>();
  EXPECT_TRUE(passed);
}

TEST(XE_Device_Gemm_bf16t_bf16t_f32_tensor_op_gmma_f32_epilogue, 256x256x32_LinCombPerColBias) {
  using ElementBias = float;

  using EpilogueDispatchPolicy = epilogue::IntelXeXMX16;
  using EpilogueOp = epilogue::fusion::LinCombPerColBias<
      ElementOutput, ElementComputeEpilogue, ElementBias, ElementAccumulator,
      ElementAccumulator, 128 / sizeof_bits_v<ElementBias>,
      FloatRoundStyle::round_to_nearest>;
  using FusionCallBacks = epilogue::fusion::FusionCallbacks<
      EpilogueDispatchPolicy, EpilogueOp, TileShape_MNK,
      decltype(tile_shape(CollectiveMainloop::TiledMma()))>;

  using CollectiveEpilogue = epilogue::collective::CollectiveEpilogue<
          EpilogueDispatchPolicy,
          TileShape_MNK,
          ElementAccumulator,
          gemm::TagToStrideC_t<LayoutC>,
          ElementOutput,
          gemm::TagToStrideC_t<LayoutD>,
          FusionCallBacks,
          XE_2D_U32x8x16_LD_N,
          void, void,
          XE_2D_U32x8x16_ST_N,
          void, void>;

  using Gemm = XE_Device_Gemm_bf16_bf16_f32_tensor_op_gmma_f32_epilogue<CollectiveEpilogue>::Gemm;

  bool passed = test::gemm::device::TestXe<Gemm>(1.0, 0.0);
  EXPECT_TRUE(passed);
}
}
} // namespace cutlass
