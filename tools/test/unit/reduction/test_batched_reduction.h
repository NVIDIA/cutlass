/***************************************************************************************************
* Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
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
\brief Test environment for batched reduction
*/

#pragma once
#include "cutlass/cutlass.h"
#include "tools/test/unit/reduction/batched_reduction_testbed.h"

template <typename BatchedRecutionTraits_>
static void test_batched_reduction(
    int m,
    int n,
    int lda,
    int ldc,
    int ldd) {
  typedef BatchedRecutionTraits_ Traits;
  typedef cutlass::reduction::BatchedReduction<Traits> batched_reduction;
  typename batched_reduction::Params params;

  test::BatchedReductionTestbed<typename cutlass::TypeTraits<typename Traits::ScalarA>::host_type,
    typename cutlass::TypeTraits<typename Traits::ScalarC>::host_type,
    typename cutlass::TypeTraits<typename Traits::ScalarD>::host_type,
    typename cutlass::TypeTraits<typename Traits::ScalarAlphaBeta>::host_type,
    typename cutlass::TypeTraits<typename Traits::ScalarAlphaBeta>::host_type,
    typename cutlass::TypeTraits<typename Traits::ScalarAccum>::host_type,
    Traits::ReductionSize>
  testbed(m, n, lda, ldc, ldd);
  testbed.initialize();

  params.initialize(testbed.M(), 
    testbed.N(),
    testbed.get_alpha(),
    testbed.get_beta(),
    testbed.get_reduction_stride(),
    testbed.ptr_A(),
    testbed.get_lda(),
    testbed.ptr_C(),
    testbed.get_ldc(),
    testbed.ptr_D(),
    testbed.get_ldd());
  
  
  batched_reduction::launch(params);
  cudaError_t result = cudaDeviceSynchronize();
  ASSERT_EQ(result, cudaSuccess) << "\nCUDA kernel launch error: " << cudaGetErrorString(result)
    << "\n";
  
  ASSERT_TRUE(testbed.verify_with_host());
}
