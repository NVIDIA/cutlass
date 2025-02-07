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
#include "cutlass/epilogue/collective/collective_builder.hpp"

#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"

using namespace cute;

namespace cutlass {
namespace gemm {
namespace device {

template<
  class ArchTag,
  class ElementA, class LayoutA, int kAlignmentA,
  class ElementB, class LayoutB, int kAlignmentB,
  class ElementC, class LayoutC,
  class ElementAccumulator>
struct GemmConfiguration {
  static_assert(sizeof(ElementA) == 0, "No valid GemmConfiguration configuration exists.");
};

/////////////////////////////////////////////////////////////////////////

// half

namespace detail {
template<typename Element, typename Layout, int Alignment, int SizeK>
struct Gemm_OperandA;

template<typename Element, typename Layout, int Alignment, int SizeK>
struct Gemm_OperandB;

/// Operand A - Column-major (M-major)
template<int SizeK>
struct Gemm_OperandA<half_t, layout::ColumnMajor, 8, SizeK> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<3, 3, 3>{},
                Layout<Shape<_64, _8>,
                  Stride<_1, _64> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U16x8_LDSM_T, half_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<uint128_t>, half_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_1, _16> >{},
                    Layout<Shape<_8, _1> >{}));
};

template<int SizeK>
struct Gemm_OperandA<half_t, layout::ColumnMajor, 4, SizeK> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<3, 3, 3>{},
                Layout<Shape<_64, _8>,
                  Stride<_1, _64> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U16x8_LDSM_T, half_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<UniversalCopy<uint64_t>, half_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_1, _16> >{},
                    Layout<Shape<_8, _1> >{}));
};

template<int SizeK>
struct Gemm_OperandA<half_t, layout::ColumnMajor, 1, SizeK> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<3, 3, 3>{},
                Layout<Shape<_64, _8>,
                  Stride<_1, _64> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U16x8_LDSM_T, half_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<UniversalCopy<uint16_t>, half_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_1, _16> >{},
                    Layout<Shape<_8, _1> >{}));
};

/// Operand A - Row-major (K-Major)
template<>
struct Gemm_OperandA<half_t, layout::RowMajor, 8, 32> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<2, 3, 3>{},
                Layout<Shape<_8, _32>,
                  Stride<_32, _1> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U32x4_LDSM_N, half_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<uint128_t>, half_t>{},
                    Layout<Shape<_32, _4>,
                      Stride<_4, _1> >{},
                    Layout<Shape<_1, _8> >{}));
};

template<>
struct Gemm_OperandA<half_t, layout::RowMajor, 1, 32> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<2, 3, 3>{},
                Layout<Shape<_8, _32>,
                  Stride<_32, _1> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U32x4_LDSM_N, half_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<UniversalCopy<uint16_t>, half_t>{},
                    Layout<Shape<_32, _4>,
                      Stride<_4, _1> >{},
                    Layout<Shape<_1, _8> >{}));
};

// Because the F32F16 TiledMMA is A-B symmetric, we can reuse the Operands

// Operand B - Column-Major (K-major)
template<int Alignment, int SizeK>
struct Gemm_OperandB<half_t, layout::ColumnMajor, Alignment, SizeK>
    : Gemm_OperandA<half_t, layout::RowMajor, Alignment, SizeK> {
};

// Operand B - Row-Major (N-major)
template<int Alignment, int SizeK>
struct Gemm_OperandB<half_t, layout::RowMajor, Alignment, SizeK>
    : Gemm_OperandA<half_t, layout::ColumnMajor, Alignment, SizeK> {
};
} // namespace details

template<typename LayoutA, int kAlignmentA, typename LayoutB, int kAlignmentB, typename LayoutC>
struct GemmConfiguration<
      arch::Sm80,
      half_t, LayoutA, kAlignmentA,
      half_t, LayoutB, kAlignmentB,
      float, LayoutC,
      float> {
  using TileShape = Shape<_128, _128, _32>;
  using DispatchPolicy = MainloopSm80CpAsync<3>;
  using TiledMma = TiledMMA<
    MMA_Atom<SM80_16x8x16_F32F16F16F32_TN>,
    Layout<Shape<_2, _2, _1> >,
    Tile<_32, _32, _16> >;

  // A
  using OperandA = detail::Gemm_OperandA<
    half_t, LayoutA, kAlignmentA, 32>;
  using SmemLayoutAtomA = typename OperandA::SmemLayoutAtom; // M, K
  using SmemCopyAtomA = typename OperandA::SmemCopyAtom;
  using GmemTiledCopyA = typename OperandA::GmemTiledCopy;

  // B
  using OperandB = detail::Gemm_OperandB<
    half_t, LayoutB, kAlignmentB, 32>;
  using SmemLayoutAtomB = typename OperandB::SmemLayoutAtom; // N, K
  using SmemCopyAtomB = typename OperandB::SmemCopyAtom;
  using GmemTiledCopyB = typename OperandB::GmemTiledCopy;

  // Mainloop
  using CollectiveMainloop = collective::CollectiveMma<
    DispatchPolicy, TileShape,
    half_t, TagToStrideA_t<LayoutA>,
    half_t, TagToStrideB_t<LayoutB>,
    TiledMma,
    GmemTiledCopyA, SmemLayoutAtomA, SmemCopyAtomA, identity, // A
    GmemTiledCopyB, SmemLayoutAtomB, SmemCopyAtomB, identity // B
  >;

  // Epilogue
  using CollectiveEpilogue = epilogue::collective::DefaultEpilogue<
    float,
    TagToStrideC_t<LayoutC>,
    TagToStrideC_t<LayoutC>,
    epilogue::thread::LinearCombination<float, 1>,
    EpilogueDefault>;

  using GemmKernel = kernel::GemmUniversal<
    Shape<int, int, int, int>,
    CollectiveMainloop,
    CollectiveEpilogue
  >;

  using Gemm = GemmUniversalAdapter<GemmKernel>;

  constexpr static typename GemmKernel::Arguments defaultArguments() { return {}; };
};

/////////////////////////////////////////////////////////////////////////

// Bfloat

namespace detail {
/// Operand A - Column-major (M-major)
template<int SizeK>
struct Gemm_OperandA<bfloat16_t, layout::ColumnMajor, 8, SizeK> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<3, 3, 3>{},
                Layout<Shape<_64, _8>,
                  Stride<_1, _64> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U16x8_LDSM_T, bfloat16_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<uint128_t>, bfloat16_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_1, _16> >{},
                    Layout<Shape<_8, _1> >{}));
};

template<int SizeK>
struct Gemm_OperandA<bfloat16_t, layout::ColumnMajor, 4, SizeK> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<3, 3, 3>{},
                Layout<Shape<_64, _8>,
                  Stride<_1, _64> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U16x8_LDSM_T, bfloat16_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<UniversalCopy<uint64_t>, bfloat16_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_1, _16> >{},
                    Layout<Shape<_4, _1> >{}));
};

template<int SizeK>
struct Gemm_OperandA<bfloat16_t, layout::ColumnMajor, 1, SizeK> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<3, 3, 3>{},
                Layout<Shape<_64, _4>,
                  Stride<_1, _64> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U16x8_LDSM_T, bfloat16_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<UniversalCopy<uint16_t>, bfloat16_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_1, _16> >{},
                    Layout<Shape<_4, _1> >{}));
};

/// Operand A - Row-major (K-Major)
template<>
struct Gemm_OperandA<bfloat16_t, layout::RowMajor, 8, 32> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<2, 3, 3>{},
                Layout<Shape<_8, _32>,
                  Stride<_32, _1> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U32x4_LDSM_N, bfloat16_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<uint128_t>, bfloat16_t>{},
                    Layout<Shape<_32, _4>,
                      Stride<_4, _1> >{},
                    Layout<Shape<_1, _8> >{}));
};

template<>
struct Gemm_OperandA<bfloat16_t, layout::RowMajor, 1, 32> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<2, 3, 3>{},
                Layout<Shape<_8, _32>,
                  Stride<_32, _1> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U32x4_LDSM_N, bfloat16_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<UniversalCopy<uint16_t>, bfloat16_t>{},
                    Layout<Shape<_32, _4>,
                      Stride<_4, _1> >{},
                    Layout<Shape<_1, _8> >{}));
};

// Because the F32F16 TiledMMA is A-B symmetric, we can reuse the Operands

// Operand B - Column-Major (K-major)
template<int Alignment, int SizeK>
struct Gemm_OperandB<bfloat16_t, layout::ColumnMajor, Alignment, SizeK>
    : Gemm_OperandA<bfloat16_t, layout::RowMajor, Alignment, SizeK> {
};

// Operand B - Row-Major (N-major)
template<int Alignment, int SizeK>
struct Gemm_OperandB<bfloat16_t, layout::RowMajor, Alignment, SizeK>
    : Gemm_OperandA<bfloat16_t, layout::ColumnMajor, Alignment, SizeK> {
};

} // namespace detail

template<typename LayoutA, int kAlignmentA, typename LayoutB, int kAlignmentB, typename LayoutC>
struct GemmConfiguration<
      arch::Sm80,
      bfloat16_t, LayoutA, kAlignmentA,
      bfloat16_t, LayoutB, kAlignmentB,
      float, LayoutC,
      float> {
  using TileShape = Shape<_128, _128, _32>;
  using DispatchPolicy = MainloopSm80CpAsync<3>;
  using TiledMma = TiledMMA<
    MMA_Atom<SM80_16x8x16_F32BF16BF16F32_TN>,
    Layout<Shape<_2, _2, _1> >,
    Tile<_32, _32, _16> >;

  // A
  using OperandA = detail::Gemm_OperandA<
    bfloat16_t, LayoutA, kAlignmentA, 32>;
  using SmemLayoutAtomA = typename OperandA::SmemLayoutAtom; // M, K
  using SmemCopyAtomA = typename OperandA::SmemCopyAtom;
  using GmemTiledCopyA = typename OperandA::GmemTiledCopy;

  // B
  using OperandB = detail::Gemm_OperandB<
    bfloat16_t, LayoutB, kAlignmentB, 32>;
  using SmemLayoutAtomB = typename OperandB::SmemLayoutAtom; // N, K
  using SmemCopyAtomB = typename OperandB::SmemCopyAtom;
  using GmemTiledCopyB = typename OperandB::GmemTiledCopy;

  // Mainloop
  using CollectiveMainloop = collective::CollectiveMma<
    DispatchPolicy, TileShape,
    bfloat16_t, TagToStrideA_t<LayoutA>,
    bfloat16_t, TagToStrideB_t<LayoutB>,
    TiledMma,
    GmemTiledCopyA, SmemLayoutAtomA, SmemCopyAtomA, identity, // A
    GmemTiledCopyB, SmemLayoutAtomB, SmemCopyAtomB, identity // B
  >;

  // Epilogue
  using CollectiveEpilogue = epilogue::collective::DefaultEpilogue<
    float,
    TagToStrideC_t<LayoutC>,
    TagToStrideC_t<LayoutC>,
    epilogue::thread::LinearCombination<float, 1>,
    EpilogueDefault>;

  using GemmKernel = kernel::GemmUniversal<
    Shape<int, int, int, int>,
    CollectiveMainloop,
    CollectiveEpilogue
  >;

  using Gemm = GemmUniversalAdapter<GemmKernel>;

  constexpr static typename GemmKernel::Arguments defaultArguments() { return {}; };
};

/////////////////////////////////////////////////////////////////////////

// TFloat32

namespace detail {
/// Operand A - Row-major  (K-major) (kBlock = 32)
template<>
struct Gemm_OperandA<tfloat32_t, layout::RowMajor, 4, 32> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<3, 2, 3>{},
                Layout<Shape<_8, _32>,
                  Stride<_32, _1> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U32x4_LDSM_N, tfloat32_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<uint128_t>, tfloat32_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_8, _1> >{},
                    Layout<Shape<_1, _4> >{}));
};

template<>
struct Gemm_OperandA<tfloat32_t, layout::RowMajor, 1, 32> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<3, 2, 3>{},
                Layout<Shape<_8, _32>,
                  Stride<_32, _1> >{}));
  using SmemCopyAtom = Copy_Atom<SM75_U32x4_LDSM_N, tfloat32_t>;

  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<UniversalCopy<uint32_t>, tfloat32_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_8, _1> >{},
                    Layout<Shape<_1, _4> >{}));
};

/// Operand A - Column-major  (M-major)
template<int SizeK>
struct Gemm_OperandA<tfloat32_t, layout::ColumnMajor, 4, SizeK> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<2, 3, 2>{},
                Layout<Shape<_32, _8>,
                  Stride<_1, _32> >{}));
  using SmemCopyAtom = Copy_Atom<UniversalCopy<tfloat32_t>, tfloat32_t>;
  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<uint128_t>, tfloat32_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_1, _16> >{},
                    Layout<Shape<_4, _1> >{}));
};

template<int SizeK>
struct Gemm_OperandA<tfloat32_t, layout::ColumnMajor, 1, SizeK> {
  // Smem
  using SmemLayoutAtom = decltype(
    composition(Swizzle<2, 3, 2>{},
                Layout<Shape<_32, _8>,
                  Stride<_1, _32> >{}));
  using SmemCopyAtom = Copy_Atom<UniversalCopy<tfloat32_t>, tfloat32_t>;
  // Gmem
  using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<UniversalCopy<uint32_t>, tfloat32_t>{},
                    Layout<Shape<_16, _8>,
                      Stride<_1, _16> >{},
                    Layout<Shape<_4, _1> >{}));
};

// Because the TF32 TiledMMA is A-B symmetric, we can reuse the Operands

// Operand B - Column-Major  (K-major)
template<int Alignment, int SizeK>
struct Gemm_OperandB<tfloat32_t, layout::ColumnMajor, Alignment, SizeK>
    : Gemm_OperandA<tfloat32_t, layout::RowMajor, Alignment, SizeK> {
};

// Operand B - Row-Major  (N-major)
template<int Alignment, int SizeK>
struct Gemm_OperandB<tfloat32_t, layout::RowMajor, Alignment, SizeK>
    : Gemm_OperandA<tfloat32_t, layout::ColumnMajor, Alignment, SizeK> {
};
} // namespace details

template<typename LayoutA, int kAlignmentA, typename LayoutB, int kAlignmentB, typename LayoutC>
struct GemmConfiguration<
      arch::Sm80,
      float, LayoutA, kAlignmentA,
      float, LayoutB, kAlignmentB,
      float, LayoutC,
      float> {
  using TileShape = Shape<_128, _128, _32>;
  using DispatchPolicy = MainloopSm80CpAsync<3>;
  using TiledMma = TiledMMA<
    MMA_Atom<SM80_16x8x8_F32TF32TF32F32_TN>,
    Layout<Shape<_2,_2,_1>, Stride<_2, _1, _1>>,
    Tile<_32,_32,_8> >;

  // A
  using OperandA = detail::Gemm_OperandA<
    tfloat32_t, LayoutA, kAlignmentA, 32>;
  using SmemLayoutAtomA = typename OperandA::SmemLayoutAtom; // M, K
  using SmemCopyAtomA = typename OperandA::SmemCopyAtom;
  using GmemTiledCopyA = typename OperandA::GmemTiledCopy;

  // B
  using OperandB = detail::Gemm_OperandB<
    tfloat32_t, LayoutB, kAlignmentB, 32>;
  using SmemLayoutAtomB = typename OperandB::SmemLayoutAtom; // N, K
  using SmemCopyAtomB = typename OperandB::SmemCopyAtom;
  using GmemTiledCopyB = typename OperandB::GmemTiledCopy;

  // Mainloop
  using CollectiveMainloop = collective::CollectiveMma<
    DispatchPolicy, TileShape,
    tfloat32_t, TagToStrideA_t<LayoutA>,
    tfloat32_t, TagToStrideB_t<LayoutB>,
    TiledMma,
    GmemTiledCopyA, SmemLayoutAtomA, SmemCopyAtomA, identity, // A
    GmemTiledCopyB, SmemLayoutAtomB, SmemCopyAtomB, identity // B
  >;

  // Epilogue
  using CollectiveEpilogue = epilogue::collective::DefaultEpilogue<
    float,
    TagToStrideC_t<LayoutC>,
    TagToStrideC_t<LayoutC>,
    epilogue::thread::LinearCombination<float, 1>,
    EpilogueDefault>;

  using GemmKernel = kernel::GemmUniversal<
    Shape<int, int, int, int>,
    CollectiveMainloop,
    CollectiveEpilogue
  >;

  using Gemm = GemmUniversalAdapter<GemmKernel>;

  constexpr static typename GemmKernel::Arguments defaultArguments() { return {}; };
};

} // namespace device
} // namespace gemm
} // namespace cutlass
