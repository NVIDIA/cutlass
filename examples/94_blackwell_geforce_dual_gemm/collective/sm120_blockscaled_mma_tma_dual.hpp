/***************************************************************************************************
 * Copyright (c) 2025 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/detail/sm100_blockscaled_layout.hpp"
#include "cutlass/trace.h"
#include "cutlass/numeric_types.h"

#include "cute/arch/cluster_sm90.hpp"
#include "cute/arch/copy_sm90.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/functional.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cute/numeric/arithmetic_tuple.hpp"

#include "dispatch_policy_extra.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {
using namespace cute;

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class DispatchPolicy,
  class TileShape,
  class ElementPairA,
  class StridePairA,
  class ElementPairB,
  class StridePairB0,
  class StridePairB1,
  class TiledMma,
  class GmemTiledCopyPairA,
  class SmemLayoutAtomsA,
  class SmemCopyAtomsA,
  class TransformA,
  class GmemTiledCopyPairB0,
  class SmemLayoutAtomsB0,
  class SmemCopyAtomsB0,
  class TransformB0,
  class GmemTiledCopyPairB1,
  class SmemLayoutAtomsB1,
  class SmemCopyAtomsB1,
  class TransformB1
>
struct DualCollectiveMma {
  static_assert(cutlass::detail::dependent_false<ElementPairA>, "Could not find a mainloop specialization.");
};

template <
  int Stages,
  int SchedulerPipelineStageCount,
  class ClusterShape,
  class KernelScheduleType,
  class TileShape_,
  class ElementPairA_,
  class StridePairA_,
  class ElementPairB_,
  class StridePairB0_,
  class StridePairB1_,
  class TiledMma_,
  class GmemTiledCopyPairA_,
  class SmemLayoutAtomsA_,
  class SmemCopyAtomsA_,
  class TransformA_,
  class GmemTiledCopyPairB0_,
  class SmemLayoutAtomsB0_,
  class SmemCopyAtomsB0_,
  class TransformB0_,
  class GmemTiledCopyPairB1_,
  class SmemLayoutAtomsB1_,
  class SmemCopyAtomsB1_,
  class TransformB1_> 
struct DualCollectiveMma<
    DualMainloopSm120TmaWarpSpecializedBlockScaled<Stages, SchedulerPipelineStageCount, ClusterShape, KernelScheduleType>,
    TileShape_,
    ElementPairA_,
    StridePairA_,
    ElementPairB_,
    StridePairB0_,
    StridePairB1_,
    TiledMma_,
    GmemTiledCopyPairA_,
    SmemLayoutAtomsA_,
    SmemCopyAtomsA_,
    TransformA_,
    GmemTiledCopyPairB0_,
    SmemLayoutAtomsB0_,
    SmemCopyAtomsB0_,
    TransformB0_,
    GmemTiledCopyPairB1_,
    SmemLayoutAtomsB1_,
    SmemCopyAtomsB1_,
    TransformB1_>  {
  //
  // Type Aliases
  //
  using DispatchPolicy = DualMainloopSm120TmaWarpSpecializedBlockScaled<Stages, SchedulerPipelineStageCount, ClusterShape, KernelScheduleType>;
  using TileShape = TileShape_;
  using ElementPairA = ElementPairA_;
  using ElementPairB = ElementPairB_;
  using StridePairA = StridePairA_;
  using StridePairB0 = StridePairB0_;
  using StridePairB1 = StridePairB1_;

  static_assert(cute::is_same_v<remove_cvref_t<decltype(get<1>(ElementPairA{}))>,
                                remove_cvref_t<decltype(get<1>(ElementPairB{}))>>, "SFA and SFB data types should be the same");

  using RuntimeDataTypeA = void*;
  using RuntimeDataTypeB = void*;

   // A and B matrices
  using ElementA = remove_cvref_t<decltype(get<0>(ElementPairA{}))>;
  using StrideA  = remove_cvref_t<decltype(get<0>(StridePairA{}))>;

  using ElementB = remove_cvref_t<decltype(get<0>(ElementPairB{}))>;
  using StrideB0 = remove_cvref_t<decltype(get<0>(StridePairB0{}))>;
  using StrideB1 = remove_cvref_t<decltype(get<0>(StridePairB1{}))>;

  // SFA and SFB
  using ElementSF  = remove_cvref_t<decltype(get<1>(ElementPairA{}))>;
  using LayoutSFA  = remove_cvref_t<decltype(get<1>(StridePairA{}))>;
  using LayoutSFB0 = remove_cvref_t<decltype(get<1>(StridePairB0{}))>;
  using LayoutSFB1 = remove_cvref_t<decltype(get<1>(StridePairB1{}))>;

  using ArrayElementA = ElementA;
  using ArrayElementB = ElementB;

  using TiledMma = TiledMma_;
  using CtaShape_MNK = decltype(shape_div(TileShape{}, ClusterShape{}));
  using ElementAccumulator = typename TiledMma::ValTypeC;

  static constexpr int SFVecSize = TiledMma::Traits::SFVecSize;
  using Sm1xxBlkScaledConfig = cutlass::detail::Sm1xxBlockScaledConfig<SFVecSize>;

  // Gmem copies
  using GmemTiledCopyPairA  = GmemTiledCopyPairA_;
  using GmemTiledCopyPairB0 = GmemTiledCopyPairB0_;
  using GmemTiledCopyPairB1 = GmemTiledCopyPairB1_;
  using GmemTiledCopyA     = remove_cvref_t<decltype(get<0>(GmemTiledCopyPairA{}))>;
  using GmemTiledCopySFA   = remove_cvref_t<decltype(get<1>(GmemTiledCopyPairA{}))>;
  using GmemTiledCopyB0    = remove_cvref_t<decltype(get<0>(GmemTiledCopyPairB0{}))>;
  using GmemTiledCopySFB0  = remove_cvref_t<decltype(get<1>(GmemTiledCopyPairB0{}))>;
  using GmemTiledCopyB1    = remove_cvref_t<decltype(get<0>(GmemTiledCopyPairB1{}))>;
  using GmemTiledCopySFB1  = remove_cvref_t<decltype(get<1>(GmemTiledCopyPairB1{}))>;

  // Smem copies
  using SmemLayoutAtomsA  = SmemLayoutAtomsA_;
  using SmemLayoutAtomsB0 = SmemLayoutAtomsB0_;
  using SmemLayoutAtomsB1 = SmemLayoutAtomsB1_;

  using SmemLayoutAtomA   = remove_cvref_t<decltype(get<0>(SmemLayoutAtomsA{}))>;
  using SmemLayoutAtomSFA = remove_cvref_t<decltype(get<1>(SmemLayoutAtomsA{}))>;
  using SmemLayoutAtomB0   = remove_cvref_t<decltype(get<0>(SmemLayoutAtomsB0{}))>;
  using SmemLayoutAtomSFB0 = remove_cvref_t<decltype(get<1>(SmemLayoutAtomsB0{}))>;
  using SmemLayoutAtomB1   = remove_cvref_t<decltype(get<0>(SmemLayoutAtomsB1{}))>;
  using SmemLayoutAtomSFB1 = remove_cvref_t<decltype(get<1>(SmemLayoutAtomsB1{}))>;

  using SmemCopyAtomsA  =  SmemCopyAtomsA_;
  using SmemCopyAtomsB0 =  SmemCopyAtomsB0_;
  using SmemCopyAtomsB1 =  SmemCopyAtomsB1_;

  using SmemCopyAtomA   = remove_cvref_t<decltype(get<0>(SmemCopyAtomsA{}))>;
  using SmemCopyAtomSFA = remove_cvref_t<decltype(get<1>(SmemCopyAtomsA{}))>;

  using SmemCopyAtomB0   = remove_cvref_t<decltype(get<0>(SmemCopyAtomsB0{}))>;
  using SmemCopyAtomSFB0 = remove_cvref_t<decltype(get<1>(SmemCopyAtomsB0{}))>;
  using SmemCopyAtomB1   = remove_cvref_t<decltype(get<0>(SmemCopyAtomsB1{}))>;
  using SmemCopyAtomSFB1 = remove_cvref_t<decltype(get<1>(SmemCopyAtomsB1{}))>;

  using TransformA = TransformA_;
  using TransformB0 = TransformB0_;
  using TransformB1 = TransformB1_;

  using ArchTag = typename DispatchPolicy::ArchTag;

  static constexpr int ThreadCount = size(TiledMma{});

  using MainloopPipeline = cutlass::PipelineTmaAsync<DispatchPolicy::Stages>;

  using PipelineParams = typename MainloopPipeline::Params;
  using PipelineState  = typename cutlass::PipelineState<DispatchPolicy::Stages>;

  // One threads per CTA are producers (1 for operand tile)
  static constexpr int NumProducerThreadEvents = 1;

  static_assert(rank(SmemLayoutAtomA{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<0>(TileShape{}) % size<0>(SmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(rank(SmemLayoutAtomB0{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<1>(TileShape{}) % size<0>(SmemLayoutAtomB0{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomB0{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(rank(SmemLayoutAtomB1{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<1>(TileShape{}) % size<0>(SmemLayoutAtomB1{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomB1{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(not cute::is_void_v<SmemCopyAtomA>,
    "SM120 mainloop must specify a copy atom for A operand smem->rmem reads.");
  static_assert(not cute::is_void_v<SmemCopyAtomB0>,
    "SM120 mainloop must specify a copy atom for B0 operand smem->rmem reads.");
  static_assert(not cute::is_void_v<SmemCopyAtomB1>,
    "SM120 mainloop must specify a copy atom for B1 operand smem->rmem reads.");

  // Tile along modes in a way that maximizes the TMA box size.
  using SmemLayoutA = decltype(tile_to_shape(
      SmemLayoutAtomA{},
      make_shape(shape<0>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      conditional_t< ::cutlass::gemm::detail::is_major<0,StrideA>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));
  using SmemLayoutB0 = decltype(tile_to_shape(
      SmemLayoutAtomB0{},
      make_shape(shape<1>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      conditional_t< ::cutlass::gemm::detail::is_major<0,StrideB0>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));
  using SmemLayoutB1 = decltype(tile_to_shape(
      SmemLayoutAtomB1{},
      make_shape(shape<1>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      conditional_t< ::cutlass::gemm::detail::is_major<0,StrideB1>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));

  // SmemLayoutAtomSFA and SmemLayoutAtomSFB are for whole CTA tiles. We add the number of pipeline stages here.
  // The number of pipeline stages is the same as the number of pipeline stages from AB Load <-> MainLoop
  using SmemLayoutSFA = decltype(make_layout(
    append(shape(SmemLayoutAtomSFA{}), Int<DispatchPolicy::Stages>{}),
    append(stride(SmemLayoutAtomSFA{}), size(filter_zeros(SmemLayoutAtomSFA{})))
  ));

  using SmemLayoutSFB0 = decltype(make_layout(
    append(shape(SmemLayoutAtomSFB0{}), Int<DispatchPolicy::Stages>{}),
    append(stride(SmemLayoutAtomSFB0{}), size(filter_zeros(SmemLayoutAtomSFB0{})))
  ));

  using SmemLayoutSFB1 = decltype(make_layout(
    append(shape(SmemLayoutAtomSFB1{}), Int<DispatchPolicy::Stages>{}),
    append(stride(SmemLayoutAtomSFB1{}), size(filter_zeros(SmemLayoutAtomSFB1{})))
  ));

  static_assert(rank(SmemLayoutA{}) == 3, "Smem layout must be rank 3.");
  static_assert(rank(SmemLayoutB0{}) == 3, "Smem layout must be rank 3.");
  static_assert(rank(SmemLayoutB1{}) == 3, "Smem layout must be rank 3.");

  static_assert(DispatchPolicy::Stages >= 2, "Specialization requires Stages set to value 2 or more.");
  static_assert(not cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeA>::value &&
                not cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeB>::value,
                "MMA atom must source both A and B operands from rmem for this mainloop.");
  static_assert(cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD>, "GmemTiledCopy - invalid SM90 TMA copy atom specified.");
  static_assert(cute::is_same_v<GmemTiledCopyB0, SM90_TMA_LOAD>, "GmemTiledCopy - invalid SM90 TMA copy atom specified.");
  static_assert(cute::is_same_v<GmemTiledCopyB1, SM90_TMA_LOAD>, "GmemTiledCopy - invalid SM90 TMA copy atom specified.");

  static constexpr bool IsF8F6F4 = detail::is_sm120_f8f6f4<TiledMma, ElementA, ElementB>();

  // For all other types, cast to size equivalent uint type to avoid any rounding by TMA.
  using TmaInternalElementA = cute::conditional_t<not IsF8F6F4,
                                                  ElementA,
                              cute::conditional_t<cute::is_same_v<ElementA, cutlass::float_e2m1_t>,
                                                  cutlass::detail::float_e2m1_unpacksmem_t,
                              cute::conditional_t<cute::is_same_v<ElementA, cutlass::float_e2m3_t>,
                                                cutlass::detail::float_e2m3_unpacksmem_t,
                              cute::conditional_t<cute::is_same_v<ElementA, cutlass::float_e3m2_t>,
                                                cutlass::detail::float_e3m2_unpacksmem_t,
                                                uint_bit_t<sizeof_bits_v<ElementA>>>>>>;

  using TmaInternalElementB = cute::conditional_t<not IsF8F6F4,
                                                  ElementB,
                              cute::conditional_t<cute::is_same_v<ElementB, cutlass::float_e2m1_t>,
                                                  cutlass::detail::float_e2m1_unpacksmem_t,
                              cute::conditional_t<cute::is_same_v<ElementB, cutlass::float_e2m3_t>,
                                                cutlass::detail::float_e2m3_unpacksmem_t,
                              cute::conditional_t<cute::is_same_v<ElementB, cutlass::float_e3m2_t>,
                                                cutlass::detail::float_e3m2_unpacksmem_t,
                                                uint_bit_t<sizeof_bits_v<ElementB>>>>>>;

  using TmaInternalElementSF = ElementSF;

  using SmemAllocTypeA = cute::conditional_t<IsF8F6F4, uint8_t, typename TiledMma::ValTypeA>;
  using SmemAllocTypeB = cute::conditional_t<IsF8F6F4, uint8_t, typename TiledMma::ValTypeB>;


  // Set the bytes transferred in this TMA transaction (may involve multiple issues)
  static constexpr uint32_t TmaTransactionBytesMK = static_cast<uint32_t>(
    cutlass::bits_to_bytes(cosize(take<0,2>(SmemLayoutSFA{})) * cute::sizeof_bits_v<ElementSF>) +
    cutlass::bits_to_bytes(size(take<0,2>(SmemLayoutA{})) * sizeof_bits<ElementA>::value));

  static constexpr uint32_t TmaTransactionBytesNK0 = static_cast<uint32_t>(
    cutlass::bits_to_bytes(cosize(take<0,2>(SmemLayoutSFB0{})) * cute::sizeof_bits_v<ElementSF>) +
    cutlass::bits_to_bytes(size(take<0,2>(SmemLayoutB0{})) * sizeof_bits<ElementB>::value));

  static constexpr uint32_t TmaTransactionBytesNK1 = static_cast<uint32_t>(
    cutlass::bits_to_bytes(cosize(take<0,2>(SmemLayoutSFB1{})) * cute::sizeof_bits_v<ElementSF>) +
    cutlass::bits_to_bytes(size(take<0,2>(SmemLayoutB1{})) * sizeof_bits<ElementB>::value));

  static constexpr uint32_t TmaTransactionBytes = TmaTransactionBytesMK + TmaTransactionBytesNK0 + TmaTransactionBytesNK1;

  struct SharedStorage {
    struct TensorStorage : cute::aligned_struct<128, _0> {
      alignas(1024) cute::ArrayEngine<SmemAllocTypeA, cute::cosize_v<SmemLayoutA>> smem_A;
      alignas(1024) cute::ArrayEngine<SmemAllocTypeB, cute::cosize_v<SmemLayoutB0>> smem_B0;
      alignas(1024) cute::ArrayEngine<SmemAllocTypeB, cute::cosize_v<SmemLayoutB1>> smem_B1;
      cute::ArrayEngine<ElementSF, cute::cosize_v<SmemLayoutSFA>> smem_SFA;
      cute::ArrayEngine<ElementSF, cute::cosize_v<SmemLayoutSFB0>> smem_SFB0;
      cute::ArrayEngine<ElementSF, cute::cosize_v<SmemLayoutSFB1>> smem_SFB1;
    } tensors;
    using PipelineStorage = typename MainloopPipeline::SharedStorage;
    alignas(16) PipelineStorage pipeline_storage;
  };

  using TensorStorage = typename SharedStorage::TensorStorage;
  using PipelineStorage = typename SharedStorage::PipelineStorage;

  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A{nullptr};
    StrideA dA{};
    ElementB const* ptr_B0{nullptr};
    StrideB0 dB0{};
    ElementB const* ptr_B1{nullptr};
    StrideB1 dB1{};
    ElementSF const* ptr_SFA{nullptr};
    LayoutSFA layout_SFA{};
    ElementSF const* ptr_SFB0{nullptr};
    LayoutSFB0 layout_SFB0{};
    ElementSF const* ptr_SFB1{nullptr};
    LayoutSFB1 layout_SFB1{};
  };

  // Device side kernel params
  struct Params {
    // Assumption: StrideA is congruent with Problem_MK
    using TMA_A = decltype(make_tma_copy(
        GmemTiledCopyA{},
        make_tensor(recast_ptr<TmaInternalElementA>(nullptr), repeat_like(StrideA{}, int32_t(0)), StrideA{}),
        SmemLayoutA{}(_,_,cute::Int<0>{}),
        make_shape(shape<0>(TileShape{}), shape<2>(TileShape{})),
        _1{}));  // No programmatic multicast

    // Assumption: StrideB is congruent with Problem_NK
    using TMA_B0 = decltype(make_tma_copy(
        GmemTiledCopyB0{},
        make_tensor(recast_ptr<TmaInternalElementB>(nullptr), repeat_like(StrideB0{}, int32_t(0)), StrideB0{}),
        SmemLayoutB0{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        _1{}));  // No programmatic multicast

    using TMA_B1 = decltype(make_tma_copy(
        GmemTiledCopyB1{},
        make_tensor(recast_ptr<TmaInternalElementB>(nullptr), repeat_like(StrideB1{}, int32_t(0)), StrideB1{}),
        SmemLayoutB1{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        _1{}));  // No programmatic multicast

    using TMA_SFA = decltype(make_tma_copy<uint16_t>(
        GmemTiledCopySFA{},
        make_tensor(static_cast<ElementSF const*>(nullptr), LayoutSFA{}),
        SmemLayoutSFA{}(_,_,cute::Int<0>{}),
        make_shape(shape<0>(TileShape{}), shape<2>(TileShape{})),
        _1{}));  // No programmatic multicast

    using TMA_SFB0 = decltype(make_tma_copy<uint16_t>(
        GmemTiledCopySFB0{},
        make_tensor(static_cast<ElementSF const*>(nullptr), LayoutSFB0{}),
        SmemLayoutSFB0{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        _1{}));  // No programmatic multicast

    using TMA_SFB1 = decltype(make_tma_copy<uint16_t>(
        GmemTiledCopySFB1{},
        make_tensor(static_cast<ElementSF const*>(nullptr), LayoutSFB1{}),
        SmemLayoutSFB1{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        _1{}));  // No programmatic multicast

    TMA_A tma_load_a;
    TMA_B0 tma_load_b0;
    TMA_B1 tma_load_b1;
    TMA_SFA tma_load_sfa;
    TMA_SFB0 tma_load_sfb0;
    TMA_SFB1 tma_load_sfb1;
    LayoutSFA layout_SFA;
    LayoutSFB0 layout_SFB0;
    LayoutSFB1 layout_SFB1;
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
    auto [M, N, K, L] = problem_shape_MNKL;

    auto ptr_A = recast_ptr<TmaInternalElementA>(args.ptr_A);
    auto ptr_B0 = recast_ptr<TmaInternalElementB>(args.ptr_B0);
    auto ptr_B1 = recast_ptr<TmaInternalElementB>(args.ptr_B1);

    Tensor tensor_a = make_tensor(ptr_A, make_layout(make_shape(M,K,L), args.dA));
    Tensor tensor_b0 = make_tensor(ptr_B0, make_layout(make_shape(N,K,L), args.dB0));
    Tensor tensor_b1 = make_tensor(ptr_B1, make_layout(make_shape(N,K,L), args.dB1));

    Tensor tensor_sfa = make_tensor(args.ptr_SFA, args.layout_SFA);
    Tensor tensor_sfb0 = make_tensor(args.ptr_SFB0, args.layout_SFB0);
    Tensor tensor_sfb1 = make_tensor(args.ptr_SFB1, args.layout_SFB1);

    typename Params::TMA_A tma_load_a = make_tma_copy(
        GmemTiledCopyA{},
        tensor_a,
        SmemLayoutA{}(_,_,cute::Int<0>{}),
        make_shape(shape<0>(TileShape{}), shape<2>(TileShape{})),
        _1{}); // No programmatic multicast
    typename Params::TMA_B0 tma_load_b0 = make_tma_copy(
        GmemTiledCopyB0{},
        tensor_b0,
        SmemLayoutB0{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        _1{}); // No programmatic multicast
    typename Params::TMA_B1 tma_load_b1 = make_tma_copy(
        GmemTiledCopyB1{},
        tensor_b1,
        SmemLayoutB1{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        _1{}); // No programmatic multicast

    typename Params::TMA_SFA tma_load_sfa = make_tma_copy<uint16_t>(
        GmemTiledCopySFA{},
        tensor_sfa,
        SmemLayoutSFA{}(_,_,cute::Int<0>{}),
        make_shape(shape<0>(TileShape{}), shape<2>(TileShape{})),
        _1{}); // No programmatic multicast

    typename Params::TMA_SFB0 tma_load_sfb0 = make_tma_copy<uint16_t>(
        GmemTiledCopySFB0{},
        tensor_sfb0,
        SmemLayoutSFB0{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        _1{}); // No programmatic multicast

    typename Params::TMA_SFB1 tma_load_sfb1 = make_tma_copy<uint16_t>(
        GmemTiledCopySFB1{},
        tensor_sfb1,
        SmemLayoutSFB1{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})),
        _1{}); // No programmatic multicast

    return {
      tma_load_a,
      tma_load_b0,
      tma_load_b1,
      tma_load_sfa,
      tma_load_sfb0,
      tma_load_sfb1,
      args.layout_SFA,
      args.layout_SFB0,
      args.layout_SFB1,
      TmaTransactionBytes,
      TmaTransactionBytesMK,
      TmaTransactionBytesNK0,
      TmaTransactionBytesNK1
    };
  }

  template<class ProblemShape>
  CUTLASS_HOST_DEVICE static bool
  can_implement(
      ProblemShape const& problem_shape,
      [[maybe_unused]] Arguments const& args) {
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M, N, K, L] = problem_shape_MNKL;

    constexpr int tma_alignment_bits_A = cutlass::detail::get_input_alignment_bits<ElementA, IsF8F6F4>();
    constexpr int tma_alignment_bits_B0 = cutlass::detail::get_input_alignment_bits<ElementB, IsF8F6F4>();
    constexpr int tma_alignment_bits_B1 = cutlass::detail::get_input_alignment_bits<ElementB, IsF8F6F4>();

    bool implementable = true;
    constexpr int min_tma_aligned_elements_A = tma_alignment_bits_A / cutlass::sizeof_bits<ElementA>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_A>(cute::make_shape(M,K,L), StrideA{});
    constexpr int min_tma_aligned_elements_B0 = tma_alignment_bits_B0 / cutlass::sizeof_bits<ElementB>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_B0>(cute::make_shape(N,K,L), StrideB0{});
    constexpr int min_tma_aligned_elements_B1 = tma_alignment_bits_B1 / cutlass::sizeof_bits<ElementB>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_B1>(cute::make_shape(N,K,L), StrideB1{});

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for TMA.\n");
    }
    return implementable;
  }

  /// Issue Tma Descriptor Prefetch -- ideally from a single thread for best performance
  CUTLASS_DEVICE
  static void prefetch_tma_descriptors(Params const& params) {
    cute::prefetch_tma_descriptor(params.tma_load_a.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_b0.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_b1.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_sfa.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_sfb0.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_sfb1.get_tma_descriptor());
  }

  // Temporary adhoc partitioning for scaling factors.
  template <class SFATensor, class Atom, class TiledThr, class TiledPerm>
  CUTE_HOST_DEVICE constexpr
  auto
  thrfrg_SFA(SFATensor&& sfatensor, TiledMMA<Atom, TiledThr, TiledPerm>& mma)
  {
    CUTE_STATIC_ASSERT_V(rank(sfatensor) >= Int<2>{});

    using AtomShape_MNK  = typename Atom::Shape_MNK;
    using AtomLayoutSFA_TV = typename Atom::Traits::SFALayout;

    auto permutation_mnk = TiledPerm{};
    auto thr_layout_vmnk = mma.get_thr_layout_vmnk();

    // Reorder the tensor for the TiledAtom
    auto t_tile = make_tile(get<0>(permutation_mnk),
                            get<2>(permutation_mnk));
    auto t_tensor = logical_divide(sfatensor, t_tile);                 // (PermM,PermK)

    // Tile the tensor for the Atom
    auto a_tile = make_tile(make_layout(size<0>(AtomShape_MNK{})),
                            make_layout(size<2>(AtomShape_MNK{})));
    auto a_tensor = zipped_divide(t_tensor, a_tile);                 // ((AtomM,AtomK),(RestM,RestK))

    // Transform the Atom mode from (M,K) to (Thr,Val)
    auto tv_tensor = a_tensor.compose(AtomLayoutSFA_TV{},_);           // ((ThrV,FrgV),(RestM,RestK))

    // Tile the tensor for the Thread
    auto thr_tile = make_tile(_,
                              make_tile(make_layout(size<1>(thr_layout_vmnk)),
                                        make_layout(size<3>(thr_layout_vmnk))));
    auto thr_tensor = zipped_divide(tv_tensor, thr_tile);            // ((ThrV,(ThrM,ThrK)),(FrgV,(RestM,RestK)))

    return thr_tensor;
  }

  template <class SFB0Tensor, class Atom, class TiledThr, class TiledPerm>
  CUTE_HOST_DEVICE constexpr
  auto
  thrfrg_SFB0(SFB0Tensor&& sfb0tensor, TiledMMA<Atom, TiledThr, TiledPerm>& mma)
  {
    CUTE_STATIC_ASSERT_V(rank(sfb0tensor) >= Int<2>{});

    using AtomShape_MNK  = typename Atom::Shape_MNK;
    using AtomLayoutSFB0_TV = typename Atom::Traits::SFBLayout;

    auto permutation_mnk = TiledPerm{};
    auto thr_layout_vmnk = mma.get_thr_layout_vmnk();

    // Reorder the tensor for the TiledAtom
    auto t_tile = make_tile(get<1>(permutation_mnk),
                            get<2>(permutation_mnk));
    auto t_tensor = logical_divide(sfb0tensor, t_tile);                 // (PermN,PermK)

    // Tile the tensor for the Atom
    auto a_tile = make_tile(make_layout(size<1>(AtomShape_MNK{})),
                            make_layout(size<2>(AtomShape_MNK{})));
    auto a_tensor = zipped_divide(t_tensor, a_tile);                 // ((AtomN,AtomK),(RestN,RestK))

    // Transform the Atom mode from (M,K) to (Thr,Val)
    auto tv_tensor = a_tensor.compose(AtomLayoutSFB0_TV{},_);           // ((ThrV,FrgV),(RestN,RestK))

    // Tile the tensor for the Thread
    auto thr_tile = make_tile(_,
                              make_tile(make_layout(size<2>(thr_layout_vmnk)),
                                        make_layout(size<3>(thr_layout_vmnk))));
    auto thr_tensor = zipped_divide(tv_tensor, thr_tile);            // ((ThrV,(ThrN,ThrK)),(FrgV,(RestN,RestK)))
    return thr_tensor;
  }

  template <class SFB1Tensor, class Atom, class TiledThr, class TiledPerm>
  CUTE_HOST_DEVICE constexpr
  auto
  thrfrg_SFB1(SFB1Tensor&& sfb1tensor, TiledMMA<Atom, TiledThr, TiledPerm>& mma)
  {
    CUTE_STATIC_ASSERT_V(rank(sfb1tensor) >= Int<2>{});

    using AtomShape_MNK  = typename Atom::Shape_MNK;
    using AtomLayoutSFB1_TV = typename Atom::Traits::SFBLayout;

    auto permutation_mnk = TiledPerm{};
    auto thr_layout_vmnk = mma.get_thr_layout_vmnk();

    // Reorder the tensor for the TiledAtom
    auto t_tile = make_tile(get<1>(permutation_mnk),
                            get<2>(permutation_mnk));
    auto t_tensor = logical_divide(sfb1tensor, t_tile);                 // (PermN,PermK)

    // Tile the tensor for the Atom
    auto a_tile = make_tile(make_layout(size<1>(AtomShape_MNK{})),
                            make_layout(size<2>(AtomShape_MNK{})));
    auto a_tensor = zipped_divide(t_tensor, a_tile);                 // ((AtomN,AtomK),(RestN,RestK))

    // Transform the Atom mode from (M,K) to (Thr,Val)
    auto tv_tensor = a_tensor.compose(AtomLayoutSFB1_TV{},_);           // ((ThrV,FrgV),(RestN,RestK))

    // Tile the tensor for the Thread
    auto thr_tile = make_tile(_,
                              make_tile(make_layout(size<2>(thr_layout_vmnk)),
                                        make_layout(size<3>(thr_layout_vmnk))));
    auto thr_tensor = zipped_divide(tv_tensor, thr_tile);            // ((ThrV,(ThrN,ThrK)),(FrgV,(RestN,RestK)))
    return thr_tensor;
  }

  template <class SFATensor, class ThrMma>
  CUTE_HOST_DEVICE constexpr
  auto
  partition_fragment_SFA(SFATensor&& sfatensor, ThrMma& thread_mma)
  {
    using ValTypeSF = typename ThrMma::Atom::Traits::ValTypeSF;
    auto thr_tensor = make_tensor(static_cast<SFATensor&&>(sfatensor).data(), thrfrg_SFA(sfatensor.layout(),thread_mma));
    auto thr_vmnk = thread_mma.thr_vmnk_;
    auto thr_vmk = make_coord(get<0>(thr_vmnk), make_coord(get<1>(thr_vmnk), get<3>(thr_vmnk)));
    auto partition_SFA =  thr_tensor(thr_vmk, make_coord(_, repeat<rank<1,1>(thr_tensor)>(_)));
    return make_fragment_like<ValTypeSF>(partition_SFA);
  }

  template <class SFB0Tensor, class ThrMma>
  CUTE_HOST_DEVICE constexpr
  auto
  partition_fragment_SFB0(SFB0Tensor&& sfb0tensor, ThrMma& thread_mma)
  {
    using ValTypeSF = typename ThrMma::Atom::Traits::ValTypeSF;
    auto thr_tensor = make_tensor(static_cast<SFB0Tensor&&>(sfb0tensor).data(), thrfrg_SFB0(sfb0tensor.layout(),thread_mma));
    auto thr_vmnk = thread_mma.thr_vmnk_;
    auto thr_vnk = make_coord(get<0>(thr_vmnk), make_coord(get<2>(thr_vmnk), get<3>(thr_vmnk)));
    auto partition_SFB0 =  thr_tensor(thr_vnk, make_coord(_, repeat<rank<1,1>(thr_tensor)>(_)));
    return make_fragment_like<ValTypeSF>(partition_SFB0);
  }

  template <class SFB1Tensor, class ThrMma>
  CUTE_HOST_DEVICE constexpr
  auto
  partition_fragment_SFB1(SFB1Tensor&& sfb1tensor, ThrMma& thread_mma)
  {
    using ValTypeSF = typename ThrMma::Atom::Traits::ValTypeSF;
    auto thr_tensor = make_tensor(static_cast<SFB1Tensor&&>(sfb1tensor).data(), thrfrg_SFB1(sfb1tensor.layout(),thread_mma));
    auto thr_vmnk = thread_mma.thr_vmnk_;
    auto thr_vnk = make_coord(get<0>(thr_vmnk), make_coord(get<2>(thr_vmnk), get<3>(thr_vmnk)));
    auto partition_SFB1 =  thr_tensor(thr_vnk, make_coord(_, repeat<rank<1,1>(thr_tensor)>(_)));
    return make_fragment_like<ValTypeSF>(partition_SFB1);
  }

  template<class TiledMma>
  CUTE_HOST_DEVICE constexpr
  auto
  get_layoutSFA_TV(TiledMma& mma)
  {
    // (M,K) -> (M,K)
    auto tile_shape_mnk = tile_shape(mma);
    auto ref_A = make_layout(make_shape(size<0>(tile_shape_mnk), size<2>(tile_shape_mnk)));
    auto thr_layout_vmnk = mma.get_thr_layout_vmnk();

    // (ThrV,(ThrM,ThrK)) -> (ThrV,(ThrM,ThrN,ThrK))
    auto atile = make_tile(_,
                          make_tile(make_layout(make_shape (size<1>(thr_layout_vmnk), size<2>(thr_layout_vmnk)),
                                                make_stride(               Int<1>{} ,                Int<0>{} )),
                                    _));

    // thr_idx -> (ThrV,ThrM,ThrN,ThrK)
    auto thridx_2_thrid = right_inverse(thr_layout_vmnk);
    // (thr_idx,val) -> (M,K)
    return thrfrg_SFA(ref_A, mma).compose(atile, _).compose(thridx_2_thrid, _);
  }

  template<class TiledMma>
  CUTE_HOST_DEVICE constexpr
  auto
  get_layoutSFB0_TV(TiledMma& mma)
  {
    // (N,K) -> (N,K)
    auto tile_shape_mnk = tile_shape(mma);
    auto ref_B0 = make_layout(make_shape(size<1>(tile_shape_mnk), size<2>(tile_shape_mnk)));
    auto thr_layout_vmnk = mma.get_thr_layout_vmnk();

    // (ThrV,(ThrM,ThrK)) -> (ThrV,(ThrM,ThrN,ThrK))
    auto btile = make_tile(_,
                          make_tile(make_layout(make_shape (size<1>(thr_layout_vmnk), size<2>(thr_layout_vmnk)),
                                                make_stride(               Int<0>{} ,                Int<1>{} )),
                                    _));

    // thr_idx -> (ThrV,ThrM,ThrN,ThrK)
    auto thridx_2_thrid = right_inverse(thr_layout_vmnk);
    // (thr_idx,val) -> (M,K)
    return thrfrg_SFB0(ref_B0, mma).compose(btile, _).compose(thridx_2_thrid, _);
  }

  template<class TiledMma>
  CUTE_HOST_DEVICE constexpr
  auto
  get_layoutSFB1_TV(TiledMma& mma)
  {
    // (N,K) -> (N,K)
    auto tile_shape_mnk = tile_shape(mma);
    auto ref_B1 = make_layout(make_shape(size<1>(tile_shape_mnk), size<2>(tile_shape_mnk)));
    auto thr_layout_vmnk = mma.get_thr_layout_vmnk();

    // (ThrV,(ThrM,ThrK)) -> (ThrV,(ThrM,ThrN,ThrK))
    auto btile = make_tile(_,
                          make_tile(make_layout(make_shape (size<1>(thr_layout_vmnk), size<2>(thr_layout_vmnk)),
                                                make_stride(               Int<0>{} ,                Int<1>{} )),
                                    _));

    // thr_idx -> (ThrV,ThrM,ThrN,ThrK)
    auto thridx_2_thrid = right_inverse(thr_layout_vmnk);
    // (thr_idx,val) -> (M,K)
    return thrfrg_SFB1(ref_B1, mma).compose(btile, _).compose(thridx_2_thrid, _);
  }

  /// Set up the data needed by this collective for load and mma.
  /// Returns a tuple of tensors. The collective and the kernel layer have the contract
  /// Returned tuple must contain at least two elements, with the first two elements being:
  /// gA_mkl - The tma tensor, A after a local tile so it has shape  (BLK_M,BLK_K,m,k,l)
  /// gB_nkl - The tma tensor, B after a local tile so it has shape  (BLK_N,BLK_K,n,k,l)
  /// The rest of the tensors can be specified as needed by this collective.
  template <class ProblemShape_MNKL>
  CUTLASS_DEVICE auto
  load_init(ProblemShape_MNKL const& problem_shape_MNKL, Params const& params) const {
    using X = Underscore;
    // Separate out problem shape for convenience
    auto [M, N, K, L] = problem_shape_MNKL;

    // TMA requires special handling of strides to deal with coord codomain mapping
    // Represent the full tensors -- get these from TMA
    Tensor mA_mkl = params.tma_load_a.get_tma_tensor(make_shape(M,K,L));                            // (m,k,l)
    Tensor mB0_nkl = params.tma_load_b0.get_tma_tensor(make_shape(N,K,L));                          // (n,k,l)
    Tensor mB1_nkl = params.tma_load_b1.get_tma_tensor(make_shape(N,K,L));                          // (n,k,l)
    Tensor mSFA_mkl = params.tma_load_sfa.get_tma_tensor(shape(params.layout_SFA));
    Tensor mSFB0_nkl = params.tma_load_sfb0.get_tma_tensor(shape(params.layout_SFB0));
    Tensor mSFB1_nkl = params.tma_load_sfb1.get_tma_tensor(shape(params.layout_SFB1));

    // Make tiled views, defer the slice
    Tensor gA_mkl = local_tile(mA_mkl, TileShape{}, make_coord(_,_,_), Step<_1, X,_1>{});          // (BLK_M,BLK_K,m,k,l)
    Tensor gB0_nkl = local_tile(mB0_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});        // (BLK_N,BLK_K,n,k,l)
    Tensor gB1_nkl = local_tile(mB1_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});        // (BLK_N,BLK_K,n,k,l)

    Tensor gSFA_mkl = local_tile(mSFA_mkl, TileShape{}, make_coord(_,_,_), Step<_1, X,_1>{});      // (TILE_M,TILE_K,m,k,l)
    Tensor gSFB0_nkl = local_tile(mSFB0_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});    // (TILE_N,TILE_K,n,k,l)
    Tensor gSFB1_nkl = local_tile(mSFB1_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});    // (TILE_N,TILE_K,n,k,l)

    return cute::make_tuple(gA_mkl, gB0_nkl, gB1_nkl, gSFA_mkl, gSFB0_nkl, gSFB1_nkl);
  }

  /// Perform a collective-scoped matrix multiply-accumulate
  /// Producer Perspective
  template <
    class TensorA, class TensorB0, class TensorB1,
    class TensorSFA, class TensorSFB0, class TensorSFB1,
    class KTileIterator, class BlockCoord
  >
  CUTLASS_DEVICE void
  load(
      Params const& params,
      MainloopPipeline pipeline,
      PipelineState smem_pipe_write,
      cute::tuple<TensorA, TensorB0, TensorB1, TensorSFA, TensorSFB0, TensorSFB1> const& load_inputs,
      BlockCoord const& blk_coord,
      KTileIterator k_tile_iter, int k_tile_count,
      int thread_idx,
      uint32_t block_rank_in_cluster,
      TensorStorage& shared_tensors) {
    int lane_predicate = cute::elect_one_sync();

    if (lane_predicate) {

      Tensor sA = make_tensor(make_smem_ptr(shared_tensors.smem_A.begin()), SmemLayoutA{});           // (BLK_M,BLK_K,PIPE)
      Tensor sB0 = make_tensor(make_smem_ptr(shared_tensors.smem_B0.begin()), SmemLayoutB0{});        // (BLK_N,BLK_K,PIPE)
      Tensor sB1 = make_tensor(make_smem_ptr(shared_tensors.smem_B1.begin()), SmemLayoutB1{});        // (BLK_N,BLK_K,PIPE)
      Tensor sSFA = make_tensor(make_smem_ptr(shared_tensors.smem_SFA.begin()), SmemLayoutSFA{});     // (BLK_M,BLK_K,PIPE)
      Tensor sSFB0 = make_tensor(make_smem_ptr(shared_tensors.smem_SFB0.begin()), SmemLayoutSFB0{});  // (BLK_N,BLK_K,PIPE)
      Tensor sSFB1 = make_tensor(make_smem_ptr(shared_tensors.smem_SFB1.begin()), SmemLayoutSFB1{});  // (BLK_N,BLK_K,PIPE)

      //
      // Prepare the TMA loads for A, B, SFA and SFB
      //

      auto [gA_mkl, gB0_nkl, gB1_nkl, gSFA_mkl, gSFB0_nkl, gSFB1_nkl] = load_inputs;

      auto block_tma_a   = params.tma_load_a.get_slice(0);
      auto block_tma_b0  = params.tma_load_b0.get_slice(0);
      auto block_tma_b1  = params.tma_load_b1.get_slice(0);

      auto block_tma_sfa  = params.tma_load_sfa.get_slice(0);
      auto block_tma_sfb0 = params.tma_load_sfb0.get_slice(0);
      auto block_tma_sfb1 = params.tma_load_sfb1.get_slice(0);

      // Partition the inputs based on the current block coordinates.
      auto [m_coord, n_coord, k_coord, l_coord] = blk_coord;

      Tensor gA  =   gA_mkl(_,_,m_coord,_,l_coord);                                                    // (BLK_M,BLK_K,k)
      Tensor gB0 =   gB0_nkl(_,_,n_coord,_,l_coord);                                                   // (BLK_N,BLK_K,k)
      Tensor gB1 =   gB1_nkl(_,_,n_coord,_,l_coord);                                                   // (BLK_N,BLK_K,k)
      Tensor gSFA  = gSFA_mkl(_,_,m_coord,_,l_coord);                                                  // (BLK_M,BLK_K,k)
      Tensor gSFB0 = gSFB0_nkl(_,_,n_coord,_,l_coord);                                                 // (BLK_N,BLK_K,k)
      Tensor gSFB1 = gSFB1_nkl(_,_,n_coord,_,l_coord);                                                 // (BLK_N,BLK_K,k)

      // Partition source and destination tensors for tma copies
      Tensor tAgA = block_tma_a.partition_S(gA);                                              // (TMA,TMA_M,TMA_K,k)
      Tensor tAsA = block_tma_a.partition_D(sA);                                              // (TMA,TMA_M,TMA_K,PIPE)

      Tensor tBgB0 = block_tma_b0.partition_S(gB0);                                           // (TMA,TMA_N,TMA_K,k)
      Tensor tBsB0 = block_tma_b0.partition_D(sB0);                                           // (TMA,TMA_N,TMA_K,PIPE)
      Tensor tBgB1 = block_tma_b1.partition_S(gB1);                                           // (TMA,TMA_N,TMA_K,k)
      Tensor tBsB1 = block_tma_b1.partition_D(sB1);                                           // (TMA,TMA_N,TMA_K,PIPE)

      Tensor tAgSFA = block_tma_sfa.partition_S(gSFA);                                        // (TMA,TMA_M,TMA_K,k)
      Tensor tAsSFA = block_tma_sfa.partition_D(sSFA);                                        // (TMA,TMA_M,TMA_K,PIPE)

      Tensor tBgSFB0 = block_tma_sfb0.partition_S(gSFB0);                                     // (TMA,TMA_N,TMA_K,k)
      Tensor tBsSFB0 = block_tma_sfb0.partition_D(sSFB0);                                     // (TMA,TMA_N,TMA_K,PIPE)
      Tensor tBgSFB1 = block_tma_sfb1.partition_S(gSFB1);                                     // (TMA,TMA_N,TMA_K,k)
      Tensor tBsSFB1 = block_tma_sfb1.partition_D(sSFB1);                                     // (TMA,TMA_N,TMA_K,PIPE)

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
        copy(params.tma_load_a.with(*tma_barrier), tAgA(_,_,_,*k_tile_iter), tAsA(_,_,_,write_stage));
        copy(params.tma_load_b0.with(*tma_barrier), tBgB0(_,_,_,*k_tile_iter), tBsB0(_,_,_,write_stage));
        copy(params.tma_load_b1.with(*tma_barrier), tBgB1(_,_,_,*k_tile_iter), tBsB1(_,_,_,write_stage));

        copy(params.tma_load_sfa.with(*tma_barrier), tAgSFA(_,_,_,*k_tile_iter), tAsSFA(_,_,_,write_stage));
        copy(params.tma_load_sfb0.with(*tma_barrier), tBgSFB0(_,_,_,*k_tile_iter), tBsSFB0(_,_,_,write_stage));
        copy(params.tma_load_sfb1.with(*tma_barrier), tBgSFB1(_,_,_,*k_tile_iter), tBsSFB1(_,_,_,write_stage));

        // Advance k tile
        ++k_tile_iter;
        ++smem_pipe_write;
      }
    }
    __syncwarp();
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
      [[maybe_unused]] Params const& params) {
    using namespace cute;

    static_assert(is_rmem<FrgTensorC0>::value, "C tensor must be rmem resident.");
    static_assert(is_rmem<FrgTensorC1>::value, "C tensor must be rmem resident.");

    clear(accum0);
    clear(accum1);

    Tensor sA = make_tensor(make_smem_ptr(shared_tensors.smem_A.begin()), SmemLayoutA{});            // (BLK_M,BLK_K,PIPE)
    Tensor sB0 = make_tensor(make_smem_ptr(shared_tensors.smem_B0.begin()), SmemLayoutB0{});         // (BLK_N,BLK_K,PIPE)
    Tensor sB1 = make_tensor(make_smem_ptr(shared_tensors.smem_B1.begin()), SmemLayoutB1{});         // (BLK_N,BLK_K,PIPE)
    Tensor sSFA = make_tensor(make_smem_ptr(shared_tensors.smem_SFA.begin()), SmemLayoutSFA{});     // (BLK_M,BLK_K,PIPE)
    Tensor sSFB0 = make_tensor(make_smem_ptr(shared_tensors.smem_SFB0.begin()), SmemLayoutSFB0{});  // (BLK_N,BLK_K,PIPE)
    Tensor sSFB1 = make_tensor(make_smem_ptr(shared_tensors.smem_SFB1.begin()), SmemLayoutSFB1{});  // (BLK_N,BLK_K,PIPE)

    //
    // Define C accumulators and A/B partitioning
    //

    TiledMma tiled_mma;
    auto thread_mma = tiled_mma.get_thread_slice(thread_idx);

    // Allocate fragments and descriptors
    Tensor tCrA  = thread_mma.partition_fragment_A(sA(_,_,Int<0>{}));                        // (MMA,MMA_M,MMA_K)
    Tensor tCrB0 = thread_mma.partition_fragment_B(sB0(_,_,Int<0>{}));                       // (MMA,MMA_N,MMA_K)
    Tensor tCrB1 = thread_mma.partition_fragment_B(sB1(_,_,Int<0>{}));                       // (MMA,MMA_N,MMA_K)

    Tensor tCrSFA  = partition_fragment_SFA(sSFA(_,_,Int<0>{}), thread_mma);                 // (MMA,MMA_M,MMA_K)
    Tensor tCrSFB0 = partition_fragment_SFB0(sSFB0(_,_,Int<0>{}), thread_mma);               // (MMA,MMA_N,MMA_K)
    Tensor tCrSFB1 = partition_fragment_SFB1(sSFB1(_,_,Int<0>{}), thread_mma);               // (MMA,MMA_N,MMA_K)

    //
    // Copy from smem to registers
    //

    // A
    auto smem_tiled_copy_A = make_tiled_copy_A(SmemCopyAtomA{}, tiled_mma);
    auto smem_thr_copy_A   = smem_tiled_copy_A.get_thread_slice(thread_idx);
    Tensor tCsA            = smem_thr_copy_A.partition_S(
      as_position_independent_swizzle_tensor(sA));                                      // (CPY,CPY_M,CPY_K,PIPE)
    Tensor tCrA_copy_view  = smem_thr_copy_A.retile_D(tCrA);                            //      (CPY,CPY_M,CPY_K)

    // B0
    auto smem_tiled_copy_B0 = make_tiled_copy_B(SmemCopyAtomB0{}, tiled_mma);
    auto smem_thr_copy_B0   = smem_tiled_copy_B0.get_thread_slice(thread_idx);
    Tensor tCsB0            = smem_thr_copy_B0.partition_S(
      as_position_independent_swizzle_tensor(sB0));                                     // (CPY,CPY_M,CPY_K,PIPE)
    Tensor tCrB0_copy_view  = smem_thr_copy_B0.retile_D(tCrB0);                         //      (CPY,CPY_M,CPY_K)

    // B1
    auto smem_tiled_copy_B1 = make_tiled_copy_B(SmemCopyAtomB1{}, tiled_mma);
    auto smem_thr_copy_B1   = smem_tiled_copy_B1.get_thread_slice(thread_idx);
    Tensor tCsB1            = smem_thr_copy_B1.partition_S(
      as_position_independent_swizzle_tensor(sB1));                                     // (CPY,CPY_M,CPY_K,PIPE)
    Tensor tCrB1_copy_view  = smem_thr_copy_B1.retile_D(tCrB1);                         //      (CPY,CPY_M,CPY_K)

    // SFA
    auto tile_shape_mnk = tile_shape(tiled_mma);
    auto smem_tiled_copy_SFA = make_tiled_copy_impl(SmemCopyAtomSFA{},
                                                    get_layoutSFA_TV(tiled_mma),
                                                    make_shape(size<0>(tile_shape_mnk), size<2>(tile_shape_mnk))
                                                  );
    auto smem_thr_copy_SFA   = smem_tiled_copy_SFA.get_thread_slice(thread_idx);
    Tensor tCsSFA            = smem_thr_copy_SFA.partition_S(
        as_position_independent_swizzle_tensor(sSFA));                                     // (CPY,CPY_M,CPY_K,PIPE)
    Tensor tCrSFA_copy_view  = smem_thr_copy_SFA.retile_D(tCrSFA);                         //      (CPY,CPY_M,CPY_K)

    // SFB0
    auto smem_tiled_copy_SFB0 = make_tiled_copy_impl(SmemCopyAtomSFB0{},
                                                    get_layoutSFB0_TV(tiled_mma),
                                                    make_shape(size<1>(tile_shape_mnk), size<2>(tile_shape_mnk))
                                                  );
    auto smem_thr_copy_SFB0   = smem_tiled_copy_SFB0.get_thread_slice(thread_idx);
    Tensor tCsSFB0            = smem_thr_copy_SFB0.partition_S(
      as_position_independent_swizzle_tensor(sSFB0));                                     // (CPY,CPY_N,CPY_K,PIPE)
    Tensor tCrSFB0_copy_view  = smem_thr_copy_SFB0.retile_D(tCrSFB0);                     //      (CPY,CPY_N,CPY_K)

    // SFB1
    auto smem_tiled_copy_SFB1 = make_tiled_copy_impl(SmemCopyAtomSFB1{},
                                                    get_layoutSFB1_TV(tiled_mma),
                                                    make_shape(size<1>(tile_shape_mnk), size<2>(tile_shape_mnk))
                                                  );
    auto smem_thr_copy_SFB1   = smem_tiled_copy_SFB1.get_thread_slice(thread_idx);
    Tensor tCsSFB1            = smem_thr_copy_SFB1.partition_S(
      as_position_independent_swizzle_tensor(sSFB1));                                     // (CPY,CPY_N,CPY_K,PIPE)
    Tensor tCrSFB1_copy_view  = smem_thr_copy_SFB1.retile_D(tCrSFB1);                     //      (CPY,CPY_N,CPY_K)

    CUTE_STATIC_ASSERT_V(size<1>(tCsA)  == size<1>(tCrA_copy_view));                      // CPY_M
    CUTE_STATIC_ASSERT_V(size<2>(tCsA)  == size<2>(tCrA_copy_view));                      // CPY_K
    CUTE_STATIC_ASSERT_V(size<1>(tCrA)  == size<1>(accum0));                              // MMA_M
    CUTE_STATIC_ASSERT_V(size<1>(tCrA)  == size<1>(accum1));                              // MMA_M
    CUTE_STATIC_ASSERT_V(size<1>(tCrB0) == size<2>(accum0));                              // MMA_N
    CUTE_STATIC_ASSERT_V(size<1>(tCrB1) == size<2>(accum1));                              // MMA_N
    CUTE_STATIC_ASSERT_V(size<2>(tCsA)  == size<2>(tCsB0));                               // CPY_K
    CUTE_STATIC_ASSERT_V(size<2>(tCsA)  == size<2>(tCsB1));                               // CPY_K
    CUTE_STATIC_ASSERT_V(size<3>(tCsA)  == size<3>(tCsB0));                               // PIPE
    CUTE_STATIC_ASSERT_V(size<3>(tCsA)  == size<3>(tCsB1));                               // PIPE
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sA));                   // PIPE
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sB0));                  // PIPE
    CUTE_STATIC_ASSERT_V(Int<DispatchPolicy::Stages>{} == size<2>(sB1));                  // PIPE

    CUTE_STATIC_ASSERT_V(size<1>(tCsSFA)  == size<1>(tCrSFA_copy_view));                  // CPY_M
    CUTE_STATIC_ASSERT_V(size<2>(tCsSFA)  == size<2>(tCrSFA_copy_view));                  // CPY_K
    CUTE_STATIC_ASSERT_V(size<1>(tCrSFA)  == size<1>(accum0));                            // MMA_M
    CUTE_STATIC_ASSERT_V(size<1>(tCrSFA)  == size<1>(accum1));                            // MMA_M
    CUTE_STATIC_ASSERT_V(size<1>(tCrSFB0) == size<2>(accum0));                            // MMA_N
    CUTE_STATIC_ASSERT_V(size<1>(tCrSFB1) == size<2>(accum1));                            // MMA_N
    CUTE_STATIC_ASSERT_V(size<2>(tCsSFA)  == size<2>(tCsSFB0));                           // CPY_K
    CUTE_STATIC_ASSERT_V(size<2>(tCsSFA)  == size<2>(tCsSFB1));                           // CPY_K
    CUTE_STATIC_ASSERT_V(size<3>(tCsSFA)  == size<3>(tCsSFB0));                           // PIPE
    CUTE_STATIC_ASSERT_V(size<3>(tCsSFA)  == size<3>(tCsSFB1));                           // PIPE
    CUTE_STATIC_ASSERT_V(size<2>(sA)  == size<2>(sSFA));                                  // PIPE
    CUTE_STATIC_ASSERT_V(size<2>(sB0) == size<2>(sSFA));                                  // PIPE
    CUTE_STATIC_ASSERT_V(size<2>(sB1) == size<2>(sSFA));                                  // PIPE

    //
    // PIPELINED MAIN LOOP
    //

    // Size of the register pipeline
    auto K_BLOCK_MAX = size<2>(tCrA);

    int read_stage = smem_pipe_read.index();
    auto tCsA_stage    = tCsA(_,_,_,read_stage);
    auto tCsB0_stage   = tCsB0(_,_,_,read_stage);
    auto tCsB1_stage   = tCsB1(_,_,_,read_stage);
    auto tCsSFA_stage  = tCsSFA(_,_,_,read_stage);
    auto tCsSFB0_stage = tCsSFB0(_,_,_,read_stage);
    auto tCsSFB1_stage = tCsSFB1(_,_,_,read_stage);

    auto copy_kblock = [&](auto k_block) {
      // copy smem->rmem for A/B operand
      copy(smem_tiled_copy_A, tCsA_stage(_,_,k_block), tCrA_copy_view(_,_,k_block));
      copy(smem_tiled_copy_B0, tCsB0_stage(_,_,k_block), tCrB0_copy_view(_,_,k_block));
      copy(smem_tiled_copy_B1, tCsB1_stage(_,_,k_block), tCrB1_copy_view(_,_,k_block));

      // Left shift A,B for FP4
      using MMAOp = typename TiledMma::MMA_Op;
      fp4_shift_A(MMAOp{}, tCrA_copy_view(_,_,k_block));
      fp4_shift_B(MMAOp{}, tCrB0_copy_view(_,_,k_block));
      fp4_shift_B(MMAOp{}, tCrB1_copy_view(_,_,k_block));


      // Copy smem->rmem for SFA/SFB operand
      copy(tCsSFA_stage(_,_,k_block), tCrSFA_copy_view(_,_,k_block));
      copy(tCsSFB0_stage(_,_,k_block), tCrSFB0_copy_view(_,_,k_block));
      copy(tCsSFB1_stage(_,_,k_block), tCrSFB1_copy_view(_,_,k_block));
    };

    auto gemm_kblock = [&](auto k_block) {
      cute::gemm(tiled_mma,
                 make_zip_tensor(tCrA   (_,_,k_block), tCrSFA  (_,_,k_block)),
                 make_zip_tensor(tCrB0  (_,_,k_block), tCrSFB0 (_,_,k_block)),
                 accum0);
      cute::gemm(tiled_mma,
                 make_zip_tensor(tCrA   (_,_,k_block), tCrSFA  (_,_,k_block)),
                 make_zip_tensor(tCrB1  (_,_,k_block), tCrSFB1 (_,_,k_block)),
                 accum1);
    };

    pipeline.consumer_wait(smem_pipe_read);

    copy_kblock(_0{});
    CUTLASS_PRAGMA_NO_UNROLL
    for ( ; k_tile_count > 1; --k_tile_count) {
      //
      // Compute on k_tile
      //
      for_each(make_int_sequence<K_BLOCK_MAX>{}, [&] (auto k_block) {

        auto k_block_next = ((k_block + 1) == K_BLOCK_MAX) ? 0 : (k_block + 1);

        if (k_block == K_BLOCK_MAX - 1) {
          cutlass::arch::NamedBarrier::sync(
          thr_size(tiled_mma), cutlass::arch::ReservedNamedBarriers::Sm120MainloopBarrier);
          // UNLOCK smem_pipe_read, done _computing_ on it
          pipeline.consumer_release(smem_pipe_read);
          ++smem_pipe_read;
          read_stage = smem_pipe_read.index();
          tCsA_stage    = tCsA(_,_,_,read_stage);
          tCsB0_stage   = tCsB0(_,_,_,read_stage);
          tCsB1_stage   = tCsB1(_,_,_,read_stage);
          tCsSFA_stage  = tCsSFA(_,_,_,read_stage);
          tCsSFB0_stage = tCsSFB0(_,_,_,read_stage);
          tCsSFB1_stage = tCsSFB1(_,_,_,read_stage);
          pipeline.consumer_wait(smem_pipe_read);
        }

        copy_kblock(k_block_next);
        gemm_kblock(k_block);

      });
    } // k_tile_count

    //
    // Hoist out last k_tile
    //
    for_each(make_int_sequence<K_BLOCK_MAX>{}, [&] (auto k_block) {

      auto k_block_next = ((k_block + 1) == K_BLOCK_MAX) ? 0 : (k_block + 1);

      if (k_block == K_BLOCK_MAX - 1) {
        cutlass::arch::NamedBarrier::sync(
        thr_size(tiled_mma), cutlass::arch::ReservedNamedBarriers::Sm120MainloopBarrier);
        // UNLOCK smem_pipe_read, done _computing_ on it
        pipeline.consumer_release(smem_pipe_read);
        ++smem_pipe_read;
      }

      if (k_block_next > 0) {
        copy_kblock(k_block_next);
      }
      gemm_kblock(k_block);

    });
}

  /// Perform a Consumer Epilogue to release all buffers
  CUTLASS_DEVICE void
  mma_tail(MainloopPipeline, PipelineState, int) {
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
