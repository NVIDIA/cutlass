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
  \brief Functor performing elementwise operations used by epilogues.
*/

#pragma once

#include <sycl/sycl.hpp>
#include "cutlass/cutlass.h"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_epilogue.hpp"
#include "cutlass/epilogue/collective/detail.hpp"
#include "cutlass/epilogue/fusion/callbacks.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/xe_visitor_softmax.hpp"
#include "cutlass/detail/layout.hpp"

#include "cute/tensor.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class WGTileMNK_,
  class EpilogueTile_,
  class ElementC_,
  class StrideC_,
  class ElementD_,
  class StrideD_,
  class FusionCallbacks_,
  class CopyOpG2R_,
  class CopyOpR2G_
>
class CollectiveEpilogue<
    IntelXeGenericGroup,
    WGTileMNK_,
    EpilogueTile_,
    ElementC_,
    StrideC_,
    ElementD_,
    StrideD_,
    FusionCallbacks_,
    CopyOpG2R_,
    CopyOpR2G_
> : public CollectiveEpilogue<
        IntelXeGeneric,
        WGTileMNK_,
        EpilogueTile_,
        ElementC_,
        cute::remove_pointer_t<StrideC_>,
        ElementD_,
        cute::remove_pointer_t<StrideD_>,
        FusionCallbacks_,
        CopyOpG2R_,
        CopyOpR2G_>
{
public:
  //
  // Type Aliases
  //
  using Base = CollectiveEpilogue<
      IntelXeGeneric,
      WGTileMNK_,
      EpilogueTile_,
      ElementC_,
      cute::remove_pointer_t<StrideC_>,
      ElementD_,
      cute::remove_pointer_t<StrideD_>,
      FusionCallbacks_,
      CopyOpG2R_,
      CopyOpR2G_>;
  using BaseArguments = typename Base::Arguments;
  using BaseParams = typename Base::Params;

  using DispatchPolicy = IntelXeXMX16Group;

  using WGTileMNK = typename Base::WGTileMNK;
  using ElementC = ElementC_;
  using StrideC = StrideC_;
  using InternalStrideC = typename Base::StrideC;
  using ElementD = ElementD_;
  using StrideD = StrideD_;
  using InternalStrideD = typename Base::StrideD;

  using FusionCallbacks = FusionCallbacks_;
  using CopyOpG2R = typename Base::CopyOpG2R;
  using CopyOpR2G = typename Base::CopyOpR2G;
  using NonVoidElementC = typename Base::NonVoidElementC;
  using ThreadEpilogueOp = typename Base::ThreadEpilogueOp;
  using ElementCompute = typename Base::ElementCompute;
  using ElementOutput = typename Base::ElementOutput;
  using GmemTiledCopyC = typename Base::GmemTiledCopyC;
  using GmemTiledCopyD = typename Base::GmemTiledCopyD;
  using SharedStorage = typename Base::SharedStorage;
  using TensorStorage = typename Base::TensorStorage;

  static constexpr int SubgroupSize = Base::SubgroupSize;

  using TensorC = decltype(make_tensor(make_gmem_ptr(static_cast<NonVoidElementC const*>(nullptr)),
                                       Layout<Shape<int,int,int>, InternalStrideC>{}));

  using TensorD = decltype(make_tensor(make_gmem_ptr(static_cast<ElementD*>(nullptr)),
                                       Layout<Shape<int,int,int>, InternalStrideD>{}));

  using EpilogueTensors = cute::tuple<TensorC, TensorD>;

private:
  constexpr static bool is_source_supported      = not is_void_v<ElementC>;
  constexpr static bool is_destination_supported = not is_void_v<ElementD>;

public:

  // Host side epilogue arguments
  struct Arguments {
    typename FusionCallbacks::Arguments thread{};
    ElementC const** ptr_C;
    StrideC dC;
    ElementD** ptr_D;
    StrideD dD;
  };

  using Params = Arguments;

  //
  // Methods
  //

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(
      ProblemShape const& problem_shape,
      Arguments const& args,
      [[maybe_unused]] void* workspace) {
    (void) workspace;
    return args;
  }

  template <class ProblemShape>
  static size_t
  get_workspace_size(ProblemShape const& problem_shape, Arguments const& args) {
    return 0;
  }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const& problem_shape, Arguments const& args, void* workspace, cudaStream_t stream,
    CudaHostAdapter* cuda_adapter = nullptr) {
    return Status::kSuccess;
  }

  template <class ProblemShape>
  static bool
  can_implement(
      ProblemShape problem_shape,
      Arguments const& args) {
    constexpr int copy_alignment_bits = 128;
    constexpr int batch_alignment_bits = 512;

    bool implementable = true;
    bool fusion_implementable = true;

    for (int i = 0; i < problem_shape.groups(); ++i) {
      auto problem_shape_MNKL = append<4>(problem_shape.get_host_problem_shape(i), 1);
      auto [M,N,K,L] = problem_shape_MNKL;

      if constexpr (is_destination_supported) {
        constexpr int min_aligned_elements_D = copy_alignment_bits / sizeof_bits<ElementD>::value;
        implementable &= cutlass::detail::check_alignment<min_aligned_elements_D>(cute::make_shape(M,N,L), InternalStrideD{});
        if (L > 1) {
          constexpr int min_batch_aligned_elements_D = batch_alignment_bits / sizeof_bits<ElementD>::value;
          implementable &= get<2>(InternalStrideD{}) % min_batch_aligned_elements_D == 0;
        }
      }

      if constexpr (is_source_supported) {
        constexpr int min_aligned_elements_C = copy_alignment_bits / sizeof_bits<ElementC>::value;
        implementable &= cutlass::detail::check_alignment<min_aligned_elements_C>(cute::make_shape(M,N,L), InternalStrideC{});
        if (L > 1) {
          constexpr int min_batch_aligned_elements_C = batch_alignment_bits / sizeof_bits<ElementC>::value;
          implementable &= get<2>(InternalStrideC{}) % min_batch_aligned_elements_C == 0;
        }
      }

      fusion_implementable = fusion_implementable && FusionCallbacks::can_implement(problem_shape_MNKL, args.thread);
    }

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for XE 2D copy.\n");
    }

    if (!fusion_implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum requirements for FusionCallbacks.\n");
    }

    return implementable && fusion_implementable;
  }

  CUTLASS_DEVICE static constexpr BaseArguments
  to_base_arguments(Arguments const &args, int idx) {
    return BaseArguments{ args.thread, args.ptr_C[idx], args.dC[idx],
                          args.ptr_D[idx], args.dD[idx]};
  }

};


/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace collective
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
