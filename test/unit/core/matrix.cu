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
/*! 
  \file
  \brief Unit tests for the small matrix class.
*/

#include <iostream>

#include "../common/cutlass_unit_test.h"

#include "cutlass/matrix.h"
#include "cutlass/core_io.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(Matrix, nonsquare_indexing) {

  cutlass::Matrix<float, 2, 3> wide = {
    1, 2, 3,
    4, 5, 6
  };

  EXPECT_EQ(wide.at(1, 0), 4);
  EXPECT_EQ(wide.diagonal().at(1, 0), 5);

  wide.at(1, 2) = 9;
  EXPECT_EQ(wide.data[5], 9);

  cutlass::Matrix<float, 2, 1> wide_diag = {7, 8};
  auto wide_from_diag = cutlass::Matrix<float, 2, 3>::from_diagonal(wide_diag);
  EXPECT_EQ(wide_from_diag.data[4], 8);

  cutlass::Matrix<float, 2, 1> left = {1, 4};
  cutlass::Matrix<float, 2, 2> right = {2, 3, 5, 6};
  EXPECT_EQ((cutlass::Matrix<float, 2, 3>::hcat(left, right).at(1, 2)), 6);

  cutlass::Matrix<float, 3, 2> tall = {
    1, 2,
    3, 4,
    5, 6
  };

  EXPECT_EQ(tall.at(2, 1), 6);
  EXPECT_EQ(tall.diagonal().at(1, 0), 4);

  cutlass::Matrix<float, 2, 1> tall_diag = {7, 8};
  auto tall_from_diag = cutlass::Matrix<float, 3, 2>::from_diagonal(tall_diag);
  EXPECT_EQ(tall_from_diag.data[3], 8);

  cutlass::Matrix<float, 1, 2> upper = {1, 2};
  EXPECT_EQ((cutlass::Matrix<float, 4, 2>::vcat(upper, tall).at(3, 1)), 6);

  cutlass::Matrix<float, 2, 4> wide4 = {1, 2, 3, 4, 5, 6, 7, 8};
  EXPECT_EQ(wide4.diagonal().data[1], 6);

  cutlass::Matrix<float, 3, 4> wide34 = {
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12
  };
  EXPECT_EQ(wide34.diagonal().data[2], 11);

  EXPECT_EQ((cutlass::Matrix<float, 4, 2>::from_diagonal(tall_diag).data[3]), 8);

  cutlass::Matrix<float, 3, 1> diag3 = {7, 8, 9};
  EXPECT_EQ((cutlass::Matrix<float, 4, 3>::from_diagonal(diag3).data[8]), 9);

  cutlass::Matrix<float, 4, 1> column = {1, 2, 3, 4};
  EXPECT_EQ(column.at(3, 0), 4);
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(Matrix, elementwise_add) {

  using Matrix4x4 = cutlass::Matrix4x4<float>;

  Matrix4x4 A = {
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12,
    13, 14, 15, 16
  };

  Matrix4x4 B = A.transpose();

  Matrix4x4 C = A.add(B * 2.125f);

  bool passed = true;

  for (int i = 0; i < 4; ++i) {
    for (int j = 0; j < 4; ++j) {
      float got = C.at(i, j);
      float expected = A.at(i, j) + A.at(j, i) * 2.125f;
      if (got != expected) {
        passed = false;
      }
    }
  }
  EXPECT_TRUE(passed);
  if (!passed) {
    std::cout << "A:\n" << A << "\n\nB:\n" << B << "\n\nC:\n" << C << std::endl;
  }
}

TEST(Matrix, elementwise_multiply) {

  using Matrix4x4 = cutlass::Matrix4x4<float>;

  Matrix4x4 A = {
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12,
    13, 14, 15, 16
  };

  Matrix4x4 B = A.transpose();

  Matrix4x4 C = A.multiply(B);

  bool passed = true;

  for (int i = 0; i < 4; ++i) {
    for (int j = 0; j < 4; ++j) {
      float got = C.at(i, j);
      float expected = A.at(i, j) * A.at(j, i);
      if (got != expected) {
        passed = false;
      }
    }
  }
  EXPECT_TRUE(passed);
  if (!passed) {
    std::cout << "A:\n" << A << "\n\nB:\n" << B << "\n\nC:\n" << C << std::endl;
  }
}

TEST(Matrix, product_4x4_overloads) {

  using Matrix4x4 = cutlass::Matrix4x4<float>;

  Matrix4x4 A = {
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12,
    13, 14, 15, 16
  };

  Matrix4x4 B = {
    -1, -2, 0, 4,
    1, 2, 1, 1,
    3, 2, 1, 1,
    1, 0, 8, 2
  };
  
  Matrix4x4 C = Matrix4x4::identity();

  Matrix4x4 D = A * B + C;

  bool passed = true;

  for (int i = 0; i < 4; ++i) {
    for (int j = 0; j < 4; ++j) {
      float got = D.at(i, j);
      float expected = (i == j ? 1.0f : 0);
      for (int k = 0; k < 4; ++k) {
        expected += A.at(i, k) * B.at(k, j);
      }
      if (got != expected) {
        passed = false;
      }
    }
  }

  EXPECT_TRUE(passed);
  if (!passed) {
    std::cout << "A:\n" << A << "\n\nB:\n" << B << "\n\nC:\n" << C << "\n\nD:\n" << D << std::endl;
  }
}


TEST(Matrix, product_4x4) {

  using Matrix4x4 = cutlass::Matrix4x4<float>;

  Matrix4x4 A = {
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12,
    13, 14, 15, 16
  };

  Matrix4x4 B = {
    -1, -2, 0, 4,
    1, 2, 1, 1,
    3, 2, 1, 1,
    1, 0, 8, 2
  };

  Matrix4x4 C = Matrix4x4::identity();

  // Compute product with optional source accumulator
  Matrix4x4 D = A.product(B, C);

  bool passed = true;

  for (int i = 0; i < 4; ++i) {
    for (int j = 0; j < 4; ++j) {
      float got = D.at(i, j);
      float expected = (i == j ? 1.0f : 0.0f);
      for (int k = 0; k < 4; ++k) {
        expected += A.at(i, k) * B.at(k, j);
      }
      if (got != expected) {
        passed = false;
      }
    }
  }

  EXPECT_TRUE(passed);
  if (!passed) {
    std::cout << "A:\n" << A << "\n\nB:\n" << B << "\n\nC:\n" << C << "\n\nD:\n" << D << std::endl;
  }

  for (int i = 0; i < 4; ++i) {
    for (int j = 0; j < 4; ++j) {
      float c = (i == j ? 1.0f : 0.0f);
      EXPECT_TRUE(A.row(i).dot(B.column(j)) + c == D.at(i, j));
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////

