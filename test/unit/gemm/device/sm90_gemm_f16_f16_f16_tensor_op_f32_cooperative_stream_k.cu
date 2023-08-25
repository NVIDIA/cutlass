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
    \brief Tests for device-wide GEMM interface with stream-K scheduling
*/

#include <iostream>

#include "cutlass/cutlass.h"
#include "cute/tensor.hpp"
#include "cute/atom/mma_atom.hpp"

#include "cutlass/numeric_types.h"

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/kernel/tile_scheduler.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/sm70_epilogue_vectorized.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"

#include "../../common/cutlass_unit_test.h"

#include "gemm_testbed_3x.hpp"

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

using namespace cute;

TEST(SM90_Device_Gemm_f16t_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_1x1x1) {
  using ElementA = cutlass::half_t;
  using LayoutA = cutlass::layout::RowMajor;
  using ElementB = cutlass::half_t;
  using LayoutB = cutlass::layout::RowMajor;
  using ElementAccumulator = float;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_1,_1,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      ElementA, LayoutA, 8,
      ElementB, LayoutB, 8,
      ElementAccumulator,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

TEST(SM90_Device_Gemm_f16t_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 256x128x64_1x2x1) {
  using ElementA = cutlass::half_t;
  using LayoutA = cutlass::layout::RowMajor;
  using ElementB = cutlass::half_t;
  using LayoutB = cutlass::layout::RowMajor;
  using ElementAccumulator = float;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_1,_2,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      ElementA, LayoutA, 8,
      ElementB, LayoutB, 8,
      ElementAccumulator,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Cluster 2x2x1  ////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16t_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_2x2x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16t_f16n_f32n_tensor_op_gmma_f32_cooperative_stream_k, 256x128x64_2x2x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16n_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_2x2x1) {
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16n_f16n_f32n_tensor_op_gmma_f32_cooperative_stream_k, 256x128x64_2x2x1) {
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_1,_2,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Cluster 4x1x1  ////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


TEST(SM90_Device_Gemm_f16t_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_4x1x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_4,_1,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16t_f16n_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_4x1x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_4,_1,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16n_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_4x1x1) {
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_4,_1,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16n_f16n_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_4x1x1) {
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_4,_1,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}


///////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Cluster 1x4x1  ////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


TEST(SM90_Device_Gemm_f16t_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_1x4x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_1,_4,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16t_f16n_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_1x4x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_1,_4,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16n_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_1x4x1) {
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_1,_4,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16n_f16n_f32n_tensor_op_gmma_f32_cooperative_stream_k, 128x128x64_1x4x1) {
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_1,_4,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}


///////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Cluster 2x4x1  ////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


TEST(SM90_Device_Gemm_f16t_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 256x128x64_2x4x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_4,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16t_f16n_f32n_tensor_op_gmma_f32_cooperative_stream_k, 256x128x64_2x4x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_4,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16n_f16t_f32n_tensor_op_gmma_f32_cooperative_stream_k, 256x128x64_2x4x1) {
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_4,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////

TEST(SM90_Device_Gemm_f16n_f16n_f32n_tensor_op_gmma_f32_cooperative_stream_k, 256x128x64_2x4x1) {
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_4,_1>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAuto,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

TEST(SM90_Device_Gemm_f16t_f16n_f16n_tensor_op_gmma_f32_cooperative_stream_k_epilogue, 256x128x64_2x2x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::TmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

TEST(SM90_Device_Gemm_f16t_f16n_f16t_tensor_op_gmma_f32_cooperative_stream_k_epilogue, 256x128x64_2x2x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::TmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

TEST(SM90_Device_Gemm_f16t_f16n_f32n_tensor_op_gmma_f32_cooperative_stream_k_epilogue, 128x128x64_2x2x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      float, LayoutC, 4,
      float, LayoutC, 4,
      cutlass::epilogue::TmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

TEST(SM90_Device_Gemm_f16t_f16n_f32t_tensor_op_gmma_f32_cooperative_stream_k_epilogue, 128x128x64_2x2x1) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using TileShape_MNK = Shape<_128,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      float, LayoutC, 4,
      float, LayoutC, 4,
      cutlass::epilogue::TmaWarpSpecializedCooperative
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>());
}

TEST(SM90_Device_Gemm_f16t_f16n_f32t_tensor_op_gmma_f32_cooperative_stream_k_epilogue, 256x128x64_2x2x1_BiasF32_ReLU) {
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using TileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using EpilogueSchedule = cutlass::epilogue::TmaWarpSpecializedCooperative;
  using FusionOperation = cutlass::epilogue::fusion::LinCombPerRowBiasEltActAux<
      LayoutC, cutlass::epilogue::thread::ReLu, cutlass::half_t, float, cutlass::half_t, float>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      EpilogueSchedule,
      FusionOperation
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutB, 8,
      float,
      TileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  bool passed = test::gemm::device::TestAllBiasElementwise<Gemm>();
  EXPECT_TRUE(passed);
}

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)
