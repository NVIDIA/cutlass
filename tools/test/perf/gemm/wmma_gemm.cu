/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
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

#include <cutlass/wmma_matrix.h>
#ifdef CUTLASS_USE_WMMA_API

////////////////////////////////////////////////////////////////////////////////////////////////////

#include <cutlass/gemm/gemm.h>

#include <tools/test/perf/gemm/gemm_profiler.h>
#include <tools/test/perf/gemm/cutlass_dispatch.h>
#include <tools/test/perf/gemm/gemm_perf_testbed.h>
#include <cutlass/gemm/wmma_gemm_traits.h>

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Traits>
struct WmmaGemmDispatch {

  typedef cutlass::gemm::Gemm<Traits> Gemm;

  typedef typename Gemm::Params Params;

  /// Indicate warp-level GEMM
  static bool const kThreadMultiplyAdd = false;

  static cutlass::MatrixLayout::Kind const kLayoutA = Traits::kLayoutA;
  static cutlass::MatrixLayout::Kind const kLayoutB = Traits::kLayoutB;

  //
  // Data members
  //

  /// Params argument
  Params params;

  //
  // Methods
  //

  WmmaGemmDispatch() {}

  /// Initializes params object
  WmmaGemmDispatch(int m, int n, int k, float alpha, half const* d_a, int lda,
                  half const* d_b, int ldb, float beta, float const* d_c, int ldc,
                  float* d_d, int ldd) {

    params.initialize(m, n, k, alpha, d_a, lda, d_b, ldb, beta, d_c, ldc, d_d, ldd);
  }

  /// Initializes params object
  WmmaGemmDispatch(Params const& _params) : params(_params) {}

  /// Launches kernel
  cudaError_t operator()() { return Gemm::launch(params); }

  /// Determines if problem is aligned (assuming no padding)
  static bool is_problem_aligned(
    int m,
    int n,
    int k) {

    bool aligned = true;

    if (kLayoutA == cutlass::MatrixLayout::kColumnMajor) {
      aligned = aligned && !(m % Gemm::Traits::GemmConfig::kScalarsPerLdgA);
    }
    else {
      aligned = aligned && !(k % Gemm::Traits::GemmConfig::kScalarsPerLdgA);
    }

    if (kLayoutB == cutlass::MatrixLayout::kColumnMajor) {
      aligned = aligned && !(k % Gemm::Traits::GemmConfig::kScalarsPerLdgB);
    }
    else {
      aligned = aligned && !(n % Gemm::Traits::GemmConfig::kScalarsPerLdgB);
    }

    aligned = aligned && !(m % Gemm::Traits::GemmConfig::kScalarsPerLdgC);

    return aligned;
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace perf {

////////////////////////////////////////////////////////////////////////////////////////////////////

int profile_wmma_gemm(TestbenchOutput &output, TestbenchOptions const &options) {

  typedef perf::GemmProfiler<cutlass::half_t, cutlass::half_t, float, float, float> GemmProfiler;

  int results = 0;

  if (!results) {

    typedef cutlass::gemm::WmmaGemmTraits<cutlass::MatrixLayout::kColumnMajor,
                                        cutlass::MatrixLayout::kRowMajor>
    WmmaGemmTraits;

    typedef WmmaGemmDispatch<WmmaGemmTraits> Dispatch;

    profile_gemm<Dispatch, GemmProfiler>(output, "wmma_gemm_nt", options);
  }

  if (!results) {

    typedef cutlass::gemm::WmmaGemmTraits<cutlass::MatrixLayout::kColumnMajor,
                                        cutlass::MatrixLayout::kColumnMajor>
    WmmaGemmTraits;

    typedef WmmaGemmDispatch<WmmaGemmTraits> Dispatch;

    profile_gemm<Dispatch, GemmProfiler>(output, "wmma_gemm_nn", options);
  }

  if (!results) {

    typedef cutlass::gemm::WmmaGemmTraits<cutlass::MatrixLayout::kRowMajor,
                                        cutlass::MatrixLayout::kColumnMajor>
      WmmaGemmTraits;

    typedef WmmaGemmDispatch<WmmaGemmTraits> Dispatch;

    profile_gemm<Dispatch, GemmProfiler>(output, "wmma_gemm_tn", options);
  }

  if (!results) {

    typedef cutlass::gemm::WmmaGemmTraits<cutlass::MatrixLayout::kRowMajor,
                                        cutlass::MatrixLayout::kRowMajor>
      WmmaGemmTraits;

    typedef WmmaGemmDispatch<WmmaGemmTraits> Dispatch;

    profile_gemm<Dispatch, GemmProfiler>(output, "wmma_gemm_tt", options);
  }

  return results;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace perf

////////////////////////////////////////////////////////////////////////////////////////////////////

#endif  // defined CUTLASS_USE_WMMA_API
