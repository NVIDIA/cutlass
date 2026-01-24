/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

// training or inference phase (not used yet)
// PHASE 0 : training
// PHASE 1 : inference
#define PHASE 0

/////////////////////////////////////////////////////////////////////////////////////////////////

template<
  bool transA,
  bool transB,
  class Element,
  class TensorA,
  class TensorB,
  class TensorC
>
void mma(TensorA tA, TensorB tB, TensorC tC) {
  using namespace cute;

  int M = transA ? int(shape<1>(tA)) : int(shape<0>(tA));
  int N = transB ? int(shape<1>(tB)) : int(shape<0>(tB));
  int K = transA ? int(shape<0>(tA)) : int(shape<1>(tA));
  for (int mi = 0; mi < M; ++mi) {
    for (int ni = 0; ni < N; ++ni) {
      for (int ki = 0; ki < K; ++ki) {
        float a = static_cast<float>(Element(transA ? tA(ki, mi) : tA(mi, ki)));
        float b = static_cast<float>(Element(transB ? tB(ki, ni) : tB(ni, ki)));
        tC(mi, ni) += a * b;
      }
    }
  }

}

template<
  class Element,
  class Tensor
>
auto segsum(Tensor tensor) {
  using namespace cute;
  auto C = shape<0>(tensor);
  auto L = shape<1>(tensor);
  auto cum_sum = make_tensor<float>(make_shape(C,L));
  // cum_sum
  for (int ci = 0; ci < C; ++ci) {
    for (int li = 0; li < L; ++li) {
      if (li == 0) {
        cum_sum(ci, li) = tensor(ci, li);
      }
      else {
        cum_sum(ci, li) = cum_sum(ci, li - 1) + tensor(ci, li);
      }
    }
  }
  auto seg_sum_out = make_tensor<float>(make_shape(C, L, L));
  // seg_sum
  // [      1,   0, 0]
  // [    e^y,   1, 0]
  // [e^(y+z), e^z, 1]
  CUTLASS_PRAGMA_UNROLL
  for (int ci = 0; ci < C; ++ci) {
    for (int i = 0; i < L; ++i) {
      for (int j = 0; j < L; ++j) {
        if (j < i) {
          float tmp = static_cast<float>(cum_sum(ci, i)) - static_cast<float>(cum_sum(ci, j));
          seg_sum_out(ci, i, j) = expf(tmp);
        } 
        else if (j == i) {
          seg_sum_out(ci, i, j) = 1.f;
        }
        else {
          seg_sum_out(ci, i, j) = 0.f;
        }
      }
    }
  }

  return seg_sum_out;
}

template<
  class Element,
  class Tensor
>
auto cumsum(Tensor tensor) {
  using namespace cute;
  auto C = shape<0>(tensor);
  auto L = shape<1>(tensor);
  auto cum_sum              = make_tensor<float>(make_shape(C,L));
  auto cum_sum_out          = make_tensor<Element>(make_shape(C,L));
  auto cum_sum_exp_out      = make_tensor<float>(make_shape(C, L));
  auto cum_sum_exp_out_last = make_tensor<float>(make_shape(C, L));
  auto last_column          = make_tensor<float>(make_shape(C));
  // [x, x+y, x+y+z, ..]
  CUTLASS_PRAGMA_UNROLL
  for (int ci = 0; ci < C; ++ci) {
    for (int li = 0; li < L; ++li) {
      if (li == 0) {
        cum_sum(ci, li) = tensor(ci, li);
      }
      else {
        cum_sum(ci, li) = cum_sum(ci, li - 1) + tensor(ci, li);
      }
      // cum_sum_out(ci, li) = static_cast<Element>(cum_sum(ci, li));
    }
  }
  CUTLASS_PRAGMA_UNROLL
  for (int ci = 0; ci < C; ++ci) {
    last_column(ci) = static_cast<float>(cum_sum(ci, L-1));
    CUTLASS_PRAGMA_UNROLL
    for (int li = 0; li < L; ++li) {
      cum_sum_exp_out_last(ci, li) = expf(static_cast<float>(last_column(ci) - cum_sum(ci, li)));
      cum_sum_exp_out(ci, li) = expf(static_cast<float>(cum_sum(ci, li)));
    }
  }

  return make_tuple(cum_sum_exp_out_last, last_column, cum_sum_exp_out);
}

template<
  bool  HAS_D,
  bool  D_HAS_HDIM,
  bool  HAS_Z,
  class TensorY,
  class TensorF,
  class TensorX,
  class TensorDelta,
  class TensorDeltaA,
  class TensorB,
  class TensorC,
  class TensorD,
  class TensorZ,
  class Params
>
void ssd_reference_impl(
    TensorY mY, TensorF mF,
    TensorX mX, TensorDelta mDelta, TensorDeltaA mDeltaA,
    TensorB mB, TensorC mC, TensorD mD, TensorZ mZ,
    Params params) {

  using namespace cute;
  using Element = typename Params::Element;
  using ElementAcc = typename Params::ElementAcc;

  // x       [b, eh, d, c, l]
  // delta   [b, eh, c, l]
  // delta_A [b, eh, c, l]
  // B       [b,  g, n, c, l]
  // C       [b,  g, n, c, l]
  // y       [b, eh, d, c, l]
  // fstate  [b, eh, d, n]
  // d       [   eh, d]
  auto [G, B, EH, C, L, D, N] = params.get_problem_shape();
  int group_ratio = EH / G;
  for (int b = 0; b < B; ++b) {
    for (int eh = 0; eh < EH; ++eh) {
      int g = eh / group_ratio;
      auto tY      = mY(b,eh,_,_,_);
      auto tF      = mF(b,eh,_,_);
      auto tX      = mX(b,eh,_,_,_);
      auto tDelta  = mDelta(b,eh,_,_);
      auto tDeltaA = mDeltaA(b,eh,_,_);
      auto tB      = mB(b,g,_,_,_);
      auto tC      = mC(b,g,_,_,_);
      auto tD      = mD(eh,_);
      auto tZ      = mZ(b,eh,_,_,_);
      // IntraBMM1 BxC, LxLxN, NT
      // B: [n, c, l]
      // C: [n, c, l]
      // O: [c, l, l]
      auto tIntraBMM1_out = make_tensor<float>(make_shape(C,L,L));
      for (int ci = 0; ci < C; ++ci) {
        mma<true,true,Element>(tC(_,ci,_), tB(_,ci,_), tIntraBMM1_out(ci,_,_)); 
      }
      // Pre_IntraBMM2 DeltaA_IntraBMM2 x Delta x IntraBMM_out
      // DeltaA_xxx   : [c, l, l]
      // Delta        : [c, l, _]
      // IntraBMM1_out: [c, l, l]
      auto tDeltaA_IntraBMM2 = segsum<Element>(tDeltaA);
      auto tIntraBMM2_inp    = make_tensor<float>(make_shape(C, L, L));
      for (int ci = 0; ci < C; ++ci) {
        for (int i = 0; i < L; ++i) {
          for (int j = 0; j < L; ++j) {
            tIntraBMM2_inp(ci, i, j) = tDeltaA_IntraBMM2(ci, i, j) * tDelta(ci, j) * tIntraBMM1_out(ci, i, j);
          }
        }
      }
      // IntraBMM2 IntraBMM2_inp x X, LxDxL, TT
      // IntraBMM2_inp: [c, l, l]
      // X            : [d, c, l]
      // IntraBMM2_out: [c, l, d]
      auto tIntraBMM2_out = make_tensor<float>(make_shape(C,L,D));
      for (int ci = 0; ci < C; ++ci) {
        mma<false,false,Element>(tIntraBMM2_inp(ci,_,_), tX(_,ci,_), tIntraBMM2_out(ci,_,_)); 
      }
      // Pre_InterBMM1 DeltaA_InterBMM1 x Delta x B
      // DeltaA_xxx   : [c, l]
      // Delta        : [c, l]
      // IntraBMM1_out: [c, n, l]
      auto [tDeltaA_InterBMM1, tLast, tCumsum_exp] = cumsum<Element>(tDeltaA); 
      auto tInterBMM1_inp    = make_tensor<float>(make_shape(C, N, L));
      for (int ci = 0; ci < C; ++ci) {
        for (int i = 0; i < N; ++i) {
          for (int j = 0; j < L; ++j) {
            tInterBMM1_inp(ci, i, j) = tDeltaA_InterBMM1(ci, j) * tDelta(ci, j) * tB(i, ci, j);
          }
        }
      }
      // InterBMM1 InterBMM1_inp x X, NxDxL, swapAB, TT
      // InterBMM1_inp: [c, n, l]
      // X            : [d, c, l]
      // InterBMM1_out: [c, n, d]
      auto tInterBMM1_out = make_tensor<float>(make_shape(C,N,D));
      for (int ci = 0; ci < C; ++ci) {
        mma<false,false,Element>(tInterBMM1_inp(ci,_,_), tX(_,ci,_), tInterBMM1_out(ci,_,_));
      }
      // Initialize state
      // PreInterBMM2 
      // InterBMM1_out: [c, n, d]
      // Last         : [c] 
      auto tInterBMM2_inp      = make_tensor<float>(make_shape(C, N, D));
      for (int ci = 0; ci < C; ++ci) {
        for (int ni = 0; ni < N; ++ ni){
          for (int di = 0; di < D; ++di) {
            if (ci == 0) {
              tInterBMM2_inp(ci, ni, di) = 0;
            }
            else {
              tInterBMM2_inp(ci, ni, di) = tInterBMM1_out(ci - 1, ni, di) + expf(tLast(ci - 1)) * tInterBMM2_inp(ci - 1, ni, di);
            }
          }
        }
      }
      // InterBMM2 InterBMM2_inp x C, LxDxN, NT
      // C            : [n, c, l]
      // InterBMM2_inp: [c, n, d]
      // InterBMM2_out: [c, l, d]
      auto tInterBMM2_out = make_tensor<float>(make_shape(C,L,D));
      for (int ci = 0; ci < C; ++ci) {
        mma<true,true,Element>(tC(_,ci,_), tInterBMM2_inp(ci,_,_), tInterBMM2_out(ci,_,_));
      }
      // Epilogue Cumsum_exp x InterBMM2_out + IntraBMM2_out
      // InterBMM2_out: [c, l, d]
      // IntraBMM2_out: [c, l, d]
      // Cumsum_exp   : [c, l]
      for (int ci = 0; ci < C; ++ci) {
        for (int li = 0; li < L; ++li) {
          for (int di = 0; di < D; ++di) {
            float y = tInterBMM2_out(ci, li, di) * tCumsum_exp(ci, li) + tIntraBMM2_out(ci, li, di);
            float scale;
            if constexpr (D_HAS_HDIM) {
              scale = static_cast<float>(tD(di));
            }
            else {
              scale = static_cast<float>(tD(_0{}));
            }
            if constexpr (HAS_D) {
              y = y + static_cast<float>(tX(di, ci, li)) * scale;
            }
            else {
              y = y;
            }
            if constexpr (HAS_Z) {
              float z = static_cast<float>(tZ(di, ci, li));
              // y = y * z * (1 / (1 + exp(-z)));
              y = y * z * (1 / (1 + exp(-z)));
            }
            tY(di, ci, li) = static_cast<typename Params::Element>(y);
          }
        }
      }
      // Epilogue Fstate(last C)
      for (int ni = 0; ni < N; ++ ni){
        for (int di = 0; di < D; ++di) {
          tF(di, ni) = static_cast<typename Params::Element>(tInterBMM1_out(C - 1, ni, di) + expf(tLast(C - 1)) * tInterBMM2_inp(C - 1, ni, di));
        }
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template<
  bool  HAS_D,
  bool  D_HAS_HDIM,
  bool  HAS_Z,
  class TensorY,
  class TensorF,
  class TensorX,
  class TensorDelta,
  class TensorDeltaA,
  class TensorB,
  class TensorC,
  class TensorD,
  class TensorZ,
  class Params
>
void ssd_reference(
    TensorY mY, TensorF mF,
    TensorX mX, TensorDelta mDelta, TensorDeltaA mDeltaA,
    TensorB mB, TensorC mC, TensorD mD, TensorZ mZ,
    Params params) {
  ssd_reference_impl<HAS_D, D_HAS_HDIM, HAS_Z>(mY, mF, mX, mDelta, mDeltaA, mB, mC, mD, mZ, params);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
