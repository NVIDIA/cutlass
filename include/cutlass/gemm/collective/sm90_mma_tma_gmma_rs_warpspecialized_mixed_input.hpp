/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/numeric_conversion.h"
#include "cute/arch/cluster_sm90.hpp"
#include "cute/arch/copy_sm90.hpp"
#include "cutlass/gemm/gemm.h"
#include "cutlass/detail/dependent_false.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/detail/layout.hpp"

#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/atom/copy_traits_sm90_tma.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cute/tensor_predicate.hpp"
#include "cute/numeric/arithmetic_tuple.hpp"
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/transform/collective/sm90_wgmma_transpose.hpp"
#include "cutlass/trace.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {
using namespace cute;

/////////////////////////////////////////////////////////////////////////////////////////////////

// WarpSpecialized Mainloop that source A operand from registers
template <
  int Stages,
  class ClusterShape,
  class KernelSchedule,
  class TileShape_,
  class ElementAOptionalTuple,
  class StrideAOptionalTuple,
  class ElementBOptionalTuple,
  class StrideBOptionalTuple,
  class TiledMma_,
  class GmemTiledCopyAOptionalTuple,
  class SmemLayoutAtomAOptionalTuple,
  class SmemCopyAtomAOptionalTuple,
  class TransformA_,
  class GmemTiledCopyBOptionalTuple,
  class SmemLayoutAtomBOptionalTuple,
  class SmemCopyAtomBOptionalTuple,
  class TransformB_>
struct CollectiveMma<
    MainloopSm90TmaGmmaRmemAWarpSpecializedMixedInput<Stages, ClusterShape, KernelSchedule>,
    TileShape_,
    ElementAOptionalTuple,
    StrideAOptionalTuple,
    ElementBOptionalTuple,
    StrideBOptionalTuple,
    TiledMma_,
    GmemTiledCopyAOptionalTuple,
    SmemLayoutAtomAOptionalTuple,
    SmemCopyAtomAOptionalTuple,
    TransformA_,
    GmemTiledCopyBOptionalTuple,
    SmemLayoutAtomBOptionalTuple,
    SmemCopyAtomBOptionalTuple,
    TransformB_>
{
private:
  template <class PointerType>
  static constexpr auto
  get_logical_ptr(PointerType const* ptr) {
    if constexpr (cute::sizeof_bits_v<PointerType> < 8) {
      return subbyte_iterator<PointerType const>(ptr);
    }
    else {  
      return ptr;
    }
  }

public:
  //
  // Type Aliases
  //
  using DispatchPolicy = MainloopSm90TmaGmmaRmemAWarpSpecializedMixedInput<Stages, ClusterShape, KernelSchedule>;
  using TileShape = TileShape_;

  using ElementA = ElementAOptionalTuple;
  using ElementB = ElementBOptionalTuple;
  static constexpr bool IsATransformed = cute::sizeof_bits_v<ElementA> < cute::sizeof_bits_v<ElementB>;
  using ElementScale = void;

  using StrideA = StrideAOptionalTuple;
  using StrideB = StrideBOptionalTuple;
  using StrideScale = void;
  static constexpr int AlignmentScale = cute::Int<0>{};

  using TiledMma = TiledMma_;
  using ElementAccumulator = typename TiledMma::ValTypeC;

  using GmemTiledCopyA = GmemTiledCopyAOptionalTuple;
  using GmemTiledCopyB = GmemTiledCopyBOptionalTuple;
  using GmemTiledCopyScale = void;

  using SmemLayoutAtomA = SmemLayoutAtomAOptionalTuple;
  using SmemLayoutAtomB = SmemLayoutAtomBOptionalTuple;
  using SmemLayoutAtomScale = void; 

  using SmemCopyAtomA = SmemCopyAtomAOptionalTuple;
  using SmemCopyAtomB = SmemCopyAtomBOptionalTuple;
  using SmemCopyAtomScale = void;

  // Swap and transpose A/B for A k-major layout and B mn-major layout since WGMMA is k-major only (e.g. tf32, Fp32, Int8, Fp8 WGMMA)
  static constexpr bool IsLayoutAkBmn =
    cute::is_same_v<gemm::detail::StrideToLayoutTagA_t<StrideA>, layout::RowMajor> &&
    cute::is_same_v<gemm::detail::StrideToLayoutTagB_t<StrideB>, layout::RowMajor>;

  static constexpr bool IsInputSizeTwoBytes = sizeof(ElementA) == 2 && sizeof(ElementB) == 2;

  // We must ensure the type to be scaled goes to RF
  static constexpr bool SwapAB = !IsATransformed;
  using InternalSmemLayoutAtomA = cute::conditional_t<!SwapAB, SmemLayoutAtomA, SmemLayoutAtomB>;
  using InternalSmemLayoutAtomB = cute::conditional_t<!SwapAB, SmemLayoutAtomB, SmemLayoutAtomA>;
  using InternalSmemCopyAtomA   = cute::conditional_t<!SwapAB, SmemCopyAtomA, SmemCopyAtomB>;
  using InternalSmemCopyAtomB   = cute::conditional_t<!SwapAB, SmemCopyAtomB, SmemCopyAtomA>;
  // TMA converts f32 input to tf32 when copying from GMEM to SMEM
  // For all other types, cast to size equivalent uint type to avoid any rounding by TMA.
  static constexpr bool ConvertF32toTF32A = cute::is_same_v<float, ElementA>;
  static constexpr bool ConvertF32toTF32B = cute::is_same_v<float, ElementB>;
  using ConvertedElementA = cute::conditional_t<ConvertF32toTF32A, tfloat32_t, uint_bit_t<sizeof_bits_v<ElementA>>>;
  using ConvertedElementB = cute::conditional_t<ConvertF32toTF32B, tfloat32_t, uint_bit_t<sizeof_bits_v<ElementB>>>;
  using RealInternalElementA = cute::conditional_t<!SwapAB, ElementA, ElementB>;
  using RealInternalElementB = cute::conditional_t<!SwapAB, ElementB, ElementA>;
  using InternalElementA = cute::conditional_t<!SwapAB, ConvertedElementA, ConvertedElementB>;
  using InternalElementB = cute::conditional_t<!SwapAB, ConvertedElementB, ConvertedElementA>;
  using InternalStrideA  = cute::conditional_t<!SwapAB, StrideA, StrideB>;
  using InternalStrideB  = cute::conditional_t<!SwapAB, StrideB, StrideA>;

  using TransformA = TransformA_;
  using TransformB = TransformB_;
  using InternalTransformA  = cute::conditional_t<!SwapAB, TransformA, TransformB>;
  using InternalTransformB  = cute::conditional_t<!SwapAB, TransformB, TransformA>;

  static_assert(sizeof(InternalElementB) == 2 || 
   (cute::is_same_v<gemm::detail::StrideToLayoutTagA_t<StrideA>, layout::RowMajor> &&
    cute::is_same_v<gemm::detail::StrideToLayoutTagB_t<StrideB>, layout::ColumnMajor>), 
    "B operand after swap must be 2 bytes OR K-major.");
  static constexpr int IsSubbyteA = cute::sizeof_bits_v<InternalElementA> < 8;
  using TmaElementA = cute::conditional_t<IsSubbyteA, uint8_t, InternalElementA>;

  using ArchTag = typename DispatchPolicy::ArchTag;

  using MainloopPipeline = cutlass::PipelineTmaAsync<
                             DispatchPolicy::Stages,
                             typename DispatchPolicy::ClusterShape>;
  using PipelineState = cutlass::PipelineState<DispatchPolicy::Stages>;

  using PipelineParams = typename MainloopPipeline::Params;

  static_assert(rank(InternalSmemLayoutAtomA{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<0>(TileShape{}) % size<0>(InternalSmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(InternalSmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(rank(InternalSmemLayoutAtomB{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<1>(TileShape{}) % size<0>(InternalSmemLayoutAtomB{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(InternalSmemLayoutAtomB{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(cute::is_same_v<GmemTiledCopyA, GmemTiledCopyScale> || cute::is_same_v<GmemTiledCopyScale, void>, 
    "The TMA mcast for A must match the mcast for scales or the scale tiled copy must be void.");
  // Tile along modes in a way that maximizes the TMA box size.
  using SmemLayoutA = decltype(tile_to_shape(
      InternalSmemLayoutAtomA{},
      make_shape(shape<0>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      conditional_t< ::cutlass::gemm::detail::is_major<0,InternalStrideA>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));
  using SmemLayoutB = decltype(tile_to_shape(
      InternalSmemLayoutAtomB{},
      make_shape(shape<1>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      conditional_t< ::cutlass::gemm::detail::is_major<0,InternalStrideB>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));

  // If A mn-layout and B mn-layout, transposing B matrix since WGMMA is k-major only (e.g. tf32, fp32, fp8, int8).
  static constexpr bool IsLayoutAmnBmn =
    cute::is_same_v<gemm::detail::StrideToLayoutTagA_t<StrideA>, layout::ColumnMajor> &&
    cute::is_same_v<gemm::detail::StrideToLayoutTagB_t<StrideB>, layout::RowMajor>;
  static constexpr bool TransposeB = !IsInputSizeTwoBytes && IsLayoutAmnBmn;
  using TransposeOperandB = decltype(cutlass::transform::collective::detail::make_transpose_operand_b(
                                      0, 0, TiledMma{}, SmemLayoutB{}, InternalSmemLayoutAtomB{},
                                      InternalElementB{}, cute::bool_constant<TransposeB>{})); 

  static_assert(DispatchPolicy::Stages >= 2, "Specialization requires Stages set to value 2 or more.");
  static_assert(not cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeA>::value &&
                    cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeB>::value,
                "MMA atom must source A from rmem and B operand from smem_desc for this mainloop.");
  static_assert(cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");
  static_assert(cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");

  using GmmaSmemLayoutAtomB = decltype(transform::collective::detail::gmma_smem_transpose_or_passthrough<
      TransposeB, InternalSmemLayoutAtomB, InternalElementB>());

  // SmemLayoutB for GMMA is different from SmemLayoutB for TMA if TransposeB
  using GmmaSmemLayoutB = decltype(tile_to_shape(
      GmmaSmemLayoutAtomB{},
      make_shape(shape<1>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      conditional_t< ::cutlass::gemm::detail::is_major<0,InternalStrideB>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));

  static_assert(!SwapAB || !TransposeB, "Cannot SwapAB and TransposeB at the same time.");
  static_assert(TransposeB xor (cute::is_same_v<SmemLayoutB, GmmaSmemLayoutB>),
    "Should be same layout if not TransposeB.");
  static_assert(!TransposeB || size<1>(SmemLayoutB{}) * cute::sizeof_bits_v<InternalElementB> / 8 == 128,
    "SmemLayoutB K must be 128bytes to be transposed.");
  
  static constexpr size_t SmemAlignmentA = cutlass::detail::alignment_for_swizzle(SmemLayoutA{}); 

  static constexpr size_t SmemAlignmentB = cutlass::detail::alignment_for_swizzle(SmemLayoutB{});

  static_assert(SmemAlignmentA >= 128 and SmemAlignmentB >= 128, "Require at least 128B alignment");

  struct SharedStorage
  {
    struct TensorStorage : cute::aligned_struct<cute::max(SmemAlignmentA, SmemAlignmentB)> {
      cute::ArrayEngine<InternalElementA, cute::cosize_v<SmemLayoutA>> smem_A;
      cute::ArrayEngine<typename TiledMma::ValTypeB, cute::cosize_v<SmemLayoutB>> smem_B;
    } tensors;

    using PipelineStorage = typename MainloopPipeline::SharedStorage;
    PipelineStorage pipeline;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;
  using PipelineStorage = typename SharedStorage::PipelineStorage;

  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A = nullptr;
    StrideA dA{};
    ElementB const* ptr_B = nullptr;
    StrideB dB{};
    uint32_t mma_promotion_interval = 4;
  };

  // Device side kernel params
  struct Params {
  private:
    using Outer = CollectiveMma<DispatchPolicy, TileShape_, 
                                ElementAOptionalTuple, StrideAOptionalTuple, 
                                ElementBOptionalTuple, StrideBOptionalTuple,
                                TiledMma_, 
                                GmemTiledCopyAOptionalTuple, SmemLayoutAtomAOptionalTuple, SmemCopyAtomAOptionalTuple, 
                                TransformA,
                                GmemTiledCopyBOptionalTuple, SmemLayoutAtomBOptionalTuple, SmemCopyAtomBOptionalTuple, 
                                TransformB>;

  public:
    // Assumption: StrideA is congruent with Problem_MK
    using TMA_A = decltype(make_tma_copy<TmaElementA>(
        GmemTiledCopyA{},
        make_tensor(Outer::get_logical_ptr(static_cast<InternalElementA const*>(nullptr)), repeat_like(InternalStrideA{}, int32_t(0)), InternalStrideA{}),
        SmemLayoutA{}(_,_,cute::Int<0>{}),
        make_shape(shape<0>(TileShape{}), shape<2>(TileShape{})),
        size<1>(ClusterShape{})));  // mcast along N mode for this M load, if any
    // Assumption: StrideB is congruent with Problem_NK
    using TMA_B = decltype(make_tma_copy(
        GmemTiledCopyB{},
        make_tensor(Outer::get_logical_ptr(static_cast<InternalElementB const*>(nullptr)), repeat_like(InternalStrideB{}, int32_t(0)), InternalStrideB{}),
        SmemLayoutB{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        size<0>(ClusterShape{}))); // mcast along M mode for this N load, if any
    TMA_A tma_load_a;
    TMA_B tma_load_b;
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

    if constexpr (SwapAB) {
      M = get<1>(problem_shape_MNKL);
      N = get<0>(problem_shape_MNKL);
    }

    InternalElementA const* ptr_A;
    InternalStrideA dA;
    InternalElementB const* ptr_B;
    InternalStrideB dB;

    if constexpr (not SwapAB) {
      ptr_A = reinterpret_cast<InternalElementA const*>(args.ptr_A);
      ptr_B = reinterpret_cast<InternalElementB const*>(args.ptr_B);
      dA = args.dA;
      dB = args.dB;
    }
    else {
      ptr_A = reinterpret_cast<InternalElementA const*>(args.ptr_B);
      ptr_B = reinterpret_cast<InternalElementB const*>(args.ptr_A);
      dA = args.dB;
      dB = args.dA;
    }

    Tensor tensor_a = make_tensor(get_logical_ptr(ptr_A), make_layout(make_shape(M,K,L), dA));
    Tensor tensor_b = make_tensor(get_logical_ptr(ptr_B), make_layout(make_shape(N,K,L), dB));
    typename Params::TMA_A tma_load_a = make_tma_copy<TmaElementA>(
        GmemTiledCopyA{},
        tensor_a,
        SmemLayoutA{}(_,_,cute::Int<0>{}),
        make_shape(shape<0>(TileShape{}), shape<2>(TileShape{})),
        size<1>(ClusterShape{})); // mcast along N mode for this M load, if any
    typename Params::TMA_B tma_load_b = make_tma_copy(
        GmemTiledCopyB{},
        tensor_b,
        SmemLayoutB{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        size<0>(ClusterShape{})); // mcast along M mode for this N load, if any
    return {
      tma_load_a,
      tma_load_b
    };
  }

  template<class ProblemShape>
  CUTLASS_HOST_DEVICE static bool
  can_implement(
      ProblemShape const& problem_shape,
      [[maybe_unused]] Arguments const& args) {
    constexpr int tma_alignment_bits = 128;
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;
    
    bool implementable = true;
    constexpr int min_tma_aligned_elements_A = tma_alignment_bits / cutlass::sizeof_bits<ElementA>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_A>(cute::make_shape(M,K,L), StrideA{});
    constexpr int min_tma_aligned_elements_B = tma_alignment_bits / cutlass::sizeof_bits<ElementB>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_B>(cute::make_shape(N,K,L), StrideB{});

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for TMA.\n");
    }
    return implementable;
  }

  static constexpr int K_PIPE_MAX = DispatchPolicy::Stages;
  static constexpr uint32_t TmaTransactionBytes =
        (size<0>(SmemLayoutA{}) * size<1>(SmemLayoutA{}) * static_cast<uint32_t>(cute::sizeof_bits_v<InternalElementA>) / 8)+
        (size<0>(SmemLayoutB{}) * size<1>(SmemLayoutB{}) * static_cast<uint32_t>(cute::sizeof_bits_v<InternalElementB>) / 8);

  /// Issue Tma Descriptor Prefetch -- ideally from a single thread for best performance
  CUTLASS_DEVICE
  static void prefetch_tma_descriptors(Params const& mainloop_params) {
    cute::prefetch_tma_descriptor(mainloop_params.tma_load_a.get_tma_descriptor());
    cute::prefetch_tma_descriptor(mainloop_params.tma_load_b.get_tma_descriptor());
  }

  /// Set up the data needed by this collective for load and mma.
  /// Returns a tuple of tensors. The collective and the kernel layer have the contract
  /// that the tuple must contain at least two elements, with the first two elements being:
  /// gA_mkl - The tma tensor, A after a local tile so it has shape  (BLK_M,BLK_K,m,k,l)
  /// gB_nkl - The tma tensor, B after a local tile so it has shape  (BLK_N,BLK_K,n,k,l)
  /// The rest of the tensors can be specified as needed by this collective.
  template <class ProblemShape_MNKL,
            class TileShapeMNK>
  CUTLASS_DEVICE auto
  tile_input_tensors(ProblemShape_MNKL const& problem_shape_MNKL, Params const& mainloop_params, TileShapeMNK const& tileshape_mnk) {
    using X = Underscore;
    // Separate out problem shape for convenience
    auto [M,N,K,L] = problem_shape_MNKL;

    // TMA requires special handling of strides to deal with coord codomain mapping
    // Represent the full tensors -- get these from TMA
    Tensor mA_mkl = mainloop_params.tma_load_a.get_tma_tensor(make_shape(M,K,L));                            // (m,k,l)
    Tensor mB_nkl = mainloop_params.tma_load_b.get_tma_tensor(make_shape(N,K,L));                            // (n,k,l)

    // Make tiled views, defer the slice
    Tensor gA_mkl = local_tile(mA_mkl, tileshape_mnk, make_coord(_,_,_), Step<_1, X,_1>{});          // (BLK_M,BLK_K,m,k,l)
    Tensor gB_nkl = local_tile(mB_nkl, tileshape_mnk, make_coord(_,_,_), Step< X,_1,_1>{});          // (BLK_N,BLK_K,n,k,l)

    return cute::make_tuple(gA_mkl, gB_nkl);
  }  

  /// Perform a collective-scoped matrix multiply-accumulate
  /// Producer Perspective
  template <
    class TensorA, class TensorB,
    class KTileIterator, class BlockCoord
  >
  CUTLASS_DEVICE void
  load(
      Params const& mainloop_params,
      MainloopPipeline pipeline, 
      PipelineState smem_pipe_write,
      cute::tuple<TensorA, TensorB> const& tiled_tensors,
      BlockCoord const& blk_coord,
      KTileIterator k_tile_iter, int k_tile_count,
      int thread_idx,
      uint32_t block_rank_in_cluster,
      TensorStorage& shared_tensors) {

    using namespace cute;
    int warp_idx = canonical_warp_idx_sync();
    int warp_idx_in_warp_group  = warp_idx % 4;
    int lane_predicate = cute::elect_one_sync();

    if (warp_idx_in_warp_group == 0 and lane_predicate) {
      Tensor sA_ = make_tensor(make_smem_ptr(shared_tensors.smem_A.begin()), SmemLayoutA{});      // (BLK_M,BLK_K,PIPE)
      Tensor sB_ = make_tensor(make_smem_ptr(shared_tensors.smem_B.begin()), SmemLayoutB{});      // (BLK_N,BLK_K,PIPE)
      Tensor sA  = as_position_independent_swizzle_tensor(sA_);                                   // (BLK_M,BLK_K,PIPE)
      Tensor sB  = as_position_independent_swizzle_tensor(sB_);                                   // (BLK_N,BLK_K,PIPE)

      //
      // Prepare the TMA loads for A and B
      //
      
      constexpr uint32_t cluster_shape_x = get<0>(DispatchPolicy::ClusterShape());
      uint2 cluster_local_block_id = {block_rank_in_cluster % cluster_shape_x, block_rank_in_cluster / cluster_shape_x};

      Tensor gA_mkl = get<0>(tiled_tensors);
      Tensor gB_nkl = get<1>(tiled_tensors);

      auto block_tma_a = mainloop_params.tma_load_a.get_slice(cluster_local_block_id.y);
      auto block_tma_b = mainloop_params.tma_load_b.get_slice(cluster_local_block_id.x);

      // Partition the inputs based on the current block coordinates.
      auto [m_coord, n_coord, k_coord, l_coord] = blk_coord;
      Tensor gA = gA_mkl(_,_,m_coord,_,l_coord);                                        // (BLK_M,BLK_K,k)
      Tensor gB = gB_nkl(_,_,n_coord,_,l_coord);                                        // (BLK_N,BLK_K,k)

      // Applies the mapping from block_tma_a
      Tensor tAgA = block_tma_a.partition_S(gA);                                        // (TMA,TMA_M,TMA_K,k)
      Tensor tAsA = block_tma_a.partition_D(sA);                                        // (TMA,TMA_M,TMA_K,PIPE)

      Tensor tBgB = block_tma_b.partition_S(gB);                                        // (TMA,TMA_N,TMA_K,k)
      Tensor tBsB = block_tma_b.partition_D(sB);                                        // (TMA,TMA_N,TMA_K,PIPE)

      uint16_t mcast_mask_a = 0;
      uint16_t mcast_mask_b = 0;

      // Issue TmaLoads
      // Maps the tile -> block, value
      if constexpr (cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD_MULTICAST>) {
        auto block_layout = Layout<typename DispatchPolicy::ClusterShape>{}; // (m,n) -> block_id
        for (int n = 0; n < size<1>(block_layout); ++n) {
          mcast_mask_a |= (uint16_t(1) << block_layout(cluster_local_block_id.x,n,Int<0>{}));
        }
      }

      if constexpr (cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD_MULTICAST>) {
        auto block_layout = Layout<typename DispatchPolicy::ClusterShape>{}; // (m,n) -> block_id
        for (int m = 0; m < size<0>(block_layout); ++m) {
          mcast_mask_b |= (uint16_t(1) << block_layout(m,cluster_local_block_id.y,Int<0>{}));
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
        copy(mainloop_params.tma_load_a.with(*tma_barrier, mcast_mask_a), tAgA(_,_,_,*k_tile_iter), tAsA(_,_,_,write_stage));
        copy(mainloop_params.tma_load_b.with(*tma_barrier, mcast_mask_b), tBgB(_,_,_,*k_tile_iter), tBsB(_,_,_,write_stage));
        ++k_tile_iter;

        // Advance smem_pipe_write
        ++smem_pipe_write;
      }
    }
  }

  /// Perform a Producer Epilogue to prevent early exit of blocks in a Cluster
  CUTLASS_DEVICE void
  load_tail(MainloopPipeline pipeline, PipelineState smem_pipe_write) {
    int warp_idx = canonical_warp_idx_sync();
    int warp_idx_in_warp_group = warp_idx % 4;
    int lane_predicate = cute::elect_one_sync();

    // Issue the epilogue waits
    if (warp_idx_in_warp_group == 0 and lane_predicate) {
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
    class FrgTensorC
  >
  CUTLASS_DEVICE void
  mma(MainloopPipeline pipeline,
      PipelineState smem_pipe_read,
      FrgTensorC& accum,
      int k_tile_count,
      int thread_idx,
      TensorStorage& shared_tensors,
      Params const& mainloop_params) {
    using namespace cute;
    static_assert(is_rmem<FrgTensorC>::value, "C tensor must be rmem resident.");
    static_assert(rank(SmemLayoutA{}) == 3, "Smem layout must be rank 3.");
    static_assert(rank(SmemLayoutB{}) == 3, "Smem layout must be rank 3.");
    static_assert(rank(InternalSmemLayoutAtomA{}) == 2, "InternalSmemLayoutAtomA must be rank 2.");
    static_assert(rank(InternalSmemLayoutAtomB{}) == 2, "InternalSmemLayoutAtomB must be rank 2.");
    static_assert(!cute::is_void_v<InternalSmemCopyAtomA>,
      "SM90 GMMA mainloops must specify a non-void copy atom for RF sourced instructions.");
    static_assert(cute::is_void_v<InternalSmemCopyAtomB>,
      "SM90 GMMA mainloops cannot have a non-void copy atom for smem sourced instructions.");

    // Obtain warp index
    int warp_idx = canonical_warp_idx_sync();
    [[maybe_unused]] int warp_group_thread_idx = thread_idx % 128;
    
    Tensor sA_ = make_tensor(make_smem_ptr(shared_tensors.smem_A.begin()), SmemLayoutA{});        // (BLK_M,BLK_K,PIPE)
    Tensor sA = as_position_independent_swizzle_tensor(sA_);                                      // (BLK_M,BLK_K,PIPE)
    
    Tensor sB_ = make_tensor(make_smem_ptr(shared_tensors.smem_B.begin()), SmemLayoutB{});        // (BLK_N,BLK_K,PIPE)
    Tensor sB  = as_position_independent_swizzle_tensor(sB_);                                     // (BLK_M,BLK_K,PIPE)

    // If TransposeB, GMMA will read from transposed B layout SMEM
    Tensor gmma_sB_position_dependent = make_tensor(make_smem_ptr(shared_tensors.smem_B.begin()), 
                                          GmmaSmemLayoutB{});                                     // (BLK_N,BLK_K,PIPE)
    Tensor gmma_sB = as_position_independent_swizzle_tensor(gmma_sB_position_dependent);          // (BLK_N,BLK_K,PIPE)

    //
    // Define C accumulators and A/B partitioning
    //

    TiledMma tiled_mma;
    auto thread_mma = tiled_mma.get_thread_slice(thread_idx);
    Tensor tCsA = thread_mma.partition_A(sA);

    // Allocate fragments and descriptors
    Tensor tCrA_mma = thread_mma.partition_fragment_A(sA(_,_,Int<0>{}));                      // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tCrA_load = make_fragment_like<InternalElementA>(tCrA_mma);
    
    Tensor tCsB = thread_mma.partition_B(gmma_sB_position_dependent);                         // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tCrB = thread_mma.make_fragment_B(tCsB);                                           // (MMA,MMA_N,MMA_K,PIPE)

    //
    // Copy Atom A retiling
    //

    auto smem_tiled_copy_A = make_tiled_copy_A(InternalSmemCopyAtomA{}, tiled_mma);
    auto smem_thr_copy_A   = smem_tiled_copy_A.get_thread_slice(warp_group_thread_idx);

    Tensor tCrA_copy_view  = smem_thr_copy_A.retile_D(tCrA_load);                                       // (CPY,CPY_M,CPY_K)

    CUTE_STATIC_ASSERT_V(size<1>(tCsA) == size<1>(tCrA_copy_view));                                            // CPY_M
    CUTE_STATIC_ASSERT_V(size<2>(tCsA) == size<2>(tCrA_copy_view));                                            // CPY_K
    CUTE_STATIC_ASSERT_V(size<1>(tCrA_mma) == size<1>(accum));                                                 // MMA_M
    CUTE_STATIC_ASSERT_V(size<1>(tCsB) == size<2>(accum));                                                         // N
    CUTE_STATIC_ASSERT_V(size<2>(tCsA) == size<2>(tCsB));                                                          // K
    CUTE_STATIC_ASSERT_V(size<3>(tCsA) == size<3>(tCsB));                                                       // PIPE
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sA));                                         // PIPE
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sB));                                         // PIPE

    //
    // PIPELINED MAIN LOOP
    //

    // We release buffers to producer warps(dma load) with some mmas in flight
    PipelineState smem_pipe_release = smem_pipe_read;

    tiled_mma.accumulate_ = GMMA::ScaleOut::Zero;

    TransposeOperandB transpose = cutlass::transform::collective::detail::make_transpose_operand_b(
                                    warp_idx, warp_group_thread_idx, tiled_mma, SmemLayoutB{}, 
                                    InternalSmemLayoutAtomB{}, InternalElementB{}, 
                                    cute::bool_constant<TransposeB>{});

    warpgroup_fence_operand(accum);
    
    ConsumerToken barrier_token = {BarrierStatus::WaitAgain};
    // first k tile
    {
      barrier_token = pipeline.consumer_try_wait(smem_pipe_read);
      pipeline.consumer_wait(smem_pipe_read, barrier_token);

      int read_stage = smem_pipe_read.index();

      ++smem_pipe_read;
      barrier_token = pipeline.consumer_try_wait(smem_pipe_read);

      // copy smem->rmem for A operand
      copy(smem_tiled_copy_A, tCsA(_,_,0,read_stage), tCrA_copy_view(_,_,0));
      transform_internal_A(tCrA_load(_, _, 0), tCrA_mma(_, _, 0));
      // transpose B operand in SMEM
      transpose(sB, gmma_sB, read_stage, 0);
      
      // Unroll the K mode manually to set scale D to 1
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tCrA_load) - 1; ++k_block) {
        copy(smem_tiled_copy_A, tCsA(_,_,k_block + 1,read_stage), tCrA_copy_view(_,_,k_block + 1));
        transform_internal_A(tCrA_load(_, _, k_block + 1), tCrA_mma(_, _, k_block + 1));
        transpose.synchronize(k_block);
        transpose(sB, gmma_sB, read_stage, k_block + 1);
        warpgroup_arrive();
        // (V,M) x (V,N) => (V,M,N)
        cute::gemm(tiled_mma, tCrA_mma(_,_,k_block), tCrB(_,_,k_block,read_stage), accum);
        tiled_mma.accumulate_ = GMMA::ScaleOut::One;
        warpgroup_commit_batch();
      }

      warpgroup_wait<2>();
      
      --k_tile_count;
      if (k_tile_count > 0) {
        pipeline.consumer_wait(smem_pipe_read, barrier_token);
        copy(smem_tiled_copy_A, tCsA(_,_,0,smem_pipe_read.index()), tCrA_copy_view(_,_,0));
        transform_internal_A(tCrA_load(_, _, 0), tCrA_mma(_, _, 0));
        transpose(sB, gmma_sB, smem_pipe_read.index(), 0);
      }
      warpgroup_arrive();
      // (V,M) x (V,N) => (V,M,N)
      const int final_k = size<2>(tCrA_load) - 1;
      cute::gemm(tiled_mma, tCrA_mma(_,_, final_k), tCrB(_,_,final_k,read_stage), accum);
      tiled_mma.accumulate_ = GMMA::ScaleOut::One;
      warpgroup_commit_batch();
      warpgroup_wait<2>();
    }

    if (k_tile_count == 0) {
      return;
    }

    warpgroup_fence_operand(accum);
    // Mainloop GMMAs
    CUTLASS_PRAGMA_NO_UNROLL
    for ( ; k_tile_count > 1; --k_tile_count) {

      //
      // Compute on k_tile
      //

      int read_stage = smem_pipe_read.index();
      ++smem_pipe_read;

      warpgroup_fence_operand(accum);
      // Unroll the K mode manually to set scale D to 1
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tCrA_load); ++k_block) {
        if (k_block == 0) {
          barrier_token = pipeline.consumer_try_wait(smem_pipe_read);
        }
        if (k_block == size<2>(tCrA_load) - 1) {
          pipeline.consumer_wait(smem_pipe_read, barrier_token);
          copy(smem_tiled_copy_A, tCsA(_,_,0,smem_pipe_read.index()), tCrA_copy_view(_,_,0));
          transform_internal_A(tCrA_load(_, _, 0), tCrA_mma(_, _, 0));
          // transpose B operand in SMEM
          transpose(sB, gmma_sB, smem_pipe_read.index(), 0);
        } 
        else {
          copy(smem_tiled_copy_A, tCsA(_,_,k_block + 1,read_stage), tCrA_copy_view(_,_,k_block + 1));
          transform_internal_A(tCrA_load(_, _, k_block + 1), tCrA_mma(_, _, k_block + 1));
          // transpose B operand in SMEM
          transpose.synchronize(k_block);                                      // make transpose of k_block available
          transpose(sB, gmma_sB, read_stage, k_block + 1);
        }
        
        warpgroup_arrive();
        // (V,M) x (V,N) => (V,M,N)
        cute::gemm(tiled_mma, tCrA_mma(_,_,k_block), tCrB(_,_,k_block,read_stage), accum);
        tiled_mma.accumulate_ = GMMA::ScaleOut::One;
        warpgroup_commit_batch();
        warpgroup_wait<2>();
        if (k_block == 1) {
          // release prior barrier
          pipeline.consumer_release(smem_pipe_release);             // UNLOCK smem_pipe_release, done _computing_ on it
          ++smem_pipe_release;
        }
      }
      warpgroup_fence_operand(accum);

    }

    warpgroup_fence_operand(accum);

    {
      //
      // Compute on k_tile
      //

      int read_stage = smem_pipe_read.index();

      warpgroup_fence_operand(accum);
      
      // Unroll the K mode manually to set scale D to 1
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tCrA_load) - 1; ++k_block) {
        
        copy(smem_tiled_copy_A, tCsA(_,_,k_block + 1,read_stage), tCrA_copy_view(_,_,k_block + 1));
        transform_internal_A(tCrA_load(_, _, k_block + 1), tCrA_mma(_, _, k_block + 1));
        transpose.synchronize(k_block);                                           // make k_block transpose available
        transpose(sB, gmma_sB, read_stage, k_block + 1);
        warpgroup_arrive();
        // (V,M) x (V,N) => (V,M,N)
        cute::gemm(tiled_mma, tCrA_mma(_,_,k_block), tCrB(_,_,k_block,read_stage), accum);
        tiled_mma.accumulate_ = GMMA::ScaleOut::One;
        warpgroup_commit_batch();
        warpgroup_wait<2>();
        if (k_block == 1) {
          // release prior barrier
          pipeline.consumer_release(smem_pipe_release);             // UNLOCK smem_pipe_release, done _computing_ on it
          ++smem_pipe_release;
        }
      }
      
      warpgroup_arrive();
      // (V,M) x (V,N) => (V,M,N)
      const int final_k = size<2>(tCrA_load) - 1;
      cute::gemm(tiled_mma, tCrA_mma(_,_,final_k), tCrB(_,_,final_k,read_stage), accum);
      tiled_mma.accumulate_ = GMMA::ScaleOut::One;
      warpgroup_commit_batch();
    }

    warpgroup_fence_operand(accum);
  }
  
  /// Perform a Consumer Epilogue to release all buffers
  CUTLASS_DEVICE void
  mma_tail(MainloopPipeline pipeline, PipelineState smem_pipe_release, int k_tile_count) {
    // Prologue GMMAs
    int prologue_mma_count = 1;
    k_tile_count -= prologue_mma_count;

    smem_pipe_release.advance(k_tile_count);
    
    // Wait on all GMMAs to complete
    warpgroup_wait<0>();

    for (int count = 0; count < prologue_mma_count; ++count) {
      pipeline.consumer_release(smem_pipe_release);                 // UNLOCK smem_pipe_release, done _computing_ on it
      ++smem_pipe_release;
    }
  }

private:
  template <class Converter>
  static constexpr bool
  is_fast_converter_exact() {
    using DstType = typename Converter::result_type;
    using SrcType = typename Converter::source_type;
    
    constexpr bool IsIntToFP32Exact = cute::is_same_v<float, DstType> && 
                                      (cute::numeric_limits<SrcType>::is_integer && cute::sizeof_bits_v<SrcType> <= 16);
    
    constexpr bool IsIntToFP16orBF16Exact = (cute::is_same_v<cute::half_t, DstType> || cute::is_same_v<cute::bfloat16_t, DstType>) &&
                                            (cute::numeric_limits<SrcType>::is_integer && cute::sizeof_bits_v<SrcType> <= 8);

    return IsIntToFP32Exact || IsIntToFP16orBF16Exact;
  }

  template <class EngineIn, class EngineOut, class TensorLayout, int N = cosize_v<TensorLayout>>
  CUTLASS_DEVICE void 
  transform_internal_A(Tensor<EngineIn,TensorLayout>&& in, Tensor<EngineOut,TensorLayout>&& out) {
    /// This is an element-wise conversion where we expect both tensors to have the same layout.
    /// As a result, we can cast as a cutlass array to use the fast numeric converters without 
    /// worrying about indexing into the layout. 

    /// The inputs must be backed by registers & be statically sized so we can unroll the conversion loops.
    static_assert(is_rmem<EngineIn>::value, "Input tensor for A conversion must come from registers");
    static_assert(is_rmem<EngineOut>::value, "Output tensor for A conversion must come from registers");
    static_assert(cute::is_same_v<typename EngineIn::value_type, InternalElementA>, "Input engine must be same type as the A operand");
    static_assert(cute::is_same_v<typename EngineOut::value_type, typename TiledMma::ValTypeA>, "Output engine must be same type as the Mma input");    
    static_assert(is_static_v<TensorLayout>, "Tensor layout for the conversion must be static");

    using SrcArray = cutlass::Array<RealInternalElementA, N>;
    using DstArray = cutlass::Array<RealInternalElementB, N>;

    constexpr cutlass::FloatRoundStyle RoundStyle = cutlass::FloatRoundStyle::round_to_nearest;
    using DefaultConverterAToB = cutlass::NumericArrayConverter<RealInternalElementB, RealInternalElementA, N, RoundStyle>;
    using FastConverterAToB = cutlass::FastNumericArrayConverter<RealInternalElementB, RealInternalElementA, N, RoundStyle>;

    using ConverterAToB = cute::conditional_t<is_fast_converter_exact<FastConverterAToB>(), FastConverterAToB, DefaultConverterAToB>;

    SrcArray* src_array_ptr = reinterpret_cast<SrcArray*>(raw_pointer_cast(in.data()));
    DstArray* dst_array_ptr = reinterpret_cast<DstArray*>(raw_pointer_cast(out.data()));
    *dst_array_ptr = std::move(ConverterAToB::convert(*src_array_ptr));
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
