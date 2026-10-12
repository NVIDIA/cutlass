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

#include "cute/layout.hpp"
#include "cute/algorithm/tuple_algorithms.hpp"
#include "cutlass/detail/layout.hpp"

/**
 * Convenience functions for computing input/output strides for sm90 gated activation kernel
 */

namespace cutlass {

template <int ModeIndex, class InputShape>
CUTLASS_HOST_DEVICE
auto
sm90_make_gated_shape(InputShape const& shape) {
  using namespace cute;
  using Tiler = Shape<_8,_2>;
  return replace<ModeIndex>(shape, append(Tiler{}, shape_div(get<ModeIndex>(shape), Tiler{})));
}

template <int ModeIndex, class InputShape>
CUTLASS_HOST_DEVICE
auto
sm90_make_gated_output_shape(InputShape const& shape) {
  using namespace cute;
  using Tiler = Shape<_8>;
  return replace<ModeIndex>(shape, append(Tiler{}, shape_div(get<ModeIndex>(shape), Tiler{})));
}

// K-major gated gemm stride
template <class StrideIntT>
CUTLASS_HOST_DEVICE
cute::Stride<cute::Stride<StrideIntT,StrideIntT,StrideIntT>, cute::Int<1>, StrideIntT>
sm90_make_gated_packed_stride(cute::Stride<cute::Stride<StrideIntT,StrideIntT,StrideIntT>, cute::Int<1>, StrideIntT>, cute::Shape<int,int,int> shape_MKL) {
  using namespace cute;
  static_assert(std::is_integral_v<StrideIntT>, "Stride must have an integral type so it can be set dynamically. Static strides not supported.");
  auto shape = sm90_make_gated_shape<0>(cute::transform(shape_MKL, [](auto s){ return static_cast<StrideIntT>(s); }));
  auto stride = compact_order(shape, Step<Step<_1,_3,_2>,_0,_4>{});
  return stride;
}

// K-major gated gemm output stride
template <class StrideIntT>
CUTLASS_HOST_DEVICE
cute::Stride<cute::Stride<StrideIntT,StrideIntT>, cute::Int<1>, StrideIntT>
sm90_make_gated_packed_stride(cute::Stride<cute::Stride<StrideIntT,StrideIntT>, cute::Int<1>, StrideIntT>, cute::Shape<int,int,int> shape_MKL) {
  using namespace cute;
  static_assert(std::is_integral_v<StrideIntT>, "Stride must have an integral type so it can be set dynamically. Static strides not supported.");
  auto shape = sm90_make_gated_output_shape<0>(cute::transform(shape_MKL, [](auto s){ return static_cast<StrideIntT>(s); }));
  auto stride = compact_order(shape, Step<Step<_1,_2>,_0,_3>{});
  return stride;
}

// K-major grouped gemm stride
template <class StrideIntT>
CUTLASS_HOST_DEVICE
cute::Stride<cute::Stride<StrideIntT,StrideIntT,StrideIntT>, cute::Int<1>, cute::Int<0>>
sm90_make_gated_packed_stride(cute::Stride<cute::Stride<StrideIntT,StrideIntT,StrideIntT>, cute::Int<1>, cute::Int<0>>, cute::Shape<int,int,int> shape_MKL) {
  using namespace cute;
  static_assert(std::is_integral_v<StrideIntT>, "Stride must have an integral type so it can be set dynamically. Static strides not supported.");
  auto shape = sm90_make_gated_shape<0>(cute::transform(shape_MKL, [](auto s){ return static_cast<StrideIntT>(s); }));
  auto stride = append(compact_order(take<0,2>(shape), Step<Step<_1,_3,_2>,_0>{}), Int<0>{});
  return stride;
}

// K-major grouped gemm output stride
template <class StrideIntT>
CUTLASS_HOST_DEVICE
cute::Stride<cute::Stride<StrideIntT,StrideIntT>, cute::Int<1>, cute::Int<0>>
sm90_make_gated_packed_stride(cute::Stride<cute::Stride<StrideIntT,StrideIntT>, cute::Int<1>, cute::Int<0>>, cute::Shape<int,int,int> shape_MKL) {
  using namespace cute;
  static_assert(std::is_integral_v<StrideIntT>, "Stride must have an integral type so it can be set dynamically. Static strides not supported.");
  auto shape = sm90_make_gated_output_shape<0>(cute::transform(shape_MKL, [](auto s){ return static_cast<StrideIntT>(s); }));
  auto stride = append(compact_order(take<0,2>(shape), Step<Step<_1,_2>,_0>{}), Int<0>{});
  return stride;
}

// MN-major gated gemm stride
template <class StrideIntT>
CUTLASS_HOST_DEVICE
cute::Stride<cute::Stride<cute::Int<1>,StrideIntT,cute::Int<8>>, StrideIntT, StrideIntT>
sm90_make_gated_packed_stride(cute::Stride<cute::Stride<cute::Int<1>,StrideIntT,cute::Int<8>>, StrideIntT, StrideIntT>, cute::Shape<int,int,int> shape_MKL) {
  using namespace cute;
  static_assert(std::is_integral_v<StrideIntT>, "Stride must have an integral type so it can be set dynamically. Static strides not supported.");
  auto shape = sm90_make_gated_shape<0>(cute::transform(shape_MKL, [](auto s){ return static_cast<StrideIntT>(s); }));
  auto stride = compact_order(shape, Step<Step<_0,_2,_1>,_3,_4>{});
  return stride;
}

// MN-major gated gemm output stride
template <class StrideIntT>
CUTLASS_HOST_DEVICE
cute::Stride<cute::Stride<cute::Int<1>,cute::Int<8>>, StrideIntT, StrideIntT>
sm90_make_gated_packed_stride(cute::Stride<cute::Stride<cute::Int<1>,cute::Int<8>>, StrideIntT, StrideIntT>, cute::Shape<int,int,int> shape_MKL) {
  using namespace cute;
  static_assert(std::is_integral_v<StrideIntT>, "Stride must have an integral type so it can be set dynamically. Static strides not supported.");
  auto shape = sm90_make_gated_output_shape<0>(cute::transform(shape_MKL, [](auto s){ return static_cast<StrideIntT>(s); }));
  auto stride = compact_order(shape, Step<Step<_0,_1>,_2,_3>{});
  return stride;
}

// MN-major gated grouped gemm stride
template <class StrideIntT>
CUTLASS_HOST_DEVICE
cute::Stride<cute::Stride<cute::Int<1>,StrideIntT,cute::Int<8>>, StrideIntT, cute::Int<0>>
sm90_make_gated_packed_stride(cute::Stride<cute::Stride<cute::Int<1>,StrideIntT,cute::Int<8>>, StrideIntT, cute::Int<0>>, cute::Shape<int,int,int> shape_MKL) {
  using namespace cute;
  static_assert(std::is_integral_v<StrideIntT>, "Stride must have an integral type so it can be set dynamically. Static strides not supported.");
  auto shape = sm90_make_gated_shape<0>(cute::transform(shape_MKL, [](auto s){ return static_cast<StrideIntT>(s); }));
  auto stride = append(compact_order(take<0,2>(shape), Step<Step<_0,_2,_1>,_3>{}), Int<0>{});
  return stride;
}

// MN-major gated grouped gemm output stride
template <class StrideIntT>
CUTLASS_HOST_DEVICE
cute::Stride<cute::Stride<cute::Int<1>,cute::Int<8>>, StrideIntT, cute::Int<0>>
sm90_make_gated_packed_stride(cute::Stride<cute::Stride<cute::Int<1>,cute::Int<8>>, StrideIntT, cute::Int<0>>, cute::Shape<int,int,int> shape_MKL) {
  using namespace cute;
  static_assert(std::is_integral_v<StrideIntT>, "Stride must have an integral type so it can be set dynamically. Static strides not supported.");
  auto shape = sm90_make_gated_output_shape<0>(cute::transform(shape_MKL, [](auto s){ return static_cast<StrideIntT>(s); }));
  auto stride = append(compact_order(take<0,2>(shape), Step<Step<_0,_1>,_2>{}), Int<0>{});
  return stride;
}

} // namespace cutlass
