/***************************************************************************************************
 * Copyright (c) 2025 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cute/tensor.hpp"
#include "collective/fmha_fusion.hpp"

using namespace cutlass::fmha::collective;
/////////////////////////////////////////////////////////////////////////////////////////////////

template<
    class ProblemShape,
    class TensorQ, class TensorK, class TensorV,
    class TensorO, class TensorLSE, class TensorDO,
    class TensorDQ, /* class TensorDK, class TensorDV, */
    class Fusion
>
void __global__ fmha_bwd_reference_dQ_kernel(
    ProblemShape problem_shape_in,
    TensorQ mQ_in, TensorK mK_in, TensorV mV_in,
    TensorO mO_in, TensorLSE mLSE_in, TensorDO mDO_in,
    TensorDQ mDQ_in, /* TensorDK mDK, TensorDV mDV, */
    Fusion fusion) {

  using namespace cute;
  using namespace cutlass::fmha::collective;

  using Element = typename TensorO::value_type;
  using ElementAccumulator = typename TensorLSE::value_type;
  
  extern __shared__ char mS_mem[];
  ElementAccumulator* mS = reinterpret_cast<ElementAccumulator*>(mS_mem);

  ElementAccumulator softmax_scale = 1.0 / sqrt(ElementAccumulator(size<2>(problem_shape_in)));

  for (int idx_L = blockIdx.y; idx_L < size<4>(problem_shape_in); idx_L += gridDim.y) {
    auto [problem_shape, offset] = apply_variable_length_offset(
        problem_shape_in,
        make_coord(_0{}, _0{}, _0{}, _0{},idx2crd(idx_L, get<4>(problem_shape_in)))
    );
    // problem_shape = problem_shape_in;
    // offset = repeat_like(problem_shape_in, _0{});
    auto mQ = domain_offset(select<0,2,4>(offset), mQ_in);
    auto mK = domain_offset(select<1,2,4>(offset), mK_in);
    auto mV = domain_offset(select<1,3,4>(offset), mV_in);
    auto mO = domain_offset(select<0,3,4>(offset), mO_in);
    auto mLSE = domain_offset(select<0,4>(offset), mLSE_in);
    auto mDO = domain_offset(select<0,3,4>(offset), mDO_in);
    auto mDQ = domain_offset(select<0,2,4>(offset), mDQ_in);
    for (int idx_Q = blockIdx.x; idx_Q < size<0>(problem_shape); idx_Q += gridDim.x) {
      for (int idx_K = threadIdx.x; idx_K < size<1>(problem_shape); idx_K += blockDim.x) {
        ElementAccumulator acc_qk = 0;
        ElementAccumulator acc_dov = 0;
        ElementAccumulator acc_doo = 0;
        for (int idx_D0 = 0; idx_D0 < size<2>(problem_shape); idx_D0++) {
          acc_qk += mQ(idx_Q, idx_D0, idx_L) * mK(idx_K, idx_D0, idx_L);
          // acc_dov += mDO(idx_Q, idx_D0, idx_L) * mV(idx_K, idx_D0, idx_L);
          // acc_doo += mDO(idx_Q, idx_D0, idx_L) * mO(idx_Q, idx_D0, idx_L);
        }  // for idx_D0

        for (int idx_D1 = 0; idx_D1 < size<3>(problem_shape); idx_D1++) {
          acc_dov += mDO(idx_Q, idx_D1, idx_L) * mV(idx_K, idx_D1, idx_L);
          acc_doo += mDO(idx_Q, idx_D1, idx_L) * mO(idx_Q, idx_D1, idx_L);
        }

        auto id = make_identity_tensor(make_shape(1, 1));
        auto frag = make_tensor<ElementAccumulator>(Shape<_1, _1>{});
        frag(0) = acc_qk;
        fusion.apply_mask(frag, make_tensor(id.data() + make_arithmetic_tuple(idx_Q, idx_K), id.layout()), problem_shape);
        acc_qk = frag(0);

        mS[idx_K] = static_cast<ElementAccumulator>(exp(softmax_scale * acc_qk - mLSE(idx_Q, idx_L)) * softmax_scale * (acc_dov - acc_doo));
      }  // for idx_K

      __syncthreads();

      for (int idx_D = threadIdx.x; idx_D < size<2>(problem_shape); idx_D += blockDim.x) {
        ElementAccumulator acc = 0;
        for (int idx_K = 0; idx_K < size<1>(problem_shape); idx_K++) {
          acc += mS[idx_K] * ElementAccumulator(mK(idx_K, idx_D, idx_L));
        }
        mDQ(idx_Q, idx_D, idx_L) = static_cast<typename TensorDQ::value_type>(acc);
      }  // for idx_D
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template<
    class ProblemShape,
    class TensorQ, class TensorK, class TensorV,
    class TensorO, class TensorLSE, class TensorDO,
    /* class TensorDQ, */ class TensorDK, /* class TensorDV, */
    class Fusion
>
void __global__ fmha_bwd_reference_dK_kernel(
    ProblemShape problem_shape_in,
    TensorQ mQ_in, TensorK mK_in, TensorV mV_in,
    TensorO mO_in, TensorLSE mLSE_in, TensorDO mDO_in,
    /* TensorDQ mDQ_in, */ TensorDK mDK_in, /* TensorDV mDV_in, */
    Fusion fusion) {

  using namespace cute;
  using namespace cutlass::fmha::collective;

  using Element = typename TensorO::value_type;
  using ElementAccumulator = typename TensorLSE::value_type;
  
  extern __shared__ char mS_mem[];
  ElementAccumulator* mS = reinterpret_cast<ElementAccumulator*>(mS_mem);

  ElementAccumulator softmax_scale = 1.0 / sqrt(ElementAccumulator(size<2>(problem_shape_in)));

  for (int idx_L = blockIdx.y; idx_L < size<4>(problem_shape_in); idx_L += gridDim.y) {
    auto [problem_shape, offset] = apply_variable_length_offset(
        problem_shape_in,
        make_coord(_0{}, _0{}, _0{}, _0{}, idx2crd(idx_L, get<4>(problem_shape_in)))
    );
    // problem_shape = problem_shape_in;
    // offset = repeat_like(problem_shape_in, _0{});
    auto mQ = domain_offset(select<0,2,4>(offset), mQ_in);
    auto mK = domain_offset(select<1,2,4>(offset), mK_in);
    auto mV = domain_offset(select<1,3,4>(offset), mV_in);
    auto mO = domain_offset(select<0,3,4>(offset), mO_in);
    auto mLSE = domain_offset(select<0,4>(offset), mLSE_in);
    auto mDO = domain_offset(select<0,3,4>(offset), mDO_in);
    auto mDK = domain_offset(select<1,2,4>(offset), mDK_in);
    for (int idx_K = blockIdx.x; idx_K < size<1>(problem_shape); idx_K += gridDim.x) {
      for (int idx_Q = threadIdx.x; idx_Q < size<0>(problem_shape); idx_Q += blockDim.x) {
        ElementAccumulator acc_qk = 0;
        ElementAccumulator acc_dov = 0;
        ElementAccumulator acc_doo = 0;
        for (int idx_D0 = 0; idx_D0 < size<2>(problem_shape); idx_D0++) {
          acc_qk += mQ(idx_Q, idx_D0, idx_L) * mK(idx_K, idx_D0, idx_L);
          // acc_dov += mDO(idx_Q, idx_D0, idx_L) * mV(idx_K, idx_D0, idx_L);
          // acc_doo += mDO(idx_Q, idx_D0, idx_L) * mO(idx_Q, idx_D0, idx_L);
        }  // for idx_D0

        for (int idx_D1 = 0; idx_D1 < size<3>(problem_shape); idx_D1++) {
          acc_dov += mDO(idx_Q, idx_D1, idx_L) * mV(idx_K, idx_D1, idx_L);
          acc_doo += mDO(idx_Q, idx_D1, idx_L) * mO(idx_Q, idx_D1, idx_L);
        }
        auto id = make_identity_tensor(make_shape(1, 1));
        auto frag = make_tensor<ElementAccumulator>(Shape<_1, _1>{});
        frag(0) = acc_qk;
        fusion.apply_mask(frag, make_tensor(id.data() + make_arithmetic_tuple(idx_Q, idx_K), id.layout()), problem_shape);
        acc_qk = frag(0);

        mS[idx_Q] = static_cast<ElementAccumulator>(exp(softmax_scale * acc_qk - mLSE(idx_Q, idx_L)) * softmax_scale * (acc_dov - acc_doo));
      }  // for idx_Q

      __syncthreads();

      for (int idx_D = threadIdx.x; idx_D < size<2>(problem_shape); idx_D += blockDim.x) {
        ElementAccumulator acc = 0;
        for (int idx_Q = 0; idx_Q < size<0>(problem_shape); idx_Q++) {
          acc += mS[idx_Q] * ElementAccumulator(mQ(idx_Q, idx_D, idx_L));
        }
        mDK(idx_K, idx_D, idx_L) = static_cast<typename TensorDK::value_type>(acc);
      }  // for idx_D
    }  // for idx_K
  }  // for idx_L
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template<
    class ProblemShape,
    class TensorQ, class TensorK, class TensorV,
    class TensorO, class TensorLSE, class TensorDO,
    /* class TensorDQ, class TensorDK, */ class TensorDV,
    class Fusion
>
void __global__ fmha_bwd_reference_dV_kernel(
    ProblemShape problem_shape_in,
    TensorQ mQ_in, TensorK mK_in, TensorV mV_in,
    TensorO mO_in, TensorLSE mLSE_in, TensorDO mDO_in,
    /* TensorDQ mDQ_in, TensorDK mDK_in, */ TensorDV mDV_in,
    Fusion fusion) {

  using namespace cute;
  using namespace cutlass::fmha::collective;

  using Element = typename TensorO::value_type;
  using ElementAcc = typename TensorLSE::value_type;
  
  extern __shared__ char mS_mem[];
  ElementAcc* mS = reinterpret_cast<ElementAcc*>(mS_mem);

  ElementAcc softmax_scale = 1.0 / sqrt(ElementAcc(size<2>(problem_shape_in)));

  for (int idx_L = blockIdx.y; idx_L < size<4>(problem_shape_in); idx_L += gridDim.y) {
    auto [problem_shape, offset] = apply_variable_length_offset(
        problem_shape_in,
        make_coord(_0{}, _0{}, _0{}, _0{}, idx2crd(idx_L, get<4>(problem_shape_in)))
    );
    // problem_shape = problem_shape_in;
    // offset = repeat_like(problem_shape_in, _0{});
    auto mQ = domain_offset(select<0,2,4>(offset), mQ_in);
    auto mK = domain_offset(select<1,2,4>(offset), mK_in);
    auto mV = domain_offset(select<1,3,4>(offset), mV_in);
    auto mO = domain_offset(select<0,3,4>(offset), mO_in);
    auto mLSE = domain_offset(select<0,4>(offset), mLSE_in);
    auto mDO = domain_offset(select<0,3,4>(offset), mDO_in);
    auto mDV = domain_offset(select<1,3,4>(offset), mDV_in);
    for (int idx_K = blockIdx.x; idx_K < size<1>(problem_shape); idx_K += gridDim.x) {
      for (int idx_Q = threadIdx.x; idx_Q < size<0>(problem_shape); idx_Q += blockDim.x) {
        ElementAcc acc_qk = 0;

        for (int idx_D0 = 0; idx_D0 < size<2>(problem_shape); idx_D0++) {
          ElementAcc rQ = mQ(idx_Q, idx_D0, idx_L);
          ElementAcc rK = mK(idx_K, idx_D0, idx_L);
          acc_qk += rQ * rK;
        }  // for idx_D0

        auto id = make_identity_tensor(make_shape(1, 1));
        auto frag = make_tensor<ElementAcc>(Shape<_1, _1>{});
        frag(0) = acc_qk;
        fusion.apply_mask(frag, make_tensor(id.data() + make_arithmetic_tuple(idx_Q, idx_K), id.layout()), problem_shape);
        acc_qk = frag(0);

        mS[idx_Q] = expf(softmax_scale * acc_qk - mLSE(idx_Q, idx_L));
      }  // for idx_Q

      __syncthreads();

      for (int idx_D = threadIdx.x; idx_D < size<3>(problem_shape); idx_D += blockDim.x) {
        ElementAcc acc = 0;
        for (int idx_Q = 0; idx_Q < size<0>(problem_shape); idx_Q++) {
          ElementAcc rS = static_cast<Element>(mS[idx_Q]);
          ElementAcc rDO = mDO(idx_Q, idx_D, idx_L);
          acc += rS * rDO;
        }
        mDV(idx_K, idx_D, idx_L) = static_cast<typename TensorDV::value_type>(acc);
      }  // for idx_D
    }  // for idx_K
  }  // for idx_L
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template<
    class ProblemShape,
    class TensorQ, class TensorK, class TensorV,
    class TensorO, class TensorLSE, class TensorDO,
    /**/ class TensorDQ, /** / class TensorDK, / ** / class TensorDV, / **/
    class Fusion
>
void fmha_bwd_reference_dQ(
    ProblemShape problem_shape,
    TensorQ mQ, TensorK mK, TensorV mV,
    TensorO mO, TensorLSE mLSE, TensorDO mDO,
    /**/ TensorDQ mDQ, /** / TensorDK mDK, / ** / TensorDV mDV, / **/
    Fusion fusion) {

  using namespace cute;

  dim3 grid(size<0>(mDQ), size<2>(mDQ), 1);
  dim3 block(256);
  int shared_mem = size<0>(mK) * sizeof(typename TensorLSE::value_type);
  fmha_bwd_reference_dQ_kernel<<<grid, block, shared_mem>>>(problem_shape, mQ, mK, mV, mO, mLSE, mDO, mDQ, fusion);
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template<
    class ProblemShape,
    class TensorQ, class TensorK, class TensorV,
    class TensorO, class TensorLSE, class TensorDO,
    /** / class TensorDQ, / **/ class TensorDK, /** / class TensorDV, / **/
    class Fusion
>
void fmha_bwd_reference_dK(
    ProblemShape problem_shape,
    TensorQ mQ, TensorK mK, TensorV mV,
    TensorO mO, TensorLSE mLSE, TensorDO mDO,
    /** / TensorDQ mDQ, / **/ TensorDK mDK, /** / TensorDV mDV, / **/
    Fusion fusion) {

  using namespace cute;

  dim3 grid(size<0>(mDK), size<2>(mDK), 1);
  dim3 block(256);
  int shared_mem = size<0>(mDO) * sizeof(typename TensorLSE::value_type);
  fmha_bwd_reference_dK_kernel<<<grid, block, shared_mem>>>(problem_shape, mQ, mK, mV, mO, mLSE, mDO, mDK, fusion);
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template<
    class ProblemShape,
    class TensorQ, class TensorK, class TensorV,
    class TensorO, class TensorLSE, class TensorDO,
    /** / class TensorDQ, / ** / class TensorDK, / **/ class TensorDV, /**/
    class Fusion
>
void fmha_bwd_reference_dV(
    ProblemShape problem_shape,
    TensorQ mQ, TensorK mK, TensorV mV,
    TensorO mO, TensorLSE mLSE, TensorDO mDO,
    /** / TensorDQ mDQ, / ** / TensorDK mDK, / **/ TensorDV mDV, /**/
    Fusion fusion) {

  using namespace cute;

  dim3 grid(size<0>(mDV), size<2>(mDV), 1);
  dim3 block(256);
  int shared_mem = size<0>(mDO) * sizeof(typename TensorLSE::value_type);
  fmha_bwd_reference_dV_kernel<<<grid, block, shared_mem>>>(problem_shape, mQ, mK, mV, mO, mLSE, mDO, mDV, fusion);
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template<
    class ProblemShape,
    class TensorQ, class TensorK, class TensorV,
    class TensorO, class TensorLSE, class TensorDO,
    class TensorDQ, class TensorDK, class TensorDV,
    class Fusion
>
void fmha_bwd_reference(
    ProblemShape problem_shape,
    TensorQ mQ, TensorK mK, TensorV mV,
    TensorO mO, TensorLSE mLSE, TensorDO mDO,
    TensorDQ mDQ, TensorDK mDK, TensorDV mDV,
    Fusion fusion) {

  fmha_bwd_reference_dQ(problem_shape, mQ, mK, mV, mO, mLSE, mDO, mDQ, fusion);
  fmha_bwd_reference_dK(problem_shape, mQ, mK, mV, mO, mLSE, mDO, mDK, fusion);
  fmha_bwd_reference_dV(problem_shape, mQ, mK, mV, mO, mLSE, mDO, mDV, fusion);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
