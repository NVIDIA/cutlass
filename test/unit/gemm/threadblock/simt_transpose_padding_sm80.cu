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
/*! \file
    \brief Compile-time checks of the shared-memory padding that the SM80 multistage SIMT MmaCores
    apply to operand tiles transposed into shared memory.

    The device tests only verify GEMM results, which are correct with or without padding. These
    checks pin the MmaPolicy padding itself: which operand is padded in each layout, the expected
    values, and alignment to the warp-level shared memory load vector (lane) width.
*/

#include "../../common/cutlass_unit_test.h"

#include "cutlass/cutlass.h"
#include "cutlass/complex.h"
#include "cutlass/arch/mma.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/gemm/threadblock/default_mma_core_simt.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm80.h"
#include "cutlass/gemm/threadblock/default_multistage_mma_complex_core_sm80.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace {

using cutlass::gemm::threadblock::detail::simt_transpose_padding;
using cutlass::gemm::threadblock::detail::simt_transpose_padding_aligned;

// The helper rounds the 2-stage padding (32 / kK / words per element) up to a nonzero multiple of
// the lane width.
static_assert(simt_transpose_padding(32, 8, 32) == 4 &&
              simt_transpose_padding_aligned(32, 8, 32, 4) == 4, "f32, kK = 8");
static_assert(simt_transpose_padding(32, 16, 32) == 2 &&
              simt_transpose_padding_aligned(32, 16, 32, 4) == 4,
              "f32, kK = 16: raw padding 2 rounds up to the lane width");
static_assert(simt_transpose_padding(32, 8, 64) == 2 &&
              simt_transpose_padding_aligned(32, 8, 64, 2) == 2, "cf32, kK = 8");
static_assert(simt_transpose_padding(32, 16, 64) == 1 &&
              simt_transpose_padding_aligned(32, 16, 64, 2) == 2,
              "cf32, kK = 16: raw padding 1 rounds up to the lane width");
static_assert(simt_transpose_padding(32, 8, 128) == 1 &&
              simt_transpose_padding_aligned(32, 8, 128, 1) == 1, "cf64, kK = 8");
static_assert(simt_transpose_padding(32, 16, 128) == 0 &&
              simt_transpose_padding_aligned(32, 16, 128, 1) == 1,
              "cf64, kK = 16: raw padding 0 becomes the minimum nonzero padding");

using Col = cutlass::layout::ColumnMajor;
using Row = cutlass::layout::RowMajor;
template <int M, int N, int K> using Shape = cutlass::gemm::GemmShape<M, N, K>;

template <typename TB, typename Warp, int Stages, typename LayoutA, typename LayoutB>
using RealCore = cutlass::gemm::threadblock::DefaultMmaCore<
    TB, Warp, Shape<1, 1, 1>, float, LayoutA, float, LayoutB, float, Row,
    cutlass::arch::OpClassSimt, Stages, cutlass::arch::OpMultiplyAdd>;

template <typename Real, typename TB, typename Warp, int Stages, typename LayoutA, typename LayoutB>
using ComplexCore = cutlass::gemm::threadblock::DefaultMultistageMmaComplexCore<
    TB, Warp, Shape<1, 1, 1>, cutlass::complex<Real>, LayoutA, cutlass::complex<Real>, LayoutB,
    cutlass::complex<Real>, Row, cutlass::arch::OpClassSimt, Stages,
    cutlass::ComplexTransform::kNone, cutlass::ComplexTransform::kNone,
    cutlass::arch::OpMultiplyAddComplex>;

/// Checks the MmaPolicy padding of one core: kPadA elements along M of the A tile and kPadB along
/// N of the B tile, both multiples of the lane width, with lane-aligned padded strides.
template <typename Core, typename TB, int kPadA, int kPadB>
struct PaddingCheck {
  using Policy = typename Core::MmaPolicy;
  static_assert(Policy::SmemPaddingA::kRow == kPadA && Policy::SmemPaddingA::kColumn == 0,
                "unexpected A padding");
  static_assert(Policy::SmemPaddingB::kRow == 0 && Policy::SmemPaddingB::kColumn == kPadB,
                "unexpected B padding");
  static_assert(kPadA % Core::LaneM == 0 && kPadB % Core::LaneN == 0,
                "padding must be a multiple of the lane width");
  static_assert((TB::kM + kPadA) % Core::LaneM == 0 && (TB::kN + kPadB) % Core::LaneN == 0,
                "padded shared memory strides must stay lane-aligned");
  static bool const kChecked = true;

  static void expect() {
    EXPECT_EQ(int(Policy::SmemPaddingA::kRow), kPadA);
    EXPECT_EQ(int(Policy::SmemPaddingA::kColumn), 0);
    EXPECT_EQ(int(Policy::SmemPaddingB::kRow), 0);
    EXPECT_EQ(int(Policy::SmemPaddingB::kColumn), kPadB);
  }
};

/// The four layout specializations of a core: nn pads only B, nt pads neither, tn pads both and
/// tt pads only A, each by kPad elements.
template <template <typename, typename> class Core, typename TB, int kPad>
struct LayoutChecks {
  using NN = PaddingCheck<Core<Col, Col>, TB, 0, kPad>;
  using NT = PaddingCheck<Core<Col, Row>, TB, 0, 0>;
  using TN = PaddingCheck<Core<Row, Col>, TB, kPad, kPad>;
  using TT = PaddingCheck<Core<Row, Row>, TB, kPad, 0>;
  static bool const kChecked = NN::kChecked && NT::kChecked && TN::kChecked && TT::kChecked;

  static void expect() {
    NN::expect();
    NT::expect();
    TN::expect();
    TT::expect();
  }
};

// f32: lane of 4 elements (128 bits), padding 4 per transposed operand.
// generated tile
template <typename LA, typename LB>
using F32_128x128x8 = RealCore<Shape<128, 128, 8>, Shape<32, 64, 8>, 5, LA, LB>;
template <typename LA, typename LB>
using F32_64x64x8 = RealCore<Shape<64, 64, 8>, Shape<32, 32, 8>, 5, LA, LB>;
// raw 2 -> 4
template <typename LA, typename LB>
using F32_64x64x16 = RealCore<Shape<64, 64, 16>, Shape<32, 32, 16>, 3, LA, LB>;

using F32Checks_128x128x8 = LayoutChecks<F32_128x128x8, Shape<128, 128, 8>, 4>;
using F32Checks_64x64x8 = LayoutChecks<F32_64x64x8, Shape<64, 64, 8>, 4>;
using F32Checks_64x64x16 = LayoutChecks<F32_64x64x16, Shape<64, 64, 16>, 4>;
static_assert(F32Checks_128x128x8::kChecked && F32Checks_64x64x8::kChecked &&
              F32Checks_64x64x16::kChecked, "f32 padding");

// cf32: lane of 2 elements, padding 2 per transposed operand.
// generated
template <typename LA, typename LB>
using CF32_128x128x8 = ComplexCore<float, Shape<128, 128, 8>, Shape<32, 64, 8>, 5, LA, LB>;
// generated, raw 1 -> 2
template <typename LA, typename LB>
using CF32_32x64x16 = ComplexCore<float, Shape<32, 64, 16>, Shape<16, 32, 16>, 4, LA, LB>;
// generated, raw 1 -> 2
template <typename LA, typename LB>
using CF32_32x32x16 = ComplexCore<float, Shape<32, 32, 16>, Shape<16, 16, 16>, 5, LA, LB>;

using CF32Checks_128x128x8 = LayoutChecks<CF32_128x128x8, Shape<128, 128, 8>, 2>;
using CF32Checks_32x64x16 = LayoutChecks<CF32_32x64x16, Shape<32, 64, 16>, 2>;
using CF32Checks_32x32x16 = LayoutChecks<CF32_32x32x16, Shape<32, 32, 16>, 2>;
static_assert(CF32Checks_128x128x8::kChecked && CF32Checks_32x64x16::kChecked &&
              CF32Checks_32x32x16::kChecked, "cf32 padding");

// cf64: lane of 1 element, padding 1 per transposed operand.
template <typename LA, typename LB>
using CF64_64x64x8 = ComplexCore<double, Shape<64, 64, 8>, Shape<32, 32, 8>, 3, LA, LB>;
// raw 0 -> 1
template <typename LA, typename LB>
using CF64_32x32x16 = ComplexCore<double, Shape<32, 32, 16>, Shape<16, 16, 16>, 3, LA, LB>;

using CF64Checks_64x64x8 = LayoutChecks<CF64_64x64x8, Shape<64, 64, 8>, 1>;
using CF64Checks_32x32x16 = LayoutChecks<CF64_32x32x16, Shape<32, 32, 16>, 1>;
static_assert(CF64Checks_64x64x8::kChecked && CF64Checks_32x32x16::kChecked, "cf64 padding");

} // namespace

/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(SM80_gemm_threadblock_simt_transpose_padding, f32) {
  F32Checks_128x128x8::expect();
  F32Checks_64x64x8::expect();
  F32Checks_64x64x16::expect();
}

TEST(SM80_gemm_threadblock_simt_transpose_padding, cf32) {
  CF32Checks_128x128x8::expect();
  CF32Checks_32x64x16::expect();
  CF32Checks_32x32x16::expect();
}

TEST(SM80_gemm_threadblock_simt_transpose_padding, cf64) {
  CF64Checks_64x64x8::expect();
  CF64Checks_32x32x16::expect();
}

/////////////////////////////////////////////////////////////////////////////////////////////////
