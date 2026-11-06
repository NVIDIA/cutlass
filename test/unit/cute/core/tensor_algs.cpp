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

#include <cute/tensor.hpp>
#include <cute/algorithm/copy.hpp>
#include <cute/algorithm/tensor_algorithms.hpp>
#include <cute/algorithm/tensor_reduce.hpp>
#include <cute/numeric/complex.hpp>

TEST(CuTe_algorithm, TensorTransform) {
  using namespace cute;
  complex<float> array[4] = {{0,0}, {1,0}, {0,1}, {1,1}};
  complex<float> correct[4] = {{0,0}, {1,0}, {0,-1}, {1,-1}};
  Tensor tensor = make_tensor(static_cast<complex<float>*>(array), make_layout(make_shape(4)));
  conjugate conj;
  transform(tensor, conj);
  for (int i = 0; i < 4; ++i) {
    EXPECT_EQ(tensor(i), correct[i]);
  }
}

TEST(CuTe_algorithm, TensorBatchReduce) {
  using namespace cute;

  int src_vals[16] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};
  Tensor src_tensor = make_tensor(static_cast<int*>(src_vals),
                                  make_layout(make_shape (make_shape (2,2), make_shape (2,2)),
                                              make_stride(make_stride(2,8), make_stride(1,4))));

  array<int, 4> dst_vals;
  fill(dst_vals, 0);
  Tensor dst_tensor = make_tensor(dst_vals.begin(), make_shape(2,2));

  batch_reduce(src_tensor, dst_tensor);

  int correct[4] = {20,24,36,40};
  for (int i = 0; i < 4; ++i) {
    //printf("%d  %d\n", dst_tensor(i), correct[i]);
    EXPECT_EQ(dst_tensor(i), correct[i]);
  }
}


TEST(CuTe_algorithm, TensorLogicalReduce) {
  using namespace cute;

  { // Reduce each column of a matrix
    Tensor src_tensor = make_tensor(counting_iterator<int>{0},
                                    Layout<Shape <_32, Shape <_12,_6>>,
                                           Stride< _1, Stride<_64,_1>>>{});
    auto slicer = make_coord(0_c, _);
    Tensor dst_tensor = make_tensor_like(src_tensor(slicer));

    logical_reduce(src_tensor, dst_tensor, slicer);

    for (int i = 0; i < size(dst_tensor); ++i) {
      EXPECT_EQ(dst_tensor(i), reduce(src_tensor(_,i), int(0)));
    }
  }

  { // Reduce each row of a matrix
    Tensor src_tensor = make_tensor(counting_iterator<int>{0},
                                    Layout<Shape <_32, Shape <_12,_6>>,
                                           Stride< _1, Stride<_64,_1>>>{});
    auto slicer = make_coord(_, 0_c);
    Tensor dst_tensor = make_tensor_like(src_tensor(slicer));

    logical_reduce(src_tensor, dst_tensor, slicer);

    for (int i = 0; i < size(dst_tensor); ++i) {
      EXPECT_EQ(dst_tensor(i), reduce(src_tensor(i,_), int(0)));
    }
  }

  { // 1 profile
    Tensor src_tensor = make_tensor(counting_iterator<int>{0},
                                    Layout<Shape<_32>, Stride<_1>>{});
    array<int, 1> dst_vals;
    fill(dst_vals, 0);
    Tensor dst_tensor = make_tensor(dst_vals.begin(), Layout<_1,_0>{});

    logical_reduce(src_tensor, dst_tensor, 1);

    for (int i = 0; i < size(dst_tensor); ++i) {
      EXPECT_EQ(dst_tensor(i), reduce(src_tensor, int(0)));
    }
  }

  { // _ profile
    Tensor src_tensor = make_tensor(counting_iterator<int>{0},
                                    Layout<Shape<_32>, Stride<_1>>{});
    auto slicer = _;
    Tensor dst_tensor = make_tensor_like(src_tensor(slicer));

    logical_reduce(src_tensor, dst_tensor, slicer);

    for (int i = 0; i < size(dst_tensor); ++i) {
      EXPECT_EQ(dst_tensor(i), src_tensor(i));
    }
  }

  { // (1,1) profile
    Tensor src_tensor = make_tensor(counting_iterator<int>{0},
                                    Layout<Shape <_32, Shape <_12,_6>>,
                                           Stride< _1, Stride<_192,_32>>>{});
    auto slicer = make_coord(1, 1);
    array<int, 1> dst_vals;
    fill(dst_vals, 0);
    Tensor dst_tensor = make_tensor(dst_vals.begin(), Layout<_1,_0>{});

    logical_reduce(src_tensor, dst_tensor, slicer);

    for (int i = 0; i < size(dst_tensor); ++i) {
      EXPECT_EQ(dst_tensor(i), reduce(src_tensor, int(0)));
    }
  }

  { // (_,_) profile
    Tensor src_tensor = make_tensor(counting_iterator<int>{0},
                                    Layout<Shape <_32, Shape <_12,_6>>,
                                           Stride< _1, Stride<_192,_32>>>{});
    auto slicer = make_coord(_,_);
    Tensor dst_tensor = make_tensor_like(src_tensor(slicer));

    logical_reduce(src_tensor, dst_tensor, slicer);

    for (int i = 0; i < size(dst_tensor); ++i) {
      EXPECT_EQ(dst_tensor(i), src_tensor(i));
    }
  }

  {
    Tensor src_tensor = make_tensor(counting_iterator<int>{0},
                                    make_layout(make_shape (2,2,2,2),
                                                make_stride(1,2,4,8)));

    array<int, 4> dst_vals;
    fill(dst_vals, 0);
    Tensor dst_tensor = make_tensor(dst_vals.begin(), make_shape(2,2));

    auto target_profile = make_coord(_,1,_,1);

    logical_reduce(src_tensor, dst_tensor, target_profile);

    int correct[4] = {20,24,36,40};
    for (int i = 0; i < 4; ++i) {
      //printf("%d  %d\n", dst_tensor(i), correct[i]);
      EXPECT_EQ(dst_tensor(i), correct[i]);
    }
  }

  {
    Tensor src_tensor = make_tensor(counting_iterator<int>{0},
                                    make_layout(make_shape (2,make_shape (2,2),2),
                                                make_stride(1,make_stride(2,4),8)));

    array<int, 4> dst_vals;
    fill(dst_vals, 0);
    Tensor dst_tensor = make_tensor(dst_vals.begin(), make_shape(2,2));

    auto target_profile = make_coord(_,make_coord(1,_),1);

    logical_reduce(src_tensor, dst_tensor, target_profile);

    int correct[4] = {20,24,36,40};
    for (int i = 0; i < 4; ++i) {
      //printf("%d  %d\n", dst_tensor(i), correct[i]);
      EXPECT_EQ(dst_tensor(i), correct[i]);
    }
  }

}

// A Copy_Atom moves one instruction's worth of elements per rest-slice. Here a 128b universal copy
// moves 4 floats, so src and dst must both be (4, Rest...) tensors.
TEST(CuTe_algorithm, CopyAtom) {
  using namespace cute;

  alignas(16) float src_data[12];
  alignas(16) float dst_data[12];
  for (int i = 0; i < 12; ++i) {
    src_data[i] = float(i);
    dst_data[i] = -1.0f;
  }

  Tensor src = make_tensor(&src_data[0], Shape<_4,_3>{});
  Tensor dst = make_tensor(&dst_data[0], Shape<_4,_3>{});

  copy(Copy_Atom<UniversalCopy<uint128_t>, float>{}, src, dst);

  for (int i = 0; i < 12; ++i) {
    EXPECT_EQ(dst_data[i], float(i));
  }
}

TEST(CuTe_algorithm, CopyIfAtom) {
  using namespace cute;

  alignas(16) float src_data[12];
  alignas(16) float dst_data[12];
  bool prd_data[12];
  for (int i = 0; i < 12; ++i) {
    src_data[i] = float(i);
    dst_data[i] = -1.0f;
    prd_data[i] = (i / 4) != 1;     // Skip the second rest-slice
  }

  Tensor src = make_tensor(&src_data[0], Shape<_4,_3>{});
  Tensor dst = make_tensor(&dst_data[0], Shape<_4,_3>{});
  Tensor prd = make_tensor(&prd_data[0], Shape<_4,_3>{});

  copy_if(Copy_Atom<UniversalCopy<uint128_t>, float>{}, prd, src, dst);

  for (int i = 0; i < 12; ++i) {
    EXPECT_EQ(dst_data[i], (i / 4) != 1 ? float(i) : -1.0f);
  }
}

TEST(CuTe_algorithm, CopyIfElementwise) {
  using namespace cute;

  int src_data[6] = {0, 1, 2, 3, 4, 5};
  int dst_data[6] = {-1, -1, -1, -1, -1, -1};
  bool prd_data[6] = {true, false, true, false, true, false};

  Tensor src = make_tensor(&src_data[0], Shape<_2,_3>{});
  Tensor dst = make_tensor(&dst_data[0], Shape<_2,_3>{});
  Tensor prd = make_tensor(&prd_data[0], Shape<_2,_3>{});

  copy_if(prd, src, dst);

  for (int i = 0; i < 6; ++i) {
    EXPECT_EQ(dst_data[i], prd_data[i] ? i : -1);
  }
}
