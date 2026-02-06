/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/detail/cluster.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/numeric_types.h"
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/gemm/gemm.h"
#include "cutlass/trace.h"

#include "cute/algorithm/functional.hpp"
#include "cute/arch/cluster_sm90.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cute/numeric/arithmetic_tuple.hpp"
#include "cutlass/kernel_hardware_info.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {
using namespace cute;

namespace detail {
template<class TiledMmaAPos_, class TiledMmaANeg_>
struct Sm100CollectiveMmaPlanarComplexTiledMmaType {
  using TiledMmaAPosAtom = TiledMmaAPos_;
  using TiledMmaANegAtom = TiledMmaANeg_;
};

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

// WarpSpecialized Mainloop
// Both DMA Load and MMA methods of this class must be run by a single thread that's picked by elect_one
template <
  int Stages,
  int SchedulerPipelineStageCount,
  int AccumulatorPipelineStageCount,
  class ClusterShape,
  class TileShape_,   // Static cluster shape or dynamic (int, int, _1)
  class ElementA_,    // (MmaAtomShapeM, MmaAtomShapeN, TileK)
  class StrideA_,
  class ElementB_,
  class StrideB_,
  class TiledMmaPair_,
  class GmemTiledCopyA_,
  class SmemLayoutAtomA_,
  class SmemCopyAtomA_,
  class TransformA_,
  class GmemTiledCopyB_,
  class SmemLayoutAtomB_,
  class SmemCopyAtomB_,
  class TransformB_>
struct CollectiveMma<
    MainloopSm100TmaUmmaWarpSpecializedPlanarComplex<
      Stages,
      SchedulerPipelineStageCount,
      AccumulatorPipelineStageCount,
      ClusterShape>,
    TileShape_,
    ElementA_,
    StrideA_,
    ElementB_,
    StrideB_,
    TiledMmaPair_,
    GmemTiledCopyA_,
    SmemLayoutAtomA_,
    SmemCopyAtomA_,
    TransformA_,
    GmemTiledCopyB_,
    SmemLayoutAtomB_,
    SmemCopyAtomB_,
    TransformB_>
{
  //
  // Type Aliases
  //

  // Determine MMA type: MMA_1SM vs MMA_2SM
  using TiledMmaPair = TiledMmaPair_;
  using TiledMma = typename TiledMmaPair::TiledMmaAPosAtom;
  using TiledMmaANeg = typename TiledMmaPair::TiledMmaANegAtom;
  using AtomThrShapeMNK = Shape<decltype(shape<0>(typename TiledMma::ThrLayoutVMNK{})), _1, _1>;

  static constexpr bool IsDynamicCluster = not cute::is_static_v<ClusterShape>;

  using DispatchPolicy = MainloopSm100TmaUmmaWarpSpecializedPlanarComplex<
                          Stages,
                          SchedulerPipelineStageCount,
                          AccumulatorPipelineStageCount,
                          ClusterShape>;
  using TileShape = TileShape_;

  CUTE_STATIC_ASSERT_V(evenly_divides(TileShape{}, tile_shape(TiledMma{})),
                       "Static cluster shape used: TileShape should be evenly divided by TiledMma");

  using CtaShape_MNK = decltype(shape_div(TileShape{}, AtomThrShapeMNK{}));

  // Define A and B block shapes for reduced size TMA_LOADs
  using MmaShapeA_MK = decltype(partition_shape_A(TiledMma{}, make_shape(size<0>(TileShape{}), size<2>(TileShape{}))));
  using MmaShapeB_NK = decltype(partition_shape_B(TiledMma{}, make_shape(size<1>(TileShape{}), size<2>(TileShape{}))));

  using ElementA = ElementA_;
  using ElementAMma = typename TiledMma::ValTypeA;
  using StrideA = StrideA_;
  using ElementB = ElementB_;
  using ElementBMma = typename TiledMma::ValTypeB;
  using StrideB = StrideB_;
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

  using MainloopPipeline = cutlass::PipelineTmaUmmaAsync<
                             DispatchPolicy::Stages,
                             ClusterShape,
                             AtomThrShapeMNK>;
  using MainloopPipelineState = typename MainloopPipeline::PipelineState;

  static_assert(rank(SmemLayoutAtomA{}) == 2, "SmemLayoutAtomA must be rank 2 (M, K)");
  static_assert(((size<0,0>(MmaShapeA_MK{}) * size<1>(MmaShapeA_MK{})) % size<0>(SmemLayoutAtomA{})) == 0,
      "SmemLayoutAtom must evenly divide tile shape.");
  static_assert(((size<0,1>(MmaShapeA_MK{}) * size<2>(MmaShapeA_MK{})) % size<1>(SmemLayoutAtomA{})) == 0,
      "SmemLayoutAtom must evenly divide tile shape.");
  static_assert(cute::is_void_v<SmemCopyAtomA>,
      "SM100 UMMA cannot have a non-void copy atom for smem sourced instructions.");

  static_assert(rank(SmemLayoutAtomB{}) == 2, "SmemLayoutAtomB must be rank 2 (N, K)");
  static_assert(((size<0,0>(MmaShapeB_NK{}) * size<1>(MmaShapeB_NK{})) % size<0>(SmemLayoutAtomB{})) == 0,
      "SmemLayoutAtom must evenly divide tile shape.");
  static_assert(((size<0,1>(MmaShapeB_NK{}) * size<2>(MmaShapeB_NK{})) % size<1>(SmemLayoutAtomB{})) == 0,
      "SmemLayoutAtom must evenly divide tile shape.");
  static_assert(cute::is_void_v<SmemCopyAtomB>,
      "SM100 UMMA cannot have a non-void copy atom for smem sourced instructions.");

  // Tile along K mode first before tiling over MN. PIPE mode last as usual.
  // This maximizes TMA boxes due to better smem-K vectorization, reducing total issued TMAs.
  using SmemLayoutA = decltype(UMMA::tile_to_mma_shape(
      SmemLayoutAtomA{},
      append(MmaShapeA_MK{}, Int<DispatchPolicy::Stages>{}),
      cute::conditional_t<cutlass::gemm::detail::is_mn_major<StrideA>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));
  using SmemLayoutB = decltype(UMMA::tile_to_mma_shape(
      SmemLayoutAtomB{},
      append(MmaShapeB_NK{}, Int<DispatchPolicy::Stages>{}),
      cute::conditional_t<cutlass::gemm::detail::is_mn_major<StrideB>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));

  static_assert(DispatchPolicy::Stages >= 2, "Specialization requires Stages set to value 1 or more.");
  static_assert(cute::is_base_of<cute::UMMA::DescriptorIterator, typename TiledMma::FrgTypeA>::value &&
                cute::is_base_of<cute::UMMA::DescriptorIterator, typename TiledMma::FrgTypeB>::value,
                "MMA atom must source both A and B operand from smem_desc for this mainloop.");
  static_assert(
      (size(AtomThrShapeMNK{}) == 1 &&
        (cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD_MULTICAST>)) ||
      (size(AtomThrShapeMNK{}) == 2 &&
        (cute::is_same_v<GmemTiledCopyA, SM100_TMA_2SM_LOAD> || cute::is_same_v<GmemTiledCopyA, SM100_TMA_2SM_LOAD_MULTICAST>)),
      "GmemTiledCopy - invalid TMA copy atom specified.");
  static_assert(
      (size(AtomThrShapeMNK{}) == 1 &&
        (cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD_MULTICAST>)) ||
      (size(AtomThrShapeMNK{}) == 2 &&
        (cute::is_same_v<GmemTiledCopyB, SM100_TMA_2SM_LOAD> || cute::is_same_v<GmemTiledCopyB, SM100_TMA_2SM_LOAD_MULTICAST>)),
      "GmemTiledCopy -  invalid TMA copy atom specified.");

  struct SharedStorage {
    struct TensorStorage : cute::aligned_struct<128, _0> {
      cute::ArrayEngine<ElementAMma, cute::cosize_v<SmemLayoutA>> smem_A_real;
      cute::ArrayEngine<ElementAMma, cute::cosize_v<SmemLayoutA>> smem_A_imag;
      cute::ArrayEngine<ElementBMma, cute::cosize_v<SmemLayoutB>> smem_B_real;
      cute::ArrayEngine<ElementBMma, cute::cosize_v<SmemLayoutB>> smem_B_imag;
    } tensors;

    using PipelineStorage = typename MainloopPipeline::SharedStorage;
    PipelineStorage pipeline;
  };

  // Expose shared storage for tensors/pipelines separately to allow kernel layer to reorder them.
  using TensorStorage = typename SharedStorage::TensorStorage;
  using PipelineStorage = typename SharedStorage::PipelineStorage;

  // Only one thread issues the TMA and updates the barriers in a 2SM MMA, adjust bytes accordingly
  static constexpr uint32_t TmaTransactionBytes = 2 * (
    cutlass::bits_to_bytes(size(AtomThrShapeMNK{}) * (cosize(take<0,3>(SmemLayoutA{})) * static_cast<uint32_t>(cute::sizeof_bits<ElementA>::value))) +
    cutlass::bits_to_bytes(size(AtomThrShapeMNK{}) * (cosize(take<0,3>(SmemLayoutB{})) * static_cast<uint32_t>(cute::sizeof_bits<ElementB>::value))));

  template<class AccTensor>
  struct TmemStorage {
    AccTensor accumulators;
  };

  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A_real{nullptr};
    StrideA dA_real{};
    ElementA const* ptr_A_imag{nullptr};
    StrideA dA_imag{};
    ElementB const* ptr_B_real{nullptr};
    StrideB dB_real{};
    ElementB const* ptr_B_imag{nullptr};
    StrideB dB_imag{};
  };

  template<
    class KTileCount,
    class GTensorPartitionedA, class GTensorPartitionedB,
    class STensorA, class STensorB
  >
  struct LoadParams {
    // For scheduler
    KTileCount k_tiles;
    // for input tensor values
    GTensorPartitionedA tAgA_real_mkl;
    GTensorPartitionedA tAgA_imag_mkl;
    GTensorPartitionedB tBgB_real_nkl;
    GTensorPartitionedB tBgB_imag_nkl;
    STensorA tAsA_real;
    STensorA tAsA_imag;
    STensorB tBsB_real;
    STensorB tBsB_imag;
    // for input tensor values
    uint16_t mcast_mask_a;
    uint16_t mcast_mask_b;

    CUTLASS_DEVICE
    LoadParams (
        KTileCount k_tiles_,
        GTensorPartitionedA tAgA_real_mkl_, GTensorPartitionedA tAgA_imag_mkl_,
        GTensorPartitionedB tBgB_real_nkl_, GTensorPartitionedB tBgB_imag_nkl_,
        STensorA tAsA_real_, STensorA tAsA_imag_,
        STensorB tBsB_real_, STensorB tBsB_imag_,
        uint16_t mcast_mask_a_, uint16_t mcast_mask_b_)
    : k_tiles(k_tiles_)
    , tAgA_real_mkl(tAgA_real_mkl_), tAgA_imag_mkl(tAgA_imag_mkl_)
    , tBgB_real_nkl(tBgB_real_nkl_), tBgB_imag_nkl(tBgB_imag_nkl_)
    , tAsA_real(tAsA_real_), tAsA_imag(tAsA_imag_)
    , tBsB_real(tBsB_real_), tBsB_imag(tBsB_imag_)
    , mcast_mask_a(mcast_mask_a_), mcast_mask_b(mcast_mask_b_) {}
  };

  template<class FragmentA, class FragmentB>
  struct MmaParams {
    TiledMma tiled_mma_a_pos;
    TiledMmaANeg tiled_mma_a_neg;
    FragmentA tCrA_real;
    FragmentA tCrA_imag;
    FragmentB tCrB_real;
    FragmentB tCrB_imag;

    CUTLASS_DEVICE
    MmaParams (
        TiledMma tiled_mma_a_pos_, TiledMmaANeg tiled_mma_a_neg_,
        FragmentA tCrA_real_, FragmentA tCrA_imag_,
        FragmentB tCrB_real_, FragmentB tCrB_imag_)
    : tiled_mma_a_pos(tiled_mma_a_pos_), tiled_mma_a_neg(tiled_mma_a_neg_)
    , tCrA_real(tCrA_real_), tCrA_imag(tCrA_imag_)
    , tCrB_real(tCrB_real_), tCrB_imag(tCrB_imag_) {}
  };

  // Device side kernel params
  struct Params {
    using ClusterLayout_VMNK = decltype(tiled_divide(make_layout(conditional_return<IsDynamicCluster>(make_shape(uint32_t(0), uint32_t(0), Int<1>{}), ClusterShape{})), make_tile(typename TiledMma::AtomThrID{})));

    using TMA_A = decltype(make_tma_atom_A_sm100<ElementA>(
        GmemTiledCopyA{},
        make_tensor(recast_ptr<ElementA>(nullptr), repeat_like(StrideA{}, int32_t(0)), StrideA{}),
        SmemLayoutA{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        ClusterLayout_VMNK{})
    );

    using TMA_B = decltype(make_tma_atom_B_sm100<ElementB>(
        GmemTiledCopyB{},
        make_tensor(recast_ptr<ElementB>(nullptr), repeat_like(StrideB{}, int32_t(0)), StrideB{}),
        SmemLayoutB{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        ClusterLayout_VMNK{})
    );

    TMA_A tma_load_a_real;
    TMA_A tma_load_a_imag;
    TMA_B tma_load_b_real;
    TMA_B tma_load_b_imag;
    TMA_A tma_load_a_real_fallback;
    TMA_A tma_load_a_imag_fallback;
    TMA_B tma_load_b_real_fallback;
    TMA_B tma_load_b_imag_fallback;
    dim3 cluster_shape_fallback;
  };

  CUTLASS_DEVICE
  CollectiveMma(Params const& params, ClusterShape cluster_shape, uint32_t block_rank_in_cluster)
    : cluster_shape_(cluster_shape)
    , block_rank_in_cluster_(block_rank_in_cluster) {
    if constexpr (IsDynamicCluster) {
      const bool is_fallback_cluster = (cute::size<0>(cluster_shape_) == params.cluster_shape_fallback.x &&
                                        cute::size<1>(cluster_shape_) == params.cluster_shape_fallback.y);
      observed_tma_load_a_real_ = is_fallback_cluster ? &params.tma_load_a_real_fallback : &params.tma_load_a_real;
      observed_tma_load_a_imag_ = is_fallback_cluster ? &params.tma_load_a_imag_fallback : &params.tma_load_a_imag;
      observed_tma_load_b_real_ = is_fallback_cluster ? &params.tma_load_b_real_fallback : &params.tma_load_b_real;
      observed_tma_load_b_imag_ = is_fallback_cluster ? &params.tma_load_b_imag_fallback : &params.tma_load_b_imag;
    }
    else {
      observed_tma_load_a_real_ = &params.tma_load_a_real;
      observed_tma_load_a_imag_ = &params.tma_load_a_imag;
      observed_tma_load_b_real_ = &params.tma_load_b_real;
      observed_tma_load_b_imag_ = &params.tma_load_b_imag;
    }
  }

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace, cutlass::KernelHardwareInfo const& hw_info = cutlass::KernelHardwareInfo{}) {
    (void) workspace;

    // Optionally append 1s until problem shape is rank-4 (MNKL), in case it is only rank-3 (MNK)
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    auto ptr_A_real = recast_ptr<ElementA>(args.ptr_A_real);
    auto ptr_A_imag = recast_ptr<ElementA>(args.ptr_A_imag);

    auto ptr_B_real = recast_ptr<ElementB>(args.ptr_B_real);
    auto ptr_B_imag = recast_ptr<ElementB>(args.ptr_B_imag);

    Tensor tensor_a_real = make_tensor(ptr_A_real, make_layout(make_shape(M,K,L), args.dA_real));
    Tensor tensor_a_imag = make_tensor(ptr_A_imag, make_layout(make_shape(M,K,L), args.dA_imag));

    Tensor tensor_b_real = make_tensor(ptr_B_real, make_layout(make_shape(N,K,L), args.dB_real));
    Tensor tensor_b_imag = make_tensor(ptr_B_imag, make_layout(make_shape(N,K,L), args.dB_imag));

    auto cluster_shape = cutlass::detail::select_cluster_shape(ClusterShape{}, hw_info.cluster_shape);
    // Cluster layout for TMA construction
    auto cluster_layout_vmnk = tiled_divide(make_layout(cluster_shape), make_tile(typename TiledMma::AtomThrID{}));

    auto cluster_shape_fallback = conditional_return<IsDynamicCluster>(make_shape(hw_info.cluster_shape_fallback.x, hw_info.cluster_shape_fallback.y, Int<1>{}), ClusterShape{});
    // Cluster layout for TMA construction
    auto cluster_layout_vmnk_fallback = tiled_divide(make_layout(cluster_shape_fallback), make_tile(typename TiledMma::AtomThrID{}));

    typename Params::TMA_A tma_load_a_real = make_tma_atom_A_sm100<ElementA>(
        GmemTiledCopyA{},
        tensor_a_real,
        SmemLayoutA{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        cluster_layout_vmnk);

    typename Params::TMA_A tma_load_a_imag = make_tma_atom_A_sm100<ElementA>(
        GmemTiledCopyA{},
        tensor_a_imag,
        SmemLayoutA{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        cluster_layout_vmnk);

    typename Params::TMA_B tma_load_b_real = make_tma_atom_B_sm100<ElementB>(
        GmemTiledCopyB{},
        tensor_b_real,
        SmemLayoutB{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        cluster_layout_vmnk);

    typename Params::TMA_B tma_load_b_imag = make_tma_atom_B_sm100<ElementB>(
        GmemTiledCopyB{},
        tensor_b_imag,
        SmemLayoutB{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        cluster_layout_vmnk);

    typename Params::TMA_A tma_load_a_real_fallback = make_tma_atom_A_sm100<ElementA>(
        GmemTiledCopyA{},
        tensor_a_real,
        SmemLayoutA{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        cluster_layout_vmnk_fallback);

    typename Params::TMA_A tma_load_a_imag_fallback = make_tma_atom_A_sm100<ElementA>(
        GmemTiledCopyA{},
        tensor_a_imag,
        SmemLayoutA{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        cluster_layout_vmnk_fallback);

    typename Params::TMA_B tma_load_b_real_fallback = make_tma_atom_B_sm100<ElementB>(
        GmemTiledCopyB{},
        tensor_b_real,
        SmemLayoutB{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        cluster_layout_vmnk_fallback);

    typename Params::TMA_B tma_load_b_imag_fallback = make_tma_atom_B_sm100<ElementB>(
        GmemTiledCopyB{},
        tensor_b_imag,
        SmemLayoutB{}(_,_,_,cute::Int<0>{}),
        TileShape{},
        TiledMma{},
        cluster_layout_vmnk_fallback);

    return {
      tma_load_a_real,
      tma_load_a_imag,
      tma_load_b_real,
      tma_load_b_imag,
      tma_load_a_real_fallback,
      tma_load_a_imag_fallback,
      tma_load_b_real_fallback,
      tma_load_b_imag_fallback,
      hw_info.cluster_shape_fallback
    };
  }

  template <class ProblemShape>
  static bool
  can_implement(
      ProblemShape const& problem_shape,
      [[maybe_unused]] Arguments const& args) {
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    bool implementable = true;
    constexpr int min_tma_aligned_elements_A = 128 / cute::sizeof_bits<ElementA>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_A>(cute::make_shape(M,K,L), StrideA{});
    constexpr int min_tma_aligned_elements_B = 128 / cute::sizeof_bits<ElementB>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_B>(cute::make_shape(N,K,L), StrideB{});

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for TMA.\n");
    }
    return implementable;
  }

  /// Issue Tma Descriptor Prefetch -- ideally from a single thread for best performance
  CUTLASS_DEVICE void
  prefetch_tma_descriptors() {
    cute::prefetch_tma_descriptor(observed_tma_load_a_real_->get_tma_descriptor());
    cute::prefetch_tma_descriptor(observed_tma_load_a_imag_->get_tma_descriptor());
    cute::prefetch_tma_descriptor(observed_tma_load_b_real_->get_tma_descriptor());
    cute::prefetch_tma_descriptor(observed_tma_load_b_imag_->get_tma_descriptor());
  }

  /// Construct A Single Stage's Accumulator Shape
  CUTLASS_DEVICE static
  auto
  partition_accumulator_shape() {
    auto acc_shape = append(
                      partition_shape_C(TiledMma{}, take<0,2>(TileShape{})),
                      Int<2>{});  // ((MMA_TILE_M,MMA_TILE_N),MMA_M,MMA_N,TMEM_PIPE,2)

    return acc_shape;
  }

  template <class TmemStorage>
  CUTLASS_DEVICE static
  auto
  slice_accumulator(TmemStorage tmem_storage, int stage) {
    return cute::make_tuple(tmem_storage.accumulators(_,_,_,_,stage));
  }

  template<class EpilogueTile, bool IsOverlappingAccum = false>
  CUTLASS_DEVICE static
  auto
  init_tmem_tensors(EpilogueTile epi_tile) {
    TiledMma tiled_mma;
    auto acc_shape = partition_accumulator_shape();
    // ((MMA_TILE_M,MMA_TILE_N),MMA_M,MMA_N,ACC_PIPE) where ACC_PIPE=2 so we can double buffer our accumulators for mainloop and epilogue.
    Tensor accumulators = cutlass::detail::make_sm100_accumulator<AccumulatorPipelineStageCount, IsOverlappingAccum>(
        tiled_mma, acc_shape, EpilogueTile{});

    TmemStorage<decltype(accumulators)> tmem_storage;
    tmem_storage.accumulators = accumulators;

    return tmem_storage;
  }

  template<class AccTensor>
  CUTLASS_DEVICE static
  void
  set_tmem_offsets(TmemStorage<AccTensor>& tmem_storage, uint32_t tmem_base_addr) {
    tmem_storage.accumulators.data() = tmem_base_addr;
  }

  /// Set up the data needed by this collective for load.
  /// Returned tuple must contain at least two elements, with the first two elements being:
  /// gA_(real/imag)_mkl - The tiled tma tensor for input A_(real/imag)
  /// gB_(real/imag)_nkl - The tiled tma tensor for input B_(real/imag)
  /// tAsA_(real/imag) - partitioned smem tensor for A_(real/imag)
  /// tBsB_(real/imag) - partitioned smem tensor for B_(real/imag)
  /// mcast_mask_a - tma multicast mask for A_(real/imag)
  /// mcast_mask_b - tma multicast mask for B_(real/imag)
  template <class ProblemShape_MNKL>
  CUTLASS_DEVICE auto
  load_init(
      ProblemShape_MNKL const& problem_shape_MNKL,
      TensorStorage& shared_tensors) const {
    using X = Underscore;

    // Separate out problem shape for convenience
    auto [M,N,K,L] = problem_shape_MNKL;

    // Represent the full tensors -- get these from TMA
    Tensor mA_real_mkl = observed_tma_load_a_real_->get_tma_tensor(make_shape(M,K,L));
    Tensor mA_imag_mkl = observed_tma_load_a_imag_->get_tma_tensor(make_shape(M,K,L));
    Tensor mB_real_nkl = observed_tma_load_b_real_->get_tma_tensor(make_shape(N,K,L));
    Tensor mB_imag_nkl = observed_tma_load_b_imag_->get_tma_tensor(make_shape(N,K,L));

    // Tile the tensors and defer the slice
    Tensor gA_real_mkl = local_tile(mA_real_mkl, TileShape{}, make_coord(_,_,_), Step<_1, X,_1>{});    // (BLK_M, BLK_K, m, k, l)
    Tensor gA_imag_mkl = local_tile(mA_imag_mkl, TileShape{}, make_coord(_,_,_), Step<_1, X,_1>{});    // (BLK_N, BLK_K, m, k, l)

    Tensor gB_real_nkl = local_tile(mB_real_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});    // (BLK_N, BLK_K, n, k, l)
    Tensor gB_imag_nkl = local_tile(mB_imag_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});    // (BLK_N, BLK_K, n, k, l)

    // Partition for this CTA
    ThrMMA cta_mma = TiledMma{}.get_slice(blockIdx.x % size(typename TiledMma::AtomThrID{}));

    Tensor tCgA_real_mkl = cta_mma.partition_A(gA_real_mkl);                                      // (MMA, MMA_M, MMA_K, m, k, l)
    Tensor tCgA_imag_mkl = cta_mma.partition_A(gA_imag_mkl);                                      // (MMA, MMA_M, MMA_K, m, k, l)

    Tensor tCgB_real_nkl = cta_mma.partition_B(gB_real_nkl);                                      // (MMA, MMA_N, MMA_K, n, k, l)
    Tensor tCgB_imag_nkl = cta_mma.partition_B(gB_imag_nkl);                                      // (MMA, MMA_N, MMA_K, n, k, l)

    Tensor sA_real = make_tensor(make_smem_ptr(shared_tensors.smem_A_real.begin()), SmemLayoutA{});      // (MMA,MMA_M,MMA_K,PIPE)
    Tensor sA_imag = make_tensor(make_smem_ptr(shared_tensors.smem_A_imag.begin()), SmemLayoutA{});      // (MMA,MMA_M,MMA_K,PIPE)

    Tensor sB_real = make_tensor(make_smem_ptr(shared_tensors.smem_B_real.begin()), SmemLayoutB{});      // (MMA,MMA_N,MMA_K,PIPE)
    Tensor sB_imag = make_tensor(make_smem_ptr(shared_tensors.smem_B_imag.begin()), SmemLayoutB{});      // (MMA,MMA_N,MMA_K,PIPE)

    // Define the CTA-in-cluster Layout and Coord
    Layout cta_layout_mnk  = make_layout(cluster_shape_);
    Layout cta_layout_vmnk = tiled_divide(cta_layout_mnk, make_tile(typename TiledMma::AtomThrID{}));
    auto cta_coord_vmnk  = cta_layout_vmnk.get_flat_coord(block_rank_in_cluster_);

    // Project the cta_layout for tma_a along the n-modes
    auto [tAgA_real_mkl, tAsA_real] = tma_partition(*observed_tma_load_a_real_,
                                      get<2>(cta_coord_vmnk), make_layout(size<2>(cta_layout_vmnk)),
                                      group_modes<0,3>(sA_real), group_modes<0,3>(tCgA_real_mkl));
    auto [tAgA_imag_mkl, tAsA_imag] = tma_partition(*observed_tma_load_a_imag_,
                                      get<2>(cta_coord_vmnk), make_layout(size<2>(cta_layout_vmnk)),
                                      group_modes<0,3>(sA_imag), group_modes<0,3>(tCgA_imag_mkl));

    // Project the cta_layout for tma_b along the m-modes
    auto [tBgB_real_nkl, tBsB_real] = tma_partition(*observed_tma_load_b_real_,
                                      get<1>(cta_coord_vmnk), make_layout(size<1>(cta_layout_vmnk)),
                                      group_modes<0,3>(sB_real), group_modes<0,3>(tCgB_real_nkl));
    auto [tBgB_imag_nkl, tBsB_imag] = tma_partition(*observed_tma_load_b_imag_,
                                      get<1>(cta_coord_vmnk), make_layout(size<1>(cta_layout_vmnk)),
                                      group_modes<0,3>(sB_imag), group_modes<0,3>(tCgB_imag_nkl));
    // TMA Multicast Masks
    uint16_t mcast_mask_a = create_tma_multicast_mask<2>(cta_layout_vmnk, cta_coord_vmnk);
    uint16_t mcast_mask_b = create_tma_multicast_mask<1>(cta_layout_vmnk, cta_coord_vmnk);

    LoadParams load_params {
      shape<3>(gA_real_mkl),                                                      // for scheduler
      tAgA_real_mkl, tAgA_imag_mkl, tBgB_real_nkl, tBgB_imag_nkl,                // for input tensor values
      tAsA_real, tAsA_imag, tBsB_real, tBsB_imag,                                // for input tensor values
      mcast_mask_a, mcast_mask_b
    };
    return load_params;
  }

  /// Set up the data needed by this collective for mma compute.
  template <class TmemStorage>
  CUTLASS_DEVICE auto
  mma_init(
      [[maybe_unused]] TmemStorage tmem_storage,
      TensorStorage& shared_tensors) const {
    Tensor sA_real = make_tensor(make_smem_ptr(shared_tensors.smem_A_real.begin()), SmemLayoutA{});          // (BLK_M,BLK_K,PIPE)
    Tensor sA_imag = make_tensor(make_smem_ptr(shared_tensors.smem_A_imag.begin()), SmemLayoutA{});          // (BLK_M,BLK_K,PIPE)

    Tensor sB_real = make_tensor(make_smem_ptr(shared_tensors.smem_B_real.begin()), SmemLayoutB{});          // (BLK_N,BLK_K,PIPE)
    Tensor sB_imag = make_tensor(make_smem_ptr(shared_tensors.smem_B_imag.begin()), SmemLayoutB{});          // (BLK_N,BLK_K,PIPE)

    // Allocate "fragments/descriptors" for A and B matrices
    Tensor tCrA_real = TiledMma::make_fragment_A(sA_real);                                           // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tCrA_imag = TiledMma::make_fragment_A(sA_imag);                                           // (MMA,MMA_M,MMA_K,PIPE)

    Tensor tCrB_real = TiledMma::make_fragment_B(sB_real);                                           // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tCrB_imag = TiledMma::make_fragment_B(sB_imag);                                           // (MMA,MMA_N,MMA_K,PIPE)

    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<3>(sA_real));                                     // PIPE
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<3>(sB_real));                                     // PIPE

    TiledMma tiled_mma_a_pos;
    TiledMmaANeg tiled_mma_a_neg;
    MmaParams<decltype(tCrA_real), decltype(tCrB_real)> mma_params {
      tiled_mma_a_pos, tiled_mma_a_neg,
      tCrA_real, tCrA_imag,
      tCrB_real, tCrB_imag
    };

    return mma_params;
  }

  /// Perform a collective-scoped matrix multiply-accumulate
  /// Producer Perspective
  template <
    class LoadParams,
    class TileCoordMNKL,
    class KTileIterator
  >
  CUTLASS_DEVICE auto
  load(
      MainloopPipeline mainloop_pipeline,
      MainloopPipelineState mainloop_pipe_producer_state,
      LoadParams const& load_inputs,
      TileCoordMNKL const& cta_coord_mnkl,
      KTileIterator k_tile_iter, int k_tile_count) {

    auto [unused_k_tiles,
          tAgA_real_mkl, tAgA_imag_mkl, tBgB_real_nkl, tBgB_imag_nkl,
          tAsA_real, tAsA_imag, tBsB_real, tBsB_imag,
          mcast_mask_a, mcast_mask_b] = load_inputs;

    // slice out the work coord from partitioned tensors
    Tensor tAgA_real = tAgA_real_mkl(_, get<0>(cta_coord_mnkl) / size(typename TiledMma::AtomThrID{}), _, get<3>(cta_coord_mnkl));
    Tensor tAgA_imag = tAgA_imag_mkl(_, get<0>(cta_coord_mnkl) / size(typename TiledMma::AtomThrID{}), _, get<3>(cta_coord_mnkl));

    Tensor tBgB_real = tBgB_real_nkl(_, get<1>(cta_coord_mnkl), _, get<3>(cta_coord_mnkl));
    Tensor tBgB_imag = tBgB_imag_nkl(_, get<1>(cta_coord_mnkl), _, get<3>(cta_coord_mnkl));

    auto barrier_token = mainloop_pipeline.producer_try_acquire(mainloop_pipe_producer_state);

    // Issue the Mainloop loads
    CUTLASS_PRAGMA_NO_UNROLL
    while (k_tile_count > 0) {
      // LOCK mainloop_pipe_producer_state for _writing_
      mainloop_pipeline.producer_acquire(mainloop_pipe_producer_state, barrier_token);

      using BarrierType = typename MainloopPipeline::ProducerBarrierType;
      BarrierType* tma_barrier = mainloop_pipeline.producer_get_barrier(mainloop_pipe_producer_state);

      int write_stage = mainloop_pipe_producer_state.index();
      ++mainloop_pipe_producer_state;
      barrier_token = mainloop_pipeline.producer_try_acquire(mainloop_pipe_producer_state);

      if (cute::elect_one_sync()) {
        copy(observed_tma_load_a_real_->with(*tma_barrier, mcast_mask_a), tAgA_real(_,*k_tile_iter), tAsA_real(_,write_stage));
        copy(observed_tma_load_a_imag_->with(*tma_barrier, mcast_mask_a), tAgA_imag(_,*k_tile_iter), tAsA_imag(_,write_stage));

        copy(observed_tma_load_b_real_->with(*tma_barrier, mcast_mask_b), tBgB_real(_,*k_tile_iter), tBsB_real(_,write_stage));
        copy(observed_tma_load_b_imag_->with(*tma_barrier, mcast_mask_b), tBgB_imag(_,*k_tile_iter), tBsB_imag(_,write_stage));
      }

      --k_tile_count;
      ++k_tile_iter;
  }

    return cute::make_tuple(mainloop_pipe_producer_state, k_tile_iter);
  }

  /// Perform a Producer Epilogue to prevent early exit of ctas in a Cluster
  CUTLASS_DEVICE void
  load_tail(MainloopPipeline mainloop_pipeline, MainloopPipelineState mainloop_pipe_producer_state) {
    // Issue the epilogue waits
    /* This helps avoid early exit of ctas in Cluster
      * Waits for all stages to either be released (all
      * Consumer UNLOCKs), or if the stage was never used
      * then would just be acquired since the phase was
      * still inverted from make_producer_start_state
      */
    mainloop_pipeline.producer_tail(mainloop_pipe_producer_state);
  }

  /// Perform a collective-scoped matrix multiply-accumulate
  /// Consumer Perspective
  template <
    class AccumulatorPipeline,
    class FrgEngine, class FrgLayout,
    class MmaParams,
    class CtaTileCoord
  >
  CUTLASS_DEVICE auto
  mma(cute::tuple<MainloopPipeline,
                  AccumulatorPipeline> pipelines,
      cute::tuple<MainloopPipelineState,
                  typename AccumulatorPipeline::PipelineState> pipeline_states,
      cute::tuple<cute::Tensor<FrgEngine, FrgLayout>> const& accumulators_pair,
      MmaParams const& mma_inputs,
      CtaTileCoord cta_tile_coord,
      int k_tile_count
    ) {
    static_assert(is_tmem<FrgEngine>::value, "Accumulator must be tmem resident.");
    static_assert(rank(FrgLayout{}) == 4 && size<3>(FrgLayout{}) == _2{}, "Accumulator must be MMA-partitioned: (MMA, MMA_M, MMA_N, _2)");

    auto [tiled_mma_a_pos, tiled_mma_a_neg, tCrA_real, tCrA_imag, tCrB_real, tCrB_imag] = mma_inputs;

    auto [mainloop_pipeline, accumulator_pipeline] = pipelines;
    auto [mainloop_pipe_consumer_state, accumulator_pipe_producer_state] = pipeline_states;

    uint32_t skip_wait = k_tile_count <= 0;
    auto barrier_token = mainloop_pipeline.consumer_try_wait(mainloop_pipe_consumer_state, skip_wait);

    //
    // PIPELINED MAIN LOOP
    //
    tiled_mma_a_pos.accumulate_ = UMMA::ScaleOut::Zero;
    tiled_mma_a_neg.accumulate_ = UMMA::ScaleOut::Zero;

    auto accumulators = get<0>(accumulators_pair);
    auto accumulators_real = accumulators(_,_,_,0);
    auto accumulators_imag = accumulators(_,_,_,1);

    // Wait for tmem accumulator buffer to become empty with a flipped phase
    accumulator_pipeline.producer_acquire(accumulator_pipe_producer_state);

    CUTLASS_PRAGMA_NO_UNROLL
    while (k_tile_count > 0) {
      // WAIT on mainloop_pipe_consumer_state until its data are available
      // (phase bit flips from mainloop_pipe_consumer_state.phase() value)
      mainloop_pipeline.consumer_wait(mainloop_pipe_consumer_state, barrier_token);

      // Compute on k_tile
      int read_stage = mainloop_pipe_consumer_state.index();
      // Save current mainlop pipeline read state
      auto curr_mainloop_pipe_consumer_state = mainloop_pipe_consumer_state;

      // Advance mainloop_pipe
      ++mainloop_pipe_consumer_state;
      --k_tile_count;
      skip_wait = k_tile_count <= 0;
      // Peek at next iteration
      barrier_token = mainloop_pipeline.consumer_try_wait(mainloop_pipe_consumer_state, skip_wait);

      // Unroll the K mode manually so we can set scale C to 1
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tCrA_real); ++k_block) {
        // (V,M) x (V,N) => (V,M,N)

        // Calculate real acc, 1st step
        // realAcc +=  realA * realB
        cute::gemm(tiled_mma_a_pos, tCrA_real(_,_,k_block,read_stage), tCrB_real(_,_,k_block,read_stage), accumulators_real);

        // Calculate imag acc, 1st step
        if constexpr (cute::is_same_v<TransformB, cute::conjugate>) {
          // imagAcc +=  realA * (-imagB)
          cute::gemm(tiled_mma_a_neg, tCrA_real(_,_,k_block,read_stage), tCrB_imag(_,_,k_block,read_stage), accumulators_imag);
        } else {
          // imagAcc +=  realA * imagB
          cute::gemm(tiled_mma_a_pos, tCrA_real(_,_,k_block,read_stage), tCrB_imag(_,_,k_block,read_stage), accumulators_imag);
        }

        tiled_mma_a_pos.accumulate_ = UMMA::ScaleOut::One;
        tiled_mma_a_neg.accumulate_ = UMMA::ScaleOut::One;

        // Calculate real acc, 2nd step
        if constexpr (cute::is_same_v<TransformA, TransformB>) {
          // realAcc -= imagA * imagB
          cute::gemm(tiled_mma_a_neg, tCrA_imag(_,_,k_block,read_stage), tCrB_imag(_,_,k_block,read_stage), accumulators_real);
        } else {
          // realAcc += imagA * imagB
          cute::gemm(tiled_mma_a_pos, tCrA_imag(_,_,k_block,read_stage), tCrB_imag(_,_,k_block,read_stage), accumulators_real);
        }

        // Calculate imag acc, 2nd step
        if constexpr (cute::is_same_v<TransformA, cute::conjugate>) {
           // imagAcc += (-imagA) * realB
          cute::gemm(tiled_mma_a_neg, tCrA_imag(_,_,k_block,read_stage), tCrB_real(_,_,k_block,read_stage), accumulators_imag);
        } else {
           // imagAcc += imagA * realB
          cute::gemm(tiled_mma_a_pos, tCrA_imag(_,_,k_block,read_stage), tCrB_real(_,_,k_block,read_stage), accumulators_imag);
        }
      }
      mainloop_pipeline.consumer_release(curr_mainloop_pipe_consumer_state);
    }

    return mainloop_pipe_consumer_state;
  }

protected:

  typename Params::TMA_A const* observed_tma_load_a_real_ = nullptr;
  typename Params::TMA_A const* observed_tma_load_a_imag_ = nullptr;
  typename Params::TMA_B const* observed_tma_load_b_real_ = nullptr;
  typename Params::TMA_B const* observed_tma_load_b_imag_ = nullptr;

  ClusterShape cluster_shape_;
  uint32_t block_rank_in_cluster_;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
