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

#include "flash_attention_v2/collective/xe_flash_attn_decode_mma.hpp"

namespace cutlass::flash_attention::kernel {

template <class ProblemShape, class CollectiveMainloop, class CollectiveSoftmaxEpilogue_, class CollectiveEpilogue, class TileScheduler_ = void>
class FMHADecode;

///////////////////////////////////////////////////////////////////////////////

template <class ProblemShape_, class CollectiveMainloop_, class CollectiveSoftmaxEpilogue_, class CollectiveEpilogue_, class TileScheduler_>
class FMHADecode {

public:
  //
  // Type Aliases
  //
  using ProblemShape = ProblemShape_;

  static_assert(rank(ProblemShape{}) == 8, "ProblemShape{} should be <batch, num_heads_q, num_heads_kv, seq_len_qo, seq_len_kv, seq_len_kv_cache, head_size_qk, head_size_vo>");

  // Mainloop derived types
  using CollectiveMainloop = CollectiveMainloop_;
  using TileShapeQK = typename CollectiveMainloop::TileShapeQK;
  using TileShapePV = typename CollectiveMainloop::TileShapePV;
  using TiledMmaQK = typename CollectiveMainloop::TiledMmaQK;
  using TiledMmaPV = typename CollectiveMainloop::TiledMmaPV;
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

  static_assert(cute::is_void_v<TileScheduler_> or cute::is_same_v<TileScheduler_, FlashDecodeIndividualScheduler>,
                "Unsupported TileScheduler for Intel PVC.");
  using TileSchedulerTag = TileScheduler_;
  using TileScheduler =
      typename detail::TileSchedulerSelector<TileScheduler_, ArchTag>::Scheduler;
  using TileSchedulerParams = typename TileScheduler::Params;

  // Epilogue derived types
  using CollectiveEpilogue = CollectiveEpilogue_;
  using ElementO = typename CollectiveEpilogue::ElementO;
  using StrideO = typename CollectiveEpilogue::StrideO;
  using ElementLSE = typename CollectiveEpilogue::ElementLSE;
  using EpilogueArguments = typename CollectiveEpilogue::Arguments;
  using EpilogueParams = typename CollectiveEpilogue::Params;
  using TileShapeOutput = typename CollectiveEpilogue::TileShapeOutput;
  using TiledMmaOutput = typename CollectiveEpilogue::TiledMmaOutput;
  static_assert(cute::is_same_v<ElementAccumulator, typename CollectiveEpilogue::ElementAccumulator>,
                "Mainloop and epilogue do not agree on accumulator value type.");

  static constexpr int SharedStorageSize = 0;

  static constexpr bool CausalMask = CollectiveMainloop::CausalMask;
  static constexpr bool PagedKV = CollectiveMainloop::PagedKV;
  static constexpr int SubgroupSize = CollectiveMainloop::SubgroupSize; // sub_group size
  static constexpr uint32_t MaxThreadsPerBlock = CollectiveMainloop::MaxThreadsPerBlock;
  using MmaAtomShape = typename CollectiveMainloop::MmaAtomShape;           // 8,16,16

  static constexpr int QK_BLK_M = CollectiveMainloop::QK_BLK_M;
  static constexpr int QK_BLK_N = CollectiveMainloop::QK_BLK_N;
  static constexpr int QK_BLK_K = CollectiveMainloop::QK_BLK_K;

  static constexpr int QK_ATOM_N = CollectiveMainloop::QK_ATOM_N;
  static constexpr int QK_ATOM_K = CollectiveMainloop::QK_ATOM_K;

  using SubgroupTileShapeQK = typename CollectiveMainloop::SubgroupTileShapeQK;
  using SubgroupTileShapePV = typename CollectiveMainloop::SubgroupTileShapePV;
  static constexpr int QK_SG_M = CollectiveMainloop::QK_SG_M;
  static constexpr int QK_SG_N = CollectiveMainloop::QK_SG_N;

  static constexpr int PV_BLK_N = get<1>(TileShapePV{});
  static constexpr int PV_BLK_K = get<2>(TileShapePV{});
  static constexpr int Epilogue_BLK_N = get<1>(TileShapeOutput{});
  static constexpr int Epilogue_BLK_K = get<2>(TileShapeOutput{});

  static constexpr int ATOM_M = CollectiveMainloop::ATOM_M;
  static constexpr int ATOM_N = CollectiveMainloop::ATOM_N;
  static constexpr int ATOM_K = CollectiveMainloop::ATOM_K;

  static constexpr auto Num_SGs = ATOM_N * ATOM_M * ATOM_K;
  static constexpr int Vec = CollectiveMainloop::Vec; // 8
  static constexpr int FragsM = CollectiveMainloop::FragsM;  // 1
  static constexpr int FragsN = CollectiveMainloop::FragsNS; // 4

  static constexpr int VSlicer = get<1>(TileShapeOutput{}) / (get<1>(TileShapePV{}) * ATOM_N);
  using AccumShape =  decltype(make_shape(Int<Vec>{}, Int<FragsM>{}, Int<get<1>(TileShapePV{}) / get<1>(MmaAtomShape())>{}, Int<VSlicer>{}));

  static_assert(FragsM == 1, "Limit the seq_len_qo to 1 MMA Atom worth of data per work-group.");

  static constexpr bool is_var_len = CollectiveMainloop::is_var_len;

  // Kernel level shared memory storage
  struct SharedStorage {
    using EpilogueTensorStorage = typename CollectiveEpilogue::TensorStorage;
    EpilogueTensorStorage epilogue;
  };

  // Device side arguments
  struct Arguments {
    gemm::GemmUniversalMode mode{};
    ProblemShape problem_shape{};
    MainloopArguments mainloop{};
    SoftmaxArguments softmax{};
    EpilogueArguments epilogue{};
    KernelHardwareInfo hw_info{};
  };

  // Kernel entry point API
  struct Params {
    gemm::GemmUniversalMode mode;
    ProblemShape problem_shape;
    MainloopParams mainloop;
    SoftmaxParams softmax;
    EpilogueParams epilogue;
    TileSchedulerParams scheduler;
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
            CollectiveEpilogue::to_underlying_arguments(args.problem_shape, args.epilogue, workspace),
            TileScheduler::to_underlying_arguments(args.problem_shape, args.hw_info, TileShapeOutput{})};
  }

  static bool can_implement(Arguments const &args) {
    bool mode_implementable = args.mode == gemm::GemmUniversalMode::kGemm or
                              (args.mode == gemm::GemmUniversalMode::kBatched && rank(ProblemShape{}) == 4);
    bool valid_page_size = !PagedKV ? true : args.mainloop.page_size >= QK_SG_N && args.mainloop.page_size % QK_SG_N == 0;
    return mode_implementable && valid_page_size;
  }

  static int get_workspace_size(Arguments const &args) { return 0; }

  static cutlass::Status initialize_workspace(Arguments const &args, void *workspace = nullptr,
                                              cudaStream_t stream = nullptr, CudaHostAdapter *cuda_adapter = nullptr) {
    return Status::kSuccess;
  }

  static dim3 get_grid_shape(Params const &params) {
    return TileScheduler::template get_grid_shape<Num_SGs>(params.scheduler);
  }

  static dim3 get_block_shape() { return dim3(MaxThreadsPerBlock, 1, 1); }

  CUTLASS_DEVICE
  Shape<int, int, int> get_sequence_length_shape(ProblemShape const& problem_shape, int const& batch) {
    if constexpr (is_var_len) {
      return cutlass::fmha::collective::apply_variable_length(select<3, 4, 5>(problem_shape), batch);
    } else {
      return select<3, 4, 5>(problem_shape);
    }
  }

  CUTLASS_DEVICE
  void operator()(Params const &params, char *smem_buf) {
    SharedStorage &shared_storage = *reinterpret_cast<SharedStorage *>(smem_buf);
    // Preconditions
    CUTE_STATIC_ASSERT(is_static<TileShapeQK>::value);
    CUTE_STATIC_ASSERT(is_static<TileShapePV>::value);
    // Separate out problem shape for convenience
    auto& batch = get<0>(params.problem_shape);
    auto& num_heads_q = get<1>(params.problem_shape);
    auto& num_heads_kv = get<2>(params.problem_shape);
    auto group_heads_q = num_heads_q / num_heads_kv;
    auto& head_size_qk = get<6>(params.problem_shape);
    auto& head_size_vo = get<7>(params.problem_shape);
    // Preconditions
    static_assert(cute::rank(StrideQ{}) == 3, "StrideQ must be rank-3: [seq_len_qo, head_size_qk, batch * num_heads_q].");
    static_assert(cute::rank(StrideK{}) == 3, "StrideK must be rank-3: [head_size_qk, seq_len_kv, batch * num_heads_kv].");
    static_assert(cute::rank(StrideV{}) == 3, "StrideV must be rank-3: [seq_len_kv, head_size_vo, batch * num_heads_kv].");

    // Assuming Tiling for cached and new key-value pairs is same and they use the same copy atom.
    static_assert(cute::is_same_v<decltype(params.mainloop.gmem_tiled_copy_k), decltype(params.mainloop.gmem_tiled_copy_k_cache)>, "Copy Atom for new and cached keys needs to be the same.");
    static_assert(cute::is_same_v<decltype(params.mainloop.gmem_tiled_copy_v), decltype(params.mainloop.gmem_tiled_copy_v_cache)>, "Copy Atom for new and cached values needs to be the same.");

    int thread_idx = int(ThreadIdxX());
    int sub_group_id = thread_idx / SubgroupSize;

    TileScheduler tile_scheduler{params.scheduler};

    CUTLASS_PRAGMA_NO_UNROLL
    for (; tile_scheduler.is_valid(); ++tile_scheduler) {
      auto blk_coord = tile_scheduler.get_block_coord(); // head_size_blk_idx, seq_len_blk_idx, batch_blk_idx, num_heads_blk_idx

      auto blk_q_coord = get<1>(blk_coord); // seq_len_q_blk_idx
      auto blk_v_coord = get<0>(blk_coord); // head_size_blk_idx
      auto batch_coord = get<2>(blk_coord); // batch_blk_idx
      auto num_heads_coord = get<3>(blk_coord); // num_heads_blk_idx

      // For variable sequence length case, batch is considered to be 1 (same as group gemm).
      // For fixed sequence length case, the l_coord is the weighted sum of both batch_coord and num_heads_coord.
      // Flash Attention implementation combines batch and num_heads to calculate the total batch_size.
      // iff is_var_len: batch_size = num_heads (as each batch would have it's own seq_len_qo and seq_len_kv)
      // iff !is_var_len: batch_size = batch * num_heads
      auto blk_l_coord = is_var_len ? num_heads_coord : batch_coord * num_heads_q + num_heads_coord;

      // Get problem shape for the current batch_blk_idx. For variable sequence length, it loads the sequence length
      // from Global memory for the given batch_blk_idx and returns the appropriate problem_shape. For fixed sequence
      // length, sequence_length_shape == select<3, 4, 5>(params.problem_shape).
      // sequence_length_shape = [seq_len_qo, seq_len_kv, seq_len_kv_cache]
      auto sequence_length_shape = get_sequence_length_shape(params.problem_shape, batch_coord);

      auto [seq_len_qo, seq_len_kv, seq_len_kv_cache] = sequence_length_shape;

      Tensor mQ_mkl = cute::get_xe_tensor(make_shape(seq_len_qo, head_size_qk, (is_var_len ? 1 : batch) * num_heads_q));   //(m,k,l)
      Tensor mK_nkl = cute::get_xe_tensor(make_shape(cute::max(seq_len_kv, seq_len_kv_cache), head_size_qk, (is_var_len ? 1 : batch) * num_heads_kv));   //(n,k,l)
      Tensor mV_nkl = cute::get_xe_tensor(make_shape(head_size_vo, cute::max(seq_len_kv, seq_len_kv_cache), (is_var_len ? 1 : batch) * num_heads_kv));   //(n,k,l)

      Tensor mQ_mk = mQ_mkl(_, _, blk_l_coord);                                                    // (m,k)
      Tensor mK_nk = mK_nkl(_, _, blk_l_coord / group_heads_q);                                    // (n,k)
      Tensor mV_nk = mV_nkl(_, _, blk_l_coord / group_heads_q);                                    // (n,k)

      auto gQ = local_tile(mQ_mk, TileShapeQK{}, make_coord(blk_q_coord, _, _), Step<_1,  X, _1>{});
      auto gK = local_tile(mK_nk, TileShapeQK{}, make_coord(_, _, _), Step<X, _1, _1>{});
      auto gV = local_tile(mV_nk, TileShapeOutput{}, make_coord(_, blk_v_coord, _), Step<X, _1, _1>{});

      auto gK_prefetch = local_tile(mK_nk, SubgroupTileShapeQK{}, make_coord(_, _, _), Step<X, _1, _1>{});
      auto gV_prefetch = local_tile(mV_nk, SubgroupTileShapePV{}, make_coord(_, _, _), Step<X, _1, _1>{});

      // Determine how many tiles are supposed to be processed using this subgroup
      const int kv_splits_new = ceil_div(seq_len_kv, QK_BLK_N);
      const int kv_splits_cache = ceil_div(seq_len_kv_cache, QK_BLK_N);
      const int kv_splits = kv_splits_new + kv_splits_cache;

      auto mainloop_params = CollectiveMainloop::get_updated_copies(params.mainloop, params.problem_shape, sequence_length_shape, batch_coord);
      // For Decode, QK_BLK_M is set to 1 MMA Atom worth of data (in our case 8), this is because seq_len_qo == 1.
      // So we need to perform atleast 1 MMA op to calculate the output properly. The size required for prefetching
      // Q is small (8 x QK_BLK_K), which leads to the use of a smaller size Prefetch Atom that throws a runtime error on
      // the device. Doing redundant prefetch for Q removes the runtime error.
      // TODO (Codeplay): Investigate the runtime error and execution stall for smaller prefetch size.
      auto tiled_prefetch_q = cute::prefetch_selector<Shape<Int<QK_BLK_M * ATOM_M>, Int<QK_BLK_K>>, Num_SGs>(mainloop_params.gmem_tiled_copy_q);
      auto tiled_prefetch_k = cute::prefetch_selector<decltype(take<1,3>(SubgroupTileShapeQK{})), Num_SGs>(mainloop_params.gmem_tiled_copy_k);
      auto tiled_prefetch_v = cute::prefetch_selector<decltype(take<1,3>(SubgroupTileShapePV{})), Num_SGs>(mainloop_params.gmem_tiled_copy_v);

      auto tiled_prefetch_k_cache = cute::prefetch_selector<decltype(take<1,3>(SubgroupTileShapeQK{})), Num_SGs>(mainloop_params.gmem_tiled_copy_k_cache);
      auto tiled_prefetch_v_cache = cute::prefetch_selector<decltype(take<1,3>(SubgroupTileShapePV{})), Num_SGs>(mainloop_params.gmem_tiled_copy_v_cache);

      auto thr_prefetch_Q = tiled_prefetch_q.get_slice(thread_idx);
      auto thr_prefetch_K = tiled_prefetch_k.get_slice(thread_idx);
      auto thr_prefetch_V = tiled_prefetch_v.get_slice(thread_idx);
      auto pQgQ = thr_prefetch_Q.partition_S(gQ);
      auto pKgK = thr_prefetch_K.partition_S(gK_prefetch);
      auto pVgV = thr_prefetch_V.partition_S(gV_prefetch);

      int kv_tile_idx = sub_group_id / ATOM_N;
      int kv_cache_tile_idx = kv_tile_idx;
      int tiles_per_page = ceil_div(mainloop_params.page_size, QK_SG_N);

      if constexpr (PagedKV) {
        if (seq_len_kv_cache != 0) {
          // get physical page idx from page table
          int curr_batch_pages = is_var_len ? mainloop_params.num_pages_per_seq[batch_coord + 1] - mainloop_params.num_pages_per_seq[batch_coord]
                                            : ceil_div(seq_len_kv_cache, mainloop_params.page_size);
          int curr_page_logical_idx = kv_tile_idx * QK_SG_N / mainloop_params.page_size;
          int batch_offset = is_var_len ? mainloop_params.num_pages_per_seq[batch_coord] : batch_coord * curr_batch_pages;
          bool valid_page = curr_page_logical_idx < curr_batch_pages;
          if (valid_page) {
            kv_cache_tile_idx = mainloop_params.ptr_page_table[
                      batch_offset +                     // page table for this batch
                      curr_page_logical_idx              // tile idx to logical page idx
                  ] * tiles_per_page +               // base block idx of physical page
                  kv_tile_idx % tiles_per_page;    // offset within page
          } else {
            kv_cache_tile_idx = curr_batch_pages * tiles_per_page; // push idx out of bounds to respect the boundary between batches
          }
        }
      }

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size<3>(pQgQ); i++) {
        prefetch(tiled_prefetch_q, pQgQ(_, _, _, i));
      }

      // The headsize for both cached and non-cached version is the same.
      // each sub-group gets a different base offset for prefetch to load it's own
      // required data for matrix K.
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < size<4>(pKgK); j++) {
        seq_len_kv_cache == 0 ? prefetch(tiled_prefetch_k, pKgK(_, _, _, kv_tile_idx, j))
                              : prefetch(tiled_prefetch_k_cache, pKgK(_, _, _, kv_cache_tile_idx, j));
      }

      // Perform the collective scoped MMA
      CollectiveMainloop collective_mma;

      ElementAccumulator max_reg = ElementAccumulator{-INFINITY};
      auto sum_reg = ElementAccumulator{0};
      Tensor out_reg = make_tensor<ElementAccumulator>(AccumShape{});
      clear(out_reg);

      auto smem = syclcompat::local_mem<ElementAccumulator[((Int<size(AccumShape{}) + 1>{}) * Num_SGs * SubgroupSize)]>();
      Tensor shmem_max_tensor = make_tensor(make_smem_ptr(smem), make_shape(Int<Num_SGs * FragsM>{}));

      bool is_KV_cache = seq_len_kv_cache != 0;

      CUTLASS_PRAGMA_UNROLL
      for(int split = 0; split < kv_splits - 1; split++) {
        int curr_kv_tile_idx = is_KV_cache ? PagedKV ? kv_cache_tile_idx : split * ATOM_M + kv_tile_idx 
                                           : (split - kv_splits_cache) * ATOM_M + kv_tile_idx;

        Tensor tSr = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>, Int<FragsN>>{});
        clear(tSr);

        // Perform GEMM S = Q*K
        collective_mma.mmaQK(tSr, gQ, gK(_, _, curr_kv_tile_idx / ATOM_M, _), tSr, ceil_div(head_size_qk, QK_BLK_K), mainloop_params, is_KV_cache, curr_kv_tile_idx % ATOM_M);

        // each sub-group gets a different base offset for prefetch to load it's own
        // required data for matrix V.
        CUTLASS_PRAGMA_UNROLL
        for(int v = 0; v < VSlicer; v++) {
          is_KV_cache ? prefetch(tiled_prefetch_v_cache, pVgV(_, _, _, v, curr_kv_tile_idx))
                      : prefetch(tiled_prefetch_v, pVgV(_, _, _, v, curr_kv_tile_idx));
        }

        bool is_next_KV_cache = split + 1 < kv_splits_cache;
        int kv_cache_next_tile_idx = kv_cache_tile_idx;
        if constexpr (PagedKV) {
          if (is_next_KV_cache) {
            int curr_batch_pages = is_var_len ? mainloop_params.num_pages_per_seq[batch_coord + 1] - mainloop_params.num_pages_per_seq[batch_coord]
                                              : ceil_div(seq_len_kv_cache, mainloop_params.page_size);
            int curr_page_logical_idx = ((split + 1) * QK_BLK_N + kv_tile_idx * QK_SG_N) / mainloop_params.page_size;
            int batch_offset = is_var_len ? mainloop_params.num_pages_per_seq[batch_coord] : batch_coord * curr_batch_pages;
            bool valid_page = curr_page_logical_idx < curr_batch_pages;
            // get physical page idx from page table
            if (valid_page) {
              kv_cache_next_tile_idx = mainloop_params.ptr_page_table[
                        batch_offset +                      // page table for this batch
                        curr_page_logical_idx               // tile idx to logical page idx
                    ] * tiles_per_page +                // base block idx of physical page
                    kv_tile_idx % tiles_per_page;     // offset within page
            } else {
              kv_cache_next_tile_idx = curr_batch_pages * tiles_per_page; // push idx out of bounds to respect the boundary between batches
            }
          }
        }

        CollectiveSoftmaxEpilogue softmax(params.softmax);
        softmax.template operator()<Num_SGs>(split == 0, tSr, max_reg, sum_reg, shmem_max_tensor, out_reg);

        collective_mma.template mmaPV<VSlicer>(out_reg, tSr, gV, out_reg, mainloop_params, is_KV_cache, curr_kv_tile_idx);

        // Prefetch the next Q tile
        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < size<3>(pQgQ); i++) {
          prefetch(tiled_prefetch_q, pQgQ(_, _, _, i));
        }

        is_KV_cache = is_next_KV_cache;
        kv_cache_tile_idx = kv_cache_next_tile_idx;
        // The headsize for both cached and non-cached version is the same.
        // each sub-group gets a different base offset for prefetch to load it's own
        // required data for matrix K.
        CUTLASS_PRAGMA_UNROLL
        for (int j = 0; j < size<4>(pKgK); j++) {
          is_KV_cache ? prefetch(tiled_prefetch_k_cache, pKgK(_, _, _, PagedKV ? kv_cache_tile_idx : (split + 1) * ATOM_M + kv_tile_idx, j))
                      : prefetch(tiled_prefetch_k, pKgK(_, _, _,(split - kv_splits_cache + 1) * ATOM_M + kv_tile_idx, j));
        }
      }

      Tensor tSr = make_tensor<ElementAccumulator>(Shape<Int<Vec>, Int<FragsM>, Int<FragsN>>{});
      clear(tSr);

      int curr_kv_tile_idx = (kv_splits_new - 1) * ATOM_M + kv_tile_idx;
      // Perform GEMM S = Q*K
      collective_mma.mmaQK(tSr, gQ, gK(_, _, kv_splits_new - 1, _), tSr, ceil_div(head_size_qk, QK_BLK_K), mainloop_params, false, kv_tile_idx);

      // each sub-group gets a different base offset for prefetch to load it's own
      // required data for matrix V.
      CUTLASS_PRAGMA_UNROLL
      for(int v = 0; v < VSlicer; v++) {
        prefetch(tiled_prefetch_v, pVgV(_, _, _, v, curr_kv_tile_idx));
      }

      if constexpr (CausalMask) {
        const int required_sgs = ceil_div(seq_len_kv, QK_SG_N);
        if(kv_tile_idx == (required_sgs % ATOM_M) - 1) {
          int column_offset = seq_len_kv - seq_len_qo + seq_len_kv_cache;
          int col_idx = (kv_tile_idx + (kv_splits_new - 1) * ATOM_M) * QK_SG_N + thread_idx % SubgroupSize;
          int row_idx = blk_q_coord * QK_SG_M; // Use Vec based on seq_len_qo
          CUTLASS_PRAGMA_UNROLL
          for (int n = 0; n < FragsN; n++, col_idx += get<1>(MmaAtomShape())) { // 4
            if (col_idx - column_offset > row_idx + seq_len_kv_cache) {
              tSr(0, 0, n) = ElementAccumulator{-INFINITY};
            }
          }
        }
      }

      if (seq_len_kv % QK_BLK_N != 0) {
        int col_idx = (kv_tile_idx + (kv_splits_new - 1) * ATOM_M) * QK_SG_N + thread_idx % SubgroupSize;
        int remainder = seq_len_kv % QK_BLK_N;
        int column_offset = (kv_splits_new - 1) * QK_BLK_N + kv_splits_cache * QK_BLK_N;
        CUTLASS_PRAGMA_UNROLL
        for (int n = 0; n < FragsN; n++, col_idx += get<1>(MmaAtomShape())) {
          if (col_idx - column_offset >= remainder) {
            tSr(0, 0, n) = ElementAccumulator{-INFINITY};
          }
        }
      }

      CollectiveSoftmaxEpilogue softmax(params.softmax);
      softmax.template operator()<Num_SGs>((kv_splits - 1) == 0, tSr, max_reg, sum_reg, shmem_max_tensor, out_reg);

      collective_mma.template mmaPV<VSlicer>(out_reg, tSr, gV, out_reg, mainloop_params, false, curr_kv_tile_idx);

      // need to apply barrier here to avoid race condition
      auto group = syclcompat::get_nd_item<1>().get_group();
      sycl::group_barrier(group);

      Tensor shmem_out_tensor = make_tensor(make_smem_ptr(smem), make_shape(Int<(size(AccumShape{})) * SubgroupSize * Num_SGs>{}));
      // write output to SLM
      int idx = (thread_idx % SubgroupSize) + (sub_group_id * out_reg.size() * SubgroupSize);
      // only the first row has actual data, rest of the rows are invalid.
      CUTLASS_PRAGMA_UNROLL
      for(int i = 0; i < Int<size(AccumShape{})>{}; i++) {
        shmem_out_tensor(idx + i * SubgroupSize) = out_reg(i);
      }

      auto epilogue_params = CollectiveEpilogue::template get_updated_copies<is_var_len>(params.epilogue, params.problem_shape, sequence_length_shape, batch_coord);
      CollectiveEpilogue epilogue{epilogue_params, shared_storage.epilogue};
      auto blk_coord_mnkl = make_coord(blk_q_coord, blk_v_coord, _, blk_l_coord);

      Tensor shmem_sum_tensor = make_tensor(make_smem_ptr(shmem_out_tensor.data() + shmem_out_tensor.size()), make_shape(Int<Num_SGs * FragsM>{}));

      epilogue(params.problem_shape, sequence_length_shape, blk_coord_mnkl, shmem_out_tensor, sum_reg, shmem_sum_tensor);
    }
  }
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::flash_attention::kernel
