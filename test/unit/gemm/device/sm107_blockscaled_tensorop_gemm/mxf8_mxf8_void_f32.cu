/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "../../../common/cutlass_unit_test.h"
#include "../gemm_testbed_3x.hpp"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM107_SUPPORTED)

// Shared structure for SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32:
// A/B are MXFP8 (e4m3), C is unused (void), D is plain f32. Only the mma tile shape, cluster
// shape, and epilogue/mainloop schedules (1SM vs 2SM, with/without B-operand reuse) vary per test.
template <
  class MmaTileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueScheduleType,
  class MainloopScheduleType
>
bool run_mxf8_mxf8_void_f32_test() {
  using ElementA           = cutlass::mx_float8_t<cutlass::float_e4m3_t>;
  using GmemLayoutA        = cutlass::layout::RowMajor;
  constexpr int AlignA     = 16;
  using ElementB           = cutlass::mx_float8_t<cutlass::float_e5m2_t>;
  using GmemLayoutB        = cutlass::layout::ColumnMajor;
  constexpr int AlignB     = 16;
  using ElementC           = void;
  using GmemLayoutC        = cutlass::layout::ColumnMajor;
  constexpr int AlignC     = 4;
  using ElementD           = float;
  using GmemLayoutD        = cutlass::layout::ColumnMajor;
  constexpr int AlignD     = 4;
  using ElementAccumulator = float;
  using ElementCompute     = float;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm107, cutlass::arch::OpClassBlockScaledTensorOp,
      MmaTileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementCompute,
      ElementC, GmemLayoutC, AlignC,
      ElementD, GmemLayoutD, AlignD,
      EpilogueScheduleType
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm107, cutlass::arch::OpClassBlockScaledTensorOp,
      ElementA, GmemLayoutA, AlignA,
      ElementB, GmemLayoutB, AlignB,
      ElementAccumulator,
      MmaTileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      MainloopScheduleType
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue
    >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  using ProblemShapeType = typename Gemm::GemmKernel::ProblemShape;
  ProblemShapeType problem_size{512, 256, 512, /* l */ 1};

  test::gemm::device::Testbed3x<Gemm> testbed;
  return testbed.run(problem_size);
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 128x64x128_2x2x1_1sm) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_128,_64,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      cutlass::gemm::KernelTmaWarpSpecialized1SmSm107BlockScaledMxf8f6f4WithoutBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 256x64x128_2x2x1_2sm) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_256,_64,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized2Sm,
      cutlass::gemm::KernelTmaWarpSpecialized2SmSm107BlockScaledMxf8f6f4WithoutBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 256x64x128_2x2x1_1sm_breuse) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_256,_64,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      cutlass::gemm::KernelTmaWarpSpecialized1SmSm107BlockScaledMxf8f6f4WithBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 512x64x128_2x2x1_2sm_breuse) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_512,_64,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized2Sm,
      cutlass::gemm::KernelTmaWarpSpecialized2SmSm107BlockScaledMxf8f6f4WithBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 128x128x128_2x2x1_1sm) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_128,_128,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      cutlass::gemm::KernelTmaWarpSpecialized1SmSm107BlockScaledMxf8f6f4WithoutBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 256x128x128_2x2x1_2sm) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_256,_128,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized2Sm,
      cutlass::gemm::KernelTmaWarpSpecialized2SmSm107BlockScaledMxf8f6f4WithoutBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 256x128x128_2x2x1_1sm_breuse) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_256,_128,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      cutlass::gemm::KernelTmaWarpSpecialized1SmSm107BlockScaledMxf8f6f4WithBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 512x128x128_2x2x1_2sm_breuse) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_512,_128,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized2Sm,
      cutlass::gemm::KernelTmaWarpSpecialized2SmSm107BlockScaledMxf8f6f4WithBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 128x192x128_2x2x1_1sm) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_128,_192,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      cutlass::gemm::KernelTmaWarpSpecialized1SmSm107BlockScaledMxf8f6f4WithoutBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 256x192x128_2x2x1_2sm) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_256,_192,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized2Sm,
      cutlass::gemm::KernelTmaWarpSpecialized2SmSm107BlockScaledMxf8f6f4WithoutBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 256x192x128_2x2x1_1sm_breuse) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_256,_192,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      cutlass::gemm::KernelTmaWarpSpecialized1SmSm107BlockScaledMxf8f6f4WithBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 512x192x128_2x2x1_2sm_breuse) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_512,_192,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized2Sm,
      cutlass::gemm::KernelTmaWarpSpecialized2SmSm107BlockScaledMxf8f6f4WithBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 128x256x128_2x2x1_1sm) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_128,_256,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      cutlass::gemm::KernelTmaWarpSpecialized1SmSm107BlockScaledMxf8f6f4WithoutBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 256x256x128_2x2x1_2sm) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_256,_256,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized2Sm,
      cutlass::gemm::KernelTmaWarpSpecialized2SmSm107BlockScaledMxf8f6f4WithoutBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 256x256x128_2x2x1_1sm_breuse) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_256,_256,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized1Sm,
      cutlass::gemm::KernelTmaWarpSpecialized1SmSm107BlockScaledMxf8f6f4WithBreuse
    >()));
}

TEST(SM107_Device_Gemm_ue8m0xe4m3t_ue8m0xe5m2n_void_f32n_bstensorop_f32, 512x256x128_2x2x1_2sm_breuse) {
  EXPECT_TRUE((run_mxf8_mxf8_void_f32_test<
      Shape<_512,_256,_128>, Shape<_2,_2,_1>,
      cutlass::epilogue::TmaWarpSpecialized2Sm,
      cutlass::gemm::KernelTmaWarpSpecialized2SmSm107BlockScaledMxf8f6f4WithBreuse
    >()));
}

#endif
