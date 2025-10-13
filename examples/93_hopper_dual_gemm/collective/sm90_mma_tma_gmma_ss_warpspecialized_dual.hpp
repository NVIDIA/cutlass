/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/numeric_types.h"
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/trace.h"

#include "cute/arch/cluster_sm90.hpp"
#include "cute/arch/copy_sm90.hpp"
#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cute/numeric/arithmetic_tuple.hpp"

#include "dispatch_policy_extra.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {
using namespace cute;

/////////////////////////////////////////////////////////////////////////////////////////////////

// Primary template declaration to enable partial/specialized definitions below.
template <
  class DispatchPolicy,
  class TileShape,
  class ElementA,
  class StrideA,
  class ElementB,
  class StrideB0,
  class StrideB1,
  class TiledMma,
  class GmemTiledCopyA,
  class SmemLayoutAtomsA,
  class SmemCopyAtomsA,
  class TransformA,
  class GmemTiledCopyB0,
  class SmemLayoutAtomsB0,
  class SmemCopyAtomsB0,
  class TransformB0,
  class GmemTiledCopyB1,
  class SmemLayoutAtomsB1,
  class SmemCopyAtomsB1,
  class TransformB1
>
struct DualCollectiveMma {
  static_assert(cutlass::detail::dependent_false<ElementA>, "Could not find a mainloop specialization.");
};

// WarpSpecialized Mainloop
template <
  int Stages,
  class ClusterShape,
  class KernelSchedule,
  class TileShape_,
  class ElementA_,
  class StrideA_,
  class ElementB_,
  class StrideB0_,
  class StrideB1_,
  class TiledMma_,
  class GmemTiledCopyA_,
  class SmemLayoutAtomA_,
  class SmemCopyAtomA_,
  class TransformA_,
  class GmemTiledCopyB0_,
  class SmemLayoutAtomB0_,
  class SmemCopyAtomB0_,
  class TransformB0_,
  class GmemTiledCopyB1_,
  class SmemLayoutAtomB1_,
  class SmemCopyAtomB1_,
  class TransformB1_>
struct DualCollectiveMma<
    DualMainloopSm90TmaGmmaWarpSpecialized<Stages, ClusterShape, KernelSchedule>,
    TileShape_,
    ElementA_,
    StrideA_,
    ElementB_,
    StrideB0_,
    StrideB1_,
    TiledMma_,
    GmemTiledCopyA_,
    SmemLayoutAtomA_,
    SmemCopyAtomA_,
    TransformA_,
    GmemTiledCopyB0_,
    SmemLayoutAtomB0_,
    SmemCopyAtomB0_,
    TransformB0_,
    GmemTiledCopyB1_,
    SmemLayoutAtomB1_,
    SmemCopyAtomB1_,
    TransformB1_>
{
  //
  // Type Aliases
  //
  using DispatchPolicy = DualMainloopSm90TmaGmmaWarpSpecialized<Stages, ClusterShape, KernelSchedule>;
  using TileShape = TileShape_;
  using ElementA = ElementA_;
  using StrideA = StrideA_;
  using ElementB = ElementB_;
  using StrideB0 = StrideB0_;
  using StrideB1 = StrideB1_;
  using TiledMma = TiledMma_;
  using ElementAccumulator = typename TiledMma::ValTypeC;
  using GmemTiledCopyA = GmemTiledCopyA_;
  using GmemTiledCopyB0 = GmemTiledCopyB0_;
  using GmemTiledCopyB1 = GmemTiledCopyB1_;
  using SmemLayoutAtomA = SmemLayoutAtomA_;
  using SmemLayoutAtomB0 = SmemLayoutAtomB0_;
  using SmemLayoutAtomB1 = SmemLayoutAtomB1_;
  using SmemCopyAtomA = SmemCopyAtomA_;
  using SmemCopyAtomB0 = SmemCopyAtomB0_;
  using SmemCopyAtomB1 = SmemCopyAtomB1_;
  using TransformA = TransformA_;
  using TransformB0 = TransformB0_;
  using TransformB1 = TransformB1_;
  using ArchTag = typename DispatchPolicy::ArchTag;

  using CtaShape_MNK = decltype(shape_div(TileShape{}, ClusterShape{}));
  using MainloopPipeline = cutlass::PipelineTmaAsync<DispatchPolicy::Stages>;
  using PipelineState = cutlass::PipelineState<DispatchPolicy::Stages>;

  using PipelineParams = typename MainloopPipeline::Params;

  // One threads per CTA are producers (1 for operand tile)
  static constexpr int NumProducerThreadEvents = 1;

  static_assert(cute::rank(SmemLayoutAtomA{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<0>(TileShape{}) % size<0>(SmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(cute::rank(SmemLayoutAtomB0{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<1>(TileShape{}) % size<0>(SmemLayoutAtomB0{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomB0{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(cute::rank(SmemLayoutAtomB1{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<1>(TileShape{}) % size<0>(SmemLayoutAtomB1{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomB1{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  // Tile along modes in a way that maximizes the TMA box size.
  using SmemLayoutA = decltype(tile_to_shape(
      SmemLayoutAtomA{},
      make_shape(shape<0>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      cute::conditional_t< ::cutlass::gemm::detail::is_major<0,StrideA>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));
  using SmemLayoutB0 = decltype(tile_to_shape(
      SmemLayoutAtomB0{},
      make_shape(shape<1>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      cute::conditional_t< ::cutlass::gemm::detail::is_major<0,StrideB0>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));
  using SmemLayoutB1 = decltype(tile_to_shape(
      SmemLayoutAtomB1{},
      make_shape(shape<1>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      cute::conditional_t< ::cutlass::gemm::detail::is_major<0,StrideB1>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));

  static_assert(DispatchPolicy::Stages >= 2, "Specialization requires Stages set to value 2 or more.");
  static_assert(cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeA>::value &&
                cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeB>::value,
                "MMA atom must source both A and B operand from smem_desc for this mainloop.");
  static_assert(cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");
  static_assert(cute::is_same_v<GmemTiledCopyB0, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyB0, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");
  static_assert(cute::is_same_v<GmemTiledCopyB1, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyB1, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");

  // TMA converts f32 input to tf32 when copying from GMEM to SMEM
  // For all other types, cast to size equivalent uint type to avoid any rounding by TMA.
  static constexpr bool ConvertF32toTF32A = cute::is_same_v<float, ElementA>;
  static constexpr bool ConvertF32toTF32B = cute::is_same_v<float, ElementB>;
  using InternalElementA = cute::conditional_t<ConvertF32toTF32A, tfloat32_t, uint_bit_t<sizeof_bits_v<ElementA>>>;
  using InternalElementB = cute::conditional_t<ConvertF32toTF32B, tfloat32_t, uint_bit_t<sizeof_bits_v<ElementB>>>;

  struct SharedStorage
  {
    struct TensorStorage : cute::aligned_struct<128, _0> {
      cute::array_aligned<typename TiledMma::ValTypeA, cute::cosize_v<SmemLayoutA>> smem_A;
      cute::array_aligned<typename TiledMma::ValTypeB, cute::cosize_v<SmemLayoutB0>> smem_B0;
      cute::array_aligned<typename TiledMma::ValTypeB, cute::cosize_v<SmemLayoutB1>> smem_B1;
    } tensors;

    using PipelineStorage = typename MainloopPipeline::SharedStorage;
    PipelineStorage pipeline;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;
  using PipelineStorage = typename SharedStorage::PipelineStorage;

  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A;
    StrideA dA;
    ElementB const* ptr_B0;
    StrideB0 dB0;
    ElementB const* ptr_B1;
    StrideB1 dB1;
    uint32_t mma_promotion_interval = 4;
  };

  // Device side kernel params
  struct Params {
    // Assumption: StrideA is congruent with Problem_MK
    using TMA_A = decltype(make_tma_copy_A_sm90(
        GmemTiledCopyA{},
        make_tensor(static_cast<InternalElementA const*>(nullptr), repeat_like(StrideA{}, int32_t(0)), StrideA{}),
        SmemLayoutA{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{}));
    // Assumption: StrideB0 is congruent with Problem_NK
    using TMA_B0 = decltype(make_tma_copy_B_sm90(
        GmemTiledCopyB0{},
        make_tensor(static_cast<InternalElementB const*>(nullptr), repeat_like(StrideB0{}, int32_t(0)), StrideB0{}),
        SmemLayoutB0{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{}));
    // Assumption: StrideB1 is congruent with Problem_NK
    using TMA_B1 = decltype(make_tma_copy_B_sm90(
        GmemTiledCopyB1{},
        make_tensor(static_cast<InternalElementB const*>(nullptr), repeat_like(StrideB1{}, int32_t(0)), StrideB1{}),
        SmemLayoutB1{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{}));
    TMA_A tma_load_a;
    TMA_B0 tma_load_b0;
    TMA_B1 tma_load_b1;   
    uint32_t tma_transaction_bytes = TmaTransactionBytes;
    uint32_t tma_transaction_bytes_mk = TmaTransactionBytesMK;
    uint32_t tma_transaction_bytes_nk0 = TmaTransactionBytesNK0;
    uint32_t tma_transaction_bytes_nk1 = TmaTransactionBytesNK1;
  };

  //
  // Methods
  //

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    (void) workspace;

    // Optionally append 1s until problem shape is rank-4 (MNKL), in case it is only rank-3 (MNK)
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    auto ptr_A = reinterpret_cast<InternalElementA const*>(args.ptr_A);
    auto ptr_B0 = reinterpret_cast<InternalElementB const*>(args.ptr_B0);
    auto ptr_B1 = reinterpret_cast<InternalElementB const*>(args.ptr_B1);

    Tensor tensor_a = make_tensor(ptr_A, make_layout(make_shape(M,K,L), args.dA));
    Tensor tensor_b0 = make_tensor(ptr_B0, make_layout(make_shape(N,K,L), args.dB0));
    Tensor tensor_b1 = make_tensor(ptr_B1, make_layout(make_shape(N,K,L), args.dB1));

    typename Params::TMA_A tma_load_a = make_tma_copy_A_sm90(
        GmemTiledCopyA{},
        tensor_a,
        SmemLayoutA{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{});
    typename Params::TMA_B0 tma_load_b0 = make_tma_copy_B_sm90(
        GmemTiledCopyB0{},
        tensor_b0,
        SmemLayoutB0{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{});
    typename Params::TMA_B1 tma_load_b1 = make_tma_copy_B_sm90(
        GmemTiledCopyB1{},
        tensor_b1,
        SmemLayoutB1{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{});
    uint32_t transaction_bytes_mk = TmaTransactionBytesMK;
    uint32_t transaction_bytes_nk0 = TmaTransactionBytesNK0;
    uint32_t transaction_bytes_nk1 = TmaTransactionBytesNK1;
    uint32_t transaction_bytes = transaction_bytes_mk + transaction_bytes_nk0 + transaction_bytes_nk1;

    return {
      tma_load_a,
      tma_load_b0,
      tma_load_b1,
      transaction_bytes,
      transaction_bytes_mk,
      transaction_bytes_nk0,
      transaction_bytes_nk1
    };
  }

  template<class ProblemShape>
  static bool
  can_implement(
      ProblemShape const& problem_shape,
      [[maybe_unused]] Arguments const& args) {
    constexpr int tma_alignment_bits = 128;
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    bool implementable = true;
    constexpr int min_tma_aligned_elements_A = tma_alignment_bits / cutlass::sizeof_bits<ElementA>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_A>(cute::make_shape(M,K,L), StrideA{});
    constexpr int min_tma_aligned_elements_B0 = tma_alignment_bits / cutlass::sizeof_bits<ElementB>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_B0>(cute::make_shape(N,K,L), StrideB0{});
    constexpr int min_tma_aligned_elements_B1 = tma_alignment_bits / cutlass::sizeof_bits<ElementB>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_B1>(cute::make_shape(N,K,L), StrideB1{});

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for TMA.\n");
    }
    return implementable;
  }

  static constexpr int K_PIPE_MAX = DispatchPolicy::Stages;
  static constexpr int K_PIPE_MMAS = 1;
  static constexpr uint32_t TmaTransactionBytesMK =
        cutlass::bits_to_bytes(size<0>(SmemLayoutA{}) * size<1>(SmemLayoutA{}) * static_cast<uint32_t>(sizeof_bits<ElementA>::value));
  static constexpr uint32_t TmaTransactionBytesNK0 =
        cutlass::bits_to_bytes(size<0>(SmemLayoutB0{}) * size<1>(SmemLayoutB0{}) * static_cast<uint32_t>(sizeof_bits<ElementB>::value));
  static constexpr uint32_t TmaTransactionBytesNK1 =
        cutlass::bits_to_bytes(size<0>(SmemLayoutB1{}) * size<1>(SmemLayoutB1{}) * static_cast<uint32_t>(sizeof_bits<ElementB>::value));
  static constexpr uint32_t TmaTransactionBytes = TmaTransactionBytesMK + TmaTransactionBytesNK0 + TmaTransactionBytesNK1;

  /// Issue Tma Descriptor Prefetch -- ideally from a single thread for best performance
  CUTLASS_DEVICE
  static void prefetch_tma_descriptors(Params const& mainloop_params) {
    cute::prefetch_tma_descriptor(mainloop_params.tma_load_a.get_tma_descriptor());
    cute::prefetch_tma_descriptor(mainloop_params.tma_load_b0.get_tma_descriptor());
    cute::prefetch_tma_descriptor(mainloop_params.tma_load_b1.get_tma_descriptor());
  }

  /// Set up the data needed by this collective for load and mma.
  /// Returns a tuple of tensors. The collective and the kernel layer have the contract
  /// Returned tuple must contain at least two elements, with the first two elements being:
  /// gA_mkl - The tma tensor, A after a local tile so it has shape  (BLK_M,BLK_K,m,k,l)
  /// gB_nkl - The tma tensor, B after a local tile so it has shape  (BLK_N,BLK_K,n,k,l)
  /// The rest of the tensors can be specified as needed by this collective.
  template <class ProblemShape_MNKL>
  CUTLASS_DEVICE auto
  load_init(ProblemShape_MNKL const& problem_shape_MNKL, Params const& mainloop_params) const {
    using X = Underscore;
    // Separate out problem shape for convenience
    auto [M,N,K,L] = problem_shape_MNKL;

    // TMA requires special handling of strides to deal with coord codomain mapping
    // Represent the full tensors -- get these from TMA
    Tensor mA_mkl  = mainloop_params.tma_load_a.get_tma_tensor(make_shape(M,K,L));                             // (m,k,l)
    Tensor mB0_nkl = mainloop_params.tma_load_b0.get_tma_tensor(make_shape(N,K,L));                            // (n,k,l)
    Tensor mB1_nkl = mainloop_params.tma_load_b1.get_tma_tensor(make_shape(N,K,L));                            // (n,k,l)

    // Make tiled views, defer the slice
    Tensor gA_mkl  = local_tile(mA_mkl,  TileShape{}, make_coord(_,_,_), Step<_1, X,_1>{});        // (BLK_M,BLK_K,m,k,l)
    Tensor gB0_nkl = local_tile(mB0_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});        // (BLK_N,BLK_K,n,k,l)
    Tensor gB1_nkl = local_tile(mB1_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});        // (BLK_N,BLK_K,n,k,l)

    return cute::make_tuple(gA_mkl, gB0_nkl, gB1_nkl);
  }

  /// Perform a collective-scoped matrix multiply-accumulate
  /// Producer Perspective
  template <
    class TensorA, class TensorB0, class TensorB1,
    class KTileIterator, class BlockCoord
  >
  CUTLASS_DEVICE void
  load(
      Params const& mainloop_params,
      MainloopPipeline pipeline,
      PipelineState smem_pipe_write,
      cute::tuple<TensorA, TensorB0, TensorB1> const& load_inputs,
      BlockCoord const& blk_coord,
      KTileIterator k_tile_iter, int k_tile_count,
      int thread_idx,
      uint32_t block_rank_in_cluster,
      TensorStorage& shared_tensors) {
    int lane_predicate = cute::elect_one_sync();

    if (lane_predicate) {
      Tensor sA  = make_tensor(make_smem_ptr(shared_tensors.smem_A.data()),  SmemLayoutA{});        // (BLK_M,BLK_K,PIPE)
      Tensor sB0 = make_tensor(make_smem_ptr(shared_tensors.smem_B0.data()), SmemLayoutB0{});       // (BLK_N,BLK_K,PIPE)
      Tensor sB1 = make_tensor(make_smem_ptr(shared_tensors.smem_B1.data()), SmemLayoutB1{});       // (BLK_N,BLK_K,PIPE)

      //
      // Prepare the TMA loads for A and B
      //

      constexpr uint32_t cluster_shape_x = get<0>(typename DispatchPolicy::ClusterShape());
      uint2 cluster_local_block_id = {block_rank_in_cluster % cluster_shape_x, block_rank_in_cluster / cluster_shape_x};

      Tensor gA_mkl  = get<0>(load_inputs);
      Tensor gB0_nkl = get<1>(load_inputs);
      Tensor gB1_nkl = get<2>(load_inputs);

      auto block_tma_a = mainloop_params.tma_load_a.get_slice(cluster_local_block_id.y);
      auto block_tma_b0 = mainloop_params.tma_load_b0.get_slice(cluster_local_block_id.x);
      auto block_tma_b1 = mainloop_params.tma_load_b1.get_slice(cluster_local_block_id.x);

      // Partition the inputs based on the current block coordinates.
      auto [m_coord, n_coord, k_coord, l_coord] = blk_coord;
      Tensor gA = gA_mkl(_,_,m_coord,_,l_coord);                                                      // (BLK_M,BLK_K,k)
      Tensor gB0 = gB0_nkl(_,_,n_coord,_,l_coord);                                                    // (BLK_N,BLK_K,k)
      Tensor gB1 = gB1_nkl(_,_,n_coord,_,l_coord);                                                    // (BLK_N,BLK_K,k)

      // Applies the mapping from block_tma_a
      Tensor tAgA = block_tma_a.partition_S(gA);                                                  // (TMA,TMA_M,TMA_K,k)
      Tensor tAsA = block_tma_a.partition_D(sA);                                               // (TMA,TMA_M,TMA_K,PIPE)

      Tensor tBgB0 = block_tma_b0.partition_S(gB0);                                               // (TMA,TMA_N,TMA_K,k)
      Tensor tBsB0 = block_tma_b0.partition_D(sB0);                                            // (TMA,TMA_N,TMA_K,PIPE)
      Tensor tBgB1 = block_tma_b1.partition_S(gB1);                                               // (TMA,TMA_N,TMA_K,k)
      Tensor tBsB1 = block_tma_b1.partition_D(sB1);                                            // (TMA,TMA_N,TMA_K,PIPE)

      uint16_t mcast_mask_a = 0;
      uint16_t mcast_mask_b0 = 0;
      uint16_t mcast_mask_b1 = 0;

      // Issue TmaLoads
      // Maps the tile -> block, value
      if constexpr (cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD_MULTICAST>) {
        auto block_layout = Layout<typename DispatchPolicy::ClusterShape>{}; // (m,n) -> block_id
        for (int n = 0; n < size<1>(block_layout); ++n) {
          mcast_mask_a |= (uint16_t(1) << block_layout(cluster_local_block_id.x,n,Int<0>{}));
        }
      }

      if constexpr (cute::is_same_v<GmemTiledCopyB0, SM90_TMA_LOAD_MULTICAST>) {
        auto block_layout = Layout<typename DispatchPolicy::ClusterShape>{}; // (m,n) -> block_id
        for (int m = 0; m < size<0>(block_layout); ++m) {
          mcast_mask_b0 |= (uint16_t(1) << block_layout(m,cluster_local_block_id.y,Int<0>{}));
        }
      }

      if constexpr (cute::is_same_v<GmemTiledCopyB1, SM90_TMA_LOAD_MULTICAST>) {
        auto block_layout = Layout<typename DispatchPolicy::ClusterShape>{}; // (m,n) -> block_id
        for (int m = 0; m < size<0>(block_layout); ++m) {
          mcast_mask_b1 |= (uint16_t(1) << block_layout(m,cluster_local_block_id.y,Int<0>{}));
        }
      }

      // Mainloop
      CUTLASS_PRAGMA_NO_UNROLL
      for ( ; k_tile_count > 0; --k_tile_count) {
        // LOCK smem_pipe_write for _writing_
        pipeline.producer_acquire(smem_pipe_write);

        //
        // Copy gmem to smem for *k_tile_iter
        //

        using BarrierType = typename MainloopPipeline::ProducerBarrierType;
        BarrierType* tma_barrier = pipeline.producer_get_barrier(smem_pipe_write);

        int write_stage = smem_pipe_write.index();
        copy(mainloop_params.tma_load_a.with(*tma_barrier,   mcast_mask_a),  tAgA(_,_,_,*k_tile_iter),  tAsA(_,_,_,write_stage));
        copy(mainloop_params.tma_load_b0.with(*tma_barrier, mcast_mask_b0), tBgB0(_,_,_,*k_tile_iter), tBsB0(_,_,_,write_stage));
        copy(mainloop_params.tma_load_b1.with(*tma_barrier, mcast_mask_b1), tBgB1(_,_,_,*k_tile_iter), tBsB1(_,_,_,write_stage));
        ++k_tile_iter;

        // Advance smem_pipe_write
        ++smem_pipe_write;
      }
    }
  }

  /// Perform a Producer Epilogue to prevent early exit of blocks in a Cluster
  CUTLASS_DEVICE void
  load_tail(MainloopPipeline pipeline, PipelineState smem_pipe_write) {
    int lane_predicate = cute::elect_one_sync();

    // Issue the epilogue waits
    if (lane_predicate) {
      /* This helps avoid early exit of blocks in Cluster
       * Waits for all stages to either be released (all
       * Consumer UNLOCKs), or if the stage was never used
       * then would just be acquired since the phase was
       * still inverted from make_producer_start_state
       */
      pipeline.producer_tail(smem_pipe_write);
    }
  }

  /// Perform a collective-scoped matrix multiply-accumulate
  /// Consumer Perspective
  template <
    class FrgTensorC0, class FrgTensorC1
  >
  CUTLASS_DEVICE void
  mma(MainloopPipeline pipeline,
      PipelineState smem_pipe_read,
      FrgTensorC0& accum0,
      FrgTensorC1& accum1,
      int k_tile_count,
      int thread_idx,
      TensorStorage& shared_tensors,
      Params const& mainloop_params) {
    static_assert(is_rmem<FrgTensorC0>::value, "C tensor must be rmem resident.");
    static_assert(is_rmem<FrgTensorC1>::value, "C tensor must be rmem resident.");
    static_assert(cute::rank(SmemLayoutA{}) == 3, "Smem layout must be rank 3.");
    static_assert(cute::rank(SmemLayoutB0{}) == 3, "Smem layout must be rank 3.");
    static_assert(cute::rank(SmemLayoutB1{}) == 3, "Smem layout must be rank 3.");
    static_assert(cute::is_void_v<SmemCopyAtomA>,
      "SM90 GMMA mainloops cannot have a non-void copy atom for smem sourced instructions.");
    static_assert(cute::is_void_v<SmemCopyAtomB0>,
      "SM90 GMMA mainloops cannot have a non-void copy atom for smem sourced instructions.");
    static_assert(cute::is_void_v<SmemCopyAtomB1>,
      "SM90 GMMA mainloops cannot have a non-void copy atom for smem sourced instructions.");

    Tensor sA  = make_tensor(make_smem_ptr(shared_tensors.smem_A.data()), SmemLayoutA{});          // (BLK_M,BLK_K,PIPE)
    Tensor sB0 = make_tensor(make_smem_ptr(shared_tensors.smem_B0.data()), SmemLayoutB0{});        // (BLK_N,BLK_K,PIPE)
    Tensor sB1 = make_tensor(make_smem_ptr(shared_tensors.smem_B1.data()), SmemLayoutB1{});        // (BLK_N,BLK_K,PIPE)

    //
    // Define C accumulators and A/B partitioning
    //

    // Layout of warp group to thread mapping

    static_assert(stride<0>(typename TiledMma::ALayout{}) == 0 and
                  stride<0>(typename TiledMma::BLayout{}) == 0 and
                  size<0>(typename TiledMma::ALayout{}) == NumThreadsPerWarpGroup and
                  size<0>(typename TiledMma::BLayout{}) == NumThreadsPerWarpGroup,
                  "Stride of the first mode must be 0 and the size of the mode must be NumThreadsPerWarpGroup");

    constexpr int MmaWarpGroups = size(TiledMma{}) / NumThreadsPerWarpGroup;
    Layout warp_group_thread_layout = make_layout(Int<MmaWarpGroups>{},
                                                  Int<NumThreadsPerWarpGroup>{});

    int warp_group_idx = __shfl_sync(0xFFFFFFFF, thread_idx / NumThreadsPerWarpGroup, 0);

    TiledMma tiled_mma;
    auto thread_mma = tiled_mma.get_slice(warp_group_thread_layout(warp_group_idx));

    Tensor tCsA  = thread_mma.partition_A(sA);                                                 // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tCsB0 = thread_mma.partition_B(sB0);                                                // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tCsB1 = thread_mma.partition_B(sB1);                                                // (MMA,MMA_N,MMA_K,PIPE)

    // Allocate "fragments/descriptors"
    Tensor tCrA  = thread_mma.make_fragment_A(tCsA);                                           // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tCrB0 = thread_mma.make_fragment_B(tCsB0);                                          // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tCrB1 = thread_mma.make_fragment_B(tCsB1);                                          // (MMA,MMA_N,MMA_K,PIPE)

    CUTE_STATIC_ASSERT_V(size<1>(tCsA) == size<1>(accum0));                                                         // M
    CUTE_STATIC_ASSERT_V(size<1>(tCsB0) == size<2>(accum0));                                                        // N
    CUTE_STATIC_ASSERT_V(size<1>(tCsB1) == size<2>(accum1));                                                        // N
    CUTE_STATIC_ASSERT_V(size<2>(tCsA) == size<2>(tCsB0));                                                          // K
    CUTE_STATIC_ASSERT_V(size<2>(tCsA) == size<2>(tCsB1));                                                          // K
    CUTE_STATIC_ASSERT_V(size<3>(tCsA) == size<3>(tCsB0));                                                       // PIPE
    CUTE_STATIC_ASSERT_V(size<3>(tCsA) == size<3>(tCsB1));                                                       // PIPE
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sA));                                          // PIPE
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sB0));                                         // PIPE
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sB1));                                         // PIPE

    //
    // PIPELINED MAIN LOOP
    //
    static_assert((0 <= K_PIPE_MMAS) && (K_PIPE_MMAS <  K_PIPE_MAX),
        "ERROR : Incorrect number of MMAs in flight");

    // We release buffers to producer warps(dma load) with some mmas in flight
    PipelineState smem_pipe_release = smem_pipe_read;

    // Prologue GMMAs
    int prologue_mma_count = min(K_PIPE_MMAS, k_tile_count);
    assert(k_tile_count >= 1);
    tiled_mma.accumulate_ = GMMA::ScaleOut::Zero;
    warpgroup_fence_operand(accum0);
    warpgroup_fence_operand(accum1);
    {
      // WAIT on smem_pipe_read until its data are available (phase bit flips from rdPhaseBit value)
      auto barrier_token = pipeline.consumer_try_wait(smem_pipe_read);
      pipeline.consumer_wait(smem_pipe_read, barrier_token);

      int read_stage = smem_pipe_read.index();
      warpgroup_arrive();
      tiled_mma.accumulate_ = GMMA::ScaleOut::Zero;
      // Unroll the K mode manually to set scale D to 1
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tCrA); ++k_block) {
        // (V,M,K) x (V,N,K) => (V,M,N)
        cute::gemm(tiled_mma, tCrA(_,_,k_block,read_stage), tCrB0(_,_,k_block,read_stage), accum0);
        tiled_mma.accumulate_ = GMMA::ScaleOut::One;
      }

      // Do the same for B1 on the same stage 
      tiled_mma.accumulate_ = GMMA::ScaleOut::Zero;
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tCrA); ++k_block) {
        // (V,M,K) x (V,N,K) => (V,M,N)
        cute::gemm(tiled_mma, tCrA(_,_,k_block,read_stage), tCrB1(_,_,k_block,read_stage), accum1);
        tiled_mma.accumulate_ = GMMA::ScaleOut::One;
      }

      warpgroup_commit_batch();

      ++smem_pipe_read;
    }

    tiled_mma.accumulate_ = GMMA::ScaleOut::One;

    warpgroup_fence_operand(accum0);
    warpgroup_fence_operand(accum1);
    CUTLASS_PRAGMA_UNROLL
    for (int k_tile_prologue = prologue_mma_count - 1; k_tile_prologue > 0; --k_tile_prologue) 
    {
      // WAIT on smem_pipe_read until its data are available (phase bit flips from rdPhaseBit value)
      auto barrier_token = pipeline.consumer_try_wait(smem_pipe_read);
      pipeline.consumer_wait(smem_pipe_read, barrier_token);

      int read_stage = smem_pipe_read.index();
      warpgroup_arrive();
      // (V,M,K) x (V,N,K) => (V,M,N)
      cute::gemm(tiled_mma, tCrA(_,_,_,read_stage), tCrB0(_,_,_,read_stage), accum0);
      cute::gemm(tiled_mma, tCrA(_,_,_,read_stage), tCrB1(_,_,_,read_stage), accum1);
      warpgroup_commit_batch();

      ++smem_pipe_read;
    }

    warpgroup_fence_operand(accum0);
    warpgroup_fence_operand(accum1);
    // Mainloop GMMAs
    k_tile_count -= prologue_mma_count;

    CUTLASS_PRAGMA_NO_UNROLL
    for ( ; k_tile_count > 0; --k_tile_count) 
    {
      // WAIT on smem_pipe_read until its data are available (phase bit flips from rdPhaseBit value)
      auto barrier_token = pipeline.consumer_try_wait(smem_pipe_read);
      pipeline.consumer_wait(smem_pipe_read, barrier_token);

      //
      // Compute on k_tile
      //

      int read_stage = smem_pipe_read.index();
      warpgroup_fence_operand(accum0);
      warpgroup_fence_operand(accum1);
      warpgroup_arrive();
      // (V,M,K) x (V,N,K) => (V,M,N)
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tCrA); ++k_block) {
        cute::gemm(tiled_mma, tCrA(_,_,k_block,read_stage), tCrB0(_,_,k_block,read_stage), accum0);
        cute::gemm(tiled_mma, tCrA(_,_,k_block,read_stage), tCrB1(_,_,k_block,read_stage), accum1);
      }
      warpgroup_commit_batch();

      /// Wait on the GMMA barrier for K_PIPE_MMAS (or fewer) outstanding to ensure smem_pipe_write is consumed
      warpgroup_wait<K_PIPE_MMAS>();
      warpgroup_fence_operand(accum0);
      warpgroup_fence_operand(accum1);

      // UNLOCK smem_pipe_release, done _computing_ on it
      pipeline.consumer_release(smem_pipe_release);

      // Advance smem_pipe_read and smem_pipe_release
      ++smem_pipe_read;
      ++smem_pipe_release;
    }

    warpgroup_fence_operand(accum0);
    warpgroup_fence_operand(accum1);
  }

  /// Perform a Consumer Epilogue to release all buffers
  CUTLASS_DEVICE void
  mma_tail(MainloopPipeline pipeline, PipelineState smem_pipe_release, int k_tile_count) {
    // Prologue GMMAs
    int prologue_mma_count = min(K_PIPE_MMAS, k_tile_count);
    k_tile_count -= prologue_mma_count;

    smem_pipe_release.advance(k_tile_count);

    // Wait on all GMMAs to complete
    warpgroup_wait<0>();

    for (int count = 0; count < prologue_mma_count; ++count) {
      pipeline.consumer_release(smem_pipe_release);                 // UNLOCK smem_pipe_release, done _computing_ on it
      ++smem_pipe_release;
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
