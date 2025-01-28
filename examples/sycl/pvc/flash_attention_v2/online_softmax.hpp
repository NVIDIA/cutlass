/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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
  \brief Functor performing online softmax.
*/

#pragma once

#include <sycl/sycl.hpp>
#include "cutlass/cutlass.h"

#ifdef __SYCL_DEVICE_ONLY__
#define SYCL_DEVICE_OCL_FMA(x, y) SYCL_EXTERNAL x
#else
#define SYCL_DEVICE_OCL_FMA(x, y) \
  inline x                        \
  {                               \
    assert(false);                \
    return (y)0;                  \
  }
#endif

#define EXP sycl::native::exp
#define DIV sycl::native::divide
// TODO:: Temporary using OpenCL function as sycl_reduce_over_group spills on sycl::maximum<>() operation
SYCL_DEVICE_OCL_FMA(float sub_group_reduce_add(float i), float);
SYCL_DEVICE_OCL_FMA(float sub_group_reduce_max(float i), float);

#undef SYCL_DEVICE_OCL_FMA

namespace flash
{

  template <typename T>
  struct MaxOp
  {
    CUTLASS_DEVICE T
    operator()(T const &x, T const &y) { return sycl::max(x, y); }
  };


  template <typename Element>
  struct Softmax
  {
    struct Arguments
    {
      Element scale;
    };

    using Params = Arguments;

    static constexpr Params
    to_underlying_arguments(Arguments const &args)
    {
      Arguments x{static_cast<Element>(args.scale) * static_cast<Element>(M_LOG2E)};
      return x;
    }

    template <
        bool CausalMask,
        int Vec,
        int FragsM,
        int FragsN,
        class FragAcc,
        class FragMax>
    CUTLASS_DEVICE static constexpr void scale_exp_log2(FragAcc &acc, FragMax const max, Element const scale)
    {
      CUTLASS_PRAGMA_UNROLL
      for (int x = 0; x < Vec; x++)
      { 
        CUTLASS_PRAGMA_UNROLL
        for (int y = 0; y < FragsM; y++)
        { 
          Element max_scaled = max(x, y) * scale;
          if (CausalMask && max(x, y) == -INFINITY)
          {
            max_scaled = 0.f;
          }

          CUTLASS_PRAGMA_UNROLL
          for (int z = 0; z < FragsN; z += 2)
          { 
            Element eq0 = (acc(x, y, z) * scale - max_scaled);
            Element eq1 = (acc(x, y, z + 1) * scale - max_scaled);
            acc(x, y, z) = sycl::native::exp2(eq0);
            acc(x, y, z + 1) = sycl::native::exp2(eq1);
          }
        }
      }
    }

    template <
        int Vec,
        int FragsM,
        int FragsN,
        class FragSrc,
        class FragDst,
        class Op>
    CUTLASS_DEVICE static void workitem_reduce(FragSrc const &src, FragDst &dst, Op op)
    {
      CUTLASS_PRAGMA_UNROLL
      for (int x = 0; x < Vec; x++)
      {
        CUTLASS_PRAGMA_UNROLL
        for (int y = 0; y < FragsM; y++)
        {
          dst(x, y) = op(dst(x, y), src(x, y, 0));
          CUTLASS_PRAGMA_UNROLL
          for (int z = 1; z < FragsN; z++)
          {
            dst(x, y) = op(dst(x, y), src(x, y, z));
          }
        }
      }
    }

    template <
        int Vec,
        int FragsM,
        int FragsN,
        class FragDst,
        class Op>
      // reduce across the sub_group to get the final output
    CUTLASS_DEVICE static void subgroup_allreduce(FragDst &dst, Op op)
    {
      CUTLASS_PRAGMA_UNROLL
      for (int x = 0; x < Vec; x++)
      {
        CUTLASS_PRAGMA_UNROLL
        for (int y = 0; y < FragsM; y++)
        {
          dst(x, y) = std::is_same_v<Op, MaxOp<Element>> ? sub_group_reduce_max(dst(x, y)):sub_group_reduce_add(dst(x, y));
        }
      }
    }

    template <
        bool CausalMask,
        int Vec,
        int FragsM,
        int FragsN,
        class FragAcc,
        class FragMax,
        class FragSum,
        class FragOut>
    CUTLASS_DEVICE static void run(bool is_first, FragAcc &frag_s, FragMax &max, FragSum &sum, FragOut &out, Params const &params)
    {
      cute::Tensor max_prev = cute::make_fragment_like(max);
      cute::copy(max, max_prev);
      //TODO:: temporarily using MaxOp as sycl::maxium<Element>() cause spilling
      workitem_reduce<Vec, FragsM, FragsN>(frag_s, max, MaxOp<Element>());
      subgroup_allreduce<Vec, FragsM, FragsN>(max, MaxOp<Element>());
      if(!is_first)
      {
        CUTLASS_PRAGMA_UNROLL
        for (int x = 0; x < Vec; x++) 
        { // TODO:: For now we need to unroll it to get SIMD4 Scheduling for exp operation. This will be removed once we find a fix 
          CUTLASS_PRAGMA_UNROLL
          for (int y = 0; y < FragsM; y += 4 ) 
          {
            Element curr_max_scale0 {(CausalMask && max(x, y    ) == -INFINITY) ? 0.f : max(x, y    ) * params.scale};
            Element curr_max_scale1 {(CausalMask && max(x, y + 1) == -INFINITY) ? 0.f : max(x, y + 1) * params.scale};
            Element curr_max_scale2 {(CausalMask && max(x, y + 2) == -INFINITY) ? 0.f : max(x, y + 2) * params.scale};
            Element curr_max_scale3 { (CausalMask && max(x, y + 3) == -INFINITY)? 0.f : max(x, y + 3) * params.scale};

            const Element eq0 = sycl::mad(max_prev(x, y    ) , params.scale , -curr_max_scale0);
            const Element eq1 = sycl::mad(max_prev(x, y + 1) , params.scale , -curr_max_scale1);
            const Element eq2 = sycl::mad(max_prev(x, y + 2) , params.scale , -curr_max_scale2);
            const Element eq3 = sycl::mad(max_prev(x, y + 3) , params.scale , -curr_max_scale3);
            
            const Element curr_scale0 = sycl::native::exp2(eq0);
            const Element curr_scale1 = sycl::native::exp2(eq1);
            const Element curr_scale2 = sycl::native::exp2(eq2);
            const Element curr_scale3 = sycl::native::exp2(eq3);
          
            sum(x, y    ) *= curr_scale0;
            sum(x, y + 1) *= curr_scale1;
            sum(x, y + 2) *= curr_scale2;
            sum(x, y + 3) *= curr_scale3;
                
            CUTLASS_PRAGMA_UNROLL
            for (int z = 0; z < FragsN; z++)
            {
              out(x, y    , z) *= curr_scale0;
              out(x, y + 1, z) *= curr_scale1;
              out(x, y + 2, z) *= curr_scale2;
              out(x, y + 3, z) *= curr_scale3;
            }
          }
        }
      }
      scale_exp_log2<CausalMask, Vec, FragsM, FragsN>(frag_s, max, params.scale);
      workitem_reduce<Vec, FragsM, FragsN>(frag_s, sum, sycl::plus<Element>());
    }

    Params params;
  };

}
