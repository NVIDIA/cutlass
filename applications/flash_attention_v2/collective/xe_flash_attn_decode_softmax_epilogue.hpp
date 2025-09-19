/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_epilogue.hpp"
#include "cutlass/epilogue/collective/detail.hpp"
#include "cutlass/detail/layout.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace flash_attention {
namespace collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <bool CausalMask_, class DispatchPolicy, class... Args> class FlashDecodeSoftmaxEpilogue {
  static_assert(cutlass::detail::dependent_false<DispatchPolicy>, "Could not find an epilogue specialization.");
};


template <bool CausalMask_, class Element_>
class FlashDecodeSoftmaxEpilogue<CausalMask_, epilogue::IntelXeXMX16, Element_> {
public:

  //
  // Type Aliases
  //
  using DispatchPolicy = epilogue::IntelXeXMX16;
  using Element = Element_;

  static constexpr bool CausalMask = CausalMask_;

  using GmemTiledCopyOut = void;

  // Host side epilogue arguments
  struct Arguments {
    Element const scale;
  };

  // Device side epilogue params
  using Params = Arguments;

  //
  // Methods
  //

  static constexpr Params to_underlying_arguments(Arguments const &args) {
    constexpr double kLog2e = 1.4426950408889634074; // log_2(e) = M_LOG2E
    Element val = args.scale * static_cast<Element>(kLog2e);
    return Params{val};
  }

  template <class ProblemShape>
  static size_t get_workspace_size() {
    return 0;
  }

  template <class ProblemShape>
  static cutlass::Status initialize_workspace() {
    return Status::kSuccess;
  }

  template <class ProblemShape>
  CUTLASS_HOST_DEVICE static bool can_implement() {
    return true;
  }

  CUTLASS_HOST_DEVICE
  FlashDecodeSoftmaxEpilogue(Params const &params_) : params(params_) {}

  template <int FragsN, class FragAcc, class FragMax, class FragSum>
  CUTLASS_DEVICE void scale_exp_log2(FragAcc &frag_s, FragMax const &max, FragSum &sum) {
    auto sg = compat::get_nd_item<1>().get_sub_group();
    const auto max_scale = max * params.scale;
      const auto max_scale_bcast = group_broadcast(sg, max_scale, 0);
      CUTLASS_PRAGMA_UNROLL
      for (int z = 0; z < FragsN; z++) {
        Element eq = frag_s(z) - max_scale_bcast;
        frag_s(z) = sycl::native::exp2(eq);
        sum += frag_s(z);
      }
  }

  template <int Num_SGs, int FragsN, class FragSrc, class STensorMax>
  CUTLASS_DEVICE void reduce_max(FragSrc &src, STensorMax &stensor_max, Element& max_val) {
    auto sg = compat::get_nd_item<1>().get_sub_group();
    auto group = compat::get_nd_item<1>().get_group();
    const int sg_group_id = sg.get_group_id()[0];
    const int sg_local_id = sg.get_local_id()[0];

      auto curr_max = group_broadcast(sg, max_val, 0);
      CUTLASS_PRAGMA_UNROLL
      for (int z = 0; z < FragsN; z++) {
        curr_max = sycl::max(curr_max, src(z));
        src(z) *= params.scale;
      }

      curr_max = reduce_over_group(sg, curr_max, sycl::maximum<>());

      if(sg_local_id == 0) {
        stensor_max(sg_group_id) = curr_max;
      }

    sycl::group_barrier(group);
    if(sg_local_id == 0) {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < Num_SGs; i++) {
        curr_max = sycl::max(curr_max, stensor_max(i));
      }
      max_val = curr_max;
    }
  }

  template <int Num_SGs, class FragAcc, class FragSum, class STensorMax, class FragOut>
  CUTLASS_DEVICE void operator()(bool is_first, FragAcc &frag_s, Element& max_val, FragSum& sum, 
                                  STensorMax& shmem_tensor_max, FragOut& out) {
    using FragAccLayout = typename FragAcc::layout_type;
    using FragOutLayout = typename FragOut::layout_type;
    constexpr int Vec = get<0>(FragAccLayout{}.shape());
    constexpr int FragsM = get<1>(FragAccLayout{}.shape());
    constexpr int FragsNS = get<2>(FragAccLayout{}.shape());
    constexpr int FragsNOut = size(select<2,3>(FragOutLayout{}.shape()));
    Element max_prev = max_val;
    static_assert(Vec * FragsM == 1, "No. of attention rows per subgroup should not exceed 1 MMA Atom worth of rows.");

    reduce_max<Num_SGs,FragsNS>(frag_s, shmem_tensor_max, max_val);

    if (!is_first) {
      auto sg = compat::get_nd_item<1>().get_sub_group();
      const int sg_group_id = sg.get_group_id()[0];
      const int sg_local_id = sg.get_local_id()[0];
      const int sg_size = sg.get_local_range()[0];

      Element max_scale{max_val * params.scale};
      Element exp_scale{sycl::native::exp2(max_prev * params.scale - max_scale)};

        auto max_scale_bcast = group_broadcast(sg, max_scale, 0);
        auto exp_scale_bcast = group_broadcast(sg, exp_scale, 0);
        sum *= exp_scale_bcast;
        CUTLASS_PRAGMA_UNROLL
        for (int z = 0; z < FragsNS; z++) {
          frag_s(z) = sycl::native::exp2((frag_s(z) - max_scale_bcast));
          sum += frag_s(z);
        }
        CUTLASS_PRAGMA_UNROLL
        for(int out_idx = 0; out_idx < FragsNOut; out_idx++) {
          out(out_idx) *= exp_scale_bcast;
        }
    } else {
      scale_exp_log2<FragsNS>(frag_s, max_val, sum);
    }
  }

  Params params;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace collective
} // namespace flash_attention
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
