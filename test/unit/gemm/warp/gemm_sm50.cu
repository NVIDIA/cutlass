/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Unit tests for thread-level GEMM
*/

#include "../../common/cutlass_unit_test.h"

#include "cutlass/complex.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/warp/mma_simt.h"

#include "testbed.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(SM50_warp_gemm_f32_col_row_col, 32x16x1_4x4x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::ColumnMajorInterleaved<2>,
    cutlass::gemm::GemmShape<4, 4, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<32, 16, 8>,
    float,
    cutlass::layout::ColumnMajor,
    float,
    cutlass::layout::RowMajor,
    float,
    cutlass::layout::ColumnMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8> >().run();
}

TEST(SM50_warp_gemm_f32_col_row_row, 16x32x1_4x4x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<4, 8>,
    cutlass::layout::RowMajorInterleaved<2>,
    cutlass::gemm::GemmShape<4, 4, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<16, 32, 8>,
    float,
    cutlass::layout::ColumnMajor,
    float,
    cutlass::layout::RowMajor,
    float,
    cutlass::layout::RowMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8> >().run();
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(SM50_warp_gemm_f32_col_row_col, 32x16x1_2x2x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::ColumnMajorInterleaved<2>,
    cutlass::gemm::GemmShape<2, 2, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<32, 16, 8>,
    float,
    cutlass::layout::ColumnMajor,
    float,
    cutlass::layout::RowMajor,
    float,
    cutlass::layout::ColumnMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

TEST(SM50_warp_gemm_f32_col_row_row, 32x16x1_2x2x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::RowMajorInterleaved<2>,
    cutlass::gemm::GemmShape<2, 2, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<32, 16, 8>,
    float,
    cutlass::layout::ColumnMajor,
    float,
    cutlass::layout::RowMajor,
    float,
    cutlass::layout::RowMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(SM50_warp_gemm_f32_col_row_col, 32x64x1_4x4x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::ColumnMajorInterleaved<2>,
    cutlass::gemm::GemmShape<4, 4, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<64, 32, 8>,
    float,
    cutlass::layout::ColumnMajor,
    float,
    cutlass::layout::RowMajor,
    float,
    cutlass::layout::ColumnMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

TEST(SM50_warp_gemm_f32_col_row_row, 32x64x1_4x4x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<4, 8>,
    cutlass::layout::RowMajorInterleaved<2>,
    cutlass::gemm::GemmShape<4, 4, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<32, 64, 8>,
    float,
    cutlass::layout::ColumnMajor,
    float,
    cutlass::layout::RowMajor,
    float,
    cutlass::layout::RowMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(SM50_warp_gemm_complex_f32_col_row_col, 64x32x1_2x2x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::ColumnMajorInterleaved<2>,
    cutlass::gemm::GemmShape<2, 2, 1>
  >;

  using complex_f32_t = cutlass::complex<float>;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<64, 32, 8>,
    complex_f32_t,
    cutlass::layout::ColumnMajor,
    complex_f32_t,
    cutlass::layout::RowMajor,
    complex_f32_t,
    cutlass::layout::ColumnMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

TEST(SM50_warp_gemm_complex_f32_col_row_row, 64x32x1_2x2x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::RowMajorInterleaved<2>,
    cutlass::gemm::GemmShape<2, 2, 1>
  >;

  using complex_f32_t = cutlass::complex<float>;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<64, 32, 8>,
    complex_f32_t,
    cutlass::layout::ColumnMajor,
    complex_f32_t,
    cutlass::layout::RowMajor,
    complex_f32_t,
    cutlass::layout::RowMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(SM50_warp_gemm_f64_col_row_col, 8x4x1_1x1x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::ColumnMajorInterleaved<2>,
    cutlass::gemm::GemmShape<1, 1, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<8, 4, 8>,
    double,
    cutlass::layout::ColumnMajor,
    double,
    cutlass::layout::RowMajor,
    double,
    cutlass::layout::ColumnMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

TEST(SM50_warp_gemm_f64_col_row_row, 8x4x1_1x1x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::RowMajorInterleaved<2>,
    cutlass::gemm::GemmShape<1, 1, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<8, 4, 8>,
    double,
    cutlass::layout::ColumnMajor,
    double,
    cutlass::layout::RowMajor,
    double,
    cutlass::layout::RowMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(SM50_warp_gemm_f64_col_row_col, 32x16x1_2x2x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::ColumnMajorInterleaved<2>,
    cutlass::gemm::GemmShape<2, 2, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<32, 16, 8>,
    double,
    cutlass::layout::ColumnMajor,
    double,
    cutlass::layout::RowMajor,
    double,
    cutlass::layout::ColumnMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

TEST(SM50_warp_gemm_f64_col_row_row, 32x16x1_2x2x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::RowMajorInterleaved<2>,
    cutlass::gemm::GemmShape<2, 2, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<32, 16, 8>,
    double,
    cutlass::layout::ColumnMajor,
    double,
    cutlass::layout::RowMajor,
    double,
    cutlass::layout::RowMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(SM50_warp_gemm_f64_col_row_col, 64x32x1_2x2x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::ColumnMajorInterleaved<2>,
    cutlass::gemm::GemmShape<2, 2, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<64, 32, 8>,
    double,
    cutlass::layout::ColumnMajor,
    double,
    cutlass::layout::RowMajor,
    double,
    cutlass::layout::ColumnMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

TEST(SM50_warp_gemm_f64_col_row_row, 64x32x1_2x2x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::RowMajorInterleaved<2>,
    cutlass::gemm::GemmShape<2, 2, 1>
  >;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<64, 32, 8>,
    double,
    cutlass::layout::ColumnMajor,
    double,
    cutlass::layout::RowMajor,
    double,
    cutlass::layout::RowMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(SM50_warp_gemm_complex_f64_col_row_col, 32x16x1_1x1x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::ColumnMajorInterleaved<2>,
    cutlass::gemm::GemmShape<1, 1, 1>
  >;

  using complex_f64_t = cutlass::complex<double>;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<64, 16, 8>,
    complex_f64_t,
    cutlass::layout::ColumnMajor,
    complex_f64_t,
    cutlass::layout::RowMajor,
    complex_f64_t,
    cutlass::layout::ColumnMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

TEST(SM50_warp_gemm_complex_f64_col_row_row, 32x16x1_1x1x1) {

  using Policy = cutlass::gemm::warp::MmaSimtPolicy<
    cutlass::MatrixShape<8, 4>,
    cutlass::layout::RowMajorInterleaved<2>,
    cutlass::gemm::GemmShape<1, 1, 1>
  >;

  using complex_f64_t = cutlass::complex<double>;

  using Mma = cutlass::gemm::warp::MmaSimt<
    cutlass::gemm::GemmShape<64, 16, 8>,
    complex_f64_t,
    cutlass::layout::ColumnMajor,
    complex_f64_t,
    cutlass::layout::RowMajor,
    complex_f64_t,
    cutlass::layout::RowMajor,
    Policy
  >;

  test::gemm::warp::Testbed<Mma, cutlass::gemm::GemmShape<128, 128, 8>>().run();
}

/////////////////////////////////////////////////////////////////////////////////////////////////
