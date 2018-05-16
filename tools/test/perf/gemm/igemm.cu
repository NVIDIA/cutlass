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

#include <cutlass/gemm/gemm.h>
#include <cutlass/gemm/igemm_traits.h>
#include <tools/test/perf/gemm/gemm_perf_testbed.h>
#include <tools/test/perf/gemm/gemm_profiler.h>
#include <tools/test/perf/gemm/cutlass_dispatch.h>

namespace perf {

////////////////////////////////////////////////////////////////////////////////////////////////////

int profile_igemm(TestbenchOutput &output, TestbenchOptions const &options) {

  typedef perf::GemmProfiler<int8_t, int8_t, int, int, int> GemmProfiler;

  int results = 0;
  
  if (!results) {
    
    typedef cutlass::gemm::IgemmTraits<
      cutlass::MatrixLayout::kColumnMajor,
      cutlass::MatrixLayout::kRowMajor
    > GemmTraits;

    typedef typename CutlassDispatchBasic<GemmTraits>::Dispatch Dispatch;

    profile_gemm<Dispatch, GemmProfiler>(output, "igemm_nt", options);
  }

  if (!results) {
    
    typedef cutlass::gemm::IgemmTraits<
      cutlass::MatrixLayout::kColumnMajor,
      cutlass::MatrixLayout::kColumnMajor
    > GemmTraits;

    typedef typename CutlassDispatchBasic<GemmTraits>::Dispatch Dispatch;

    profile_gemm<Dispatch, GemmProfiler>(output, "igemm_nn", options);
  }

  if (!results) {
    
    typedef cutlass::gemm::IgemmTraits<
      cutlass::MatrixLayout::kRowMajor,
      cutlass::MatrixLayout::kColumnMajor
    > GemmTraits;

    typedef typename CutlassDispatchBasic<GemmTraits>::Dispatch Dispatch;

    profile_gemm<Dispatch, GemmProfiler>(output, "igemm_tn", options);
  }

  if (!results) {
    
    typedef cutlass::gemm::IgemmTraits<
      cutlass::MatrixLayout::kRowMajor,
      cutlass::MatrixLayout::kRowMajor
    > GemmTraits;

    typedef typename CutlassDispatchBasic<GemmTraits>::Dispatch Dispatch;

    profile_gemm<Dispatch, GemmProfiler>(output, "igemm_tt", options);
  }

  return results;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace perf
