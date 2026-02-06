/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/arch/mma_sm100.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cute/atom/mma_traits_sm100.hpp"
#include "../../common/cutlass_unit_test.h"
#include "gemm_testbed_3x_planar_complex.hpp"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////// 64x64x64 ///////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NNN
TEST(SM100_Device_Gemm_Planar_cf16n_cf16n_f32n_tensorop_1sm, 64x64x64_1x1x1) {
  using ElementA = cutlass::half_t;
  using TransformA = cute::identity;
  using ElementPairA = cute::tuple<ElementA, TransformA>;
  using LayoutA = cutlass::layout::ColumnMajor;

  using ElementB = cutlass::half_t;
  using TransformB = cute::identity;
  using ElementPairB = cute::tuple<ElementB, TransformB>;
  using LayoutB = cutlass::layout::ColumnMajor;

  using ElementAccumulator = float;
  using LayoutC = cutlass::layout::ColumnMajor;

  using MmaTileShape = cute::Shape<_64,_64,_64>;
  using ClusterShape = Shape<_1,_1,_1>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      MmaTileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::PlanarComplexTmaWarpSpecialized1Sm
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      ElementPairA, LayoutA, 8,
      ElementPairB, LayoutB, 8,
      ElementAccumulator,
      MmaTileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAutoCarveout<
        static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      cutlass::gemm::KernelTmaWarpSpecialized1SmPlanarComplexSm100
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestPlanarComplexSmall<Gemm>());
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////// TMA MULTICAST ///////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NTT
TEST(SM100_Device_Gemm_Planar_cf16n_cf16t_f32t_tensorop_1sm, 512x512x64_4x4x1) {
  using ElementA = cutlass::half_t;
  using TransformA = cute::identity;
  using ElementPairA = cute::tuple<ElementA, TransformA>;
  using LayoutA = cutlass::layout::ColumnMajor;

  using ElementB = cutlass::half_t;
  using TransformB = cute::identity;
  using ElementPairB = cute::tuple<ElementB, TransformB>;
  using LayoutB = cutlass::layout::RowMajor;

  using ElementAccumulator = float;
  using LayoutC = cutlass::layout::RowMajor;

  using MmaTileShape = cute::Shape<_128,_128,_64>;
  using ClusterShape = Shape<_4,_4,_1>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      MmaTileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      float, float,
      cutlass::half_t, LayoutC, 8,
      cutlass::half_t, LayoutC, 8,
      cutlass::epilogue::PlanarComplexTmaWarpSpecialized1Sm
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      ElementPairA, LayoutA, 8,
      ElementPairB, LayoutB, 8,
      ElementAccumulator,
      MmaTileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAutoCarveout<
        static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>, 
      cutlass::gemm::KernelTmaWarpSpecialized1SmPlanarComplexSm100
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  EXPECT_TRUE(test::gemm::device::TestPlanarComplexSmall<Gemm>());
}

#endif // #if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
