/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Test for sm100 dense gemm stage
*/

#include "../../../../common/cutlass_unit_test.h"
#include "cute/atom/mma_atom.hpp"
#include "cute/tensor.hpp"
#include "cutlass/arch/mma_sm100.h"
#include "cutlass/cutlass.h"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/numeric_types.h"
#include "../../gemm_testbed_3x.hpp"

using namespace cute;

namespace cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_128x128x32_1x1x1_0_tnt_align4_1sm_stage6 {
    using CollectiveEpilogue =
        typename cutlass::epilogue::collective::CollectiveBuilder<
            cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
            cute::Shape<cute::_128, cute::_128, cute::_32>,
            cute::Shape<cute::_1, cute::_1, cute::_1>,
            cutlass::epilogue::collective::EpilogueTileAuto,
            float, float,
            void, cutlass::layout::RowMajor, 4,
            float, cutlass::layout::RowMajor, 4,
            cutlass::epilogue::TmaWarpSpecialized1Sm,
            cutlass::epilogue::fusion::LinearCombination<
            float,
            float,
            void,
            float
            >
        >::CollectiveOp;

    using CollectiveMainloop =
        typename cutlass::gemm::collective::CollectiveBuilder<
            cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
            float, cutlass::layout::RowMajor, 4,
            float, cutlass::layout::ColumnMajor, 4,
            float,
            cute::Shape<cute::_128, cute::_128, cute::_32>,
            cute::Shape<cute::_1, cute::_1, cute::_1>,
            cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
            cutlass::gemm::KernelTmaWarpSpecialized1SmSm100
        >::CollectiveOp;

    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
        cute::Shape<int,int,int,int>,
        CollectiveMainloop,
        CollectiveEpilogue,
        void>;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
}

namespace cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_128x256x32_1x1x1_0_tnt_align4_1sm_stage4 {
    using CollectiveEpilogue =
        typename cutlass::epilogue::collective::CollectiveBuilder<
            cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
            cute::Shape<cute::_128, cute::_256, cute::_32>,
            cute::Shape<cute::_1, cute::_1, cute::_1>,
            cutlass::epilogue::collective::EpilogueTileAuto,
            float, float,
            void, cutlass::layout::RowMajor, 4,
            float, cutlass::layout::RowMajor, 4,
            cutlass::epilogue::TmaWarpSpecialized1Sm,
            cutlass::epilogue::fusion::LinearCombination<
            float,
            float,
            void,
            float
            >
        >::CollectiveOp;

    using CollectiveMainloop =
        typename cutlass::gemm::collective::CollectiveBuilder<
            cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
            float, cutlass::layout::RowMajor, 4,
            float, cutlass::layout::ColumnMajor, 4,
            float,
            cute::Shape<cute::_128, cute::_256, cute::_32>,
            cute::Shape<cute::_1, cute::_1, cute::_1>,
            cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
            cutlass::gemm::KernelTmaWarpSpecialized1SmSm100
        >::CollectiveOp;

    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
        cute::Shape<int,int,int,int>,
        CollectiveMainloop,
        CollectiveEpilogue,
        void>;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
}

namespace cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_256x128x32_2x1x1_0_tnt_align4_2sm_stage8 {
    using CollectiveEpilogue =
        typename cutlass::epilogue::collective::CollectiveBuilder<
            cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
            cute::Shape<cute::_256, cute::_128, cute::_32>,
            cute::Shape<cute::_2, cute::_1, cute::_1>,
            cutlass::epilogue::collective::EpilogueTileAuto,
            float, float,
            void, cutlass::layout::RowMajor, 4,
            float, cutlass::layout::RowMajor, 4,
            cutlass::epilogue::TmaWarpSpecialized2Sm,
            cutlass::epilogue::fusion::LinearCombination<
            float,
            float,
            void,
            float
            >
        >::CollectiveOp;

    using CollectiveMainloop =
        typename cutlass::gemm::collective::CollectiveBuilder<
            cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
            float, cutlass::layout::RowMajor, 4,
            float, cutlass::layout::ColumnMajor, 4,
            float,
            cute::Shape<cute::_256, cute::_128, cute::_32>,
            cute::Shape<cute::_2, cute::_1, cute::_1>,
            cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
            cutlass::gemm::KernelTmaWarpSpecialized2SmSm100
        >::CollectiveOp;

    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
        cute::Shape<int,int,int,int>,
        CollectiveMainloop,
        CollectiveEpilogue,
        void>;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
}

namespace cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_256x256x32_2x1x1_0_tnt_align4_2sm_stage6 {
    using CollectiveEpilogue =
        typename cutlass::epilogue::collective::CollectiveBuilder<
            cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
            cute::Shape<cute::_256, cute::_256, cute::_32>,
            cute::Shape<cute::_2, cute::_1, cute::_1>,
            cutlass::epilogue::collective::EpilogueTileAuto,
            float, float,
            void, cutlass::layout::RowMajor, 4,
            float, cutlass::layout::RowMajor, 4,
            cutlass::epilogue::TmaWarpSpecialized2Sm,
            cutlass::epilogue::fusion::LinearCombination<
            float,
            float,
            void,
            float
            >
        >::CollectiveOp;

    using CollectiveMainloop =
        typename cutlass::gemm::collective::CollectiveBuilder<
            cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
            float, cutlass::layout::RowMajor, 4,
            float, cutlass::layout::ColumnMajor, 4,
            float,
            cute::Shape<cute::_256, cute::_256, cute::_32>,
            cute::Shape<cute::_2, cute::_1, cute::_1>,
            cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
            cutlass::gemm::KernelTmaWarpSpecialized2SmSm100
        >::CollectiveOp;

    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
        cute::Shape<int,int,int,int>,
        CollectiveMainloop,
        CollectiveEpilogue,
        void>;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
}

TEST(cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_128x128x32_1x1x1_0_tnt_align4_1sm, stage_check)
{
  static constexpr int Stages = cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_128x128x32_1x1x1_0_tnt_align4_1sm_stage6::CollectiveMainloop::DispatchPolicy::Stages;
  EXPECT_TRUE(Stages == 6);
}

TEST(cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_128x256x32_1x1x1_0_tnt_align4_1sm, stage_check)
{
  static constexpr int Stages = cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_128x256x32_1x1x1_0_tnt_align4_1sm_stage4::CollectiveMainloop::DispatchPolicy::Stages;
  EXPECT_TRUE(Stages == 4);
}

TEST(cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_256x128x32_2x1x1_0_tnt_align4_2sm, stage_check)
{
  static constexpr int Stages = cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_256x128x32_2x1x1_0_tnt_align4_2sm_stage8::CollectiveMainloop::DispatchPolicy::Stages;
  EXPECT_TRUE(Stages == 8);
}

TEST(cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_256x256x32_2x1x1_0_tnt_align4_2sm, stage_check)
{
  static constexpr int Stages = cutlass3x_sm100_tensorop_gemm_f32_f32_f32_void_f32_256x256x32_2x1x1_0_tnt_align4_2sm_stage6::CollectiveMainloop::DispatchPolicy::Stages;
  EXPECT_TRUE(Stages == 6);
}
