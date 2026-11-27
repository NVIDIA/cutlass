/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Statically sized array of elements that accommodates all CUTLASS-supported numeric types
           and is safe to use in a union.
*/


#include <gtest/gtest.h>
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "gemm_operation_3x.hpp"
#include "grouped_gemm_operation_3x.hpp"
#include "block_scaled_gemm_operation_3x.hpp"
#include "blockwise_gemm_operation_3x.hpp"

using namespace cute;
using namespace cutlass::library;
namespace cg = cutlass::gemm;
namespace ce = cutlass::epilogue;

namespace {

// Construct real library descriptions without instantiating a launch path or
// querying a GPU. The operators and collectives below are the actual builders.
template <class Base>
struct DescriptionOnlyCommon : Base {
  using Base::Base;
  cutlass::Status can_implement(void const*, void const*) const override {
    return cutlass::Status::kErrorNotSupported;
  }
  uint64_t get_device_workspace_size(void const*, void const*) const override { return 0; }
  cutlass::Status initialize(void const*, void*, void*, cudaStream_t) const override {
    return cutlass::Status::kErrorNotSupported;
  }
  cutlass::Status run(void const*, void*, void*, cudaStream_t) const override {
    return cutlass::Status::kErrorNotSupported;
  }
};

template <class Base>
struct DescriptionOnly : DescriptionOnlyCommon<Base> {
  using DescriptionOnlyCommon<Base>::DescriptionOnlyCommon;
  uint64_t get_host_workspace_size(void const*) const override { return 0; }
};

template <class Arch, class Element, class Schedule, class EpilogueSchedule,
          class Tile = Shape<_128, _128, _64>, class Cluster = Shape<_1, _1, _1>,
          bool Grouped = false, class OpClass = cutlass::arch::OpClassTensorOp>
struct GemmConfig {
  using LayoutA = conditional_t<Grouped, cutlass::layout::RowMajor*, cutlass::layout::RowMajor>;
  using LayoutB = conditional_t<Grouped, cutlass::layout::ColumnMajor*, cutlass::layout::ColumnMajor>;
  using ProblemShape = conditional_t<Grouped, cg::GroupProblemShape<Shape<int, int, int>>, Shape<int, int, int, int>>;
  static constexpr int Alignment = 128 / cutlass::sizeof_bits<Element>::value;
  static constexpr int AlignmentA = is_same_v<OpClass, cutlass::arch::OpClassSparseTensorOp> ? 2 * Alignment : Alignment;
  using Epilogue = typename ce::collective::CollectiveBuilder<
      Arch, cutlass::arch::OpClassTensorOp, Tile, Cluster,
      ce::collective::EpilogueTileAuto, float, float,
      cutlass::half_t, LayoutA, 8,
      cutlass::half_t, LayoutA, 8, EpilogueSchedule>::CollectiveOp;
  using Mainloop = typename cg::collective::CollectiveBuilder<
      Arch, OpClass,
      Element, LayoutA, AlignmentA,
      Element, LayoutB, Alignment,
      float, Tile, Cluster, cg::collective::StageCount<2>, Schedule>::CollectiveOp;
  using Kernel = cg::kernel::GemmUniversal<ProblemShape, Mainloop, Epilogue>;
  using Gemm = cg::device::GemmUniversalAdapter<Kernel>;
};

template <class Config>
void check_description(MainloopScheduleKind schedule, MainloopLoadKind load,
                       EpilogueScheduleKind epilogue, AccumulationKind accumulation = AccumulationKind::kDefault) {
  DescriptionOnly<GemmOperation3xBase<typename Config::Gemm>> operation("schedule_test");
  auto const& desc = operation.get_gemm_description();
  EXPECT_STREQ(desc.name, "schedule_test");
  EXPECT_EQ(desc.mainloop_schedule, schedule);
  EXPECT_EQ(desc.mainloop_load, load);
  EXPECT_EQ(desc.epilogue_schedule, epilogue);
  EXPECT_EQ(desc.accumulation_kind, accumulation);
  EXPECT_EQ(desc.A.element, NumericTypeID(NumericTypeMap<typename Config::Gemm::ElementA>::kId));
  EXPECT_EQ(desc.A.layout, LayoutTypeID::kRowMajor);
  EXPECT_EQ(desc.B.layout, LayoutTypeID::kColumnMajor);
  EXPECT_EQ(desc.tile_description.math_instruction.instruction_shape,
            cutlass::make_Coord(Config::Gemm::InstructionShape::kM,
                               Config::Gemm::InstructionShape::kN,
                               Config::Gemm::InstructionShape::kK));
}

TEST(GemmDescription, LegacyConstructorsDefaultToUnknown) {
  GemmDescription descriptions[] = {
      GemmDescription(),
      GemmDescription(GemmKind::kUniversal),
      GemmDescription(OperationDescription(), GemmKind::kUniversal,
                      TensorDescription(), TensorDescription(), TensorDescription(), TensorDescription(),
                      NumericTypeID::kF32, SplitKMode::kNone, ComplexTransform::kNone, ComplexTransform::kNone)};
  for (auto const& d : descriptions) {
    EXPECT_EQ(d.mainloop_schedule, MainloopScheduleKind::kUnknown);
    EXPECT_EQ(d.mainloop_load, MainloopLoadKind::kUnknown);
    EXPECT_EQ(d.epilogue_schedule, EpilogueScheduleKind::kUnknown);
    EXPECT_EQ(d.accumulation_kind, AccumulationKind::kUnknown);
  }
}

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)
TEST(GemmDescription, HopperCooperative) {
  using Config = GemmConfig<cutlass::arch::Sm90, cutlass::half_t,
      cg::KernelTmaWarpSpecializedCooperative, ce::TmaWarpSpecializedCooperative>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecializedCooperative,
                           MainloopLoadKind::kTma, EpilogueScheduleKind::kTma);
}

TEST(GemmDescription, HopperPingpongDirectStore) {
  using Config = GemmConfig<cutlass::arch::Sm90, cutlass::half_t,
      cg::KernelTmaWarpSpecializedPingpong, ce::NoSmemWarpSpecialized>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecializedPingpong,
                           MainloopLoadKind::kTma, EpilogueScheduleKind::kNoSmem);
}

TEST(GemmDescription, HopperFp8DefaultAndFastAccumulation) {
  using Default = GemmConfig<cutlass::arch::Sm90, cutlass::float_e4m3_t,
      cg::KernelTmaWarpSpecializedCooperative, ce::TmaWarpSpecializedCooperative>;
  using Fast = GemmConfig<cutlass::arch::Sm90, cutlass::float_e4m3_t,
      cg::KernelTmaWarpSpecializedCooperativeFP8FastAccum, ce::TmaWarpSpecializedCooperative>;
  check_description<Default>(MainloopScheduleKind::kWarpSpecializedCooperative,
                            MainloopLoadKind::kTma, EpilogueScheduleKind::kTma);
  check_description<Fast>(MainloopScheduleKind::kWarpSpecializedCooperative,
                         MainloopLoadKind::kTma, EpilogueScheduleKind::kTma, AccumulationKind::kFastAccum);
}

#endif

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
TEST(GemmDescription, BlackwellOneSm) {
  using Config = GemmConfig<cutlass::arch::Sm100, cutlass::half_t,
      cg::KernelTmaWarpSpecialized1SmSm100, ce::TmaWarpSpecialized1Sm>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecialized1Sm,
                           MainloopLoadKind::kTma, EpilogueScheduleKind::kTma);
}

TEST(GemmDescription, BlackwellTwoSm) {
  using Config = GemmConfig<cutlass::arch::Sm100, cutlass::half_t,
      cg::KernelTmaWarpSpecialized2SmSm100, ce::TmaWarpSpecialized2Sm,
      Shape<_256, _128, _64>, Shape<_2, _1, _1>>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecialized2Sm,
                           MainloopLoadKind::kTma, EpilogueScheduleKind::kTma);
}

TEST(GemmDescription, BlackwellAutoResolvesSchedule) {
  using Config = GemmConfig<cutlass::arch::Sm100, cutlass::half_t,
      cg::collective::KernelScheduleAuto, ce::collective::EpilogueScheduleAuto,
      Shape<_256, _128, _64>, Shape<_2, _1, _1>>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecialized2Sm,
                           MainloopLoadKind::kTma, EpilogueScheduleKind::kTma);
}

#endif


#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)
TEST(GemmDescription, HopperCpAsync) {
  using Config = GemmConfig<cutlass::arch::Sm90, cutlass::half_t,
      cg::KernelCpAsyncWarpSpecialized, ce::NoSmemWarpSpecialized>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecialized,
                           MainloopLoadKind::kCpAsync, EpilogueScheduleKind::kNoSmem);
}

TEST(GemmDescription, HopperGroupedFp8FastAccumulation) {
  using Config = GemmConfig<cutlass::arch::Sm90, cutlass::float_e4m3_t,
      cg::KernelPtrArrayTmaWarpSpecializedCooperativeFP8FastAccum, ce::PtrArrayTmaWarpSpecializedCooperative,
      Shape<_128, _128, _64>, Shape<_1, _1, _1>, true>;
  DescriptionOnlyCommon<GroupedGemmOperation3xBase<typename Config::Gemm>> operation;
  auto const& desc = static_cast<GroupedGemmDescription const&>(operation.description());
  EXPECT_EQ(desc.kind, OperationKind::kGroupedGemm);
  EXPECT_EQ(desc.gemm.mainloop_schedule, MainloopScheduleKind::kWarpSpecializedCooperative);
  EXPECT_EQ(desc.gemm.mainloop_load, MainloopLoadKind::kTma);
  EXPECT_EQ(desc.gemm.epilogue_schedule, EpilogueScheduleKind::kTma);
  EXPECT_EQ(desc.gemm.accumulation_kind, AccumulationKind::kFastAccum);
}

TEST(GemmDescription, HopperBlockwiseDescription) {
  using Tile = Shape<_128, _128, _128>;
  using Cluster = Shape<_1, _1, _1>;
  using ScaleConfig = cutlass::detail::Sm90BlockwiseScaleConfig<1, 128, 128>;
  using LayoutSFA = decltype(ScaleConfig::deduce_layoutSFA());
  using LayoutSFB = decltype(ScaleConfig::deduce_layoutSFB());
  using Epilogue = typename GemmConfig<cutlass::arch::Sm90, cutlass::float_e4m3_t,
      cg::KernelTmaWarpSpecializedCooperative, ce::TmaWarpSpecializedCooperative, Tile, Cluster>::Epilogue;
  using Mainloop = typename cg::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      cutlass::float_e4m3_t, tuple<cutlass::layout::RowMajor, LayoutSFA>, 16,
      cutlass::float_e4m3_t, tuple<cutlass::layout::ColumnMajor, LayoutSFB>, 16,
      float, Tile, Cluster, cg::collective::StageCountAutoCarveout<sizeof(typename Epilogue::SharedStorage)>,
      cg::KernelTmaWarpSpecializedCooperativeFP8Blockwise>::CollectiveOp;
  using Kernel = cg::kernel::GemmUniversal<Shape<int, int, int, int>, Mainloop, Epilogue>;
  using Gemm = cg::device::GemmUniversalAdapter<Kernel>;
  DescriptionOnly<BlockwiseGemmUniversal3xOperation<Gemm>> operation;
  auto const& desc = static_cast<BlockwiseGemmDescription const&>(operation.description());
  EXPECT_EQ(desc.kind, OperationKind::kBlockwiseGemm);
  EXPECT_EQ(desc.mainloop_schedule, MainloopScheduleKind::kWarpSpecializedCooperative);
  EXPECT_EQ(desc.mainloop_load, MainloopLoadKind::kTma);
  EXPECT_EQ(desc.epilogue_schedule, EpilogueScheduleKind::kTma);
  EXPECT_EQ(desc.accumulation_kind, AccumulationKind::kDefault);
  EXPECT_EQ(desc.SFKVecSize, 128);
}
#endif

#if defined(CUTLASS_ARCH_MMA_SPARSE_SM90_SUPPORTED)
TEST(GemmDescription, HopperSparse) {
  using Config = GemmConfig<cutlass::arch::Sm90, cutlass::half_t,
      cg::KernelTmaWarpSpecializedCooperative, ce::TmaWarpSpecializedCooperative,
      Shape<_128, _128, _64>, Shape<_1, _1, _1>, false, cutlass::arch::OpClassSparseTensorOp>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecializedCooperative,
                           MainloopLoadKind::kTma, EpilogueScheduleKind::kTma);
}
#endif

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
TEST(GemmDescription, BlackwellDirectStore) {
  using Config = GemmConfig<cutlass::arch::Sm100, cutlass::half_t,
      cg::KernelTmaWarpSpecialized1SmSm100, ce::NoSmemWarpSpecialized1Sm>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecialized1Sm,
                           MainloopLoadKind::kTma, EpilogueScheduleKind::kNoSmem);
}

TEST(GemmDescription, BlackwellOneSmWithTwoCtaCluster) {
  using Config = GemmConfig<cutlass::arch::Sm100, cutlass::half_t,
      cg::KernelTmaWarpSpecialized1SmSm100, ce::TmaWarpSpecialized1Sm,
      Shape<_128, _128, _64>, Shape<_2, _1, _1>>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecialized1Sm,
                           MainloopLoadKind::kTma, EpilogueScheduleKind::kTma);
}

TEST(GemmDescription, BlackwellCpAsync) {
  using Config = GemmConfig<cutlass::arch::Sm100, cutlass::half_t,
      cg::KernelWarpSpecialized1SmSm100, ce::NoSmemWarpSpecialized1Sm>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecialized1Sm,
                           MainloopLoadKind::kCpAsync, EpilogueScheduleKind::kNoSmem);
}

TEST(GemmDescription, BlackwellMixedTmaCpAsync) {
  using Config = GemmConfig<cutlass::arch::Sm100, cutlass::half_t,
      cg::KernelMixedTmaCpAsyncWarpSpecialized1SmSm100, ce::TmaWarpSpecialized1Sm>;
  check_description<Config>(MainloopScheduleKind::kWarpSpecialized1Sm,
                           MainloopLoadKind::kMixedTmaCpAsync, EpilogueScheduleKind::kTma);
}

TEST(GemmDescription, BlackwellGroupedTwoSm) {
  using Config = GemmConfig<cutlass::arch::Sm100, cutlass::half_t,
      cg::KernelPtrArrayTmaWarpSpecialized2SmSm100, ce::PtrArrayTmaWarpSpecialized2Sm,
      Shape<_256, _128, _64>, Shape<_2, _1, _1>, true>;
  DescriptionOnlyCommon<GroupedGemmOperation3xBase<typename Config::Gemm>> operation;
  auto const& desc = static_cast<GroupedGemmDescription const&>(operation.description());
  EXPECT_EQ(desc.kind, OperationKind::kGroupedGemm);
  EXPECT_EQ(desc.gemm.mainloop_schedule, MainloopScheduleKind::kWarpSpecialized2Sm);
  EXPECT_EQ(desc.gemm.mainloop_load, MainloopLoadKind::kTma);
  EXPECT_EQ(desc.gemm.epilogue_schedule, EpilogueScheduleKind::kTma);
  EXPECT_EQ(desc.gemm.accumulation_kind, AccumulationKind::kDefault);
}

TEST(GemmDescription, BlackwellBlockScaledDescription) {
  using Config = GemmConfig<cutlass::arch::Sm100, cutlass::mx_float8_t<cutlass::float_e4m3_t>,
      cg::collective::KernelScheduleAuto, ce::collective::EpilogueScheduleAuto,
      Shape<_256, _128, _128>, Shape<_2, _1, _1>, false, cutlass::arch::OpClassBlockScaledTensorOp>;
  DescriptionOnly<BlockScaledGemmUniversal3xOperationBase<typename Config::Gemm>> operation;
  auto const& desc = operation.get_gemm_description();
  EXPECT_EQ(desc.kind, OperationKind::kBlockScaledGemm);
  EXPECT_EQ(desc.mainloop_schedule, MainloopScheduleKind::kWarpSpecialized2Sm);
  EXPECT_EQ(desc.mainloop_load, MainloopLoadKind::kTma);
  EXPECT_EQ(desc.epilogue_schedule, EpilogueScheduleKind::kTma);
  EXPECT_EQ(desc.accumulation_kind, AccumulationKind::kDefault);
  EXPECT_EQ(desc.SFVecSize, 32);
}
#endif

TEST(GemmDescription, QuantizedConstructorsDefaultToUnknown) {
  BlockScaledGemmDescription block_scaled;
  EXPECT_EQ(block_scaled.mainloop_schedule, MainloopScheduleKind::kUnknown);
  EXPECT_EQ(block_scaled.mainloop_load, MainloopLoadKind::kUnknown);
  EXPECT_EQ(block_scaled.epilogue_schedule, EpilogueScheduleKind::kUnknown);
  EXPECT_EQ(block_scaled.accumulation_kind, AccumulationKind::kUnknown);
  BlockwiseGemmDescription blockwise;
  EXPECT_EQ(blockwise.mainloop_schedule, MainloopScheduleKind::kUnknown);
  EXPECT_EQ(blockwise.mainloop_load, MainloopLoadKind::kUnknown);
  EXPECT_EQ(blockwise.epilogue_schedule, EpilogueScheduleKind::kUnknown);
  EXPECT_EQ(blockwise.accumulation_kind, AccumulationKind::kUnknown);
}

struct CustomSchedule {};
struct CustomEpilogue {};
TEST(GemmDescription, CustomPoliciesStayUnknown) {
  EXPECT_EQ(KernelScheduleMap<CustomSchedule>::kSchedule, MainloopScheduleKind::kUnknown);
  EXPECT_EQ(KernelScheduleMap<CustomSchedule>::kLoad, MainloopLoadKind::kUnknown);
  EXPECT_EQ(KernelScheduleMap<CustomSchedule>::kAccumulation, AccumulationKind::kUnknown);
  EXPECT_EQ(CollectiveEpilogueScheduleMap<CustomEpilogue>::kId, EpilogueScheduleKind::kUnknown);
}

} // namespace
