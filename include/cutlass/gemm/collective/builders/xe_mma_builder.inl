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

#include "cutlass/gemm/collective/collective_mma.hpp"

namespace cutlass::gemm::collective {

  // Intel Xe 3 stage pipeline, using prefetch
  // Also the auto builder

template<typename MMAAtom, typename T_m, typename T_n>
constexpr auto get_num_atoms(T_m tile_m, T_n tile_n){
  constexpr auto atom_m = get<0>(typename MMAAtom::Shape_MNK{});
  constexpr auto atom_n = get<1>(typename MMAAtom::Shape_MNK{});
  // try to create the biggest number of atoms possible, up to 32, trying to fit the most, up to 8 in m dimension
  auto atoms_m_tmp = cute::min(tile_m / atom_m, _8{}); // at most 8
  auto atoms_n = cute::min(tile_n / atom_n, _32{} / atoms_m_tmp); // at most however many are not in m out of 32
  auto atoms_m = cute::min(tile_m / atom_m, _32{} / atoms_n);  // at most however many are not in n out of 32
  return make_shape(atoms_m, atoms_n);
}

template<bool is_t, bool is_v, typename T_m, typename T_n>
constexpr auto select_copy_atom_16b(T_m tile_m, T_n tile_n){
  #define RETURN_ATOM(WIDTH, HEIGHT, LETTER) \
    return XE_2D_U16x##WIDTH##x##HEIGHT##_LD_##LETTER {};

  if constexpr(is_t){
    // tile_m and tile_n have swapped role in case of _T
    static_assert(tile_n % 16 == 0 && "Invalid tile_m");
    if constexpr(tile_m == 8){
      RETURN_ATOM(16, 8, T)
    } else if constexpr(tile_m % 16 == 0){
      RETURN_ATOM(16, 16, T)
    } else{
      static_assert(dependent_false<T_m> && "Invalid tile_n");
    }
  } else if constexpr(is_v){
    #define SELECT_HEIGHT_V(WIDTH) \
      if constexpr(tile_n == 16){ \
        RETURN_ATOM(WIDTH, 16, V) \
      } else if constexpr(tile_n % 32 == 0){ \
        RETURN_ATOM(WIDTH, 32, V) \
      } else{ \
        static_assert(dependent_false<T_n> && "Invalid tile_n"); \
      }

    if constexpr(tile_m == 16){
      SELECT_HEIGHT_V(16)
    } else if constexpr(tile_m % 32 == 0){
      SELECT_HEIGHT_V(32)
    } else{
      static_assert(dependent_false<T_m> && "Invalid tile_m");
    }
    #undef SELECT_HEIGHT_V
  } else{ // _N
    #define SELECT_WIDTH_N(HEIGHT) \
      if constexpr(tile_m == 1){ \
        RETURN_ATOM(1, HEIGHT, N) \
      } else if constexpr(tile_m == 2){ \
        RETURN_ATOM(2, HEIGHT, N) \
      } else if constexpr(tile_m == 4){ \
        RETURN_ATOM(4, HEIGHT, N) \
      } else if constexpr(tile_m == 8){ \
        RETURN_ATOM(8, HEIGHT, N) \
      } else if constexpr(tile_m == 16){ \
        RETURN_ATOM(16, HEIGHT, N) \
      } else if constexpr(tile_m % 32 == 0){ \
        RETURN_ATOM(32, HEIGHT, N) \
      } else { \
        static_assert(dependent_false<T_m> && "Invalid tile_m"); \
      }

    if constexpr(tile_n == 16){
      SELECT_WIDTH_N(16)
    } else if constexpr(tile_n % 32 == 0){
      SELECT_WIDTH_N(32)
    } else {
      static_assert(dependent_false<T_n> && "Invalid tile_n");
    }
    #undef SELECT_WIDTH_N
  }
  #undef RETURN_ATOM
}

namespace {
template <typename ElementAB, typename ElementCD>
struct pick_mma_atom{
  static_assert(dependent_false<ElementAB> && "no mma atom for this combination of types");
};

#define PICK_MMA(ElementAB, ElementCD, ATOM)             \
template <> struct pick_mma_atom<ElementAB, ElementCD> { \
  using atom = MMA_Atom<ATOM>;                           \
};

PICK_MMA(bfloat16_t, float, XE_8x16x16_F32BF16BF16F32_TT);
PICK_MMA(bfloat16_t, bfloat16_t, XE_8x16x16_BF16BF16BF16BF16_TT);
PICK_MMA(half_t, float, XE_8x16x16_F32F16F16F32_TT);
PICK_MMA(half_t, half_t, XE_8x16x16_F16F16F16F16_TT);

#undef PICK_MMA
}

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
  arch::IntelXe,
  arch::OpClassTensorOp,   // Reusing opClassTensorOp for Intel devices
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
    cute::is_any_of_v<KernelScheduleType, KernelScheduleAuto, KernelXe, KernelXeCooperative, KernelXePtrArrayCooperative> &&
    cute::is_same_v<ElementA, ElementB> &&
    cute::is_any_of_v<ElementA, bfloat16_t, half_t> &&
    cute::is_any_of_v<ElementB, bfloat16_t, half_t>
  >
    >{

      #ifdef SYCL_NVIDIA_TARGET
        static_assert(cutlass::detail::dependent_false<arch::IntelXe>,
          "Trying to use Intel pipeline on Non Intel hardware");
      #endif
      static_assert(is_static<TileShape_MNK>::value);
      static_assert(cute::is_any_of_v<ElementAccumulator, float, bfloat16_t, half_t>,
        "Intel multi-stage pipeline requires ElementC to be of type float, bfloat or half");

      using MMAAtom = typename pick_mma_atom<ElementA, ElementAccumulator>::atom;

      static constexpr auto tile_M = get<0>(TileShape_MNK{});
      static constexpr auto tile_N = get<1>(TileShape_MNK{});
      static constexpr auto tile_K = get<2>(TileShape_MNK{});

      static constexpr auto n_atoms = get_num_atoms<MMAAtom>(tile_M, tile_N);
      using atoms_M = decltype(get<0>(n_atoms));
      using atoms_N = decltype(get<1>(n_atoms));
      using TiledMma =
          typename TiledMMAHelper<MMAAtom,
                                  Layout<TileShape_MNK>,
                                  Layout<Shape<atoms_M, atoms_N, _1>, Stride<atoms_N, _1, _0>>>::TiledMMA;

      static constexpr bool IsGroup = cute::is_same_v<KernelScheduleType, KernelXePtrArrayCooperative>;

      using KernelSchedule = std::conditional_t<cute::is_same_v<KernelScheduleType, KernelScheduleAuto>, KernelXe, KernelScheduleType>;
      static constexpr int PipelineStages = IsGroup ? 2 : 3;
      using DispatchPolicy = std::conditional_t<IsGroup,
                                                cutlass::gemm::MainloopIntelXeXMX16Group<PipelineStages, KernelSchedule>,
                                                cutlass::gemm::MainloopIntelXeXMX16<PipelineStages, KernelSchedule>>;

      using GmemTiledCopyA = decltype(select_copy_atom_16b<cute::is_same_v<GmemLayoutATag, cutlass::layout::ColumnMajor>, false>(tile_M/atoms_M{}, tile_K));
      using GmemTiledCopyB = decltype(select_copy_atom_16b<cute::is_same_v<GmemLayoutBTag, cutlass::layout::ColumnMajor>, true>(tile_K, tile_N/atoms_N{}));

      // Xe pipeline does not use shared memory
      using SmemLayoutAtomA = void;
      using SmemLayoutAtomB = void;
      using SmemCopyAtomA = void;
      using SmemCopyAtomB = void;

      using TransformA = cute::identity;
      using TransformB = cute::identity;

      using CollectiveOp = cutlass::gemm::collective::CollectiveMma<
              DispatchPolicy,
              TileShape_MNK,
              ElementA,
              cutlass::gemm::TagToStrideA_t<std::conditional_t<IsGroup, GmemLayoutATag*, GmemLayoutATag>>,
              ElementB,
              cutlass::gemm::TagToStrideB_t<std::conditional_t<IsGroup, GmemLayoutBTag*, GmemLayoutBTag>>,
              TiledMma,
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
}
