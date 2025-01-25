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



/*! \file
    \brief Tests for device-wide GEMM interface
*/

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
#include "../../common/cutlass_unit_test.h"

#include "gemm_testbed_3x.hpp"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

TEST(SM100_Device_Gemm_e2m1t_e2m1n_f32t_tensorop_2sm_f32_runtime_datatype, 512x512x128_4x4x1) {
  using CollectiveEpilogue =
    typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      cute::Shape<cute::_128, cute::_128, cute::_128>,
      cute::Shape<cute::_4,cute::_4,cute::_1>,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      float, cutlass::layout::RowMajor, 4,
      float, cutlass::layout::RowMajor, 4,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      
      cutlass::epilogue::fusion::LinearCombination<
        float,
        float,
        float,
        float
      >

    >::CollectiveOp;

  using CollectiveMainloop =
    typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      cutlass::type_erased_dynamic_float4_t, cutlass::layout::RowMajor, 128,
      cutlass::type_erased_dynamic_float4_t, cutlass::layout::ColumnMajor, 128,
      float,
      cute::Shape<cute::_256, cute::_128, cute::_128>,
      cute::Shape<cute::_4,cute::_4,cute::_1>,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
    cutlass::gemm::KernelTmaWarpSpecialized2SmSm100
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      cute::Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      void>;

  using namespace test::gemm::device;
  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  auto pass = TestRuntimeDataTypeSmall<Gemm>(cute::UMMA::MXF8F6F4Format::E2M1, cute::UMMA::MXF8F6F4Format::E2M1);
  EXPECT_TRUE(pass);

}


TEST(SM100_Device_Gemm_e2m1t_e2m1n_f32t_tensorop_1sm_f32_runtime_datatype, 256x256x128_2x2x1) {
  using CollectiveEpilogue =
    typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      cute::Shape<cute::_128, cute::_128, cute::_128>,
      cute::Shape<cute::_2,cute::_2,cute::_1>,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      float, cutlass::layout::RowMajor, 4,
      float, cutlass::layout::RowMajor, 4,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      
      cutlass::epilogue::fusion::LinearCombination<
        float,
        float,
        float,
        float
      >

    >::CollectiveOp;

  using CollectiveMainloop =
    typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      cutlass::type_erased_dynamic_float4_t, cutlass::layout::RowMajor, 128,
      cutlass::type_erased_dynamic_float4_t, cutlass::layout::ColumnMajor, 128,
      float,
      cute::Shape<cute::_128, cute::_128, cute::_128>,
      cute::Shape<cute::_2,cute::_2,cute::_1>,
      cutlass::gemm::collective::StageCountAutoCarveout<sizeof(typename CollectiveEpilogue::SharedStorage)>,
    cutlass::gemm::KernelTmaWarpSpecialized1SmSm100
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      cute::Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      void>;

  using namespace test::gemm::device;
  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  auto pass = TestRuntimeDataTypeSmall<Gemm>(cute::UMMA::MXF8F6F4Format::E2M1, cute::UMMA::MXF8F6F4Format::E2M1);
  EXPECT_TRUE(pass);
}

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
