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

#include "cutlass/gemm/collective/sm70_mma_twostage.hpp"

namespace cutlass::gemm::collective {
  using namespace cute;

template <
  class TileShape_,
  class ElementA_,
  class StrideA_,
  class ElementB_,
  class StrideB_,
  class TiledMma_,
  class GmemTiledCopyA_,
  class SmemLayoutAtomA_,
  class SmemCopyAtomA_,
  class TransformA_,
  class GmemTiledCopyB_,
  class SmemLayoutAtomB_,
  class SmemCopyAtomB_,
  class TransformB_>
struct CollectiveMma <
  MainloopDeviceAgnostic,
  TileShape_,
  ElementA_,
  StrideA_,
  ElementB_,
  StrideB_,
  TiledMma_,
  GmemTiledCopyA_,
  SmemLayoutAtomA_,
  SmemCopyAtomA_,
  TransformA_,
  GmemTiledCopyB_,
  SmemLayoutAtomB_,
  SmemCopyAtomB_,
  TransformB_
> : 
  CollectiveMma<
    MainloopSm70TwoStage,
    TileShape_,
    ElementA_,
    StrideA_,
    ElementB_,
    StrideB_,
    TiledMma_,
    GmemTiledCopyA_,
    SmemLayoutAtomA_,
    SmemCopyAtomA_,
    TransformA_,
    GmemTiledCopyB_,
    SmemLayoutAtomB_,
    SmemCopyAtomB_,
    TransformB_
  >

 {
    using DispatchPolicy = MainloopDeviceAgnostic;
    using TileShape = TileShape_;
    using ElementA = ElementA_;
    using StrideA = StrideA_;
    using ElementB = ElementB_;
    using StrideB = StrideB_;
    using TiledMma = TiledMma_;
    using ElementAccumulator = typename TiledMma::ValTypeC;
    using GmemTiledCopyA = GmemTiledCopyA_;
    using GmemTiledCopyB = GmemTiledCopyB_;
    using SmemLayoutAtomA = SmemLayoutAtomA_;
    using SmemLayoutAtomB = SmemLayoutAtomB_;
    using SmemCopyAtomA = SmemCopyAtomA_;
    using SmemCopyAtomB = SmemCopyAtomB_;
    using TransformA = TransformA_;
    using TransformB = TransformB_;
    using ArchTag = typename DispatchPolicy::ArchTag;

    static_assert(cute::rank(SmemLayoutAtomA{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
    static_assert((size<0>(TileShape{}) % size<0>(SmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
    static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

    static_assert(cute::rank(SmemLayoutAtomB{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
    static_assert((size<1>(TileShape{}) % size<0>(SmemLayoutAtomB{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
    static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomB{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

    using SmemLayoutA = decltype(tile_to_shape(
        SmemLayoutAtomA{},
        make_shape(shape<0>(TileShape{}), shape<2>(TileShape{}))));
    using SmemLayoutB = decltype(tile_to_shape(
        SmemLayoutAtomB{},
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{}))));

    struct SharedStorage
    {
      cute::array_aligned<ElementA, cute::cosize_v<SmemLayoutA>> smem_a;
      cute::array_aligned<ElementB, cute::cosize_v<SmemLayoutB>> smem_b;
    };


    struct Arguments {
      ElementA const* ptr_A;
      StrideA dA;
      ElementB const* ptr_B;
      StrideB dB;
    };
  
    using Params = Arguments;

    template <class ProblemShape>
    static constexpr Params
    to_underlying_arguments(ProblemShape const& _, Arguments const& args, void* workspace) {
      (void) workspace;
      return args;
    }
      
  template <
    class FrgTensorD,
    class TensorA,
    class TensorB,
    class FrgTensorC,
    class KTileIterator,
    class ResidueMNK
  >
  CUTLASS_DEVICE void
  operator() (
      FrgTensorD &accum,
      TensorA gA,
      TensorB gB,
      FrgTensorC const &src_accum,
      KTileIterator k_tile_iter, int k_tile_count,
      ResidueMNK residue_mnk,
      int thread_idx,
      char *smem_buf)
    {
      // We can reuse the 2 stage blocking gemm in SM_70 predicated pipeline, giving a somewhat performant 
      // device agnostic pipeline

      CollectiveMma<
        MainloopSm70TwoStage,
        TileShape_,
        ElementA_,
        StrideA_,
        ElementB_,
        StrideB_,
        TiledMma_,
        GmemTiledCopyA_,
        SmemLayoutAtomA_,
        SmemCopyAtomA_,
        TransformA_,
        GmemTiledCopyB_,
        SmemLayoutAtomB_,
        SmemCopyAtomB_,
        TransformB_
      >::operator()(
        accum,
        gA,
        gB,
        src_accum, 
        k_tile_iter, k_tile_count,
        residue_mnk, thread_idx,
        smem_buf
      );
    }
  };
}
