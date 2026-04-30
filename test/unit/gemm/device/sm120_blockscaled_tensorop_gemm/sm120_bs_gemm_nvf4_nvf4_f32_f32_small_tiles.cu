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
#include <type_traits>

#include "cutlass/cutlass.h"
#include "cute/tensor.hpp"
#include "cute/atom/mma_atom.hpp"

#include "cutlass/numeric_types.h"

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/fusion/operations.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/util/device_memory.h"

#include "../../../common/cutlass_unit_test.h"

#include "../gemm_testbed_3x.hpp"

#if (defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED) || defined(CUTLASS_ARCH_MMA_SM121_SUPPORTED))

using namespace cute;

///////////////////////////////////////////////////////////////////////////////

namespace sm120_nvf4_small_tiles {

template <class TileShape_>
struct Kernel {
  using ElementA = cutlass::float_e2m1_t;
  using ElementB = cutlass::float_e2m1_t;
  using ElementC = float;
  using ElementD = float;
  using ElementAccumulator = float;
  using ElementCompute = float;
  using ElementSF = cutlass::float_ue4m3_t;

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using LayoutD = cutlass::layout::ColumnMajor;

  using ElementPairA = cutlass::nv_float4_t<cutlass::float_e2m1_t>;
  using ElementPairB = cutlass::nv_float4_t<cutlass::float_e2m1_t>;

  static constexpr int AlignmentA = 16 * 8 / cutlass::sizeof_bits<ElementA>::value;
  static constexpr int AlignmentB = 16 * 8 / cutlass::sizeof_bits<ElementB>::value;
  static constexpr int AlignmentC = 128 / cutlass::sizeof_bits<ElementC>::value;
  static constexpr int AlignmentD = 128 / cutlass::sizeof_bits<ElementD>::value;

  using TileShape = TileShape_;
  using ClusterShape = Shape<_1,_1,_1>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassTensorOp,
      TileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementCompute,
      ElementC, LayoutC, AlignmentC,
      ElementD, LayoutD, AlignmentD,
      cutlass::epilogue::collective::EpilogueScheduleAuto
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassBlockScaledTensorOp,
      ElementPairA, LayoutA, AlignmentA,
      ElementPairB, LayoutB, AlignmentB,
      ElementAccumulator,
      TileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      cutlass::gemm::KernelTmaWarpSpecializedCooperative
    >::CollectiveOp;

  using TileSchedulerTag = cutlass::gemm::PersistentScheduler;
  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int,int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      TileSchedulerTag>;
  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
};

template <class TileShape>
bool run() {
  using Gemm = typename Kernel<TileShape>::Gemm;
  using ElementScalar = typename Gemm::EpilogueOutputOp::ElementScalar;
  using Testbed = test::gemm::device::Testbed3x<
    Gemm,
    cutlass::epilogue::thread::Identity,
    true>;

  Testbed testbed(
    test::gemm::device::CheckEquality::RELATIVE,
    test::gemm::device::ScalarLoc::ON_DEVICE,
    test::gemm::device::VectorScale::ENABLED);

  Shape<int,int,int,int> problem_size{
    2 * int(size<0>(TileShape{})),
    2 * int(size<1>(TileShape{})),
    2 * int(size<2>(TileShape{})),
    1};

  return testbed.run(
    problem_size,
    cutlass::from_real<ElementScalar>(1.0),
    cutlass::from_real<ElementScalar>(0.5));
}

} // namespace sm120_nvf4_small_tiles

///////////////////////////////////////////////////////////////////////////////

namespace sm120_nvf4_active_tile_adapter {

using ElementAB = cutlass::nv_float4_t<cutlass::float_e2m1_t>;
using ElementC = void;
using ElementD = cutlass::bfloat16_t;
using ElementAccumulator = float;
using ElementCompute = float;
using LayoutA = cutlass::layout::RowMajor;
using LayoutB = cutlass::layout::ColumnMajor;
using LayoutC = cutlass::layout::RowMajor;
using LayoutD = cutlass::layout::RowMajor;
using TileShape = Shape<_64,_128,_128>;
using ClusterShape = Shape<_1,_1,_1>;

static constexpr int AlignmentAB = 32;
static constexpr int AlignmentD = 128 / cutlass::sizeof_bits<ElementD>::value;

using FusionOperation = cutlass::epilogue::fusion::LinearCombination<
    ElementD,
    ElementCompute,
    ElementC,
    ElementCompute>;

using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm120,
    cutlass::arch::OpClassTensorOp,
    TileShape,
    ClusterShape,
    cutlass::epilogue::collective::EpilogueTileAuto,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    LayoutC,
    AlignmentD,
    ElementD,
    LayoutD,
    AlignmentD,
    cutlass::epilogue::TmaWarpSpecialized,
    FusionOperation
  >::CollectiveOp;

using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    cutlass::arch::Sm120,
    cutlass::arch::OpClassBlockScaledTensorOp,
    ElementAB,
    LayoutA,
    AlignmentAB,
    ElementAB,
    LayoutB,
    AlignmentAB,
    ElementAccumulator,
    TileShape,
    ClusterShape,
    cutlass::gemm::collective::StageCount<2>,
    cutlass::gemm::KernelTmaWarpSpecializedCooperative
  >::CollectiveOp;

using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>,
    CollectiveMainloop,
    CollectiveEpilogue,
    cutlass::gemm::StaticPersistentScheduler>;
using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

bool run(int m, int n, int k) {
  using Sm1xxBlkScaledConfig = typename GemmKernel::CollectiveMainloop::Sm1xxBlkScaledConfig;
  using ElementSF = typename GemmKernel::CollectiveMainloop::ElementSF;

  auto problem_shape = make_shape(m, n, k, 1);
  auto layout_sfa = Sm1xxBlkScaledConfig::tile_atom_to_shape_SFA(problem_shape);
  auto layout_sfb = Sm1xxBlkScaledConfig::tile_atom_to_shape_SFB(problem_shape);

  cutlass::device_memory::allocation<uint8_t> tensor_a(m * k / 2);
  cutlass::device_memory::allocation<uint8_t> tensor_b(n * k / 2);
  cutlass::device_memory::allocation<ElementSF> tensor_sfa(size(filter_zeros(layout_sfa)));
  cutlass::device_memory::allocation<ElementSF> tensor_sfb(size(filter_zeros(layout_sfb)));
  cutlass::device_memory::allocation<ElementD> tensor_d(m * n);
  cutlass::device_memory::allocation<ElementCompute> alpha(1);

  float alpha_host = 1.0f;
  alpha.copy_from_host(&alpha_host);
  cudaMemset(tensor_a.get(), 0, tensor_a.bytes());
  cudaMemset(tensor_b.get(), 0, tensor_b.bytes());
  cudaMemset(tensor_sfa.get(), 0, tensor_sfa.bytes());
  cudaMemset(tensor_sfb.get(), 0, tensor_sfb.bytes());
  cudaMemset(tensor_d.get(), 0, tensor_d.size() * sizeof(ElementD));

  typename Gemm::Arguments args{};
  args.mode = cutlass::gemm::GemmUniversalMode::kGemm;
  args.problem_shape = problem_shape;
  args.mainloop.ptr_A = reinterpret_cast<typename Gemm::ElementA const*>(tensor_a.get());
  args.mainloop.ptr_B = reinterpret_cast<typename Gemm::ElementB const*>(tensor_b.get());
  args.mainloop.ptr_SFA = tensor_sfa.get();
  args.mainloop.ptr_SFB = tensor_sfb.get();

  int batch_stride = 0;
  args.mainloop.dA = cute::make_int_tuple_from<typename GemmKernel::StrideA>(k, batch_stride);
  args.mainloop.dB = cute::make_int_tuple_from<typename GemmKernel::StrideB>(k, batch_stride);
  args.mainloop.layout_SFA = layout_sfa;
  args.mainloop.layout_SFB = layout_sfb;

  args.epilogue.thread.alpha_ptr = alpha.get();
  args.epilogue.ptr_C = nullptr;
  args.epilogue.ptr_D = tensor_d.get();
  args.epilogue.dC = cute::make_int_tuple_from<typename GemmKernel::StrideC>(n, batch_stride);
  args.epilogue.dD = cute::make_int_tuple_from<typename GemmKernel::StrideD>(n, batch_stride);

  args.hw_info.device_id = 0;
  args.hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(args.hw_info.device_id);
  args.hw_info.cluster_shape = dim3(1, 1, 1);
  args.hw_info.cluster_shape_fallback = dim3(1, 1, 1);

  if constexpr (!std::is_const_v<decltype(args.scheduler.max_swizzle_size)>) {
    args.scheduler.max_swizzle_size = 1;
  }
  if constexpr (!std::is_const_v<decltype(args.scheduler.raster_order)>) {
    using RasterOrder = decltype(args.scheduler.raster_order);
    args.scheduler.raster_order = RasterOrder::Heuristic;
  }

  Gemm gemm;
  size_t workspace_size = Gemm::get_workspace_size(args);
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  cutlass::Status status = gemm.can_implement(args);
  EXPECT_TRUE(status == cutlass::Status::kSuccess) << to_string(status);
  if (status != cutlass::Status::kSuccess) {
    return false;
  }

  status = gemm.initialize(args, workspace.get());
  EXPECT_TRUE(status == cutlass::Status::kSuccess) << to_string(status);
  if (status != cutlass::Status::kSuccess) {
    return false;
  }

  status = gemm.run();
  EXPECT_TRUE(status == cutlass::Status::kSuccess) << to_string(status);
  if (status != cutlass::Status::kSuccess) {
    return false;
  }

  cudaError_t result = cudaDeviceSynchronize();
  EXPECT_EQ(result, cudaSuccess) << "Error at Kernel Sync.";
  return result == cudaSuccess;
}

} // namespace sm120_nvf4_active_tile_adapter

///////////////////////////////////////////////////////////////////////////////

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, M64_N64_K64) {
  bool result = sm120_nvf4_small_tiles::run<Shape<_64,_64,_64>>();
  EXPECT_TRUE(result);
}

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, M64_N64_K128) {
  bool result = sm120_nvf4_small_tiles::run<Shape<_64,_64,_128>>();
  EXPECT_TRUE(result);
}

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, M64_N128_K64) {
  bool result = sm120_nvf4_small_tiles::run<Shape<_64,_128,_64>>();
  EXPECT_TRUE(result);
}

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, M64_N128_K128) {
  bool result = sm120_nvf4_small_tiles::run<Shape<_64,_128,_128>>();
  EXPECT_TRUE(result);
}

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, M128_N64_K64) {
  bool result = sm120_nvf4_small_tiles::run<Shape<_128,_64,_64>>();
  EXPECT_TRUE(result);
}

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, M128_N64_K128) {
  bool result = sm120_nvf4_small_tiles::run<Shape<_128,_64,_128>>();
  EXPECT_TRUE(result);
}

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, M128_N128_K64) {
  bool result = sm120_nvf4_small_tiles::run<Shape<_128,_128,_64>>();
  EXPECT_TRUE(result);
}

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, M128_N128_K128) {
  bool result = sm120_nvf4_small_tiles::run<Shape<_128,_128,_128>>();
  EXPECT_TRUE(result);
}

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, ActiveTile_GemmUniversalAdapter_M64_N128_K128_UnpaddedScaleTensors) {
  bool result = sm120_nvf4_active_tile_adapter::run(64, 128, 256);
  EXPECT_TRUE(result);
}

TEST(SM120_Device_Blockscaled_Gemm_nvf4t_nvf4n_f32n_tensor_op_f32_small_tiles, ActiveTile_GemmUniversalAdapter_M1024_N8192_K128_UnpaddedScaleTensors) {
  bool result = sm120_nvf4_active_tile_adapter::run(1024, 8192, 256);
  EXPECT_TRUE(result);
}

#endif // (defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED) || defined(CUTLASS_ARCH_MMA_SM121_SUPPORTED))
