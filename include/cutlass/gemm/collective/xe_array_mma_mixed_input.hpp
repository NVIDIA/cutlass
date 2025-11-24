/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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

#include "cutlass/cutlass.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/fp8_to_fp16.h"

#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/gemm.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {
using namespace cute;

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int Stages,
  class Schedule,
  class TileShape_,
  class ElementAOptionalTuple,
  class StrideA_,
  class ElementBOptionalTuple,
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
struct CollectiveMma<
    MainloopIntelXeXMX16GroupMixedPrecision<Stages, Schedule>,
    TileShape_,
    ElementAOptionalTuple,
    StrideA_,
    ElementBOptionalTuple,
    StrideB_,
    TiledMma_,
    GmemTiledCopyA_,
    SmemLayoutAtomA_,
    SmemCopyAtomA_,
    TransformA_,
    GmemTiledCopyB_,
    SmemLayoutAtomB_,
    SmemCopyAtomB_,
    TransformB_> : public CollectiveMma<MainloopIntelXeXMX16MixedPrecision<Stages>,
                                TileShape_,
                                ElementAOptionalTuple,
                                StrideA_,
                                ElementBOptionalTuple,
                                StrideB_,
                                TiledMma_,
                                GmemTiledCopyA_,
                                SmemLayoutAtomA_,
                                SmemCopyAtomA_,
                                TransformA_,
                                GmemTiledCopyB_,
                                SmemLayoutAtomB_,
                                SmemCopyAtomB_,
                                TransformB_>
{
public:
  //
  // Type Aliases
  //
  using Base = CollectiveMma<MainloopIntelXeXMX16MixedPrecision<Stages>,
                                TileShape_,
                                ElementAOptionalTuple,
                                StrideA_,
                                ElementBOptionalTuple,
                                StrideB_,
                                TiledMma_,
                                GmemTiledCopyA_,
                                SmemLayoutAtomA_,
                                SmemCopyAtomA_,
                                TransformA_,
                                GmemTiledCopyB_,
                                SmemLayoutAtomB_,
                                SmemCopyAtomB_,
                                TransformB_>;
  using BaseArguments = typename Base::Arguments;
  using BaseParams = typename Base::Params;

  using ElementA = typename Base::ElementA;
  using ElementB = typename Base::ElementB;
  using ElementScale = typename Base::ElementScale;
  using ElementZero = typename Base::ElementZero;

  using StrideScale = typename Base::StrideScale;
  using StrideZero = typename Base::StrideZero;

  using NonVoidStrideScale = cute::conditional_t<cute::is_same_v<StrideScale, void>, cute::Stride<_1, int64_t, int64_t> *, StrideScale>;
  using NonVoidStrideZero = cute::conditional_t<cute::is_same_v<StrideZero, void>, cute::Stride<_1, int64_t, int64_t> *, StrideZero>;

  using NonVoidElementScale = typename Base::NonVoidElementScale;
  using NonVoidElementZero = typename Base::NonVoidElementZero;

  using DispatchPolicy = MainloopIntelXeXMX16GroupMixedPrecision<Stages, Schedule>;

  using InternalNonVoidStrideScale = cute::remove_pointer_t<NonVoidStrideScale>;
  using InternalNonVoidStrideZero = cute::remove_pointer_t<NonVoidStrideZero>;

  using StrideA = StrideA_;
  using InternalStrideA = typename Base::StrideA;
  using StrideB = StrideB_;
  using InternalStrideB = typename Base::StrideB;

  // Host side kernel arguments
  struct Arguments {
    ElementA const** ptr_A;
    StrideA dA;
    ElementB const** ptr_B;
    StrideB dB;
    NonVoidElementScale const** ptr_S = nullptr;
    NonVoidStrideScale dS{};
    NonVoidElementZero const** ptr_Z = nullptr;
    NonVoidStrideZero dZ{};
    int group_size = 1;
  };

  using Params = Arguments;

  //
  // Methods
  //

  CollectiveMma() = default;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const &problem_shape,
                          Arguments const &args, void *workspace) {
    (void)workspace;
    return Params{args.ptr_A, args.dA, args.ptr_B, args.dB, args.ptr_S, args.dS, args.ptr_Z, args.dZ, args.group_size};
  }

  template<class ProblemShape>
  static bool
  can_implement(
      ProblemShape problem_shapes,
      Arguments const& args) {
    constexpr int copy_alignment_bits = 128;
    constexpr int batch_alignment_bits = 512;
    auto problem_shape_MNKL = append<4>(problem_shapes, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    bool implementable = true;

    constexpr int min_aligned_elements_A = copy_alignment_bits / sizeof_bits<ElementA>::value;
    constexpr int min_aligned_elements_B = copy_alignment_bits / sizeof_bits<ElementB>::value;
    constexpr int min_batch_aligned_elements_A = batch_alignment_bits / sizeof_bits<ElementA>::value;
    constexpr int min_batch_aligned_elements_B = batch_alignment_bits / sizeof_bits<ElementB>::value;
    for (int i = 0; i < problem_shapes.groups(); i++) {
      auto problem_shape_MNKL = append<4>(problem_shapes.get_host_problem_shape(i), 1);
      auto [M,N,K,L] = problem_shape_MNKL;

      implementable &= cutlass::detail::check_alignment<min_aligned_elements_A>(cute::make_shape(M,K,L), InternalStrideA{});
      implementable &= cutlass::detail::check_alignment<min_aligned_elements_B>(cute::make_shape(N,K,L), InternalStrideB{});

      if (L > 1) {
        implementable &= get<2>(InternalStrideA{}) % min_batch_aligned_elements_A == 0;
        implementable &= get<2>(InternalStrideB{}) % min_batch_aligned_elements_B == 0;
      }
    }

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for XE 2D copy.\n");
    }

    return implementable;
  }

  CUTLASS_DEVICE static constexpr BaseArguments
  to_base_arguments(Arguments const &args, int idx) {
    return BaseArguments{ args.ptr_A[idx], args.dA[idx],
                          args.ptr_B[idx], args.dB[idx],
                          args.ptr_S[idx], args.dS[idx],
                          args.ptr_Z[idx], args.dZ[idx],
                          args.group_size};
  }

};


} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
