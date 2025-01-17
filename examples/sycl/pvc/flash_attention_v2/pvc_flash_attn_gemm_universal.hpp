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

#include "online_softmax.hpp"
#include "pvc_flash_attn_mma.hpp"

#ifdef __SYCL_DEVICE_ONLY__
#define SYCL_DEVICE_SPV_SPLIT_BARRIER(x) SYCL_EXTERNAL x
#else
#define SYCL_DEVICE_SPV_SPLIT_BARRIER(x) \
  inline x { assert(false); }
#endif

SYCL_DEVICE_SPV_SPLIT_BARRIER(void __spirv_ControlBarrierArriveINTEL(int, int, int));
SYCL_DEVICE_SPV_SPLIT_BARRIER(void __spirv_ControlBarrierWaitINTEL(int, int, int));

#undef SYCL_DEVICE_SPV_SPLIT_BARRIER
namespace cutlass::gemm::kernel {

template <
  class ProblemShape,
  class CollectiveMainloop,
  class CollectiveEpilogue,
  class TileScheduler_ = void
>
class GemmUniversalAttention;

///////////////////////////////////////////////////////////////////////////////

template <
  class ProblemShape_,
  class CollectiveMainloop_,
  class CollectiveEpilogue_,
  class TileScheduler_
>
class GemmUniversalAttention
{
// 3 is for subgroup, 2 is for workgroup
#define barrier_arrive(scope) __spirv_ControlBarrierArriveINTEL(scope,0,0);
#define barrier_wait(scope) __spirv_ControlBarrierWaitINTEL(scope, 0, 0); 
public:
  //
  // Type Aliases
  //
  using ProblemShape = ProblemShape_;

  static_assert(rank(ProblemShape{}) == 4,
    "ProblemShape{} should be <batch, num_heads, seq_len, head_size>");

  // Mainloop derived types
  using CollectiveMainloop = CollectiveMainloop_;
  using TileShape = typename CollectiveMainloop::WorkgroupTileShape;
  using WorkgroupTileShape = TileShape;
  using TiledMma  = typename CollectiveMainloop::TiledMma;
  using ArchTag   = typename CollectiveMainloop::ArchTag;
  using ElementQ  = typename CollectiveMainloop::ElementQ;
  using StrideQ   = typename CollectiveMainloop::StrideQ;
  using ElementK  = typename CollectiveMainloop::ElementK;
  using StrideK   = typename CollectiveMainloop::StrideK;
  using ElementV  = typename CollectiveMainloop::ElementV;
  using StrideV   = typename CollectiveMainloop::StrideV;
  using DispatchPolicy = typename CollectiveMainloop::DispatchPolicy;
  using ElementAccumulator = typename CollectiveMainloop::ElementAccumulator;
  using MainloopArguments = typename CollectiveMainloop::Arguments;
  using MainloopParams = typename CollectiveMainloop::Params;

  using SoftmaxArguments = typename flash::Softmax<ElementAccumulator>::Arguments;
  using SoftmaxParams = typename flash::Softmax<ElementAccumulator>::Params;

  static_assert(cute::is_void_v<TileScheduler_> or cute::is_same_v<TileScheduler_, PersistentScheduler>,
    "Intel PVC does not support specializing the tile scheduler.");
  using TileSchedulerTag = TileScheduler_;
  using TileScheduler = typename detail::TileSchedulerSelector<
    TileScheduler_, ArchTag, WorkgroupTileShape,
    cute::Shape<cute::Int<1>, cute::Int<1>, cute::Int<1>>>::Scheduler;
  using TileSchedulerArguments = typename TileScheduler::Arguments;

  // Epilogue derived types
  using CollectiveEpilogue = CollectiveEpilogue_;
  using ElementO = typename CollectiveEpilogue::ElementO;
  using StrideO  = typename CollectiveEpilogue::StrideO;
  using ElementLSE = typename CollectiveEpilogue::ElementLSE;
  using StrideLSE  = typename CollectiveEpilogue::StrideLSE;
  using EpilogueArguments = typename CollectiveEpilogue::Arguments;
  using EpilogueParams = typename CollectiveEpilogue::Params;
  static_assert(cute::is_same_v<ElementAccumulator, typename CollectiveEpilogue::ElementAccumulator>,
    "Mainloop and epilogue do not agree on accumulator value type.");

  // MSVC requires the cast to fix a warning-as-error.
  static constexpr int SharedStorageSize = 0;

  static constexpr bool CausalMask = CollectiveMainloop::CausalMask;
  static constexpr int SubgroupSize = CollectiveMainloop::SubgroupSize; // sub_group size
  static constexpr uint32_t MaxThreadsPerBlock = CollectiveMainloop::MaxThreadsPerBlock;
  using MmaAtomShape = typename CollectiveMainloop::MmaAtomShape;
  using SubgroupTileShape = typename CollectiveMainloop::SubgroupTileShape;

  static constexpr int BLK_M = CollectiveMainloop::BLK_M;
  static constexpr int BLK_N = CollectiveMainloop::BLK_N;
  static constexpr int BLK_K = CollectiveMainloop::BLK_K;

  static constexpr int ATOM_M = CollectiveMainloop::ATOM_M;
  static constexpr int ATOM_N = CollectiveMainloop::ATOM_N;
  static constexpr int ATOM_K = CollectiveMainloop::ATOM_K;

  static constexpr int SG_M = CollectiveMainloop::SG_M;
  static constexpr int SG_N = CollectiveMainloop::SG_N;
  static constexpr int SG_K = CollectiveMainloop::SG_K;

  static constexpr int Vec = (get<0>(MmaAtomShape()) * get<1>(MmaAtomShape())) / SubgroupSize; //8
  static constexpr int FragsM = get<0>(SubgroupTileShape{}) / get<0>(MmaAtomShape());  // 4
  static constexpr int FragsN = get<1>(SubgroupTileShape{}) / get<1>(MmaAtomShape());  // 2

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
    SoftmaxArguments softmax;
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
      flash::Softmax<ElementAccumulator>::to_underlying_arguments(args.softmax),
      CollectiveEpilogue::to_underlying_arguments(args.problem_shape, args.epilogue, workspace)
    };
  }

  static bool
  can_implement(Arguments const& args) {
    bool mode_implementable = args.mode == GemmUniversalMode::kGemm or
          (args.mode == GemmUniversalMode::kBatched && rank(ProblemShape{}) == 4);
    return mode_implementable && TileScheduler::can_implement(args.scheduler);
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
    return dim3(
            cute::size(cute::ceil_div(cute::shape<3>(params.problem_shape), cute::shape<1>(WorkgroupTileShape{}))),
            cute::size(cute::ceil_div(cute::shape<2>(params.problem_shape), cute::shape<0>(WorkgroupTileShape{}))),
            cute::size(cute::shape<0>(params.problem_shape) * cute::shape<1>(params.problem_shape))
    );
  }

  static dim3
  get_block_shape() {
    return dim3(MaxThreadsPerBlock, 1, 1);
  }

  CUTLASS_DEVICE
  void operator()(Params const& params, char* smem_buf) {
    SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(smem_buf);
    // Preconditions
    CUTE_STATIC_ASSERT(is_static<WorkgroupTileShape>::value);
    // Separate out problem shape for convenience
    auto batch = get<0>(params.problem_shape);
    auto num_heads = get<1>(params.problem_shape);
    auto seq_len = get<2>(params.problem_shape);
    auto head_size = get<3>(params.problem_shape);
    // Preconditions
    static_assert(cute::rank(StrideQ{}) == 3, "StrideQ must be rank-4: [batch, num_heads, seq_len, head_size].");
    static_assert(cute::rank(StrideK{}) == 3, "StrideK must be rank-4: [batch, num_heads, seq_len, head_size].");
    static_assert(cute::rank(StrideV{}) == 3, "StrideV must be rank-4: [batch, num_heads, seq_len, head_size].");

    int thread_idx = int(ThreadIdxX());
    int sub_group_id = thread_idx / SubgroupSize;
    constexpr auto workgroup_shape = WorkgroupTileShape{};  // (SUB_M,SUB_N,SUB_K)
    constexpr auto subgroup_shape = SubgroupTileShape{};     // (SUB_M,SUB_N,SUB_K)

    auto blk_shape = TileShape{};
    auto blk_m_coord = BlockIdxY();
    auto blk_n_coord = BlockIdxX();
    auto blk_l_coord = BlockIdxZ();
    auto blk_coord_mnkl = make_coord(blk_m_coord, blk_n_coord, _, blk_l_coord);

    Tensor mQ_mkl = make_tensor(make_gmem_ptr(static_cast<ElementQ const*>(nullptr)),
                                make_shape(seq_len, head_size, batch * num_heads), StrideQ{});   //(m,k,l)
    Tensor mK_nkl = make_tensor(make_gmem_ptr(static_cast<ElementK const*>(nullptr)),
                                make_shape(seq_len, head_size, batch * num_heads), StrideK{});   //(n,k,l)
    Tensor mV_nkl = make_tensor(make_gmem_ptr(static_cast<ElementV const*>(nullptr)),
                                make_shape(head_size, seq_len, batch * num_heads), StrideV{});   //(n,k,l)
    Tensor mQ_mk = mQ_mkl(_,_,blk_l_coord);                                                      // (m,k)
    Tensor mK_nk = mK_nkl(_,_,blk_l_coord);                                                      // (n,k)
    Tensor mV_nk = mV_nkl(_,_,blk_l_coord);                                                      // (n,k)

    auto gQ = local_tile(mQ_mk, blk_shape, make_coord(blk_m_coord, 0, _), Step<_1,  X, _1>{});

    const int seq_coord = BlockIdxY() * BLK_M + (sub_group_id / ATOM_N) * SG_M;
    const int head_size_coord = BlockIdxX() * BLK_N + (sub_group_id % ATOM_N) * SG_N;
    const int l_coord = BlockIdxZ();

    // Compute tile residues for predication
    auto m_max_coord = seq_len - get<0>(subgroup_shape) * seq_coord;                                // M - SUB_M * m_coord
    auto n_max_coord = seq_len - get<1>(subgroup_shape) * seq_coord;                                // N - SUB_N * n_coord
    auto k_residue   = head_size - get<2>(subgroup_shape) * (head_size / get<2>(subgroup_shape));  // K - SUB_K * k_coord_max
    auto residue_mnk = make_tuple(m_max_coord, n_max_coord, k_residue);

    static constexpr size_t cacheline_bytes = 64;
    static constexpr auto block_size_w_a = cute::min(SG_K, cacheline_bytes / sizeof(ElementQ)); //32
    static constexpr auto block_size_w_b = cute::min(SG_N, cacheline_bytes / sizeof(ElementK)); //32
    static constexpr auto nums_block_w_a = ceil_div(SG_K, block_size_w_a); // 1
    static constexpr auto nums_block_w_b = ceil_div(SG_N, block_size_w_b); // 1
    using PrefetchQThrShape =
        Shape<Int<ATOM_N /cute::gcd(ATOM_N, nums_block_w_a)>, Int<cute::gcd(ATOM_N, nums_block_w_a)>>; //shape<2,1>
    using PrefetchKThrShape =
        Shape<Int<ATOM_M /cute::gcd(ATOM_M, nums_block_w_b)>, Int<cute::gcd(ATOM_M, nums_block_w_b)>>; //shape <4,1>
    using PrefetchVThrShape =
        Shape<Int<ATOM_M /cute::gcd(ATOM_M, nums_block_w_b)>, Int<cute::gcd(ATOM_M, nums_block_w_b)>>; //shape <4,1>
    using PrefetchQTileSize = decltype(ceil_div(Shape<Int<SG_M>, Int<SG_K>>{},PrefetchQThrShape{})); //16x32
    using PrefetchKTileSize = decltype(ceil_div(Shape<Int<SG_K>, Int<SG_N>>{},PrefetchKThrShape{})); //8x32
    using PrefetchVTileSize = decltype(ceil_div(Shape<Int<SG_K>, Int<SG_N>>{},PrefetchVThrShape{})); // 8x32

    const int causal_seq_len = seq_coord + get<0>(subgroup_shape);
    const int non_causal_seq_len = seq_len;

    const int nblock_limit = CausalMask ? cute::ceil_div(causal_seq_len, get<1>(subgroup_shape)) 
                                : cute::ceil_div(non_causal_seq_len, get<1>(subgroup_shape));

    const int item_id = thread_idx % SubgroupSize;
    const int k_tile_count= head_size / get<1>(subgroup_shape); 
    //m, k
    Tensor prefetch_iter_2d_a = params.mainloop.gmem_prefetch_q.get_pvc_tensor(
      make_coord(seq_coord + (((sub_group_id % ATOM_N) / get<1>(PrefetchQThrShape{}))* get<0>(PrefetchQTileSize{})),   // iteration 0/M/Hight/vertical
                ((sub_group_id % ATOM_N) % get<1>(PrefetchQThrShape{})) * get<1>(PrefetchQTileSize{}), // Iteration 1/K/Width/Horisontal
                blk_l_coord),
            make_shape(_1{}, _1{}, _1{}));
    Tensor prefetch_iter_a = append_pvc_tensor<1>(prefetch_iter_2d_a, k_tile_count, BLK_K);
      // append<4>(make_shape(_1{}, _1{}, _1{}), k_tile_count),
      // append<3>(make_shape(_, _), BLK_K), seq<0, 0, 1>{});
    // The Key point is 1 is horisontal and zero is vertical
    // the iteration over K dimention of B matrix (head_size) should be :
    auto iter_over_head_count = head_size / BLK_N;
    // k, n
    Tensor prefetch_iter_2d_b = params.mainloop.gmem_prefetch_k.get_pvc_tensor(
         make_coord(sub_group_id * get<0>(PrefetchKTileSize{}),            // iteration 0/K/Hight/vertical
                    (sub_group_id % ATOM_N) * get<1>(PrefetchKTileSize{}), //  iteration 1/N/W/Horisontal
                    blk_l_coord),                                          // batch
         // ?, ?, k, N swap k and n here to match cutlass
         make_shape(_1{}, _1{}, nblock_limit/*This is N*/));
          // iter_over_head_count/* This is K*/), //(frag, iter_m, iter_n, iter_k)
         // K, ?, N (The N should move along the N as get<0>(PrefetchKThrShape) load 32 each and we want 128 of N )
         // The K should move along the dimmension of Block load as we lay 8x32 using the 8x1  shape for subgroups
         // leading to load 64x32 of (K,N) per each prefetch (BLOCK_N SHows K DIM)
        //  append<3>(make_shape(_, SG_N), BLK_N), seq<0, 1, 0>{}); // so 64 * iteration 0 (SG_N that is K which is vertical) and 32 * iteration 1 (N which is horisontal)
      // V is a transposed matrix, So here the Sequense length is consumed, it is transposed so the consumed dimension looks like B matrix
      // Hence, the Head size is the fast moving dimention and horisontal and sequence length is vertical.
     // The prefetch only move along the sequence lenth. Here we call sequence length K since it get consumed and head size N since it stay

    Tensor prefetch_iter_b = append_pvc_tensor<0>(prefetch_iter_2d_b, iter_over_head_count, BLK_N);

    Tensor prefetch_iter_2d_v = params.mainloop.gmem_prefetch_v.get_pvc_tensor(
         make_coord((sub_group_id / ATOM_N) * get<0>(PrefetchVTileSize{}), // iteration 0/K/Hight/vertical/ sequence lengh
                    head_size_coord,         //  iteration 1/N/W/Horisontal / Head size
                    blk_l_coord),
          // We loop over the consuming dimension which is the iteration 0(N) here 
         make_shape(_1{}, _1{}, _1{}));
        //  , nblock_limit),
         // first one is to use the intrinsic along the vertical , Second one is N/M  and third one is K
        //  append<3>(make_shape(_, _), BLK_K), seq<0, 1, 0>{});
    Tensor prefetch_iter_v = append_pvc_tensor<0>(prefetch_iter_2d_v, nblock_limit, BLK_K);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < k_tile_count; i++) {
      if constexpr (cute::detail::has_prefetch<typename CollectiveMainloop::GmemTiledCopyQ>) {
        prefetch(params.mainloop.gmem_tiled_copy_q, prefetch_iter_a(_, _, _, i));
      }
    }
    auto Prefetch_per_workgroup = cute::min(nblock_limit, DispatchPolicy::Stages);
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < Prefetch_per_workgroup; i++) {
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < iter_over_head_count; j++) {
        if constexpr (cute::detail::has_prefetch<typename CollectiveMainloop::GmemTiledCopyK>) {
          prefetch(params.mainloop.gmem_tiled_copy_k, prefetch_iter_b(_, _, i, j));
        }
      }
    }

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < Prefetch_per_workgroup; i++) {
      if constexpr(cute::detail::has_prefetch<typename CollectiveMainloop::GmemTiledCopyK>) {
        prefetch(params.mainloop.gmem_tiled_copy_v, prefetch_iter_v(_, _, _, i));
      }
    }

    // Allocate the tiled_mma and the accumulators for the (M,N) subgroup_shape
    TiledMma tiled_mma;
    Tensor out_reg = partition_fragment_C(tiled_mma, take<0, 2>(blk_shape));
    // the max reg and sum reg each contains a 2d tesnor for 8 x 4 This is number of sequence lenght process per subgroup
    Tensor max_reg = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>>{});
    Tensor sum_reg = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>>{});

    fill(max_reg, -INFINITY);
    clear(sum_reg);
    clear(out_reg);
    // Perform the collective scoped MMA
    CollectiveMainloop collective_mma;
    // when causal mask is true.It is not possible to set the scope
    // of the barrier to workgroup level as the number n block is
    // different for each subgroup due to triangular nature of causal based operation
    static constexpr int barrier_scope = CausalMask ? 3 : 2;

    // MAIN LOOP: loop over K and V, perform fused attention + online softmax
    for (int nblock = 0, load_idx = 0; nblock < nblock_limit; nblock++,
              load_idx += get<1>(subgroup_shape)) {
      barrier_arrive(barrier_scope);
      // 1) Load K (performed inside mmaQK)
      // 2) Create Tensor S
      auto gK = local_tile(mK_nk, blk_shape, make_coord(0, 0, _), Step<X, _1, _1>{});
      Tensor tSr = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>, Int<FragsN>>{});
      clear(tSr);

      // 3) Perform GEMM S = Q*K
      auto tile_coord_QK = make_coord(seq_coord, load_idx, _, blk_l_coord);
      collective_mma.mmaQK(tile_coord_QK, tSr, gQ, gK, tSr, head_size / get<1>(subgroup_shape), params.mainloop);

      // Apply causal mask
      if constexpr (CausalMask)
      {
        // mask the elements of each tile where j > i
        int col_idx = item_id + load_idx;
        CUTLASS_PRAGMA_UNROLL
        for (int n = 0; n < FragsN; n++, col_idx += get<1>(MmaAtomShape()))
        {
          CUTLASS_PRAGMA_UNROLL
          for (int m = 0; m < FragsM; m++)
          {
            int row_idx = m * Vec + seq_coord;
            CUTLASS_PRAGMA_UNROLL
            for (int row = 0; row < Vec; row++, row_idx++)
            {
              if (col_idx > row_idx)
                tSr(row, m, n) = -INFINITY;
            }
          }
        }
      }
      
      flash::Softmax<ElementAccumulator>::template run<CausalMask, Vec, FragsM, FragsN>(nblock == 0, tSr,
                                                                                        max_reg, sum_reg, out_reg, params.softmax);
      // 7) Convert S to P (FP32 -> BF16)
      Tensor tPr = make_tensor<typename TiledMma::ValTypeA>(shape(tSr));
      CUTLASS_PRAGMA_UNROLL
      for (int p_idx = 0; p_idx < size(tPr); p_idx++)
      {
        #ifdef __SYCL_DEVICE_ONLY__
        // Temporary patch to avoid linking in the devicelib fallback unconditionally.
        tPr(p_idx).storage = __spirv_ConvertFToBF16INTEL(tSr(p_idx));
        #else
        tPr(p_idx) = static_cast<typename TiledMma::ValTypeA>(tSr(p_idx));
        #endif
      }
      // 8) Scale out_reg with l
      // 10) Perform GEMM O = 
      auto gV = local_tile(mV_nk, blk_shape, make_coord(0, 0, _), Step< X, _1, _1>{});
      auto tile_coord_PV = make_coord(0, head_size_coord, _, blk_l_coord);
      collective_mma.mmaPV(tile_coord_PV, out_reg, tPr, gV, out_reg, 1, nblock, params.mainloop);
      if(nblock + Prefetch_per_workgroup < nblock_limit ) {
        CUTLASS_PRAGMA_UNROLL
        for (int j = 0; j < iter_over_head_count; j++) {
          if constexpr(cute::detail::has_prefetch<typename CollectiveMainloop::GmemTiledCopyK>)
            prefetch(params.mainloop.gmem_tiled_copy_k, prefetch_iter_b(_,_,nblock + Prefetch_per_workgroup, j));
        }
        prefetch(params.mainloop.gmem_tiled_copy_v, prefetch_iter_v(_,_,_,nblock + Prefetch_per_workgroup));
      }
      barrier_wait(barrier_scope);
    }

    // Reduce the sum of exponents across the subgroup before scaling/normalizing output
    flash::SumOp<ElementAccumulator> op;
    flash::Softmax<ElementAccumulator>::template subgroup_allreduce<Vec, FragsM, FragsN>(sum_reg, op);

    CollectiveEpilogue epilogue{params.epilogue, shared_storage.epilogue};

    epilogue(
      params.problem_shape, 
      blk_coord_mnkl, 
      out_reg, 
      max_reg, 
      sum_reg, 
      tiled_mma, 
      params.softmax.scale);
  }
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::kernel
