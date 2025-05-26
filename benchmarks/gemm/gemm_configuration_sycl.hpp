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

#pragma once

#include "cute/atom/mma_atom.hpp"
#include "cute/atom/copy_atom.hpp"

#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/arch/arch.h"
#include "cutlass/arch/mma.h"
#include "cutlass/layout/layout.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"

#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"

using namespace cute;

namespace cutlass::gemm::device {

enum class Scheduler { Gemm, GemmSplitK, GemmStreamK };

template<
  class ArchTag,
  class ElementA, class LayoutA,
  class ElementB, class LayoutB,
  class ElementC, class LayoutC,
  class ElementAccumulator,
  class TileShape, Scheduler TileScheduler, class TiledMma = void,
  class GmemTiledCopyA = void, class GmemTiledCopyB = void,
  class EpilogueOp = epilogue::fusion::LinearCombination<float, float, float, float, FloatRoundStyle::round_to_nearest>>
struct GemmConfiguration {
  static_assert(sizeof(ElementA) == 0, "No valid GemmConfiguration configuration exists.");
};

/////////////////////////////////////////////////////////////////////////

// bfloat16

template<class ElementA, class LayoutA,
  class ElementB, class LayoutB, typename LayoutC,
  class TileShape, Scheduler TileScheduler,
  class TiledMma, class GmemTiledCopyA, class GmemTiledCopyB,  class EpilogueOp>
struct GemmConfiguration<
      arch::IntelXe,
      ElementA, LayoutA,
      ElementB, LayoutB,
      float, LayoutC,
      float,
      TileShape, TileScheduler, TiledMma,
      GmemTiledCopyA, GmemTiledCopyB, EpilogueOp>
{
  using KernelScheduleType = std::conditional_t<TileScheduler == Scheduler::Gemm,
    cutlass::gemm::KernelXe, cutlass::gemm::KernelXeCooperative>;
  using DispatchPolicy = MainloopIntelXeXMX16<3, KernelScheduleType>;

  // Configurations in benchmarks.hpp can pass either a layout tag (e.g. RowMajor) or a Stride directly
  using StrideA = std::conditional_t<cute::is_tuple_v<LayoutA>, LayoutA, TagToStrideA_t<LayoutA>>;
  using StrideB = std::conditional_t<cute::is_tuple_v<LayoutB>, LayoutB, TagToStrideB_t<LayoutB>>;
  using StrideC = std::conditional_t<cute::is_tuple_v<LayoutC>, LayoutC, TagToStrideC_t<LayoutC>>;

  using ClusterShape = Shape<_1, _1, _1>;
  static constexpr bool use_collective_mma_builder = std::is_void_v<TiledMma>;
  static_assert(
    use_collective_mma_builder == std::is_void_v<GmemTiledCopyA> and
    use_collective_mma_builder == std::is_void_v<GmemTiledCopyB>,
    "TiledMma, GmemTileCopyA, and GmemTileCopyB must be all void or none of them may be void."
  );
  // Mainloop
  using CollectiveMainloop =
    std::conditional_t<use_collective_mma_builder,
      typename cutlass::gemm::collective::CollectiveBuilder<
        cutlass::arch::IntelXe, cutlass::arch::OpClassTensorOp,
        ElementA, LayoutA, sizeof(ElementA),
        ElementB, LayoutB, sizeof(ElementB),
        float,
        TileShape, ClusterShape,
        cutlass::gemm::collective::StageCountAuto,
        KernelScheduleType
      >::CollectiveOp,
      collective::CollectiveMma<
        DispatchPolicy, TileShape,
        ElementA, StrideA,
        ElementB, StrideB,
        TiledMma,
        GmemTiledCopyA, void, void, identity, // A
        GmemTiledCopyB, void, void, identity // B
  >>;

  // Epilogue
  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::IntelXe, cutlass::arch::OpClassTensorOp,
    TileShape, ClusterShape,
    cutlass::epilogue::collective::EpilogueTileAuto, float,
    float,
    float, LayoutC, sizeof(float),
    float, LayoutC, sizeof(float),
    cutlass::epilogue::collective::EpilogueScheduleAuto,
    EpilogueOp
  >::CollectiveOp;

  using GemmKernel = kernel::GemmUniversal<
    Shape<int, int, int, int>,
    CollectiveMainloop,
    CollectiveEpilogue,
    std::conditional_t<TileScheduler == Scheduler::Gemm, void, cutlass::gemm::StreamKScheduler>
  >;

  using Gemm = GemmUniversalAdapter<GemmKernel>;

  constexpr static typename GemmKernel::Arguments defaultArguments() {
    using StreamKMode =
      cutlass::gemm::kernel::detail::PersistentTileSchedulerXeStreamKParams::DecompositionMode;
    if constexpr (TileScheduler == Scheduler::Gemm) {
      return {};
    } else if constexpr (TileScheduler == Scheduler::GemmStreamK) {
      typename GemmKernel::Arguments arguments{};
      arguments.scheduler = {1, StreamKMode::StreamK};
      return arguments;
    } else {
      static_assert(TileScheduler == Scheduler::GemmSplitK);
      typename GemmKernel::Arguments arguments{};
      arguments.scheduler = {2, StreamKMode::SplitK};
      return arguments;
    }
  }
};

} // namespace cutlass::gemm::device
