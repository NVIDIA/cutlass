/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Tests for Sm90 f16_f16_f16 persistent EVT epilogue
    D = row|column|scalar_reduce(alpha * acc + beta * C)
*/

#include <iostream>

#include "cutlass/cutlass.h"
#include "cute/tensor.hpp"
#include "cute/atom/mma_atom.hpp"

#include "cutlass/numeric_types.h"

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/sm70_epilogue_vectorized.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/epilogue/thread/linear_combination_bias_elementwise.h"

#include "../../common/cutlass_unit_test.h"

#include "gemm_testbed_3x_evt.hpp"
#include "sm90_evt_operations.hpp"


#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

using namespace cute;


TEST(SM90_Device_Gemm_f16t_f16n_f32t_tensor_op_gmma_f32_persistent_epilogue, 128x128x64_2x2x1_RowReduce) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using EpilogueSchedule = cutlass::epilogue::TmaWarpSpecialized;
  using FusionCallbacks = cutlass::epilogue::fusion::Sm90LinCombPerColumnReduce<
    cutlass::plus, cutlass::red, float, TileShape_MNK, cutlass::half_t, float, float>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      EpilogueSchedule,
      FusionCallbacks
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
      cutlass::gemm::KernelTmaWarpSpecializedPingpong
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  // Host reference
  using HostReference = test::gemm::device::HostReduce<Gemm, test::gemm::device::HostRowReduce>;
  bool passed = test::gemm::device::TestAllEVT<Gemm, HostReference>(true);
  EXPECT_TRUE(passed);
}

TEST(SM90_Device_Gemm_f16t_f16n_f32t_tensor_op_gmma_f32_persistent_epilogue, 128x128x64_2x2x1_ColumnReduce) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using EpilogueSchedule = cutlass::epilogue::TmaWarpSpecialized;
  using FusionCallbacks = cutlass::epilogue::fusion::Sm90LinCombPerRowReduce<
    cutlass::plus, cutlass::red, float, TileShape_MNK, cutlass::half_t, float, float>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      EpilogueSchedule,
      FusionCallbacks
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
      cutlass::gemm::KernelTmaWarpSpecializedPingpong
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  // Host reference
  using HostReference = test::gemm::device::HostReduce<Gemm, test::gemm::device::HostColumnReduce>;
  bool passed = test::gemm::device::TestAllEVT<Gemm, HostReference>(true);
  EXPECT_TRUE(passed);
}

TEST(SM90_Device_Gemm_f16t_f16n_f32t_tensor_op_gmma_f32_persistent_epilogue, 128x128x64_2x2x1_ScalarReduce) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using EpilogueSchedule = cutlass::epilogue::TmaWarpSpecialized;
  using FusionCallbacks = cutlass::epilogue::fusion::Sm90LinCombScalarReduce<
    cutlass::plus, cutlass::red, float, cutlass::half_t, float, float>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      EpilogueSchedule,
      FusionCallbacks
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
      cutlass::gemm::KernelTmaWarpSpecializedPingpong
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  // Host reference
  using HostReference = test::gemm::device::HostReduce<Gemm, test::gemm::device::HostScalarReduce>;
  bool passed = test::gemm::device::TestAllEVT<Gemm, HostReference>(true);
  EXPECT_TRUE(passed);
}
#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)
