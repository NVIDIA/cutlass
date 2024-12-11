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

#include <cutlass/arch/arch.h>
#include <cutlass/gemm/dispatch_policy.hpp>

#include "cutlass/gemm/collective/device_agnostic_mma.hpp"


namespace cutlass::gemm::collective {

template <
  class ElementA,
  class GmemLayoutATag,
  int AlignmentA,
  class ElementB,
  class GmemLayoutBTag,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class KernelScheduleType
  > 
struct CollectiveBuilder<
  arch::Agnostic,
  arch::OpMultiplyAdd,
  ElementA,
  GmemLayoutATag,
  AlignmentA,
  ElementB,
  GmemLayoutBTag,
  AlignmentB,
  ElementAccumulator,
  TileShape_MNK,
  Shape<_1, _1, _1>,    // Cluster Shape
  cutlass::gemm::collective::StageCountAuto, 
  KernelScheduleType,
  cute::enable_if_t<
     cute::is_same_v<KernelScheduleType, KernelScheduleAuto>>
>{
#ifndef CUTLASS_ENABLE_SYCL
  static_assert(cutlass::detail::dependent_false<arch::Agnostic>,
    "Trying to use device Agnostic pipeline without SYCL enabled");
#endif

  using TiledMMA = TiledMMA<MMA_Atom<UniversalFMA<ElementAccumulator, ElementA, ElementB, ElementAccumulator>>,
                        Layout<Shape<_4, _4, _1>>>;

  using DispatchPolicy = MainloopDeviceAgnostic;
  using GmemTiledCopyA = decltype(
        make_tiled_copy(Copy_Atom<UniversalCopy<ElementA>, ElementA>{},
                        Layout<Shape<_4, _4>, Stride<_4, _1>>{},
                        Layout<Shape<_1, _1>>{}
        ));

  using GmemTiledCopyB = decltype(
        make_tiled_copy(Copy_Atom<UniversalCopy<ElementB>, ElementB>{},
                        Layout<Shape<_4, _4>, Stride<_1, _4>>{},
                        Layout<Shape<_1, _1>>{}
        ));

  using SmemCopyAtomA = Copy_Atom<UniversalCopy<ElementA>, ElementA>;
  using SmemCopyAtomB = Copy_Atom<UniversalCopy<ElementB>, ElementB>;

  //
  using SmemLayoutAtomA = decltype(
    make_layout(make_shape(get<0>(TileShape_MNK{}), get<2>(TileShape_MNK{})),
                make_stride(_1{}, get<0>(TileShape_MNK{})))
  );

  using SmemLayoutAtomB = decltype(
    make_layout(make_shape(get<1>(TileShape_MNK{}), get<2>(TileShape_MNK{})),
                make_stride(_1{}, get<1>(TileShape_MNK{})))
  );

  using TransformA = cute::identity;
  using TransformB = cute::identity;

  using CollectiveOp = cutlass::gemm::collective::CollectiveMma<
    MainloopDeviceAgnostic,
    TileShape_MNK,
    ElementA,
    cutlass::gemm::TagToStrideA_t<GmemLayoutATag>,
    ElementB,
    cutlass::gemm::TagToStrideB_t<GmemLayoutBTag>,
    TiledMMA,
    GmemTiledCopyA,
    SmemLayoutAtomA,
    SmemCopyAtomA,
    TransformA,
    GmemTiledCopyB,
    SmemLayoutAtomB,
    SmemCopyAtomB,
    TransformB
  >;
};

} // namespace cutlass::gemm::collective
