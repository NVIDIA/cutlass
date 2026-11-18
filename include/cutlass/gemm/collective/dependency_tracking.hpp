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


#pragma once

#include "cutlass/detail/dependent_false.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_mma_decl.hpp"

#include "cutlass/gemm/dependency_roles.hpp"

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

// Utility for converting already-instantiated collective mainloop to collective mainloop with
// TMA validity reporting.
template <
  class CollectiveMainloop_,
  ProducerRoleType ProducerRole,
  ConsumerRoleType ConsumerRole
>
struct make_dependency_tracking {
  static_assert(cutlass::detail::dependent_false<CollectiveMainloop_>,
    "gemm::collective::make_dependency_tracking only supports TMA-based dense GEMM Rubin (Sm107) collectives.");
};

// Sm100 specialization
// Needed because most trivial dense GEMMs for Sm107 reuse the Sm100 collective.
template <
  int Stages, int SchedulerPipelineStageCount, int AccumulatorPipelineStageCount,
  class ClusterShape, class ArchTag,
  class TileShape, class ElementA, class StrideA, class ElementB, class StrideB,
  class TiledMma, class GmemTiledCopyA, class SmemLayoutAtomA, class SmemCopyAtomA, class TransformA,
  class GmemTiledCopyB, class SmemLayoutAtomB, class SmemCopyAtomB, class TransformB,
  ProducerRoleType ProducerRole, ConsumerRoleType ConsumerRole
>
struct make_dependency_tracking<
  cutlass::gemm::collective::CollectiveMma<
    MainloopSm100TmaUmmaWarpSpecialized<
      Stages, SchedulerPipelineStageCount, AccumulatorPipelineStageCount, ClusterShape, ArchTag>,
    TileShape, ElementA, StrideA, ElementB, StrideB, TiledMma,
    GmemTiledCopyA, SmemLayoutAtomA, SmemCopyAtomA, TransformA,
    GmemTiledCopyB, SmemLayoutAtomB, SmemCopyAtomB, TransformB>,
  ProducerRole, ConsumerRole
> {
  static_assert(ArchTag::kMinComputeCapability == 107, "gemm::collective::make_dependency_tracking only supports Rubin (Sm107) for now.");

  using Mainloop = cutlass::gemm::collective::CollectiveMma<
      MainloopSm107TmaUmmaWarpSpecialized<
        Stages, SchedulerPipelineStageCount, AccumulatorPipelineStageCount, ClusterShape,
        /*WithBreuse=*/false, ArchTag, ProducerRole, ConsumerRole>,
      TileShape, ElementA, StrideA, ElementB, StrideB, TiledMma,
      GmemTiledCopyA, SmemLayoutAtomA, SmemCopyAtomA, TransformA,
      GmemTiledCopyB, SmemLayoutAtomB, SmemCopyAtomB, TransformB>;
};

// Sm107 specialization; any roles already on the input policy are replaced with the new ones.
template <
  int Stages, int SchedulerPipelineStageCount, int AccumulatorPipelineStageCount,
  class ClusterShape, bool WithBreuse, class ArchTag,
  ProducerRoleType OldProducerRole, ConsumerRoleType OldConsumerRole,
  class TileShape, class ElementA, class StrideA, class ElementB, class StrideB,
  class TiledMma, class GmemTiledCopyA, class SmemLayoutAtomA, class SmemCopyAtomA, class TransformA,
  class GmemTiledCopyB, class SmemLayoutAtomB, class SmemCopyAtomB, class TransformB,
  ProducerRoleType ProducerRole, ConsumerRoleType ConsumerRole
>
struct make_dependency_tracking<
  cutlass::gemm::collective::CollectiveMma<
    MainloopSm107TmaUmmaWarpSpecialized<
      Stages, SchedulerPipelineStageCount, AccumulatorPipelineStageCount, ClusterShape,
      WithBreuse, ArchTag, OldProducerRole, OldConsumerRole>,
    TileShape, ElementA, StrideA, ElementB, StrideB, TiledMma,
    GmemTiledCopyA, SmemLayoutAtomA, SmemCopyAtomA, TransformA,
    GmemTiledCopyB, SmemLayoutAtomB, SmemCopyAtomB, TransformB>,
  ProducerRole, ConsumerRole
> {
  static_assert(ArchTag::kMinComputeCapability == 107, "gemm::collective::make_dependency_tracking only supports Rubin (Sm107) for now.");

  using Mainloop = cutlass::gemm::collective::CollectiveMma<
      MainloopSm107TmaUmmaWarpSpecialized<
        Stages, SchedulerPipelineStageCount, AccumulatorPipelineStageCount, ClusterShape,
        WithBreuse, ArchTag, ProducerRole, ConsumerRole>,
      TileShape, ElementA, StrideA, ElementB, StrideB, TiledMma,
      GmemTiledCopyA, SmemLayoutAtomA, SmemCopyAtomA, TransformA,
      GmemTiledCopyB, SmemLayoutAtomB, SmemCopyAtomB, TransformB>;
};

} // namespace detail

template <
  class CollectiveMainloop_,
  ProducerRoleType ProducerRole,
  ConsumerRoleType ConsumerRole
>
using make_dependency_tracking =
    typename detail::make_dependency_tracking<
        CollectiveMainloop_, ProducerRole, ConsumerRole>::Mainloop;

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
