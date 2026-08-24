/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 *modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *this list of conditions and the following disclaimer in the documentation
 *and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *may be used to endorse or promote products derived from this software without
 *specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 *FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **************************************************************************************************/

/*! \file
    \brief Packed value and block-scale layout consumed by the SM120 NVFP4 W4A16
   GEMM.
*/

#pragma once

#include "cute/tensor.hpp"

#include "cutlass/cutlass.h"

#include <cstddef>
#include <cstdint>

namespace cutlass::layout {

/// Storage contract for a K-by-N NVFP4 weight matrix used by the SM120 W4A16
/// kernel.
///
/// Values are packed as two consecutive K elements per byte. Each output column
/// owns a contiguous K/2-byte row. UE4M3 block scales cover 16 K elements and
/// are interleaved in groups of four output columns. The four-column interleave
/// makes every scale payload for a 64-wide K tile a naturally aligned 16-byte
/// vector while preserving coalesced access in the decode GEMV.
struct Nvfp4W4a16Weight {
  static constexpr int kElementsPerValueByte = 2;
  static constexpr int kScaleGranularityK = 16;
  static constexpr int kScaleGroupN = 4;

  using ScaleLayout =
      cute::Layout<cute::Shape<cute::Shape<int64_t, cute::Int<kScaleGroupN>>,
                               int64_t, int64_t>,
                   cute::Stride<cute::Stride<int64_t, cute::_1>,
                                cute::Int<kScaleGroupN>, int64_t>>;

  CUTLASS_HOST_DEVICE
  static constexpr bool is_valid_shape(int64_t n, int64_t k) {
    return n > 0 && k > 0 && n % kScaleGroupN == 0 &&
           k % kScaleGranularityK == 0;
  }

  CUTLASS_HOST_DEVICE
  static constexpr ScaleLayout make_scale_layout(int64_t n, int64_t k,
                                                 int64_t batches = 1) {
    CUTLASS_ASSERT(is_valid_shape(n, k) && batches > 0);
    int64_t const blocks = k / kScaleGranularityK;
    return cute::make_layout(
        cute::make_shape(
            cute::make_shape(n / kScaleGroupN, cute::Int<kScaleGroupN>{}),
            blocks, batches),
        cute::make_stride(cute::make_stride(blocks * kScaleGroupN, cute::_1{}),
                          cute::Int<kScaleGroupN>{}, n * blocks));
  }

  CUTLASS_HOST_DEVICE
  static constexpr int64_t packed_value_offset(int64_t column,
                                               int64_t k_element, int64_t k) {
    CUTLASS_ASSERT(column >= 0 && k_element >= 0 && k > 0 &&
                   k % kScaleGranularityK == 0 && k_element < k);
    return column * (k / kElementsPerValueByte) +
           k_element / kElementsPerValueByte;
  }

  CUTLASS_HOST_DEVICE
  static constexpr int64_t scale_offset(int64_t column, int64_t scale_block,
                                        int64_t scale_blocks) {
    CUTLASS_ASSERT(column >= 0 && scale_block >= 0 && scale_blocks > 0 &&
                   scale_block < scale_blocks);
    return ((column / kScaleGroupN) * scale_blocks + scale_block) *
               kScaleGroupN +
           column % kScaleGroupN;
  }

  CUTLASS_HOST_DEVICE
  static constexpr int64_t scale_offset(ScaleLayout const &layout,
                                        int64_t column, int64_t scale_block,
                                        int64_t batch = 0) {
    CUTLASS_ASSERT(column >= 0 && column < cute::size<0>(layout) &&
                   scale_block >= 0 && scale_block < cute::size<1>(layout) &&
                   batch >= 0 && batch < cute::size<2>(layout));
    return layout(cute::make_coord(
        cute::make_coord(column / kScaleGroupN, column % kScaleGroupN),
        scale_block, batch));
  }

  CUTLASS_HOST_DEVICE
  static constexpr int64_t scale_blocks(int64_t k) {
    CUTLASS_ASSERT(k > 0 && k % kScaleGranularityK == 0);
    return k / kScaleGranularityK;
  }

  CUTLASS_HOST_DEVICE
  static constexpr size_t packed_values_bytes(int64_t n, int64_t k) {
    CUTLASS_ASSERT(is_valid_shape(n, k));
    return static_cast<size_t>(n) * static_cast<size_t>(k) /
           kElementsPerValueByte;
  }

  CUTLASS_HOST_DEVICE
  static constexpr size_t scales_bytes(int64_t n, int64_t k) {
    CUTLASS_ASSERT(is_valid_shape(n, k));
    return static_cast<size_t>(n) * static_cast<size_t>(scale_blocks(k));
  }

  CUTLASS_HOST_DEVICE
  static constexpr size_t allocation_bytes(int64_t n, int64_t k) {
    CUTLASS_ASSERT(is_valid_shape(n, k));
    return packed_values_bytes(n, k) + scales_bytes(n, k);
  }
};

} // namespace cutlass::layout
