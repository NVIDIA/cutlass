/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 *modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *this list of conditions and the following disclaimer in the documentation
 *and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *may be used to endorse or promote products derived from this software without
 *specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 *FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **************************************************************************************************/

/*! \file
    \brief GemmUniversal specialization for the SM120/SM121 NVFP4 W4A16
   collective.
*/

#pragma once

#include "cute/tensor.hpp"

#include "cutlass/arch/arch.h"
#include "cutlass/cuda_host_adapter.hpp"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/collective/sm120_mma_cp_async_nvfp4_w4a16.hpp"
#include "cutlass/gemm/gemm.h"

#include <cstdint>

namespace cutlass::gemm::kernel {

template <class ProblemShape_, class CollectiveMainloop_,
          class CollectiveEpilogue_, class TileScheduler_>
class GemmUniversal<
    ProblemShape_, CollectiveMainloop_, CollectiveEpilogue_, TileScheduler_,
    cute::enable_if_t<
        cute::is_same_v<typename CollectiveMainloop_::DispatchPolicy::Schedule,
                        cutlass::gemm::KernelCpAsyncNvfp4W4A16Sm120>>> {
public:
  using ProblemShape = ProblemShape_;
  static_assert(cute::rank(ProblemShape{}) == 3 ||
                    cute::rank(ProblemShape{}) == 4,
                "ProblemShape must be MNK or MNKL");
  static_assert(
      cute::is_void_v<TileScheduler_>,
      "The SM120 W4A16 kernel uses a fixed one-CTA-per-output-tile mapping");

  using CollectiveMainloop = CollectiveMainloop_;
  using CollectiveEpilogue = CollectiveEpilogue_;
  using TileShape = typename CollectiveMainloop::TileShape;
  using TiledMma = typename CollectiveMainloop::TiledMma;
  using DispatchPolicy = typename CollectiveMainloop::DispatchPolicy;
  using ArchTag = typename CollectiveMainloop::ArchTag;
  using ElementA = typename CollectiveMainloop::ElementA;
  using StrideA = typename CollectiveMainloop::StrideA;
  using ElementB = typename CollectiveMainloop::ElementB;
  using StrideB = typename CollectiveMainloop::StrideB;
  using ElementAccumulator = typename CollectiveMainloop::ElementAccumulator;
  using ElementC = typename CollectiveEpilogue::ElementC;
  using StrideC = typename CollectiveEpilogue::StrideC;
  using ElementD = typename CollectiveEpilogue::ElementD;
  using StrideD = typename CollectiveEpilogue::StrideD;
  using MainloopArguments = typename CollectiveMainloop::Arguments;
  using MainloopParams = typename CollectiveMainloop::Params;
  using EpilogueArguments = typename CollectiveEpilogue::Arguments;
  using EpilogueParams = typename CollectiveEpilogue::Params;

  static_assert(
      cute::is_same_v<ElementAccumulator,
                      typename CollectiveEpilogue::ElementAccumulator>,
      "Mainloop and epilogue accumulator types must match");

  static constexpr int MaxThreadsPerBlock = cute::size(TiledMma{});
  static constexpr int MinBlocksPerMultiprocessor = 1;
  static constexpr bool IsGdcEnabled = false;

  struct Arguments {
    cutlass::gemm::GemmUniversalMode mode{};
    ProblemShape problem_shape{};
    MainloopArguments mainloop{};
    EpilogueArguments epilogue{};
    cutlass::KernelHardwareInfo hw_info{};
  };

  struct Params {
    cutlass::gemm::GemmUniversalMode mode{};
    ProblemShape problem_shape{};
    MainloopParams mainloop{};
    EpilogueParams epilogue{};
  };

  union SharedStorage {
    typename CollectiveMainloop::SharedStorage mainloop;
    typename CollectiveEpilogue::SharedStorage epilogue;
  };

  static constexpr int SharedStorageSize = sizeof(SharedStorage);

  static Params to_underlying_arguments(Arguments const &args,
                                        void *workspace) {
    size_t const epilogue_workspace_size =
        CollectiveEpilogue::get_workspace_size(args.problem_shape,
                                               args.epilogue);
    void *const mainloop_workspace =
        workspace == nullptr
            ? nullptr
            : static_cast<void *>(static_cast<uint8_t *>(workspace) +
                                  epilogue_workspace_size);
    return Params{args.mode, args.problem_shape,
                  CollectiveMainloop::to_underlying_arguments(
                      args.problem_shape, args.mainloop, mainloop_workspace),
                  CollectiveEpilogue::to_underlying_arguments(
                      args.problem_shape, args.epilogue, workspace)};
  }

  static bool can_implement(Arguments const &args) {
    return args.mode == cutlass::gemm::GemmUniversalMode::kGemm &&
           CollectiveMainloop::can_implement(args.problem_shape,
                                             args.mainloop) &&
           CollectiveEpilogue::can_implement(args.problem_shape, args.epilogue);
  }

  static size_t get_workspace_size(Arguments const &args) {
    return CollectiveEpilogue::get_workspace_size(args.problem_shape,
                                                  args.epilogue) +
           CollectiveMainloop::get_workspace_size(args.problem_shape,
                                                  args.mainloop);
  }

  static cutlass::Status
  initialize_workspace(Arguments const &args, void *workspace = nullptr,
                       cudaStream_t stream = nullptr,
                       cutlass::CudaHostAdapter *cuda_adapter = nullptr) {
    cutlass::Status status = CollectiveEpilogue::initialize_workspace(
        args.problem_shape, args.epilogue, workspace, stream, cuda_adapter);
    if (status != cutlass::Status::kSuccess) {
      return status;
    }
    size_t const epilogue_workspace_size =
        CollectiveEpilogue::get_workspace_size(args.problem_shape,
                                               args.epilogue);
    void *const mainloop_workspace =
        workspace == nullptr
            ? nullptr
            : static_cast<void *>(static_cast<uint8_t *>(workspace) +
                                  epilogue_workspace_size);
    return CollectiveMainloop::initialize_workspace(
        args.problem_shape, args.mainloop, mainloop_workspace, stream,
        cuda_adapter);
  }

  static dim3 get_grid_shape(Params const &params) {
    auto problem_shape_mnkl = cute::append<4>(params.problem_shape, cute::_1{});
    return dim3(static_cast<unsigned int>(cute::size<1>(problem_shape_mnkl) /
                                          cute::size<1>(TileShape{})),
                static_cast<unsigned int>(cute::size<0>(problem_shape_mnkl) /
                                          cute::size<0>(TileShape{})),
                static_cast<unsigned int>(cute::size<3>(problem_shape_mnkl)));
  }

  static dim3 get_block_shape() { return dim3(MaxThreadsPerBlock, 1, 1); }

  CUTLASS_DEVICE
  void operator()(Params const &params, char *shared_storage) const {
    auto problem_shape_mnkl = cute::append<4>(params.problem_shape, cute::_1{});
    auto [m, n, k, l] = problem_shape_mnkl;
    auto &storage = *reinterpret_cast<SharedStorage *>(shared_storage);
    int const row_base =
        static_cast<int>(blockIdx.y) * cute::size<0>(TileShape{});
    int const column_base =
        static_cast<int>(blockIdx.x) * cute::size<1>(TileShape{});
    int const tile_count = static_cast<int>(k / cute::size<2>(TileShape{}));

    TiledMma tiled_mma;
    auto accumulators =
        cute::partition_fragment_C(tiled_mma, cute::take<0, 2>(TileShape{}));
    cute::clear(accumulators);

    CollectiveMainloop collective_mma;
    collective_mma(params.mainloop, storage.mainloop, accumulators, row_base,
                   column_base, tile_count);

    auto block_coord_mnkl = cute::make_coord(
        static_cast<int>(blockIdx.y), static_cast<int>(blockIdx.x), cute::_,
        static_cast<int>(blockIdx.z));
    auto residue_mnk =
        cute::make_tuple(m - row_base, n - column_base,
                         k - tile_count * cute::size<2>(TileShape{}));
    CollectiveEpilogue epilogue{params.epilogue};
    epilogue(problem_shape_mnkl, TileShape{}, block_coord_mnkl, accumulators,
             tiled_mma, residue_mnk, static_cast<int>(threadIdx.x),
             shared_storage);
  }
};

} // namespace cutlass::gemm::kernel
