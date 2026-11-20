/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/conv/conv2d_problem_size.h"
#include "cutlass/conv/conv3d_problem_size.h"

#include "gtest/gtest.h"

TEST(Conv2dProblemSize, ComputesDilatedOutputSize) {
  cutlass::conv::Conv2dProblemSize problem(
      cutlass::Tensor4DCoord{1, 8, 9, 4},
      cutlass::Tensor4DCoord{16, 3, 2, 4},
      cutlass::Tensor4DCoord{0, 0, 0, 0},
      cutlass::MatrixCoord{1, 1},
      cutlass::MatrixCoord{2, 3});

  EXPECT_EQ(problem.P, 4);
  EXPECT_EQ(problem.Q, 6);
}

TEST(Conv2dProblemSize, AccountsForAsymmetricPaddingAndStride) {
  cutlass::conv::Conv2dProblemSize problem(
      cutlass::Tensor4DCoord{1, 18, 21, 4},
      cutlass::Tensor4DCoord{16, 3, 4, 4},
      cutlass::Tensor4DCoord{1, 2, 3, 1},
      cutlass::MatrixCoord{2, 3},
      cutlass::MatrixCoord{2, 2});

  EXPECT_EQ(problem.P, 9);
  EXPECT_EQ(problem.Q, 7);
}

TEST(Conv2dProblemSize, UnitFilterIsUnaffectedByDilation) {
  cutlass::conv::Conv2dProblemSize problem(
      cutlass::Tensor4DCoord{1, 7, 11, 4},
      cutlass::Tensor4DCoord{16, 1, 1, 4},
      cutlass::Tensor4DCoord{0, 0, 0, 0},
      cutlass::MatrixCoord{2, 3},
      cutlass::MatrixCoord{5, 7});

  EXPECT_EQ(problem.P, 4);
  EXPECT_EQ(problem.Q, 4);
}

TEST(Conv3dProblemSize, ComputesDilatedOutputSizeWithSymmetricPadding) {
  cutlass::conv::Conv3dProblemSize problem(
      cutlass::Tensor5DCoord{1, 11, 8, 9, 4},
      cutlass::Tensor5DCoord{16, 3, 3, 2, 4},
      cutlass::Coord<3>({1, 0, 0}),
      cutlass::Coord<3>({2, 1, 1}),
      cutlass::Coord<3>({2, 2, 3}));

  EXPECT_EQ(problem.Z, 5);
  EXPECT_EQ(problem.P, 4);
  EXPECT_EQ(problem.Q, 6);
}

TEST(Conv3dProblemSize, ComputesDilatedOutputSizeWithAsymmetricPadding) {
  cutlass::conv::Conv3dProblemSize problem(
      cutlass::Tensor5DCoord{1, 19, 18, 21, 4},
      cutlass::Tensor5DCoord{16, 4, 3, 4, 4},
      CUTLASS_STL_NAMESPACE::make_tuple(
          cutlass::Coord<3>({2, 1, 3}),
          cutlass::Coord<3>({1, 2, 1})),
      cutlass::Coord<3>({3, 2, 3}),
      cutlass::Coord<3>({2, 2, 2}));

  EXPECT_EQ(problem.Z, 6);
  EXPECT_EQ(problem.P, 9);
  EXPECT_EQ(problem.Q, 7);
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
