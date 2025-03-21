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

  static constexpr auto Num_SGs = ATOM_N * ATOM_M * ATOM_K;
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

    Tensor mQ_mkl = cute::get_pvc_tensor(make_shape(seq_len, head_size, batch * num_heads));   //(m,k,l)
    Tensor mK_nkl = cute::get_pvc_tensor(make_shape(seq_len, head_size, batch * num_heads));   //(m,k,l)
    Tensor mV_nkl = cute::get_pvc_tensor(make_shape(head_size, seq_len, batch * num_heads));   //(n,k,l)
    Tensor mQ_mk = mQ_mkl(_,_,blk_l_coord);                                                    // (m,k)
    Tensor mK_nk = mK_nkl(_,_,blk_l_coord);                                                    // (n,k)
    Tensor mV_nk = mV_nkl(_,_,blk_l_coord);                                                    // (n,k)
    
    auto gQ = local_tile(mQ_mk, subgroup_shape, make_coord(blk_m_coord * ATOM_M, _, _), Step<_1,  X, _1>{}); // subgroup_shape<16, 64, 64> // Atom_M ->8   // 16x64
    auto gK = local_tile(mK_nk, subgroup_shape, make_coord(_, _ , _), Step<X, _1, _1>{});                    // subgroup_shape<16, 64, 64>                 // 64x64
    auto gV = local_tile(mV_nk, subgroup_shape, make_coord(_, blk_n_coord * ATOM_N, _), Step<X, _1, _1>{});  // subgroup_shape<16, 64, 64> // Atom_N -> 2  // 64x64

    const int seq_coord = blk_m_coord * BLK_M + (sub_group_id / ATOM_N) * SG_M;
    const int l_coord = blk_l_coord;
    
    const int causal_seq_len = seq_coord + get<0>(subgroup_shape);
    const int non_causal_seq_len = seq_len;

    const int nblock_limit = CausalMask ? cute::ceil_div(causal_seq_len, SG_N)
                                        : cute::ceil_div(non_causal_seq_len, SG_N);

    auto tiled_prefetch_q =  params.mainloop.gmem_tiled_copy_q.template prefetch_selector<Shape<Int<BLK_M>,Int<BLK_N>>, Num_SGs>(params.mainloop.mQ);   // <M=128 (BLK_M), K=128 (BLK_N)>  // is_reverse_needed=0
    auto tiled_prefetch_k =  params.mainloop.gmem_tiled_copy_k.template prefetch_selector<Shape<Int<BLK_K>,Int<BLK_N>>, Num_SGs>(params.mainloop.mK);   // <N=64  (BLK_K), K=128 (BLK_N)>  // is_revese_needed=0
    auto tiled_prefetch_v =  params.mainloop.gmem_tiled_copy_v.template prefetch_selector<Shape<Int<BLK_N>,Int<BLK_K>>, Num_SGs>(params.mainloop.mV);   // <N=128 (BLK_N), K=64  (BLK_K)>  // is_reverse_needed=1 
    auto thr_prefetch_Q = tiled_prefetch_q.get_slice(thread_idx);
    auto thr_prefetch_K = tiled_prefetch_k.get_slice(thread_idx);
    auto thr_prefetch_V = tiled_prefetch_v.get_slice(thread_idx);
    auto pQgQ = thr_prefetch_Q.partition_S(gQ);
    auto pKgK = thr_prefetch_K.partition_S(gK);
    auto pVgV = thr_prefetch_V.partition_S(gV);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size<3>(pQgQ); i++) {
      prefetch(tiled_prefetch_q, pQgQ(_, _, _, i));
    }
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < DispatchPolicy::Stages; i++) {
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < size<4>(pKgK); j++) {
        prefetch(tiled_prefetch_k, pKgK(_, _, _ , i, j));
      }
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
    // when causal mask is true. It is not possible to set the scope
    // of the barrier to workgroup level as the number n block is
    // different for each subgroup due to triangular nature of causal based operation
    static constexpr int barrier_scope = CausalMask ? 3 : 2;
    // MAIN LOOP: loop over K and V, perform fused attention + online softmax
    for (int nblock = 0, load_idx = 0; nblock < nblock_limit - static_cast<int>(CausalMask); nblock++, 
         load_idx += SG_N) {
      barrier_arrive(barrier_scope);
      // 1) Load K (performed inside mmaQK)
      // 2) Create Tensor S
      Tensor tSr = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>, Int<FragsN>>{});
      clear(tSr);

      // 3) Perform GEMM S = Q*K
      collective_mma.mmaQK(tSr, gQ, gK(_, _, nblock, _), tSr, ceil_div(head_size , SG_N), params.mainloop);
      
      // we only need one block ahead, there is enough gap to prefetch it while doing softmax. because the gap between the two MMA is big,
      // prefetching it the same way as cutlass K matrix does not make sense
      prefetch(tiled_prefetch_v, pVgV(_, _, _ , nblock));

      CollectiveSoftmaxEpilogue softmax(params.softmax);
      softmax(nblock == 0, tSr, max_reg, sum_reg, out_reg);

      collective_mma.mmaPV(out_reg, tSr, gV(_, _ , nblock), out_reg, params.mainloop);
      
      // Prefetch the next K tile
     // there is no need to gaurd it with if statememt as prefetch will ignore out of bound reading
        CUTLASS_PRAGMA_UNROLL
        for (int j = 0; j < size<4>(pKgK); j++) {
          prefetch(tiled_prefetch_k, pKgK(_, _, _, nblock + DispatchPolicy::Stages, j));
        }
      barrier_wait(barrier_scope);
    }
    if constexpr (CausalMask) {
      // BAND Matrix
      // 1) Load K (performed inside mmaQK)
      // 2) Create Tensor S
      Tensor tSr = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>, Int<FragsN>>{});
      clear(tSr);
      // 3) Perform GEMM S = Q*K
      collective_mma.mmaQK(tSr, gQ,  gK(_, _, nblock_limit - 1, _), tSr, ceil_div(head_size , SG_N), params.mainloop);
      // we only need one block ahead, there is enough gap to prefetch it while doing softmax. because the gap between the two MMA is big,
      // prefetching it the same way as cutlass K matrix does not make sense
      prefetch(tiled_prefetch_v, pVgV(_, _, _ , nblock_limit - 1));
      // mask the elements of each tile where j > i
      const int item_id = thread_idx % SubgroupSize;
      int col_idx = item_id + (nblock_limit - 1) * SG_N;
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

      collective_mma.mmaPV(out_reg, tSr,  gV(_, _ , nblock_limit - 1), out_reg, params.mainloop);
    }

    CollectiveEpilogue epilogue{params.epilogue, shared_storage.epilogue};
    auto blk_coord_mnkl = make_coord(blk_m_coord, blk_n_coord, _, blk_l_coord);
    epilogue(params.problem_shape, blk_coord_mnkl, out_reg, max_reg, sum_reg, tiled_mma, params.softmax.scale);
  }
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::kernel
