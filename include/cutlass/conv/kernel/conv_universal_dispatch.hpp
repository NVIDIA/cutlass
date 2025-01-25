/***************************************************************************************************
 * Copyright (c) 2024 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/conv/kernel/conv_universal.hpp"
#include "cutlass/gemm/kernel/tile_scheduler.hpp"
#include "cutlass/fast_math.h"
#include "cutlass/workspace.h"

#include <cute/util/type_traits.hpp>
#include <cute/int_tuple.hpp>

////////////////////////////////////////////////////////////////////////////////

namespace cutlass::conv::kernel {

////////////////////////////////////////////////////////////////////////////////

enum class DispatchMode {
  VoidC // Select between voidC and non-voidC kernel based on beta scaling
};

// Dispatch between two ConvUniversal kernels
template <DispatchMode Mode, class KernelA, class KernelB, class = void>
class ConvUniversalDispatch;

////////////////////////////////////////////////////////////////////////////////

template <
  class ProblemShape_,
  class MainloopWithC_, class EpilogueWithC_,
  class MainloopVoidC_, class EpilogueVoidC_,
  class TileScheduler_
>
class ConvUniversalDispatch<
  DispatchMode::VoidC,
  ConvUniversal<ProblemShape_, MainloopWithC_, EpilogueWithC_, TileScheduler_>,
  ConvUniversal<ProblemShape_, MainloopVoidC_, EpilogueVoidC_, TileScheduler_>,
  cute::void_t<decltype(typename EpilogueWithC_::Arguments{}.thread.dBeta),
               decltype(typename EpilogueVoidC_::Arguments{}.thread.dBeta)>
> : public ConvUniversal<ProblemShape_, MainloopWithC_, EpilogueWithC_, TileScheduler_> {
private:
  using KernelWithC = ConvUniversal<ProblemShape_, MainloopWithC_, EpilogueWithC_, TileScheduler_>;
  using KernelVoidC = ConvUniversal<ProblemShape_, MainloopVoidC_, EpilogueVoidC_, TileScheduler_>;
  using FusionArguments = cute::remove_cvref_t<decltype(typename EpilogueWithC_::Arguments{}.thread)>;

public:
  // Mainloop derived types
  static_assert(cute::is_same_v<typename KernelWithC::TileShape, typename KernelVoidC::TileShape>);
  static_assert(cute::is_same_v<typename KernelWithC::TiledMma, typename KernelVoidC::TiledMma>);
  static_assert(cute::is_same_v<typename KernelWithC::ArchTag, typename KernelVoidC::ArchTag>);
  static_assert(cute::is_same_v<typename KernelWithC::ElementA, typename KernelVoidC::ElementA>);
  static_assert(cute::is_same_v<typename KernelWithC::StrideA, typename KernelVoidC::StrideA>);
  static_assert(cute::is_same_v<typename KernelWithC::ElementB, typename KernelVoidC::ElementB>);
  static_assert(cute::is_same_v<typename KernelWithC::StrideB, typename KernelVoidC::StrideB>);
  static_assert(cute::is_same_v<typename KernelWithC::ElementAccumulator, typename KernelVoidC::ElementAccumulator>);
  static_assert(cute::is_same_v<typename KernelWithC::ClusterShape, typename KernelVoidC::ClusterShape>);

  // Epilogue derived types
  static_assert(not cute::is_void_v<typename KernelWithC::ElementC>);
  static_assert(    cute::is_void_v<typename KernelVoidC::ElementC>);
  static_assert(cute::is_same_v<typename KernelWithC::StrideC, typename KernelVoidC::StrideC>);
  static_assert(cute::is_same_v<typename KernelWithC::ElementD, typename KernelVoidC::ElementD>);
  static_assert(cute::is_same_v<typename KernelWithC::StrideD, typename KernelVoidC::StrideD>);

  // TileID scheduler
  static_assert(cute::is_same_v<typename KernelWithC::TileScheduler, typename KernelVoidC::TileScheduler>);

  static constexpr int SharedStorageSize = cute::max(KernelWithC::SharedStorageSize, KernelVoidC::SharedStorageSize);

  static_assert(KernelWithC::MaxThreadsPerBlock == KernelVoidC::MaxThreadsPerBlock);

  static_assert(KernelWithC::MinBlocksPerMultiprocessor == KernelVoidC::MinBlocksPerMultiprocessor);

  using Arguments = typename KernelWithC::Arguments;

  struct Params {
    typename KernelWithC::Params withC;
    typename KernelVoidC::Params voidC;

    void const* ptr_C;
    decltype(FusionArguments{}.beta) beta;
    decltype(FusionArguments{}.beta_ptr) beta_ptr;
    decltype(FusionArguments{}.dBeta) dBeta;
    cutlass::KernelHardwareInfo hw_info{};
  };

  static size_t
  get_workspace_size(Arguments const& args) {
    return KernelWithC::get_workspace_size(args);
  }

  static cutlass::Status
  initialize_workspace(Arguments const& args, void* workspace = nullptr, cudaStream_t stream = nullptr, CudaHostAdapter* cuda_adapter = nullptr) {
    return KernelWithC::initialize_workspace(args, workspace, stream, cuda_adapter);
  }

  static Params
  to_underlying_arguments(Arguments const& args, void* workspace) {
    return {
      KernelWithC::to_underlying_arguments(args, workspace),
      KernelVoidC::to_underlying_arguments(reinterpret_cast<typename KernelVoidC::Arguments const&>(args), workspace),
      args.epilogue.ptr_C,
      args.epilogue.thread.beta,
      args.epilogue.thread.beta_ptr,
      args.epilogue.thread.dBeta,
      args.hw_info
    };
  }

  static dim3
  get_grid_shape(Params const& params) {
    return KernelWithC::get_grid_shape(params.withC);
  }

  CUTLASS_DEVICE
  void
  operator()(Params const& params, char* smem_buf) {
    using namespace cute;

    bool run_voidC = false;
    if (params.ptr_C == nullptr) {
      run_voidC = true;
    }
    else if (params.beta_ptr == nullptr) { // Host scalar beta
      run_voidC = params.beta == 0;
    }
    else if (get<0>(params.dBeta) == 0 && get<1>(params.dBeta) == 0) { // Device scalar beta
      auto L = get<3>(append<4>(params.withC.problem_shape, _1{}));
      if (get<2>(params.dBeta) == repeat_like(L, 0) || size(L) == 1) { // Non-batched
        run_voidC = *params.beta_ptr == 0;
      }
    }

    if (run_voidC) {
      return kernel_voidC(params.voidC, smem_buf);
    }
    else {
      return KernelWithC::operator()(params.withC, smem_buf);
    }
  }

private:
  KernelVoidC kernel_voidC;

};

////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::conv::kernel

////////////////////////////////////////////////////////////////////////////////
