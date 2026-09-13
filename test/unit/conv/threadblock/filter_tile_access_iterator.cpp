/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass_unit_test.h"

#include "cutlass/conv/threadblock/conv2d_fprop_filter_tile_access_iterator_analytic.h"
#include "cutlass/conv/threadblock/conv2d_fprop_filter_tile_access_iterator_few_channels.h"
#include "cutlass/conv/threadblock/conv2d_fprop_filter_tile_access_iterator_fixed_channels.h"
#include "cutlass/conv/threadblock/conv3d_fprop_filter_tile_access_iterator_analytic.h"
#include "cutlass/conv/threadblock/depthwise_direct_conv_params.h"
#include "cutlass/conv/threadblock/depthwise_fprop_filter_tile_access_iterator_direct_conv_optimized.h"
#include "cutlass/matrix_shape.h"

namespace {

using Element = cutlass::half_t;
using Shape = cutlass::MatrixShape<1, 1>;
using Layout2d = cutlass::layout::TensorNHWC;

struct ThreadMap {
  using Iterations = cutlass::layout::PitchLinearShape<1, 1>;
  using Delta = cutlass::layout::PitchLinearShape<1, 1>;
  static int const kElementsPerAccess = 1;
  static int const kThreads = 1;

  CUTLASS_HOST_DEVICE
  static cutlass::layout::PitchLinearCoord initial_offset(int) {
    return {0, 0};
  }
};

using Analytic2d = cutlass::conv::threadblock::
    Conv2dFpropFilterTileAccessIteratorAnalytic<Shape, Element, Layout2d,
                                                ThreadMap>;
using Fixed2d = cutlass::conv::threadblock::
    Conv2dFpropFilterTileAccessIteratorFixedChannels<Shape, Element, Layout2d,
                                                     ThreadMap>;
using Few2d = cutlass::conv::threadblock::
    Conv2dFpropFilterTileAccessIteratorFewChannels<Shape, Element, Layout2d,
                                                   ThreadMap>;
using Analytic3d = cutlass::conv::threadblock::
    Conv3dFpropFilterTileAccessIteratorAnalytic<Shape, Element, ThreadMap>;
using Depthwise2d = cutlass::conv::threadblock::
    DepthwiseFpropFilterDirectConvTileAccessIteratorOptimized<
        Shape, Element, Layout2d, ThreadMap>;

template <class Iterator, class Params, class Problem>
int64_t measure_pointer_offset(Params const& params,
                               Problem const& problem,
                               Element const* pointer) {
  Iterator iterator(params, problem, pointer, 0);
  auto before = reinterpret_cast<char const*>(iterator.get());
  iterator.add_pointer_offset(8);
  auto after = reinterpret_cast<char const*>(iterator.get());
  return after - before;
}

} // namespace

TEST(Conv_threadblock, Filter_tile_access_iterator_pointer_offset) {
  cutlass::conv::Conv2dProblemSize problem2d(
      1, 1, 1, 1, 1, 1, 1, 1, 1,
      cutlass::conv::Mode::kCrossCorrelation);
  cutlass::conv::Conv3dProblemSize problem3d(
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      cutlass::conv::Mode::kCrossCorrelation);

  auto layout2d = Layout2d::packed({1, 1, 1, 1});
  auto layout3d = cutlass::layout::TensorNDHWC::packed({1, 1, 1, 1, 1});
  typename Analytic2d::Params analytic_params(problem2d, layout2d);
  typename Few2d::Params few_params(problem2d, layout2d);
  typename Analytic3d::Params analytic3d_params(problem3d, layout3d);
  auto depthwise_params = Depthwise2d::getParams(problem2d, layout2d);

  alignas(16) Element storage[64]{};
  int64_t expected = 8 * sizeof(Element);

  EXPECT_EQ(measure_pointer_offset<Analytic2d>(analytic_params, problem2d, storage), expected);
  EXPECT_EQ(measure_pointer_offset<Fixed2d>(few_params, problem2d, storage), expected);
  EXPECT_EQ(measure_pointer_offset<Few2d>(few_params, problem2d, storage), expected);
  EXPECT_EQ(measure_pointer_offset<Analytic3d>(analytic3d_params, problem3d, storage), expected);
  EXPECT_EQ(measure_pointer_offset<Depthwise2d>(depthwise_params, problem2d, storage), expected);
}
