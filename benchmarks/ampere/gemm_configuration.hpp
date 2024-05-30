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

#include "cutlass/half.h"
#include "cutlass/layout/layout.h"

#include "cute/swizzle.hpp"
#include "cute/layout.hpp"
#include "cute/arch/copy_sm75.hpp"
#include "cute/arch/copy_sm80.hpp"
#include "cute/atom/copy_atom.hpp"

using namespace cute;

template <typename Element, typename Layout, int Alignment, int SizeK>
struct DefaultGemm_TensorOpSm80_OperandA;

template <typename Element, typename Layout, int Alignment, int SizeK>
struct DefaultGemm_TensorOpSm80_OperandB;

/////////////////////////////////////////////////////////////////////////

// half

/// Operand A - Row-major (K-Major)
template <>
struct DefaultGemm_TensorOpSm80_OperandA<cutlass::half_t, cutlass::layout::RowMajor, 8, 64>
{
    // Smem
    using SmemLayoutAtom = decltype(
    composition(Swizzle<3,3,3>{},
                Layout<Shape < _8,_64>,
                Stride<_64, _1>>{}));
    using SmemCopyAtom = Copy_Atom<SM75_U32x4_LDSM_N, half_t>;

    // Gmem
    using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<cute::uint128_t>, half_t>{},
                    Layout<Shape <_16,_8>,
                    Stride< _8,_1>>{},
                    Layout<Shape < _1,_8>>{}));
};

/// Operand A - Column-major (M-major)
template <int SizeK>
struct DefaultGemm_TensorOpSm80_OperandA<half_t, cutlass::layout::ColumnMajor, 8, SizeK>
{
    // Smem
    using SmemLayoutAtom = decltype(
    composition(Swizzle<3,3,3>{},
                Layout<Shape <_64, _8>,
                Stride< _1,_64>>{}));
    using SmemCopyAtom = Copy_Atom<SM75_U16x8_LDSM_T, half_t>;

    // Gmem
    using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<cute::uint128_t>, half_t>{},
                    Layout<Shape <_16, _8>,
                    Stride< _1,_16>>{},
                    Layout<Shape < _8, _1>>{}));
};

/// Operand A - Row-major (K-Major)
template <>
struct DefaultGemm_TensorOpSm80_OperandA<half_t, cutlass::layout::RowMajor, 8, 32>
{
    // Smem
    using SmemLayoutAtom = decltype(
    composition(Swizzle<2,3,3>{},
                Layout<Shape < _8,_32>,
                Stride<_32, _1>>{}));
    using SmemCopyAtom = Copy_Atom<SM75_U32x4_LDSM_N, half_t>;

    // Gmem
    using GmemTiledCopy = decltype(
    make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<cute::uint128_t>, half_t>{},
                    Layout<Shape <_32,_4>,
                    Stride< _4,_1>>{},
                    Layout<Shape < _1,_8>>{}));
};

// Because the F32F16 TiledMMA is A-B symmetric, we can reuse the DefaultOperands

// Operand B - Column-Major (K-major)
template <int Alignment, int SizeK>
struct DefaultGemm_TensorOpSm80_OperandB<half_t, cutlass::layout::ColumnMajor, Alignment, SizeK>
        : DefaultGemm_TensorOpSm80_OperandA<half_t, cutlass::layout::RowMajor, Alignment, SizeK>
{};

// Operand B - Row-Major (N-major)
template <int Alignment, int SizeK>
struct DefaultGemm_TensorOpSm80_OperandB<half_t, cutlass::layout::RowMajor, Alignment, SizeK>
        : DefaultGemm_TensorOpSm80_OperandA<half_t, cutlass::layout::ColumnMajor, Alignment, SizeK>
{};
