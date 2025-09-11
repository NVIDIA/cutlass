/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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

// Cutlass includes
#include "cutlass/cutlass.h"
#include "cutlass/tensor_view.h"

#include "cutlass/util/reference/device/tensor_foreach.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace reference {
namespace device {

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorSiLuFunc {

  /// View type
  using TensorView = TensorView<Element, Layout>;

  /// Coordinate in tensor's index space
  using TensorCoord = typename TensorView::TensorCoord;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    TensorView view_in0, view_in1, view_out;
    //
    // Methods
    //

    Params(
      TensorView view_out_ = TensorView(),
      TensorView view_in0_ = TensorView(),
      TensorView view_in1_ = TensorView()
    ):
      view_out(view_out_), view_in0(view_in0_), view_in1(view_in1_){

    }
  };

  //
  // Data members
  //

  Params params;

  //
  // Methods
  //

  CUTLASS_DEVICE
  TensorSiLuFunc(Params const &params): params(params) {

  }

  CUTLASS_DEVICE
  void operator()(TensorCoord const &coord) {

    Element const& in0_val = params.view_in0.at(coord);
    Element const& in1_val = params.view_in1.at(coord);

    cutlass::epilogue::thread::SiLu<Element> silu;
    cutlass::multiplies<Element> mul;

    auto silu_lhs = silu(in0_val);
    params.view_out.at(coord) = mul(silu_lhs, in1_val);
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Apply SiLu on a tensor
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorSiLu(
  TensorView<Element, Layout> view_out,       ///< destination tensor
  TensorView<Element, Layout> view_in0,       ///< source tensor
  TensorView<Element, Layout> view_in1) {        ///< source tensor
  
  using Func = detail::TensorSiLuFunc<Element, Layout>;
  using Params = typename Func::Params;

  TensorForEach<Func, Layout::kRank, Params>(
    view_out.extent(),
    Params(view_out, view_in0, view_in1)
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace device
} // namespace reference
} // namespace cutlass
