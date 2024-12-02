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
#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/kernel_hardware_info.hpp"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/dispatch_policy.hpp"

#include "cute/tensor.hpp"

namespace cutlass::gemm::kernel {

///////////////////////////////////////////////////////////////////////////////

template <
  class ProblemShape_,
  class CollectiveMainloop_,
  class CollectiveEpilogue_,
  class TileScheduler_
>
class GemmUniversal<
  ProblemShape_,
  CollectiveMainloop_,
  CollectiveEpilogue_,
  TileScheduler_,
  cute::enable_if_t<cute::is_base_of_v<KernelPVC, typename CollectiveMainloop_::DispatchPolicy::Schedule> 
                    && !cute::is_same_v<TileScheduler_, cutlass::gemm::StreamKScheduler>>>
{
public:
  //
  // Type Aliases
  //
  using ProblemShape = ProblemShape_;

  static_assert(rank(ProblemShape{}) == 3 or rank(ProblemShape{}) == 4,
    "ProblemShape{} should be <M,N,K> or <M,N,K,L>");

  // Mainloop derived types
  using CollectiveMainloop = CollectiveMainloop_;
  using TileShape = typename CollectiveMainloop::WorkgroupTileShape;
  using WorkgroupTileShape = TileShape;
  using TiledMma  = typename CollectiveMainloop::TiledMma;
  using ArchTag   = typename CollectiveMainloop::ArchTag;
  using ElementA  = typename CollectiveMainloop::ElementA;
  using StrideA   = typename CollectiveMainloop::StrideA;
  using ElementB  = typename CollectiveMainloop::ElementB;
  using StrideB   = typename CollectiveMainloop::StrideB;
  using DispatchPolicy = typename CollectiveMainloop::DispatchPolicy;
  using ElementAccumulator = typename CollectiveMainloop::ElementAccumulator;
  using MainloopArguments = typename CollectiveMainloop::Arguments;
  using MainloopParams = typename CollectiveMainloop::Params;

  static_assert(cute::is_void_v<TileScheduler_> or cute::is_same_v<TileScheduler_, PersistentScheduler>,
    "Intel PVC does not support specializing the tile scheduler.");
  using TileSchedulerTag = TileScheduler_;
  using TileScheduler = typename detail::TileSchedulerSelector<
    TileScheduler_, ArchTag, WorkgroupTileShape,
    cute::Shape<cute::Int<1>, cute::Int<1>, cute::Int<1>>>::Scheduler;
  using TileSchedulerArguments = typename TileScheduler::Arguments;

  // Epilogue derived types
  using CollectiveEpilogue = CollectiveEpilogue_;
  using ElementC = typename CollectiveEpilogue::ElementC;
  using StrideC  = typename CollectiveEpilogue::StrideC;
  using ElementD = typename CollectiveEpilogue::ElementD;
  using StrideD  = typename CollectiveEpilogue::StrideD;
  using EpilogueArguments = typename CollectiveEpilogue::Arguments;
  using EpilogueParams = typename CollectiveEpilogue::Params;
  static_assert(cute::is_same_v<ElementAccumulator, typename CollectiveEpilogue::ElementAccumulator>,
    "Mainloop and epilogue do not agree on accumulator value type.");

  // MSVC requires the cast to fix a warning-as-error.
  static constexpr int SharedStorageSize = 0;

  static constexpr int SubgroupSize = CollectiveMainloop::SubgroupSize; // sub_group size
  static constexpr uint32_t MaxThreadsPerBlock = CollectiveMainloop::MaxThreadsPerBlock;
  using MmaAtomShape = typename CollectiveMainloop::MmaAtomShape;
  using SubgroupTileShape = typename CollectiveMainloop::SubgroupTileShape;
  using PrefetchATileSize = typename CollectiveMainloop::PrefetchATileSize;
  using PrefetchBTileSize = typename CollectiveMainloop::PrefetchBTileSize;
  static constexpr int PrefetchStrideA = static_cast<int>(get<1>(PrefetchATileSize{}));
  static constexpr int PrefetchStrideB = static_cast<int>(get<0>(PrefetchBTileSize{}));

  // Kernel level shared memory storage
  struct SharedStorage {
    using EpilogueTensorStorage = typename CollectiveEpilogue::TensorStorage;
    EpilogueTensorStorage epilogue;
  };

  // Device side arguments
  struct Arguments {
    GemmUniversalMode mode{};
    ProblemShape problem_shape{};
    MainloopArguments mainloop{};
    EpilogueArguments epilogue{};
    KernelHardwareInfo hw_info{};
    TileSchedulerArguments scheduler{};
  };

  // Kernel entry point API
  struct Params {
    GemmUniversalMode mode;
    ProblemShape problem_shape;
    MainloopParams mainloop;
    EpilogueParams epilogue;
  };

  //
  // Methods
  //

  // Convert to underlying arguments. In this case, a simple copy for the aliased type.
  static
  Params
  to_underlying_arguments(Arguments const& args, void* workspace) {
    (void) workspace;
    return {
      args.mode,
      args.problem_shape,
      CollectiveMainloop::to_underlying_arguments(args.problem_shape, args.mainloop, workspace),
      CollectiveEpilogue::to_underlying_arguments(args.problem_shape, args.epilogue, workspace)
    };
  }

  static bool
  can_implement(Arguments const& args) {
    auto m = get<0>(args.problem_shape);
    auto n = get<1>(args.problem_shape);
    auto k = get<2>(args.problem_shape);
    // TODO(codeplay): base *_valid on the atom shapes
    bool m_valid = m > 0;
    bool n_valid = n > 0 && n % 4 == 0;
    bool k_valid = k > 0 && k % get<2>(TileShape{}) == 0;
    bool shape_implementable = (m_valid && n_valid && k_valid);

    bool mode_implementable = args.mode == GemmUniversalMode::kGemm ||
          (args.mode == GemmUniversalMode::kBatched && rank(ProblemShape{}) == 4);
    return shape_implementable && mode_implementable && TileScheduler::can_implement(args.scheduler);
  }

  static int
  get_workspace_size(Arguments const& args) {
    return 0;
  }

  static
  cutlass::Status
  initialize_workspace(Arguments const& args, void* workspace = nullptr, cudaStream_t stream = nullptr, 
    CudaHostAdapter* cuda_adapter = nullptr) {
    return Status::kSuccess;
  }

  static dim3
  get_grid_shape(Params const& params) {
    int batch_count = 1;
    if constexpr (cute::rank(ProblemShape{}) == 4) {
      batch_count = cute::size<3>(params.problem_shape);
    }
    return dim3(
        #ifdef CUTLASS_SYCL_SWITCH_WG
            cute::size(cute::ceil_div(cute::shape<0>(params.problem_shape), cute::shape<0>(WorkgroupTileShape{}))),
            cute::size(cute::ceil_div(cute::shape<1>(params.problem_shape), cute::shape<1>(WorkgroupTileShape{}))),
        #else
            cute::size(cute::ceil_div(cute::shape<1>(params.problem_shape), cute::shape<1>(WorkgroupTileShape{}))),
            cute::size(cute::ceil_div(cute::shape<0>(params.problem_shape), cute::shape<0>(WorkgroupTileShape{}))),
        #endif
            batch_count
    );
  }

  static dim3
  get_block_shape() {
    return dim3(MaxThreadsPerBlock, 1, 1);
  }

  CUTLASS_DEVICE
  void
  operator()(Params const& params, char* smem_buf) {
    SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(smem_buf);
    // Preconditions
    CUTE_STATIC_ASSERT(is_static<WorkgroupTileShape>::value);

    // Separate out problem shape for convenience
    // Optionally append 1s until problem shape is rank-4 in case its is only rank-3 (MNK)
    auto problem_shape_MNKL = append<4>(params.problem_shape, Int<1>{});
    auto M = get<0>(problem_shape_MNKL);
    auto N = get<1>(problem_shape_MNKL);
    auto K = get<2>(problem_shape_MNKL);
    auto L = get<3>(problem_shape_MNKL);

    // Preconditions
    static_assert(cute::rank(StrideA{}) == 3, "StrideA must be rank-3: [M, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideB{}) == 3, "StrideB must be rank-3: [N, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideC{}) == 3, "StrideC must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideD{}) == 3, "StrideD must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");

    // Get the appropriate blocks for this sub_group -- potential for sub_group locality
    int thread_idx = int(ThreadIdxX());
    auto blk_shape = TileShape{};
    #ifdef CUTLASS_SYCL_SWITCH_WG
    auto m_coord = BlockIdxX();
    auto n_coord = BlockIdxY();
    #else
    auto m_coord = BlockIdxY();
    auto n_coord = BlockIdxX();
    #endif
    auto l_coord = BlockIdxZ();
    auto blk_coord_mnkl = make_coord(m_coord, n_coord, _, l_coord);  
    int sub_group_id = thread_idx / SubgroupSize;
    constexpr auto workgroup_shape = WorkgroupTileShape{};                                                  // (SUB_M,SUB_N,SUB_K)
    constexpr auto subgroup_shape = SubgroupTileShape{};                   

    Tensor mA_mkl = make_tensor(make_gmem_ptr(static_cast<ElementA const*>(nullptr)), make_shape(M,K,L), StrideA{});   //(m,k,l)
    Tensor mB_nkl = make_tensor(make_gmem_ptr(static_cast<ElementB const*>(nullptr)), make_shape(N,K,L), StrideB{});   //(n,k,l)
    Tensor mA_mk = mA_mkl(_,_,l_coord);                                                                        // (m,k)
    Tensor mB_nk = mB_nkl(_,_,l_coord);                                                                        // (n,k)

    auto gA = local_tile(mA_mk, blk_shape, take<0, 3>(blk_coord_mnkl), Step<_1,  X, _1>{});
    auto gB = local_tile(mB_nk, blk_shape, take<0, 3>(blk_coord_mnkl), Step< X, _1, _1>{});

    // Compute tile residues for predication
    auto m_max_coord = M - get<0>(subgroup_shape) * m_coord;                             // M - SUB_M * m_coord
    auto n_max_coord = N - get<1>(subgroup_shape) * n_coord;                             // N - SUB_N * n_coord
    auto k_residue   = K - get<2>(subgroup_shape) * (K / get<2>(subgroup_shape));        // K - SUB_K * k_coord_max
    auto residue_mnk = make_tuple(m_max_coord, n_max_coord, k_residue);

    // Allocate the tiled_mma and the accumulators for the (M,N) subgroup_shape
    TiledMma tiled_mma;

    Tensor accumulators = partition_fragment_C(tiled_mma, take<0,2>(blk_shape)); 
    clear(accumulators);

    auto k_tile_iter  = cute::make_coord_iterator(idx2crd(0, make_shape(K)), make_shape(K));
    int  k_tile_count = K / get<2>(workgroup_shape);

    // Perform the collective scoped MMA
    CollectiveMainloop collective_mma;
    collective_mma.template operator()<PrefetchStrideA, PrefetchStrideB>(
      accumulators,
      gA,
      gB,
      accumulators,
      k_tile_iter, k_tile_count,
      residue_mnk,
      blk_coord_mnkl,
      K,
      thread_idx,
      smem_buf,
      params.mainloop
    );

    CollectiveEpilogue epilogue{params.epilogue, shared_storage.epilogue};
    epilogue(
      problem_shape_MNKL,
      subgroup_shape, // TODO(joe): Inconsistency here w/ blk_coord_mnkl
      blk_coord_mnkl,
      accumulators,
      tiled_mma,
      residue_mnk,
      thread_idx,
      smem_buf
    );
  }
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::kernel
