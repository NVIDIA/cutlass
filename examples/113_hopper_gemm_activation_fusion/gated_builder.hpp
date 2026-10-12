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
#pragma once

// This is a temp fix for circular include issue in CuTe
#include "cute/atom/copy_atom.hpp"

#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"

#include "gated_stride.hpp"
#include "sm90_visitor_gated_act.hpp"

namespace cutlass::detail {

template <int ModeIndex, class InputStride>
using GatedStride = cute::conditional_t<
  cutlass::detail::is_major<ModeIndex, InputStride>(),
  decltype(replace<ModeIndex>(InputStride{}, cute::Stride<cute::_1,int64_t,cute::_8>{})),
  decltype(replace<ModeIndex>(InputStride{}, cute::Stride< int64_t,int64_t, int64_t>{}))
>;

template <int ModeIndex, class InputStride>
using GatedOutputStride = cute::conditional_t<
  cutlass::detail::is_major<ModeIndex, InputStride>(),
  decltype(replace<ModeIndex>(InputStride{}, cute::Stride<cute::_1,cute::_8>{})),
  decltype(replace<ModeIndex>(InputStride{}, cute::Stride< int64_t, int64_t>{}))
>;

}

namespace cutlass::gemm::collective {

template <
  class OpClass,
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK_,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct Sm90CollectiveBuilderGated {

  using TileShape_MNK = decltype(cutlass::sm90_make_gated_shape<0>(TileShape_MNK_{}));

  using InternalStrideA = cute::remove_pointer_t<cutlass::gemm::TagToStrideA_t<GmemLayoutA>>;
  using GatedInternalStrideA = cutlass::detail::GatedStride<0, InternalStrideA>;
  using StrideA = cute::conditional_t<platform::is_pointer<GmemLayoutA>::value, GatedInternalStrideA *, GatedInternalStrideA>;

  using StrideB = cutlass::gemm::TagToStrideB_t<GmemLayoutB>;
  
  using CollectiveOp = typename CollectiveBuilder<
    arch::Sm90, OpClass,
    ElementA, StrideA, AlignmentA,
    ElementB, StrideB, AlignmentB,
    ElementAccumulator,
    TileShape_MNK, ClusterShape_MNK,
    StageCountType, KernelScheduleType
  >::CollectiveOp;
};

} // namespace cutlass::gemm::collective

namespace cutlass::epilogue::collective {

template <
  class OpClass,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementScalar,
  class ElementIntermediate,
  class ElementC,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class EpilogueSchedule,
  template <class> class ActivationFn,
  bool Quantize
>
struct Sm90CollectiveBuilderGated {

  static constexpr bool IsPtrArray = platform::is_pointer<GmemLayoutTagD>::value;

  using EpilogueTile_MN =
    decltype(detail::sm90_compute_tile_shape_or_override<ElementD, EpilogueTileType, EpilogueSchedule, TileShape_MNK>());

  // Factor out a 8x2 sub-tile in TileM
  using GatedTileShape_MNK = decltype(cutlass::sm90_make_gated_shape<0>(TileShape_MNK{}));
  using GatedEpilogueTile_MN = decltype(cutlass::sm90_make_gated_shape<0>(EpilogueTile_MN{}));

  using InternalStrideC = cute::remove_pointer_t<cutlass::gemm::TagToStrideC_t<GmemLayoutTagC>>;
  using GatedInternalStrideC = cutlass::detail::GatedStride<0, InternalStrideC>;
  using StrideC = cute::conditional_t<IsPtrArray, GatedInternalStrideC *, GatedInternalStrideC>;

  using InternalStrideD = cute::remove_pointer_t<cutlass::gemm::TagToStrideC_t<GmemLayoutTagD>>;
  using GatedInternalStrideD = cutlass::detail::GatedStride<0, InternalStrideD>;
  using StrideD = cute::conditional_t<IsPtrArray, GatedInternalStrideD *, GatedInternalStrideD>;

  // Gated kernel uses Aux output instead of D due to change in tensor shape
  using InternalStrideDAux = cutlass::detail::GatedOutputStride<0, InternalStrideD>;
  using StrideDAux = cute::conditional_t<IsPtrArray, InternalStrideDAux *, InternalStrideDAux>;

  using FusionOp = cutlass::epilogue::fusion::LinCombGatedActFunc<
    Quantize,            // Quantize
    ActivationFn,        // ActivationFn
    StrideDAux,          // GmemLayoutTagOutput
    ElementD,            // ElementOutput
    ElementCompute,      // ElementCompute
    ElementC,            // ElementSource
    ElementScalar,       // ElementScalar
    ElementIntermediate, // ElementIntermediate
    AlignmentD           // Alignment
  >;

  using CollectiveOp = typename CollectiveBuilder<
    arch::Sm90,
    OpClass,
    GatedTileShape_MNK,
    ClusterShape_MNK,
    GatedEpilogueTile_MN,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    StrideC,
    AlignmentC,
    void, // output through AuxStore
    StrideD,
    AlignmentD,
    EpilogueSchedule,
    FusionOp
  >::CollectiveOp;
};

} // namespace cutlass::epilogue::collective 
