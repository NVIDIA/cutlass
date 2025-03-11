/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/gemm.h"
#include "cutlass/kernel_hardware_info.hpp"

#include "flash_attention_v2/collective/xe_flash_attn_mma.hpp"

namespace cutlass::gemm::kernel {

template <class ProblemShape, class CollectiveMainloop, class CollectiveSoftmaxEpilogue_, class CollectiveEpilogue, class TileScheduler_ = void>
class GemmUniversalAttention;

///////////////////////////////////////////////////////////////////////////////

template <class ProblemShape_, class CollectiveMainloop_, class CollectiveSoftmaxEpilogue_, class CollectiveEpilogue_, class TileScheduler_>
class GemmUniversalAttention {

public:
  //
  // Type Aliases
  //
  using ProblemShape = ProblemShape_;

  static_assert(rank(ProblemShape{}) == 4, "ProblemShape{} should be <batch, num_heads, seq_len, head_size>");

  // Mainloop derived types
  using CollectiveMainloop = CollectiveMainloop_;
  using TileShape = typename CollectiveMainloop::WorkgroupTileShape;
  using WorkgroupTileShape = TileShape;
  using TiledMma = typename CollectiveMainloop::TiledMma;
  using ArchTag = typename CollectiveMainloop::ArchTag;
  using ElementQ = typename CollectiveMainloop::ElementQ;
  using StrideQ = typename CollectiveMainloop::StrideQ;
  using ElementK = typename CollectiveMainloop::ElementK;
  using StrideK = typename CollectiveMainloop::StrideK;
  using ElementV = typename CollectiveMainloop::ElementV;
  using StrideV = typename CollectiveMainloop::StrideV;
  using DispatchPolicy = typename CollectiveMainloop::DispatchPolicy;
  using ElementAccumulator = typename CollectiveMainloop::ElementAccumulator;
  using MainloopArguments = typename CollectiveMainloop::Arguments;
  using MainloopParams = typename CollectiveMainloop::Params;

  using CollectiveSoftmaxEpilogue = CollectiveSoftmaxEpilogue_;
  using SoftmaxArguments = typename CollectiveSoftmaxEpilogue::Arguments;
  using SoftmaxParams = typename CollectiveSoftmaxEpilogue::Params;

  static_assert(cute::is_void_v<TileScheduler_> or cute::is_same_v<TileScheduler_, PersistentScheduler>,
                "Intel PVC does not support specializing the tile scheduler.");
  using TileSchedulerTag = TileScheduler_;
  using TileScheduler =
      typename detail::TileSchedulerSelector<TileScheduler_, ArchTag, WorkgroupTileShape,
                                             cute::Shape<cute::Int<1>, cute::Int<1>, cute::Int<1>>>::Scheduler;
  using TileSchedulerArguments = typename TileScheduler::Arguments;

  // Epilogue derived types
  using CollectiveEpilogue = CollectiveEpilogue_;
  using ElementO = typename CollectiveEpilogue::ElementO;
  using StrideO = typename CollectiveEpilogue::StrideO;
  using ElementLSE = typename CollectiveEpilogue::ElementLSE;
  using EpilogueArguments = typename CollectiveEpilogue::Arguments;
  using EpilogueParams = typename CollectiveEpilogue::Params;
  static_assert(cute::is_same_v<ElementAccumulator, typename CollectiveEpilogue::ElementAccumulator>,
                "Mainloop and epilogue do not agree on accumulator value type.");

  // MSVC requires the cast to fix a warning-as-error.
  static constexpr int SharedStorageSize = 0;

  static constexpr bool CausalMask = CollectiveMainloop::CausalMask;
  static constexpr int SubgroupSize = CollectiveMainloop::SubgroupSize; // sub_group size
  static constexpr uint32_t MaxThreadsPerBlock = CollectiveMainloop::MaxThreadsPerBlock;
  using MmaAtomShape = typename CollectiveMainloop::MmaAtomShape;           // 8,16,16
  using SubgroupTileShape = typename CollectiveMainloop::SubgroupTileShape; //(16,64,64)

  static constexpr int BLK_M = CollectiveMainloop::BLK_M; // 128
  static constexpr int BLK_N = CollectiveMainloop::BLK_N; // 64
  static constexpr int BLK_K = CollectiveMainloop::BLK_K; // 64

  static constexpr int ATOM_M = CollectiveMainloop::ATOM_M; // 8
  static constexpr int ATOM_N = CollectiveMainloop::ATOM_N; // 1
  static constexpr int ATOM_K = CollectiveMainloop::ATOM_K; // 1

  static constexpr int SG_M = CollectiveMainloop::SG_M; // 16
  static constexpr int SG_N = CollectiveMainloop::SG_N; // 64
  static constexpr int SG_K = CollectiveMainloop::SG_K; // 64

  static_assert(ATOM_K * BLK_N == ATOM_N * BLK_K,
                "The QKV multiplication in this implementation requires the squar block computation in per subgroup.");

  static constexpr int Vec = (get<0>(MmaAtomShape()) * get<1>(MmaAtomShape())) / SubgroupSize; // 8
  using FragsShape = decltype(cute::shape_div(take<0, 2>(SubgroupTileShape{}), take<0, 2>(MmaAtomShape())));
  static constexpr int FragsM = get<0>(FragsShape{});                                          // 2
  static constexpr int FragsN = get<1>(FragsShape{});                                          // 4

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
    SoftmaxArguments softmax{};
    EpilogueArguments epilogue{};
    KernelHardwareInfo hw_info{};
    TileSchedulerArguments scheduler{};
  };

  // Kernel entry point API
  struct Params {
    GemmUniversalMode mode;
    ProblemShape problem_shape;
    MainloopParams mainloop;
    SoftmaxParams softmax;
    EpilogueParams epilogue;
  };

  //
  // Methods
  //

  // Convert to underlying arguments. In this case, a simple copy for the aliased type.
  static Params to_underlying_arguments(Arguments const &args, void *workspace) {
    (void)workspace;
    return {args.mode, args.problem_shape,
            CollectiveMainloop::to_underlying_arguments(args.problem_shape, args.mainloop, workspace),
            CollectiveSoftmaxEpilogue::to_underlying_arguments(args.softmax),
            CollectiveEpilogue::to_underlying_arguments(args.problem_shape, args.epilogue, workspace)};
  }

  static bool can_implement(Arguments const &args) {
    bool mode_implementable = args.mode == GemmUniversalMode::kGemm or
                              (args.mode == GemmUniversalMode::kBatched && rank(ProblemShape{}) == 4);
    return mode_implementable && TileScheduler::can_implement(args.scheduler);
  }

  static int get_workspace_size(Arguments const &args) { return 0; }

  static cutlass::Status initialize_workspace(Arguments const &args, void *workspace = nullptr,
                                              cudaStream_t stream = nullptr, CudaHostAdapter *cuda_adapter = nullptr) {
    return Status::kSuccess;
  }

  static dim3 get_grid_shape(Params const &params) {
    return dim3(cute::size(cute::ceil_div(cute::shape<3>(params.problem_shape), cute::shape<1>(WorkgroupTileShape{}))),
                cute::size(cute::ceil_div(cute::shape<2>(params.problem_shape), cute::shape<0>(WorkgroupTileShape{}))),
                cute::size(cute::shape<0>(params.problem_shape) * cute::shape<1>(params.problem_shape)));
  }

  static dim3 get_block_shape() { return dim3(MaxThreadsPerBlock, 1, 1); }

  CUTLASS_DEVICE
  void operator()(Params const &params, char *smem_buf) {
    SharedStorage &shared_storage = *reinterpret_cast<SharedStorage *>(smem_buf);
    // Preconditions
    CUTE_STATIC_ASSERT(is_static<WorkgroupTileShape>::value);
    // Separate out problem shape for convenience
    auto batch = get<0>(params.problem_shape);
    auto num_heads = get<1>(params.problem_shape);
    auto seq_len = get<2>(params.problem_shape);
    auto head_size = get<3>(params.problem_shape);
    // Preconditions
    static_assert(cute::rank(StrideQ{}) == 3, "StrideQ must be rank-3: [seq_len, head_size, batch * num_heads].");
    static_assert(cute::rank(StrideK{}) == 3, "StrideK must be rank-3: [head_size, seq_len, batch * num_heads].");
    static_assert(cute::rank(StrideV{}) == 3, "StrideV must be rank-3: [seq_len, head_size, batch * num_heads].");

    int thread_idx = int(ThreadIdxX());
    int sub_group_id = thread_idx / SubgroupSize;
    constexpr auto subgroup_shape = SubgroupTileShape{};   // (SUB_M,SUB_N,SUB_K)

    auto blk_m_coord = BlockIdxY();
    auto blk_n_coord = BlockIdxX();
    auto blk_l_coord = BlockIdxZ();

    Tensor mQ_mkl = params.mainloop.gmem_tiled_copy_q.get_pvc_tensor(make_shape(seq_len, head_size, batch * num_heads));   //(m,k,l)
    Tensor mK_nkl = params.mainloop.gmem_tiled_copy_k.get_pvc_tensor(make_shape(seq_len, head_size, batch * num_heads));   //(m,k,l)
    Tensor mV_nkl = params.mainloop.gmem_tiled_copy_v.get_pvc_tensor(make_shape(head_size, seq_len, batch * num_heads));   //(n,k,l)
    Tensor mQ_mk = mQ_mkl(_,_,blk_l_coord);                                                      // (m,k)
    Tensor mK_nk = mK_nkl(_,_,blk_l_coord);                                                      // (n,k)
    Tensor mV_nk = mV_nkl(_,_,blk_l_coord);                                                      // (n,k)

    auto gQ = local_tile(mQ_mk, subgroup_shape, make_coord(blk_m_coord * ATOM_M, _, _), Step<_1,  X, _1>{});

    const int seq_coord = blk_m_coord * BLK_M + (sub_group_id / ATOM_N) * SG_M;
    const int head_size_coord = blk_n_coord * BLK_N + (sub_group_id % ATOM_N) * SG_N;
    const int l_coord = blk_l_coord;

    using PrefetchQThrShape = typename CollectiveMainloop::PrefetchQThrShape; // shape<4,2> // (4,4)
    using PrefetchKThrShape = typename CollectiveMainloop::PrefetchKThrShape; // shape<4,2> // (4,4)
    using PrefetchVThrShape = typename CollectiveMainloop::PrefetchVThrShape; // shape<4,2> // (4,4)
    using PrefetchQTileSize = typename CollectiveMainloop::PrefetchQTileSize; // 32x32   // 32x32
    using PrefetchKTileSize = typename CollectiveMainloop::PrefetchKTileSize; // 16x32   // 16x32
    using PrefetchVTileSize = typename CollectiveMainloop::PrefetchVTileSize; // 16x32   // 16x32

    const int causal_seq_len = seq_coord + get<0>(subgroup_shape);
    const int non_causal_seq_len = seq_len;

    const int nblock_limit = CausalMask ? cute::ceil_div(causal_seq_len, get<1>(subgroup_shape))
                                        : cute::ceil_div(non_causal_seq_len, get<1>(subgroup_shape));

    const int k_tile_count = head_size / (get<1>(PrefetchQThrShape{}) * get<1>(PrefetchQTileSize{}));
    // m, k
    Tensor prefetch_iter_2d_q = params.mainloop.gmem_prefetch_q.get_pvc_tensor(
        // subgroup arranged 4x2 to load 128x64 in 2 load load (each 32X32)
        make_coord(BlockIdxY() * BLK_M + ((sub_group_id / get<1>(PrefetchQThrShape{})) *
                                          get<0>(PrefetchQTileSize{})), // iteration 0/M/Hight/vertical
                   (sub_group_id % get<1>(PrefetchQThrShape{})) *
                       get<1>(PrefetchQTileSize{}), // Iteration 1/K/Width/Horisontal
                   blk_l_coord),
        make_shape(_1{}, _1{}, _1{}));
    Tensor prefetch_iter_q = append_pvc_tensor<1>(prefetch_iter_2d_q, k_tile_count,
                                                  (get<1>(PrefetchQThrShape{}) * get<1>(PrefetchQTileSize{})));
    // The Key point is 1 is horisontal and zero is vertical
    // the iteration over K dimention of B matrix (head_size) should be :
    const auto iter_over_head_count =
        head_size / (get<1>(PrefetchKThrShape{}) * get<1>(PrefetchKTileSize{})); // head_size / BLK_N;
    // subgroup arranged 4x2 to load (64x64) in one load(each 16x32)
    // Assume LD_T/LD_N will indicate ColumnMajor and RowMajor
    auto k_prefetch_coordinate = make_coord(
        (sub_group_id / get<1>(PrefetchKThrShape{})) * get<0>(PrefetchKTileSize{}), // iteration 0/N/Hight/vertical
        (sub_group_id % get<1>(PrefetchKThrShape{})) * get<1>(PrefetchKTileSize{}), // iteration 1/K//Horizontal
        blk_l_coord);
    // To load the 64x64
    Tensor prefetch_iter_k_base =
        params.mainloop.gmem_prefetch_k.get_pvc_tensor(k_prefetch_coordinate, make_shape(_1{}, _1{}, _1{}));
    // Adding iterator for the dimention N(sequence length) along 0 /Vertical
    Tensor prefetch_iter_ndim = append_pvc_tensor<0>(prefetch_iter_k_base, nblock_limit,
                                                     (get<0>(PrefetchKThrShape{}) * get<0>(PrefetchKTileSize{})));
    // Adding iterator for  the dimension K (head size) along /Horizontal
    Tensor prefetch_iter_k = append_pvc_tensor<1>(prefetch_iter_ndim, iter_over_head_count,
                                                  (get<1>(PrefetchKThrShape{}) * get<1>(PrefetchKTileSize{})));

    // V is a transposed matrix, So here the sequence length is consumed, it is transposed so the consumed dimension
    // looks like B matrix Hence, the Head size is the fast moving dimension and horizontal and sequence length is
    // vertical. The prefetch only move along the sequence length. Here we call sequence length K since it get consumed
    // and head size N since it stay subgroup arranged 4x2 to load (64x64) in one load(each 64x32)
    Tensor prefetch_iter_2d_v = params.mainloop.gmem_prefetch_v.get_pvc_tensor(
        make_coord((sub_group_id / get<1>(PrefetchVThrShape{})) *
                       get<0>(PrefetchVTileSize{}), // iteration 0/K/Hight/vertical/ sequence lengh
                   BlockIdxX() * BLK_N + ((sub_group_id % get<1>(PrefetchVThrShape{})) *
                                          get<1>(PrefetchVTileSize{})), //  iteration 1/N/W/Horisontal / Head size
                   blk_l_coord),
        // We loop over the consuming dimension which is the iteration 0(N) here
        make_shape(_1{}, _1{}, _1{}));
    Tensor prefetch_iter_v = append_pvc_tensor<0>(prefetch_iter_2d_v, nblock_limit,
                                                  (get<0>(PrefetchVThrShape{}) * get<0>(PrefetchVTileSize{})));
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < k_tile_count; i++) {
      prefetch(params.mainloop.gmem_prefetch_q, prefetch_iter_q(_, _, _, i));
    }
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < DispatchPolicy::Stages; i++) {
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < iter_over_head_count; j++) {
        prefetch(params.mainloop.gmem_prefetch_k, prefetch_iter_k(_, _, _, i, j));
      }
    }

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < DispatchPolicy::Stages; i++) {
      prefetch(params.mainloop.gmem_prefetch_v, prefetch_iter_v(_, _, _, i));
    }

    // Allocate the tiled_mma and the accumulators for the (M,N) subgroup_shape
    TiledMma tiled_mma;
    Tensor out_reg = partition_fragment_C(tiled_mma, take<0, 2>(subgroup_shape));
    // There are 16 workitem and 32 max per subgroup, each worktime containt 2 max and cumulatively, they calculate the
    // max per subgroup
    ElementAccumulator max_reg{-INFINITY};
    // The sum reg each contains a 2d tesnor for 8 x 4 This is number of sequence lenght process per subgroup
    Tensor sum_reg = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>>{});

    clear(sum_reg);
    clear(out_reg);
    // Perform the collective scoped MMA
    CollectiveMainloop collective_mma;
    // when causal mask is true.It is not possible to set the scope
    // of the barrier to workgroup level as the number n block is
    // different for each subgroup due to triangular nature of causal based operation
    static constexpr int barrier_scope = CausalMask ? 3 : 2;

    // MAIN LOOP: loop over K and V, perform fused attention + online softmax
    for (int nblock = 0, load_idx = 0; nblock < nblock_limit - static_cast<int>(CausalMask);
         nblock++, load_idx += get<1>(subgroup_shape)) {
      barrier_arrive(barrier_scope);
      // 1) Load K (performed inside mmaQK)
      // 2) Create Tensor S
      auto gK = local_tile(mK_nk, subgroup_shape, make_coord(_, nblock, _), Step<X, _1, _1>{});
      Tensor tSr = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>, Int<FragsN>>{});
      clear(tSr);

      // 3) Perform GEMM S = Q*K
      auto tile_coord_QK = make_coord(seq_coord, load_idx, _, blk_l_coord);
      collective_mma.mmaQK(tile_coord_QK, tSr, gQ, gK, tSr, ceil_div(head_size , get<1>(subgroup_shape)), params.mainloop);

      CollectiveSoftmaxEpilogue softmax(params.softmax);
      softmax(nblock == 0, tSr, max_reg, sum_reg, out_reg);

      auto gV = local_tile(mV_nk, subgroup_shape, make_coord(_, blk_n_coord * ATOM_N, nblock), Step<X, _1, _1>{}); 
      auto tile_coord_PV = make_coord(0, head_size_coord, _, blk_l_coord);
      collective_mma.mmaPV(tile_coord_PV, out_reg, tSr, gV, out_reg, params.mainloop);
      if (nblock + DispatchPolicy::Stages < nblock_limit) {
        CUTLASS_PRAGMA_UNROLL
        for (int j = 0; j < iter_over_head_count; j++) {
          prefetch(params.mainloop.gmem_prefetch_k, prefetch_iter_k(_, _, _, nblock + DispatchPolicy::Stages, j));
        }
        prefetch(params.mainloop.gmem_prefetch_v, prefetch_iter_v(_, _, _, nblock + DispatchPolicy::Stages));
      }
      barrier_wait(barrier_scope);
    }
    if constexpr (CausalMask) {
      // BAND Matrix
      // 1) Load K (performed inside mmaQK)
      // 2) Create Tensor S
      auto gK = local_tile(mK_nk, subgroup_shape, make_coord(0, nblock_limit - 1, _), Step<X, _1, _1>{});
      Tensor tSr = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>, Int<FragsN>>{});
      clear(tSr);
      // 3) Perform GEMM S = Q*K
      auto tile_coord_QK = make_coord(seq_coord, (nblock_limit - 1) * get<1>(subgroup_shape), _, blk_l_coord);
      collective_mma.mmaQK(tile_coord_QK, tSr, gQ, gK, tSr, ceil_div(head_size , get<1>(subgroup_shape)), params.mainloop);
      // mask the elements of each tile where j > i
      const int item_id = thread_idx % SubgroupSize;
      int col_idx = item_id + (nblock_limit - 1) * get<1>(subgroup_shape);
      CUTLASS_PRAGMA_UNROLL
      for (int n = 0; n < FragsN; n++, col_idx += get<1>(MmaAtomShape())) { // 4
        CUTLASS_PRAGMA_UNROLL
        for (int m = 0; m < FragsM; m++) { // 2
          int row_idx = m * Vec + seq_coord;
          CUTLASS_PRAGMA_UNROLL
          for (int row = 0; row < Vec; row++, row_idx++) { // 8
            if (col_idx > row_idx)
              tSr(row, m, n) = -INFINITY;
          }
        }
      }

      CollectiveSoftmaxEpilogue softmax(params.softmax);
      softmax((nblock_limit - 1) == 0, tSr, max_reg, sum_reg, out_reg);

      auto gV = local_tile(mV_nk, subgroup_shape, make_coord(0, blk_n_coord * ATOM_N, nblock_limit - 1), Step<X, _1, _1>{});
      auto tile_coord_PV = make_coord(0, head_size_coord, _, blk_l_coord);
      collective_mma.mmaPV(tile_coord_PV, out_reg, tSr, gV, out_reg, params.mainloop);
    }

    CollectiveEpilogue epilogue{params.epilogue, shared_storage.epilogue};
    auto blk_coord_mnkl = make_coord(blk_m_coord, blk_n_coord, _, blk_l_coord);
    epilogue(params.problem_shape, blk_coord_mnkl, out_reg, max_reg, sum_reg, tiled_mma, params.softmax.scale);
  }
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::kernel
