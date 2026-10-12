/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/gemm/gemm.h"
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/detail/dependent_false.hpp"
#include "cutlass/trace.h"
#include "cutlass/numeric_types.h"

#include "cute/arch/cluster_sm90.hpp"
#include "cute/arch/copy_sm90.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/functional.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cute/numeric/arithmetic_tuple.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {
using namespace cute;

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int Stages,
  int SchedulerPipelineStageCount,
  class ClusterShape,
  class KernelScheduleType,
  class TileShape_,
  class ElementA_,
  class StrideA_,
  class ElementB_,
  class StrideB_,
  class TiledMma_,
  class GmemTiledCopyA_,
  class SmemLayoutAtomA_,
  class SmemCopyAtomA_,
  class TransformA_,
  class GmemTiledCopyB_,
  class SmemLayoutAtomB_,
  class SmemCopyAtomB_,
  class TransformB_>
struct CollectiveMma<
    MainloopSm120ArrayTmaWarpSpecialized<Stages, SchedulerPipelineStageCount, ClusterShape, KernelScheduleType>,
    TileShape_,
    ElementA_,
    StrideA_,
    ElementB_,
    StrideB_,
    TiledMma_,
    GmemTiledCopyA_,
    SmemLayoutAtomA_,
    SmemCopyAtomA_,
    TransformA_,
    GmemTiledCopyB_,
    SmemLayoutAtomB_,
    SmemCopyAtomB_,
    TransformB_> {
  //
  // Type Aliases
  //
  using DispatchPolicy = MainloopSm120ArrayTmaWarpSpecialized<Stages, SchedulerPipelineStageCount, ClusterShape, KernelScheduleType>;
  using TileShape = TileShape_;
  using ElementA = remove_cvref_t<ElementA_>;
  // StrideA may be a pointer-to-stride (grouped GEMM) or a direct stride (batched GEMM)
  using StrideA = cute::remove_cvref_t<StrideA_>;
  using InternalStrideA = cute::remove_pointer_t<StrideA>;
  using ElementB = remove_cvref_t<ElementB_>;
  using StrideB = cute::remove_cvref_t<StrideB_>;
  using InternalStrideB = cute::remove_pointer_t<StrideB>;
  using TiledMma = TiledMma_;
  using CtaShape_MNK = decltype(shape_div(TileShape{}, ClusterShape{}));
  using ElementAccumulator = typename TiledMma::ValTypeC;
  using GmemTiledCopyA = GmemTiledCopyA_;
  using GmemTiledCopyB = GmemTiledCopyB_;
  using SmemLayoutAtomA = SmemLayoutAtomA_;
  using SmemLayoutAtomB = SmemLayoutAtomB_;
  using SmemCopyAtomA = SmemCopyAtomA_;
  using SmemCopyAtomB = SmemCopyAtomB_;
  using TransformA = TransformA_;
  using TransformB = TransformB_;
  using ArchTag = typename DispatchPolicy::ArchTag;

  using RuntimeDataTypeA = void*;
  using RuntimeDataTypeB = void*;

  static constexpr int ThreadCount = size(TiledMma{});

  using MainloopPipeline = cutlass::PipelineTmaAsync<DispatchPolicy::Stages>;
  using PipelineParams = typename MainloopPipeline::Params;
  using PipelineState  = typename cutlass::PipelineState<DispatchPolicy::Stages>;

  // TMA hardware self-signals the mbarrier; no CP_ASYNC producer_commit needed
  static constexpr int NumProducerThreadEvents = 1;

  static_assert(rank(SmemLayoutAtomA{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<0>(TileShape{}) % size<0>(SmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(rank(SmemLayoutAtomB{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<1>(TileShape{}) % size<0>(SmemLayoutAtomB{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomB{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(not cute::is_void_v<SmemCopyAtomA>,
    "SM120 mainloop must specify a copy atom for A operand smem->rmem reads.");
  static_assert(not cute::is_void_v<SmemCopyAtomB>,
    "SM120 mainloop must specify a copy atom for B operand smem->rmem reads.");

  using SmemLayoutA = decltype(tile_to_shape(
      SmemLayoutAtomA{},
      make_shape(shape<0>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      conditional_t< ::cutlass::gemm::detail::is_major<0,InternalStrideA>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));
  using SmemLayoutB = decltype(tile_to_shape(
      SmemLayoutAtomB{},
      make_shape(shape<1>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      conditional_t< ::cutlass::gemm::detail::is_major<0,InternalStrideB>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));

  static_assert(rank(SmemLayoutA{}) == 3, "Smem layout must be rank 3.");
  static_assert(rank(SmemLayoutB{}) == 3, "Smem layout must be rank 3.");
  static_assert(DispatchPolicy::Stages >= 2, "Specialization requires Stages set to value 2 or more.");

  static_assert(not cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeA>::value &&
                not cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeB>::value,
                "MMA atom must source both A and B operands from rmem for this mainloop.");
  static_assert(cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");
  static_assert(cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");

  static constexpr bool IsF8F6F4 = detail::is_sm120_f8f6f4<TiledMma, ElementA, ElementB>();

  using TmaInternalElementA = cute::conditional_t<cute::is_same_v<ElementA, float>,
                                                  cutlass::tfloat32_t,
                              cute::conditional_t<cute::is_same_v<ElementA, cutlass::float_e2m1_t>,
                                                  cutlass::detail::float_e2m1_unpacksmem_t,
                              cute::conditional_t<cute::is_same_v<ElementA, cutlass::float_e2m3_t>,
                                                cutlass::detail::float_e2m3_unpacksmem_t,
                              cute::conditional_t<cute::is_same_v<ElementA, cutlass::float_e3m2_t>,
                                                cutlass::detail::float_e3m2_unpacksmem_t,
                                                uint_bit_t<sizeof_bits_v<ElementA>>>>>>;
  using TmaInternalElementB = cute::conditional_t<cute::is_same_v<ElementB, float>,
                                                  cutlass::tfloat32_t,
                              cute::conditional_t<cute::is_same_v<ElementB, cutlass::float_e2m1_t>,
                                                  cutlass::detail::float_e2m1_unpacksmem_t,
                              cute::conditional_t<cute::is_same_v<ElementB, cutlass::float_e2m3_t>,
                                                cutlass::detail::float_e2m3_unpacksmem_t,
                              cute::conditional_t<cute::is_same_v<ElementB, cutlass::float_e3m2_t>,
                                                cutlass::detail::float_e3m2_unpacksmem_t,
                                                uint_bit_t<sizeof_bits_v<ElementB>>>>>>;

  using SmemAllocTypeA = cute::conditional_t<IsF8F6F4, uint8_t, typename TiledMma::ValTypeA>;
  using SmemAllocTypeB = cute::conditional_t<IsF8F6F4, uint8_t, typename TiledMma::ValTypeB>;

  static constexpr uint32_t TmaTransactionBytesMK = static_cast<uint32_t>(
      cutlass::bits_to_bytes(size(take<0,2>(SmemLayoutA{})) * sizeof_bits<ElementA>::value));
  static constexpr uint32_t TmaTransactionBytesNK = static_cast<uint32_t>(
      cutlass::bits_to_bytes(size(take<0,2>(SmemLayoutB{})) * sizeof_bits<ElementB>::value));
  static constexpr uint32_t TmaTransactionBytes = TmaTransactionBytesMK + TmaTransactionBytesNK;

  struct SharedStorage {
    struct TensorStorage : cute::aligned_struct<128, _0> {
      alignas(1024) cute::array_aligned<SmemAllocTypeA, cute::cosize_v<SmemLayoutA>> smem_A;
      alignas(1024) cute::array_aligned<SmemAllocTypeB, cute::cosize_v<SmemLayoutB>> smem_B;
    } tensors;

    struct TensorMapStorage : cute::aligned_struct<128, _0> {
      cute::TmaDescriptor smem_tensormap_A;
      cute::TmaDescriptor smem_tensormap_B;
    } tensormaps;

    using PipelineStorage = typename MainloopPipeline::SharedStorage;
    alignas(16) PipelineStorage pipeline_storage;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;
  using PipelineStorage = typename SharedStorage::PipelineStorage;
  using TensorMapStorage = typename SharedStorage::TensorMapStorage;

  // Grouped GEMM when stride is passed as a pointer array; batched GEMM otherwise
  static constexpr bool IsGroupedGemmKernel = !cute::is_same_v<InternalStrideA, StrideA>;

  // Host side kernel arguments
  struct Arguments {
    ElementA const** ptr_A{nullptr};
    StrideA dA{};
    ElementB const** ptr_B{nullptr};
    StrideB dB{};
  };

  // Device side kernel params
  struct Params {
    using TMA_A = decltype(make_tma_copy(
        GmemTiledCopyA{},
        make_tensor(recast_ptr<TmaInternalElementA>(nullptr), repeat_like(InternalStrideA{}, int32_t(0)), InternalStrideA{}),
        SmemLayoutA{}(_,_,0),
        make_shape(shape<0>(TileShape{}), shape<2>(TileShape{})),
        size<1>(ClusterShape{})));  // mcast along N mode for this M load, if any
    using TMA_B = decltype(make_tma_copy(
        GmemTiledCopyB{},
        make_tensor(recast_ptr<TmaInternalElementB>(nullptr), repeat_like(InternalStrideB{}, int32_t(0)), InternalStrideB{}),
        SmemLayoutB{}(_,_,0),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        size<0>(ClusterShape{})));  // mcast along M mode for this N load, if any
    TMA_A tma_load_a;
    TMA_B tma_load_b;
    uint32_t tma_transaction_bytes    = TmaTransactionBytes;
    uint32_t tma_transaction_bytes_mk = TmaTransactionBytesMK;
    uint32_t tma_transaction_bytes_nk = TmaTransactionBytesNK;
    cute::TmaDescriptor* tensormaps;
    ElementA const** ptr_A;
    StrideA dA;
    ElementB const** ptr_B;
    StrideB dB;
  };

  //
  // Methods
  //

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shapes, Arguments const& args, void* workspace) {
    (void) workspace;

    constexpr int tma_alignment_bits = 128;
    auto init_M = int32_t(tma_alignment_bits);
    auto init_N = int32_t(tma_alignment_bits);
    auto init_K = int32_t(tma_alignment_bits);
    const uint32_t init_L = 1;
    TmaInternalElementA const* ptr_A_first_batch = nullptr;
    TmaInternalElementB const* ptr_B_first_batch = nullptr;
    InternalStrideA stride_a;
    InternalStrideB stride_b;

    if constexpr (IsGroupedGemmKernel) {
      // Grouped GEMM: use dummy shape; actual shape comes from tensormaps at runtime
      stride_a = InternalStrideA{};
      stride_b = InternalStrideB{};
    }
    else {
      auto problem_shape_MNK = problem_shapes.get_host_problem_shape(0);
      init_M = get<0>(problem_shape_MNK);
      init_N = get<1>(problem_shape_MNK);
      init_K = get<2>(problem_shape_MNK);
      stride_a = args.dA;
      stride_b = args.dB;
    }

    Tensor tensor_a = make_tensor(ptr_A_first_batch, make_layout(make_shape(init_M, init_K, init_L), stride_a));
    Tensor tensor_b = make_tensor(ptr_B_first_batch, make_layout(make_shape(init_N, init_K, init_L), stride_b));

    typename Params::TMA_A tma_load_a = make_tma_copy(
        GmemTiledCopyA{},
        tensor_a,
        SmemLayoutA{}(_,_,cute::Int<0>{}),
        make_shape(shape<0>(TileShape{}), shape<2>(TileShape{})),
        size<1>(ClusterShape{}));
    typename Params::TMA_B tma_load_b = make_tma_copy(
        GmemTiledCopyB{},
        tensor_b,
        SmemLayoutB{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        size<0>(ClusterShape{}));

    return {
      tma_load_a,
      tma_load_b,
      TmaTransactionBytes,
      TmaTransactionBytesMK,
      TmaTransactionBytesNK,
      reinterpret_cast<cute::TmaDescriptor*>(workspace),
      reinterpret_cast<ElementA const**>(args.ptr_A),
      args.dA,
      reinterpret_cast<ElementB const**>(args.ptr_B),
      args.dB
    };
  }

  template <class ProblemShape>
  static size_t
  get_workspace_size(ProblemShape const& problem_shape, Arguments const& args, int sm_count) {
    constexpr uint32_t NumInputTmaTensors = 2;
    constexpr size_t SizeOfCuTensorMap = sizeof(cute::TmaDescriptor);
    return (NumInputTmaTensors * SizeOfCuTensorMap * sm_count);
  }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const& problem_shape, Arguments const& args, void* workspace,
                       cudaStream_t stream, CudaHostAdapter* cuda_adapter = nullptr) {
    return cutlass::Status::kSuccess;
  }

  template<class ProblemShape>
  static bool
  can_implement(ProblemShape problem_shapes, [[maybe_unused]] Arguments const& args) {
    constexpr int tma_alignment_bits_A = cutlass::detail::get_input_alignment_bits<ElementA, IsF8F6F4>();
    constexpr int tma_alignment_bits_B = cutlass::detail::get_input_alignment_bits<ElementB, IsF8F6F4>();
    constexpr int min_tma_aligned_elements_A = tma_alignment_bits_A / cutlass::sizeof_bits<ElementA>::value;
    constexpr int min_tma_aligned_elements_B = tma_alignment_bits_B / cutlass::sizeof_bits<ElementB>::value;

    bool implementable = true;
    if (problem_shapes.is_host_problem_shape_available()) {
      for (int i = 0; i < problem_shapes.groups(); ++i) {
        auto problem_shape_MNKL = append<4>(problem_shapes.get_host_problem_shape(i), 1);
        auto [M, N, K, L] = problem_shape_MNKL;
        implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_A>(cute::make_shape(M,K,L), InternalStrideA{});
        implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_B>(cute::make_shape(N,K,L), InternalStrideB{});

        if (!implementable) {
          CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for TMA.\n");
        }
      }
    }
    return implementable;
  }

  CUTLASS_DEVICE
  static void prefetch_tma_descriptors(Params const& mainloop_params) {
    cute::prefetch_tma_descriptor(mainloop_params.tma_load_a.get_tma_descriptor());
    cute::prefetch_tma_descriptor(mainloop_params.tma_load_b.get_tma_descriptor());
  }

  /// Returns (gA_mkl, gB_nkl) tiled tensors for the given problem shape.
  template <class ProblemShape_MNKL>
  CUTLASS_DEVICE auto
  load_init(ProblemShape_MNKL const& problem_shape_MNKL, Params const& mainloop_params) const {
    using X = Underscore;
    auto [M, N, K, L] = problem_shape_MNKL;
    const int32_t init_L = 1;  // each group is a single "batch"

    Tensor mA_mkl = mainloop_params.tma_load_a.get_tma_tensor(make_shape(M,K,init_L));
    Tensor mB_nkl = mainloop_params.tma_load_b.get_tma_tensor(make_shape(N,K,init_L));

    Tensor gA_mkl = local_tile(mA_mkl, TileShape{}, make_coord(_,_,_), Step<_1, X,_1>{});  // (BLK_M,BLK_K,m,k,l)
    Tensor gB_nkl = local_tile(mB_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});  // (BLK_N,BLK_K,n,k,l)

    return cute::make_tuple(gA_mkl, gB_nkl);
  }

  /// Producer: issue TMA loads for A and B from gmem into smem pipeline stages.
  template <
    class TensorA, class TensorB,
    class TensorMapA, class TensorMapB,
    class KTileIterator, class BlockCoord
  >
  CUTLASS_DEVICE void
  load(
      Params const& mainloop_params,
      MainloopPipeline pipeline,
      PipelineState smem_pipe_write,
      cute::tuple<TensorA, TensorB> const& load_inputs,
      cute::tuple<TensorMapA, TensorMapB> const& input_tensormaps,
      BlockCoord const& blk_coord,
      KTileIterator k_tile_iter, int k_tile_count,
      int thread_idx,
      uint32_t block_rank_in_cluster,
      TensorStorage& shared_tensors) {
    int lane_predicate = cute::elect_one_sync();

    if (lane_predicate) {
      Tensor sA = make_tensor(make_smem_ptr(shared_tensors.smem_A.data()), SmemLayoutA{});  // (BLK_M,BLK_K,PIPE)
      Tensor sB = make_tensor(make_smem_ptr(shared_tensors.smem_B.data()), SmemLayoutB{});  // (BLK_N,BLK_K,PIPE)

      constexpr uint32_t cluster_shape_x = get<0>(typename DispatchPolicy::ClusterShape());
      uint2 cluster_local_block_id = {block_rank_in_cluster % cluster_shape_x, block_rank_in_cluster / cluster_shape_x};

      Tensor gA_mkl = get<0>(load_inputs);
      Tensor gB_nkl = get<1>(load_inputs);

      auto block_tma_a = mainloop_params.tma_load_a.get_slice(cluster_local_block_id.y);
      auto block_tma_b = mainloop_params.tma_load_b.get_slice(cluster_local_block_id.x);

      auto [m_coord, n_coord, k_coord, l_coord] = blk_coord;
      Tensor gA = gA_mkl(_,_,m_coord,_,l_coord);  // (BLK_M,BLK_K,k)
      Tensor gB = gB_nkl(_,_,n_coord,_,l_coord);  // (BLK_N,BLK_K,k)

      Tensor tAgA = block_tma_a.partition_S(gA);  // (TMA,TMA_M,TMA_K,k)
      Tensor tAsA = block_tma_a.partition_D(sA);  // (TMA,TMA_M,TMA_K,PIPE)

      Tensor tBgB = block_tma_b.partition_S(gB);  // (TMA,TMA_N,TMA_K,k)
      Tensor tBsB = block_tma_b.partition_D(sB);  // (TMA,TMA_N,TMA_K,PIPE)

      Layout cta_layout_mnk = make_layout(ClusterShape{});
      auto cta_coord_mnk = cta_layout_mnk.get_flat_coord(block_rank_in_cluster);
      uint16_t mcast_mask_a = create_tma_multicast_mask<1>(cta_layout_mnk, cta_coord_mnk);
      uint16_t mcast_mask_b = create_tma_multicast_mask<0>(cta_layout_mnk, cta_coord_mnk);

      CUTLASS_PRAGMA_NO_UNROLL
      for ( ; k_tile_count > 0; --k_tile_count) {
        pipeline.producer_acquire(smem_pipe_write);

        using BarrierType = typename MainloopPipeline::ProducerBarrierType;
        BarrierType* tma_barrier = pipeline.producer_get_barrier(smem_pipe_write);

        int write_stage = smem_pipe_write.index();
        copy(mainloop_params.tma_load_a.with(get<0>(input_tensormaps), *tma_barrier, mcast_mask_a),
             tAgA(_,_,_,*k_tile_iter), tAsA(_,_,_,write_stage));
        copy(mainloop_params.tma_load_b.with(get<1>(input_tensormaps), *tma_barrier, mcast_mask_b),
             tBgB(_,_,_,*k_tile_iter), tBsB(_,_,_,write_stage));
        ++k_tile_iter;
        ++smem_pipe_write;
      }
    }
    __syncwarp();
  }

  CUTLASS_DEVICE void
  load_tail(MainloopPipeline pipeline, PipelineState smem_pipe_write) {
    int lane_predicate = cute::elect_one_sync();
    if (lane_predicate) {
      pipeline.producer_tail(smem_pipe_write);
    }
  }

  /// Consumer: perform the pipelined MMA, accumulating directly into accum.
  template <
    class FrgTensorC,
    class BlockCoord
  >
  CUTLASS_DEVICE void
  mma(MainloopPipeline pipeline,
      PipelineState smem_pipe_read,
      FrgTensorC& accum,
      int k_tile_count,
      int thread_idx,
      TensorStorage& shared_tensors,
      Params const& mainloop_params,
      [[maybe_unused]] BlockCoord& blk_crd) {
    using namespace cute;

    static_assert(is_rmem<FrgTensorC>::value, "C tensor must be rmem resident.");

    clear(accum);

    Tensor sA = make_tensor(make_smem_ptr(shared_tensors.smem_A.data()), SmemLayoutA{});  // (BLK_M,BLK_K,PIPE)
    Tensor sB = make_tensor(make_smem_ptr(shared_tensors.smem_B.data()), SmemLayoutB{});  // (BLK_N,BLK_K,PIPE)

    TiledMma tiled_mma;
    auto thread_mma = tiled_mma.get_thread_slice(thread_idx);

    Tensor tCrA = thread_mma.partition_fragment_A(sA(_,_,Int<0>{}));  // (MMA,MMA_M,MMA_K)
    Tensor tCrB = thread_mma.partition_fragment_B(sB(_,_,Int<0>{}));  // (MMA,MMA_N,MMA_K)

    auto smem_tiled_copy_A = make_tiled_copy_A(SmemCopyAtomA{}, tiled_mma);
    auto smem_thr_copy_A   = smem_tiled_copy_A.get_thread_slice(thread_idx);
    Tensor tCsA            = smem_thr_copy_A.partition_S(
      as_position_independent_swizzle_tensor(sA));                                    // (CPY,CPY_M,CPY_K,PIPE)
    Tensor tCrA_copy_view  = smem_thr_copy_A.retile_D(tCrA);                          //      (CPY,CPY_M,CPY_K)

    auto smem_tiled_copy_B = make_tiled_copy_B(SmemCopyAtomB{}, tiled_mma);
    auto smem_thr_copy_B   = smem_tiled_copy_B.get_thread_slice(thread_idx);
    Tensor tCsB            = smem_thr_copy_B.partition_S(
      as_position_independent_swizzle_tensor(sB));                                    // (CPY,CPY_N,CPY_K,PIPE)
    Tensor tCrB_copy_view  = smem_thr_copy_B.retile_D(tCrB);                          //      (CPY,CPY_N,CPY_K)

    CUTE_STATIC_ASSERT_V(size<1>(tCsA) == size<1>(tCrA_copy_view));
    CUTE_STATIC_ASSERT_V(size<2>(tCsA) == size<2>(tCrA_copy_view));
    CUTE_STATIC_ASSERT_V(size<1>(tCrA) == size<1>(accum));
    CUTE_STATIC_ASSERT_V(size<1>(tCrB) == size<2>(accum));
    CUTE_STATIC_ASSERT_V(size<2>(tCsA) == size<2>(tCsB));
    CUTE_STATIC_ASSERT_V(size<3>(tCsA) == size<3>(tCsB));
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sA));
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sB));

    auto K_BLOCK_MAX = size<2>(tCrA);

    int read_stage = smem_pipe_read.index();
    auto tCsA_stage = tCsA(_,_,_,read_stage);
    auto tCsB_stage = tCsB(_,_,_,read_stage);

    auto copy_kblock = [&](auto k_block) {
      copy(smem_tiled_copy_A, tCsA_stage(_,_,k_block), tCrA_copy_view(_,_,k_block));
      copy(smem_tiled_copy_B, tCsB_stage(_,_,k_block), tCrB_copy_view(_,_,k_block));

      using MMAOp = typename TiledMma::MMA_Op;
      fp4_shift_A(MMAOp{}, tCrA_copy_view(_,_,k_block));
      fp4_shift_B(MMAOp{}, tCrB_copy_view(_,_,k_block));
    };

    auto gemm_kblock = [&](auto k_block) {
      cute::gemm(tiled_mma, tCrA(_,_,k_block), tCrB(_,_,k_block), accum);
    };

    pipeline.consumer_wait(smem_pipe_read);
    copy_kblock(_0{});

    CUTLASS_PRAGMA_NO_UNROLL
    for ( ; k_tile_count > 1; --k_tile_count) {
      for_each(make_int_sequence<K_BLOCK_MAX>{}, [&] (auto k_block) {
        auto k_block_next = ((k_block + 1) == K_BLOCK_MAX) ? 0 : (k_block + 1);

        if (k_block == K_BLOCK_MAX - 1) {
          cutlass::arch::NamedBarrier::sync(
            thr_size(tiled_mma), cutlass::arch::ReservedNamedBarriers::Sm120MainloopBarrier);
          pipeline.consumer_release(smem_pipe_read);
          ++smem_pipe_read;
          read_stage = smem_pipe_read.index();
          tCsA_stage = tCsA(_,_,_,read_stage);
          tCsB_stage = tCsB(_,_,_,read_stage);
          pipeline.consumer_wait(smem_pipe_read);
        }

        copy_kblock(k_block_next);
        gemm_kblock(k_block);
      });
    }

    // Hoist last k_tile out of loop
    for_each(make_int_sequence<K_BLOCK_MAX>{}, [&] (auto k_block) {
      auto k_block_next = ((k_block + 1) == K_BLOCK_MAX) ? 0 : (k_block + 1);

      if (k_block == K_BLOCK_MAX - 1) {
        cutlass::arch::NamedBarrier::sync(
          thr_size(tiled_mma), cutlass::arch::ReservedNamedBarriers::Sm120MainloopBarrier);
        pipeline.consumer_release(smem_pipe_read);
        ++smem_pipe_read;
      }

      if (k_block_next > 0) {
        copy_kblock(k_block_next);
      }
      gemm_kblock(k_block);
    });
  }

  CUTLASS_DEVICE void
  mma_tail(MainloopPipeline, PipelineState, int) {}

  //
  // TMA tensormap management (required for grouped GEMM: one descriptor per SM, updated per group)
  //

  CUTLASS_DEVICE auto
  tensormaps_init(
      Params const& mainloop_params,
      TensorMapStorage& shared_tensormaps,
      int32_t sm_count,
      int32_t sm_idx) {
    cute::TmaDescriptor* gmem_tensormap = reinterpret_cast<cute::TmaDescriptor*>(mainloop_params.tensormaps);

    cute::TmaDescriptor* tma_desc_a = &gmem_tensormap[sm_idx];
    cute::TmaDescriptor* tma_desc_b = &gmem_tensormap[sm_idx + sm_count];

    if (cute::elect_one_sync()) {
      // Copy initial descriptors from params into smem for per-group modification
      Tensor pA_tensormap = make_tensor(mainloop_params.tma_load_a.get_tma_descriptor(), Int<1>{}, Int<1>{});
      Tensor sA_tensormap = make_tensor(make_smem_ptr(&shared_tensormaps.smem_tensormap_A), Int<1>{}, Int<1>{});
      Tensor pB_tensormap = make_tensor(mainloop_params.tma_load_b.get_tma_descriptor(), Int<1>{}, Int<1>{});
      Tensor sB_tensormap = make_tensor(make_smem_ptr(&shared_tensormaps.smem_tensormap_B), Int<1>{}, Int<1>{});

      copy(recast<uint128_t>(pA_tensormap), recast<uint128_t>(sA_tensormap));
      copy(recast<uint128_t>(pB_tensormap), recast<uint128_t>(sB_tensormap));
    }
    __syncwarp();
    return cute::make_tuple(tma_desc_a, tma_desc_b);
  }

  CUTLASS_DEVICE void
  tensormaps_replace_global_address(
      TensorMapStorage& shared_tensormaps,
      Params const& mainloop_params,
      int32_t next_batch) {
    cute::tma_descriptor_replace_addr_in_shared_mem(shared_tensormaps.smem_tensormap_A,
                                                    mainloop_params.ptr_A[next_batch]);
    cute::tma_descriptor_replace_addr_in_shared_mem(shared_tensormaps.smem_tensormap_B,
                                                    mainloop_params.ptr_B[next_batch]);
  }

  template <class ProblemShape_MNKL>
  CUTLASS_DEVICE void
  tensormaps_replace_global_tensor_properties(
      TensorMapStorage& shared_tensormaps,
      Params const& mainloop_params,
      int32_t next_group,
      ProblemShape_MNKL problem_shape_mnkl) {
    const uint32_t M = get<0>(problem_shape_mnkl);
    const uint32_t N = get<1>(problem_shape_mnkl);
    const uint32_t K = get<2>(problem_shape_mnkl);
    constexpr int MaxTensorRank = 5;
    cute::array<uint32_t, MaxTensorRank> prob_shape_A  = {1,1,1,1,1};
    cute::array<uint64_t, MaxTensorRank> prob_stride_A = {0,0,0,0,0};
    cute::array<uint32_t, MaxTensorRank> prob_shape_B  = {1,1,1,1,1};
    cute::array<uint64_t, MaxTensorRank> prob_stride_B = {0,0,0,0,0};

    TmaInternalElementA const* ptr_A = nullptr;
    Tensor tensor_a = make_tensor(ptr_A, make_shape(M, K, Int<1>{}), mainloop_params.dA[next_group]);

    TmaInternalElementB const* ptr_B = nullptr;
    Tensor tensor_b = make_tensor(ptr_B, make_shape(N, K, Int<1>{}), mainloop_params.dB[next_group]);

    cute::detail::fill_tma_gmem_shape_stride(mainloop_params.tma_load_a, tensor_a,
                                             prob_shape_A, prob_stride_A);
    cute::detail::fill_tma_gmem_shape_stride(mainloop_params.tma_load_b, tensor_b,
                                             prob_shape_B, prob_stride_B);

    for (uint64_t& stride : prob_stride_A) {
      stride = (stride * sizeof_bits_v<TmaInternalElementA>) / 8;
    }
    for (uint64_t& stride : prob_stride_B) {
      stride = (stride * sizeof_bits_v<TmaInternalElementB>) / 8;
    }

    cute::tma_descriptor_replace_dims_strides_in_shared_mem(shared_tensormaps.smem_tensormap_A,
                                                            prob_shape_A, prob_stride_A);
    cute::tma_descriptor_replace_dims_strides_in_shared_mem(shared_tensormaps.smem_tensormap_B,
                                                            prob_shape_B, prob_stride_B);
  }

  template <class TensorMapA, class TensorMapB, class ProblemShape_MNKL>
  CUTLASS_DEVICE void
  tensormaps_perform_update(
      TensorMapStorage& shared_tensormaps,
      Params const& mainloop_params,
      cute::tuple<TensorMapA, TensorMapB> const& input_tensormaps,
      ProblemShape_MNKL problem_shape_mnkl,
      int32_t next_batch) {
    if (cute::elect_one_sync()) {
      tensormaps_replace_global_address(shared_tensormaps, mainloop_params, next_batch);

      if constexpr (IsGroupedGemmKernel) {
        tensormaps_replace_global_tensor_properties(shared_tensormaps, mainloop_params,
                                                    next_batch, problem_shape_mnkl);
      }
    }
  }

  template <class TensorMapA, class TensorMapB>
  CUTLASS_DEVICE void
  tensormaps_cp_fence_release(
      TensorMapStorage& shared_tensormaps,
      cute::tuple<TensorMapA, TensorMapB> const& input_tensormaps) {
    if (cute::elect_one_sync()) {
      cute::tma_desc_commit_group();
      cute::tma_desc_wait_group();
    }
    // Entire warp must do this (i.e. it's aligned)
    tma_descriptor_cp_fence_release(get<0>(input_tensormaps), shared_tensormaps.smem_tensormap_A);
    tma_descriptor_cp_fence_release(get<1>(input_tensormaps), shared_tensormaps.smem_tensormap_B);
  }

  template <class TensorMapA, class TensorMapB>
  CUTLASS_DEVICE void
  tensormaps_fence_acquire(cute::tuple<TensorMapA, TensorMapB> const& input_tensormaps) {
    cute::tma_descriptor_fence_acquire(get<0>(input_tensormaps));
    cute::tma_descriptor_fence_acquire(get<1>(input_tensormaps));
  }

  template <class InputTensors, class ProblemShape_MNKL>
  CUTLASS_DEVICE InputTensors
  tensors_perform_update(
      InputTensors const& input_tensors,
      Params const& mainloop_params,
      ProblemShape_MNKL problem_shape_mnkl,
      int32_t next_batch) {
    if constexpr (IsGroupedGemmKernel) {
      return load_init(problem_shape_mnkl, mainloop_params);
    }
    else {
      return input_tensors;
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
