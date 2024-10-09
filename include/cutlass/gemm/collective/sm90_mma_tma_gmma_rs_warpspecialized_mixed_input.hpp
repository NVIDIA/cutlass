/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/gemm/gemm.h"
#include "cutlass/detail/dependent_false.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/numeric_types.h"
#include "cutlass/detail/layout.hpp"
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/transform/collective/sm90_wgmma_transpose.hpp"
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/trace.h"
#include "cutlass/detail/collective.hpp"

#include "cute/arch/cluster_sm90.hpp"
#include "cute/arch/copy_sm90.hpp"
#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/atom/copy_traits_sm90_tma.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cute/tensor_predicate.hpp"
#include "cute/numeric/arithmetic_tuple.hpp"

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
  class StrideA_,
  class ElementBOptionalTuple,
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
    MainloopSm90TmaGmmaRmemAWarpSpecializedMixedInput<Stages, ClusterShape, KernelSchedule>,
    TileShape_,
    ElementAOptionalTuple,
    StrideA_,
    ElementBOptionalTuple,
    StrideB_,
    TiledMma_,
    GmemTiledCopyA_,
    SmemLayoutAtomA_,
    SmemCopyAtomA_,
    TransformA_,
    GmemTiledCopyB_,
    SmemLayoutAtomB_,
    SmemCopyAtomB_,
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

  enum class ConversionMode {
    DirectConvert,
    ConvertAndScale,
    ConvertAndScaleWithZero
  };

  using ScaleA = detail::deduce_mixed_width_dtype_t<1, ElementAOptionalTuple>;
  using ScaleB = detail::deduce_mixed_width_dtype_t<1, ElementBOptionalTuple>;
  using ZeroA = detail::deduce_mixed_width_dtype_t<2, ElementAOptionalTuple>;
  using ZeroB = detail::deduce_mixed_width_dtype_t<2, ElementBOptionalTuple>;

public:
  //
  // Type Aliases
  //
  using DispatchPolicy = MainloopSm90TmaGmmaRmemAWarpSpecializedMixedInput<Stages, ClusterShape, KernelSchedule>;
  using TileShape = TileShape_;

  static_assert(cute::is_tuple<ElementAOptionalTuple>::value ^ cute::is_tuple<ElementBOptionalTuple>::value, 
    "Either A OR B must be a tuple. It must take the from {ElementOperand, [ElementScale],"
    "[ElementZero]}. Inputs in [] are optional.");

  using ElementA = detail::deduce_mixed_width_dtype_t<0, ElementAOptionalTuple>;
  using ElementB = detail::deduce_mixed_width_dtype_t<0, ElementBOptionalTuple>;
  static constexpr bool IsATransformed = cute::is_tuple<ElementAOptionalTuple>::value;
  using ElementScale = cute::conditional_t<IsATransformed, ScaleA, ScaleB>;
  using ElementZero = cute::conditional_t<IsATransformed, ZeroA, ZeroB>;
  // For cases where we can't have a void type, we can use this to allow the code to compile when the scale / zero is void.
  using NonVoidElementScale = cute::conditional_t<cute::is_void_v<ElementScale>, float, ElementScale>;
  using NonVoidElementZero = cute::conditional_t<cute::is_void_v<ElementZero>, float, ElementZero>;

  using StrideA = StrideA_;
  using StrideB = StrideB_;
  // These are always MN major
  using StrideScale = cute::Stride<cute::Int<1>, int64_t, int64_t>;
  // For cases where we can't have a void scale, we can use this to allow the code to compile when the scale is void.
  using NonVoidStrideScale = cute::conditional_t<
      cute::is_void_v<StrideScale>, cute::Stride<_1, int64_t, int64_t>, StrideScale>;

  static_assert((IsATransformed && cutlass::gemm::detail::is_k_major<StrideA>()) || 
                (!IsATransformed && cutlass::gemm::detail::is_k_major<StrideB>()),
                "The transformed type must be K-major.");

  static_assert(( IsATransformed && (sizeof(ElementB) == 2)) ||
                (!IsATransformed && (sizeof(ElementA) == 2)) ||
                (cutlass::gemm::detail::is_k_major<StrideA>() && 
                 cutlass::gemm::detail::is_k_major<StrideB>()), 
                "The unscaled element must be 2 bytes OR both inputs must be K-major");

  static_assert(cutlass::gemm::detail::is_mn_major<NonVoidStrideScale>(), 
    "Scale must be MN major [Col Major if A is scaled, Row Major if B is scaled].");

  using CtaShape_MNK = decltype(shape_div(TileShape{}, ClusterShape{}));

  using TiledMma = TiledMma_;
  using ElementAccumulator = typename TiledMma::ValTypeC;

  using GmemTiledCopyA = GmemTiledCopyA_;
  using GmemTiledCopyB = GmemTiledCopyB_;
  using GmemTiledCopyScale = cute::SM90_TMA_LOAD;

  using SmemLayoutAtomA = SmemLayoutAtomA_;
  using SmemLayoutAtomB = SmemLayoutAtomB_;
  // Scale layout atom set after swapping.

  using SmemCopyAtomA = SmemCopyAtomA_;
  using SmemCopyAtomB = SmemCopyAtomB_;
  using SmemCopyAtomScale = Copy_Atom<cute::AutoVectorizingCopy, NonVoidElementScale>;

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

  static constexpr int IsSubbyteA = cute::sizeof_bits_v<InternalElementA> < 8;
  using TmaElementA = cute::conditional_t<IsSubbyteA, uint8_t, InternalElementA>;
  using TmaElementScale = uint_bit_t<sizeof_bits_v<NonVoidElementScale> >; // in case we have array. translating to uint to satisfy tma descriptor's specialization

  using ArchTag = typename DispatchPolicy::ArchTag;

  using MainloopPipeline = cutlass::PipelineTmaAsync<
                             DispatchPolicy::Stages>;
  using PipelineState = cutlass::PipelineState<DispatchPolicy::Stages>;

  using PipelineParams = typename MainloopPipeline::Params;

  using SmemLayoutAtomScale = Layout<Shape<decltype(cute::shape<0>(InternalSmemLayoutAtomA{})), cute::Int<1>>>;
  using ScaleTileShape = decltype(make_shape(shape<0>(TileShape{}), shape<1>(SmemLayoutAtomScale{})));

  static_assert(cute::rank(InternalSmemLayoutAtomA{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<0>(TileShape{}) % size<0>(InternalSmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(InternalSmemLayoutAtomA{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(cute::rank(InternalSmemLayoutAtomB{}) == 2, "SmemLayoutAtom must be rank 2 (M/N, K)");
  static_assert((size<1>(TileShape{}) % size<0>(InternalSmemLayoutAtomB{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(InternalSmemLayoutAtomB{})) == 0, "SmemLayoutAtom must evenly divide tile shape.");

  static_assert(rank(SmemLayoutAtomScale{}) == 2, "SmemLayoutAtomScale must be rank 2");
  static_assert((size<0>(TileShape{}) % size<0>(SmemLayoutAtomScale{})) == 0, "SmemLayoutAtomScale must equal the tile shape.");
  static_assert((size<2>(TileShape{}) % size<1>(SmemLayoutAtomScale{})) == 0, "SmemLayoutAtomScale must evenly divide tile k shape.");

  // Tile along modes in a way that maximizes the TMA box size.
  using SmemLayoutA = decltype(tile_to_shape(
      InternalSmemLayoutAtomA{},
      make_shape(shape<0>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      cute::conditional_t< ::cutlass::gemm::detail::is_major<0,InternalStrideA>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));
  using SmemLayoutB = decltype(tile_to_shape(
      InternalSmemLayoutAtomB{},
      make_shape(shape<1>(TileShape{}), shape<2>(TileShape{}), Int<DispatchPolicy::Stages>{}),
      cute::conditional_t< ::cutlass::gemm::detail::is_major<0,InternalStrideB>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));
    
  // It is assumed that the scales and zero-points share the same smem layout
  using SmemLayoutScale = decltype(tile_to_shape(
    SmemLayoutAtomScale{}, 
    make_shape(shape<0>(ScaleTileShape{}), shape<1>(ScaleTileShape{}), Int<Stages>{}),
    cute::conditional_t< ::cutlass::gemm::detail::is_major<0,NonVoidStrideScale>(), Step<_2,_1,_3>, Step<_1,_2,_3>>{}));

  static_assert(DispatchPolicy::Stages >= 2, "Specialization requires Stages set to value 2 or more.");
  static_assert(not cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeA>::value &&
                    cute::is_base_of<cute::GMMA::DescriptorIterator, typename TiledMma::FrgTypeB>::value,
                "MMA atom must source A from rmem and B operand from smem_desc for this mainloop.");
  static_assert(cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");
  static_assert(cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");

  // To relax them, we need to handle loading more than 1 row of scales for every main loop iteration.
  // We must also handle updating the pipeline transaction bytes on the fly.
  // NOTE: Deleting this assertion without required changes will cause the code to hang.
  static_assert(size<1>(SmemLayoutAtomScale{}) == 1, "size<1>(SmemLayoutAtomScale) must be 1.");

private:
  static constexpr ConversionMode 
  get_conversion_mode() {
    if constexpr (cute::is_void_v<ElementScale>) {
      return ConversionMode::DirectConvert;
    } 
    else if constexpr (cute::is_void_v<ElementZero>) {
      return ConversionMode::ConvertAndScale;
    }
    else {
      return ConversionMode::ConvertAndScaleWithZero;
    }
  }

  static constexpr ConversionMode KernelConversionMode = get_conversion_mode();
  static constexpr bool ModeHasScales = KernelConversionMode == ConversionMode::ConvertAndScale ||
                                        KernelConversionMode == ConversionMode::ConvertAndScaleWithZero;
  static constexpr bool UseScaleLookupTable = KernelConversionMode == ConversionMode::ConvertAndScale &&
                                              cutlass::detail::is_Array_v<ElementScale>;

  static constexpr auto
  elements_per_smem_scale() {
    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      return 0;
    } 
    else if constexpr (ModeHasScales) {
      return cute::cosize_v<SmemLayoutScale>;
    } 
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Type not handled in scale smem allocation.");
    }
  }

  static constexpr auto
  elements_per_smem_zero() {
    if constexpr (KernelConversionMode == ConversionMode::DirectConvert ||
                  KernelConversionMode == ConversionMode::ConvertAndScale ) {
      return 0;
    } 
    else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
      return cute::cosize_v<SmemLayoutScale>;
    } 
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Type not handled in scale smem allocation.");
    }
  }

  // These methods use some the public members of the class. For that reason, we define them after the public section.
  static constexpr uint32_t
  compute_tma_transaction_bytes_mk() {
    return cutlass::bits_to_bytes(size<0>(SmemLayoutA{}) * size<1>(SmemLayoutA{}) * static_cast<uint32_t>(cute::sizeof_bits_v<InternalElementA>));
  }

  static constexpr uint32_t
  compute_tma_transaction_bytes_nk() {
    return cutlass::bits_to_bytes(size<0>(SmemLayoutB{}) * size<1>(SmemLayoutB{}) * static_cast<uint32_t>(cute::sizeof_bits_v<InternalElementB>));
  }

  static constexpr uint32_t
  compute_tma_transaction_bytes_extra() {
    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      return 0;
    }
    else if constexpr (ModeHasScales) {
      constexpr uint32_t scale_tx_bytes = cutlass::bits_to_bytes(size<0>(SmemLayoutScale{}) * size<1>(SmemLayoutScale{}) * static_cast<uint32_t>(cute::sizeof_bits_v<ElementScale>));
      static_assert(scale_tx_bytes % 128 == 0, "Each scale stage must be 128B aligned."); // required by TMA
      if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
        return scale_tx_bytes;
      }
      else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
        // Scale and zero share smem layout
        constexpr uint32_t zero_tx_bytes = cutlass::bits_to_bytes(size<0>(SmemLayoutScale{}) * size<1>(SmemLayoutScale{}) * static_cast<uint32_t>(cute::sizeof_bits_v<ElementZero>));
        static_assert(zero_tx_bytes % 128 == 0, "Each zero stage must be 128B aligned."); // required by TMA
        return scale_tx_bytes + zero_tx_bytes;
      }
      else {
        static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Type not handled in tma transaction bytes computation.");
      }
    }
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Type not handled in tma transaction bytes computation.");
    }
  }

public:
  static constexpr size_t SmemAlignmentA = cutlass::detail::alignment_for_swizzle(SmemLayoutA{}); 

  static constexpr size_t SmemAlignmentB = cutlass::detail::alignment_for_swizzle(SmemLayoutB{});

  // Just pick the max alignment of A and B since it is required to be at least 128B
  static constexpr size_t SmemAlignmentScale = cute::max(SmemAlignmentA, SmemAlignmentB);

  static_assert(SmemAlignmentA >= 128 and SmemAlignmentB >= 128, "Require at least 128B alignment");

  struct SharedStorage
  {
    static constexpr int scale_elements = elements_per_smem_scale();
    static constexpr int zero_elements = elements_per_smem_zero();
    struct TensorStorage : cute::aligned_struct<cute::max(SmemAlignmentA, SmemAlignmentB), _0> {
      cute::ArrayEngine<RealInternalElementA, cute::cosize_v<SmemLayoutA>> smem_A;
      cute::ArrayEngine<typename TiledMma::ValTypeB, cute::cosize_v<SmemLayoutB>> smem_B;
      cute::ArrayEngine<NonVoidElementScale, scale_elements> smem_scale;
      cute::ArrayEngine<NonVoidElementZero, zero_elements> smem_zero;
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
    ElementScale const* ptr_S = nullptr;
    NonVoidStrideScale dS{};
    int group_size = 0;
    ElementZero const* ptr_Z = nullptr;
    uint32_t mma_promotion_interval = 4;
  };

  // Device side kernel params
  struct Params {
  private:
    using Outer = CollectiveMma<DispatchPolicy, TileShape_, 
                                ElementAOptionalTuple, StrideA_, 
                                ElementBOptionalTuple, StrideB_,
                                TiledMma_, 
                                GmemTiledCopyA_, SmemLayoutAtomA_, SmemCopyAtomA_,
                                TransformA_,
                                GmemTiledCopyB_, SmemLayoutAtomB_, SmemCopyAtomB_,
                                TransformB_>;

  public:
    // Assumption: StrideA is congruent with Problem_MK
    using TMA_A = decltype(make_tma_copy_A_sm90<TmaElementA>(
        GmemTiledCopyA{},
        make_tensor(Outer::get_logical_ptr(static_cast<InternalElementA const*>(nullptr)), repeat_like(InternalStrideA{}, int32_t(0)), InternalStrideA{}),
        SmemLayoutA{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{}));  // mcast along N mode for this M load, if any

   using TMA_Scale = decltype(make_tma_copy<TmaElementScale>(
        GmemTiledCopyScale{},
        make_tensor(Outer::get_logical_ptr(static_cast<NonVoidElementScale const*>(nullptr)), repeat_like(NonVoidStrideScale{}, int32_t(0)), NonVoidStrideScale{}),
        SmemLayoutScale{}(_,_,cute::Int<0>{}),
        ScaleTileShape{},
        _1{}));  // mcast along N mode for this M load, if any. Scale is ALWAYS loaded with A for RF kernel

   using TMA_Zero = decltype(make_tma_copy(
        GmemTiledCopyScale{},
        make_tensor(Outer::get_logical_ptr(static_cast<NonVoidElementZero const*>(nullptr)), repeat_like(NonVoidStrideScale{}, int32_t(0)), NonVoidStrideScale{}),
        SmemLayoutScale{}(_,_,cute::Int<0>{}),
        ScaleTileShape{},
        _1{}));  // mcast along N mode for this M load, if any. Scale is ALWAYS loaded with A for RF kernel

    // Assumption: StrideB is congruent with Problem_NK
    using TMA_B = decltype(make_tma_copy_B_sm90(
        GmemTiledCopyB{},
        make_tensor(Outer::get_logical_ptr(static_cast<InternalElementB const*>(nullptr)), repeat_like(InternalStrideB{}, int32_t(0)), InternalStrideB{}),
        SmemLayoutB{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{})); // mcast along M mode for this N load, if any
    TMA_A tma_load_a;
    TMA_B tma_load_b;
    TMA_Scale tma_load_scale;
    TMA_Zero tma_load_zero;
    int64_t scale_k;
    int group_size;
    uint32_t tma_transaction_bytes = TmaTransactionBytes;
    int reload_factor = (group_size + size<2>(TileShape{}) - 1) / size<2>(TileShape{});
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
    typename Params::TMA_A tma_load_a = make_tma_copy_A_sm90<TmaElementA>(
        GmemTiledCopyA{},
        tensor_a,
        SmemLayoutA{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{}); // mcast along N mode for this M load, if any

    typename Params::TMA_B tma_load_b = make_tma_copy_B_sm90(
        GmemTiledCopyB{},
        tensor_b,
        SmemLayoutB{}(_,_,cute::Int<0>{}),
        TileShape{},
        ClusterShape{}); // mcast along M mode for this N load, if any

    typename Params::TMA_Scale tma_load_scale{};
    typename Params::TMA_Zero tma_load_zero{};

    uint32_t tma_transaction_bytes = TmaTransactionBytesMK + TmaTransactionBytesNK;
    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      return { tma_load_a, tma_load_b, tma_load_scale, tma_load_zero, 0, 0, tma_transaction_bytes, 1 };
    } 
    else if constexpr (ModeHasScales) {
      auto scale_k = (K + args.group_size - 1) / args.group_size;
      ElementScale const* ptr_S = args.ptr_S;
      StrideScale dS = args.dS;
      Tensor tensor_scale = make_tensor(get_logical_ptr(ptr_S), make_layout(make_shape(M,scale_k,L), dS));
      tma_load_scale = make_tma_copy<TmaElementScale>(
          GmemTiledCopyScale{},
          tensor_scale,
          SmemLayoutScale{}(_,_,cute::Int<0>{}),
          ScaleTileShape{},
          _1{}); // mcast along N mode for this M load, if any

      if constexpr(KernelConversionMode == ConversionMode::ConvertAndScale) {
        return { tma_load_a, tma_load_b, tma_load_scale, tma_load_zero, scale_k, args.group_size, tma_transaction_bytes + TmaTransactionBytesExtra, (args.group_size + size<2>(TileShape{}) - 1) / size<2>(TileShape{}) };
      }
      else if constexpr(KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
        Tensor tensor_zero = make_tensor(get_logical_ptr(args.ptr_Z), make_layout(make_shape(M,scale_k,L), dS));
        tma_load_zero = make_tma_copy(
            GmemTiledCopyScale{},
            tensor_zero,
            SmemLayoutScale{}(_,_,cute::Int<0>{}),
            ScaleTileShape{},
            _1{}); // mcast along N mode for this M load, if any
        return { tma_load_a, tma_load_b, tma_load_scale, tma_load_zero, scale_k, args.group_size, tma_transaction_bytes + TmaTransactionBytesExtra, (args.group_size + size<2>(TileShape{}) - 1) / size<2>(TileShape{}) };
      } else {
        static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in to_underlying_arguments.");
      }
    } 
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in to_underlying_arguments.");
    }
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
    constexpr int min_tma_aligned_elements_B = tma_alignment_bits / cutlass::sizeof_bits<ElementB>::value;
    implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_B>(cute::make_shape(N,K,L), StrideB{});

    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      implementable = implementable && (args.ptr_S == nullptr);
      implementable = implementable && (args.ptr_Z == nullptr);
    } 
    else if constexpr (ModeHasScales) {
      const int scale_mn = SwapAB ? N : M;
      const int scale_k = (K + args.group_size - 1) / args.group_size;
      constexpr int min_tma_aligned_elements_scale = tma_alignment_bits / cutlass::sizeof_bits<ElementScale>::value;
      implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_scale>(cute::make_shape(scale_mn,scale_k,L), StrideScale{});
      implementable = implementable && (args.group_size == K || ((args.group_size % size<2>(TileShape{})) == 0));
      implementable = implementable && args.group_size != 0;
      implementable = implementable && (args.ptr_S != nullptr);

      if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
        implementable = implementable && (args.ptr_Z == nullptr);
      }
      else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
        constexpr int min_tma_aligned_elements_zero = tma_alignment_bits / cutlass::sizeof_bits<ElementZero>::value;
        implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_zero>(cute::make_shape(scale_mn,scale_k,L), StrideScale{});
        implementable = implementable && (args.ptr_Z != nullptr);
      } 
      else {
        static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in can_implement.");
      }
    }
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in can_implement.");
    }

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for TMA.\n");
    }
    return implementable;
  }

  static constexpr int K_PIPE_MAX = DispatchPolicy::Stages;
  static constexpr uint32_t TmaTransactionBytesMK = compute_tma_transaction_bytes_mk();
  static constexpr uint32_t TmaTransactionBytesNK = compute_tma_transaction_bytes_nk();
  static constexpr uint32_t TmaTransactionBytesExtra = compute_tma_transaction_bytes_extra();
  static constexpr uint32_t TmaTransactionBytes = TmaTransactionBytesMK + TmaTransactionBytesNK + TmaTransactionBytesExtra;

  /// Issue Tma Descriptor Prefetch -- ideally from a single thread for best performance
  CUTLASS_DEVICE
  static void prefetch_tma_descriptors(Params const& mainloop_params) {
    cute::prefetch_tma_descriptor(mainloop_params.tma_load_a.get_tma_descriptor());
    cute::prefetch_tma_descriptor(mainloop_params.tma_load_b.get_tma_descriptor());

    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      // Nothing extra to do
    } 
    else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
      cute::prefetch_tma_descriptor(mainloop_params.tma_load_scale.get_tma_descriptor());
    }
    else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
      cute::prefetch_tma_descriptor(mainloop_params.tma_load_scale.get_tma_descriptor());
      cute::prefetch_tma_descriptor(mainloop_params.tma_load_zero.get_tma_descriptor());
    }  
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in TMA prefetch.");
    }
    
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
    Tensor mA_mkl = mainloop_params.tma_load_a.get_tma_tensor(make_shape(M,K,L));                            // (m,k,l)
    Tensor mB_nkl = mainloop_params.tma_load_b.get_tma_tensor(make_shape(N,K,L));                            // (n,k,l)

    // Make tiled views, defer the slice
    Tensor gA_mkl = local_tile(mA_mkl, TileShape{}, make_coord(_,_,_), Step<_1, X,_1>{});        // (BLK_M,BLK_K,m,k,l)
    Tensor gB_nkl = local_tile(mB_nkl, TileShape{}, make_coord(_,_,_), Step< X,_1,_1>{});        // (BLK_N,BLK_K,n,k,l)

    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      return cute::make_tuple(gA_mkl, gB_nkl);
    } 
    else if constexpr (ModeHasScales) {
      auto scale_k = mainloop_params.scale_k;
      Tensor mS_mkl = mainloop_params.tma_load_scale.get_tma_tensor(make_shape(M,scale_k,L));          // (m,scale_k,l)
      Tensor gS_mkl = local_tile(mS_mkl, ScaleTileShape{}, make_coord(_,_));         // (BLK_M,BLK_Scale_K,m,scale_k,l)
      if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
        return cute::make_tuple(gA_mkl, gB_nkl, gS_mkl);
      }
      else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
        Tensor mZ_mkl = mainloop_params.tma_load_zero.get_tma_tensor(make_shape(M,scale_k,L));         // (m,scale_k,l)
        Tensor gZ_mkl = local_tile(mZ_mkl, ScaleTileShape{}, make_coord(_,_));       // (BLK_M,BLK_Scale_K,m,scale_k,l)
        return cute::make_tuple(gA_mkl, gB_nkl, gS_mkl, gZ_mkl);
      }
      else {
        static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in load_init.");
      }
    } 
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in load_init.");
    }
  }  

  /// Perform a collective-scoped matrix multiply-accumulate
  /// Producer Perspective
  /// This overload gets triggered when we have scales.
  template <
    class... Ts,
    class KTileIterator, class BlockCoord
  >
  CUTLASS_DEVICE void
  load(
      Params const& mainloop_params,
      MainloopPipeline pipeline, 
      PipelineState smem_pipe_write,
      cute::tuple<Ts...> const& load_inputs,
      BlockCoord const& blk_coord,
      KTileIterator k_tile_iter, int k_tile_count,
      int thread_idx,
      uint32_t block_rank_in_cluster,
      TensorStorage& shared_tensors) {
    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      static_assert(sizeof... (Ts) == 2, "Direct convert needs two inputs");
    } 
    else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
      static_assert(sizeof... (Ts) == 3, "Scaled convert needs three inputs");
    } 
    else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
      static_assert(sizeof... (Ts) == 4, "Scaled and zero convert needs four inputs");
    } 
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in TMA load.");
    }

    int lane_predicate = cute::elect_one_sync();

    Tensor sA_ = make_tensor(make_smem_ptr(shared_tensors.smem_A.begin()), SmemLayoutA{});      // (BLK_M,BLK_K,PIPE)
    Tensor sB_ = make_tensor(make_smem_ptr(shared_tensors.smem_B.begin()), SmemLayoutB{});      // (BLK_N,BLK_K,PIPE)
    Tensor sA  = as_position_independent_swizzle_tensor(sA_);                                   // (BLK_M,BLK_K,PIPE)
    Tensor sB  = as_position_independent_swizzle_tensor(sB_);                                   // (BLK_N,BLK_K,PIPE)

    //
    // Prepare the TMA loads for A, B and Scales
    //
    
    constexpr uint32_t cluster_shape_x = get<0>(ClusterShape());
    uint2 cluster_local_block_id = {block_rank_in_cluster % cluster_shape_x, block_rank_in_cluster / cluster_shape_x};

    Tensor gA_mkl = get<0>(load_inputs);
    Tensor gB_nkl = get<1>(load_inputs);

    auto block_tma_a = mainloop_params.tma_load_a.get_slice(cluster_local_block_id.y);
    auto block_tma_b = mainloop_params.tma_load_b.get_slice(cluster_local_block_id.x);

    // Partition the inputs based on the current block coordinates.
    auto [m_coord, n_coord, k_coord, l_coord] = blk_coord;
    Tensor gA = gA_mkl(_,_,m_coord,_,l_coord);                                                     // (BLK_M,BLK_K,k)
    Tensor gB = gB_nkl(_,_,n_coord,_,l_coord);                                                     // (BLK_N,BLK_K,k)

    // Applies the mapping from block_tma_a
    Tensor tAgA = block_tma_a.partition_S(gA);                                                 // (TMA,TMA_M,TMA_K,k)
    Tensor tAsA = block_tma_a.partition_D(sA);                                              // (TMA,TMA_M,TMA_K,PIPE)

    Tensor tBgB = block_tma_b.partition_S(gB);                                                 // (TMA,TMA_N,TMA_K,k)
    Tensor tBsB = block_tma_b.partition_D(sB);                                              // (TMA,TMA_N,TMA_K,PIPE)

    uint16_t mcast_mask_a = 0;
    uint16_t mcast_mask_b = 0;
    uint16_t mcast_mask_s = 0;

    // Issue TmaLoads
    // Maps the tile -> block, value
    if constexpr (cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD_MULTICAST>) {
      auto block_layout = Layout<typename DispatchPolicy::ClusterShape>{};                       // (m,n) -> block_id
      for (int n = 0; n < size<1>(block_layout); ++n) {
        mcast_mask_a |= (uint16_t(1) << block_layout(cluster_local_block_id.x,n,Int<0>{}));
      }
    }

    if constexpr (cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD_MULTICAST>) {
      auto block_layout = Layout<typename DispatchPolicy::ClusterShape>{};                       // (m,n) -> block_id
      for (int m = 0; m < size<0>(block_layout); ++m) {
        mcast_mask_b |= (uint16_t(1) << block_layout(m,cluster_local_block_id.y,Int<0>{}));
      }
    }

    auto extra_input_partitions = partition_extra_tma_inputs(mainloop_params, load_inputs, shared_tensors, cluster_local_block_id, m_coord, l_coord);

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
      if (cute::elect_one_sync()) copy(mainloop_params.tma_load_a.with(*tma_barrier, mcast_mask_a), tAgA(_,_,_,*k_tile_iter), tAsA(_,_,_,write_stage));
      if (cute::elect_one_sync()) copy(mainloop_params.tma_load_b.with(*tma_barrier, mcast_mask_b), tBgB(_,_,_,*k_tile_iter), tBsB(_,_,_,write_stage));

      if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
        // Nothing extra to do.
      }
      else if constexpr (ModeHasScales) {
        auto tSgS = get<0>(extra_input_partitions);
        auto tSsS = get<1>(extra_input_partitions);

        // Temporary factor which will determine which k tile to reload from gmem. Needed so we don't modify tma transaction bytes
        // on the fly.
        // We must do a ceiling divide here to correctly handle with group_size == K. In that case, we don't require that K
        // is a multiple of the threadblock tile K
        int const scale_load_k = *k_tile_iter / mainloop_params.reload_factor; // This will always be 0 when group_size == K.
        if (cute::elect_one_sync()) copy(mainloop_params.tma_load_scale.with(*tma_barrier, mcast_mask_s), tSgS(_,_,_,scale_load_k), tSsS(_,_,_,write_stage));

        if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
          // Nothing extra to do
        } 
        else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
          auto tZgZ = get<2>(extra_input_partitions);
          auto tZsZ = get<3>(extra_input_partitions);
          if (cute::elect_one_sync()) copy(mainloop_params.tma_load_zero.with(*tma_barrier, mcast_mask_s), tZgZ(_,_,_,scale_load_k), tZsZ(_,_,_,write_stage));
        }
        else {
          static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled for TMA copy op.");
        } 
      } 
      else {
        static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled for TMA copy op.");
      }

      ++k_tile_iter;

      // Advance smem_pipe_write
      ++smem_pipe_write;
    }
  }

  /// Perform a Producer Epilogue to prevent early exit of blocks in a Cluster
  CUTLASS_DEVICE void
  load_tail(MainloopPipeline pipeline, PipelineState smem_pipe_write) {
    // Issue the epilogue waits
    if (cute::elect_one_sync()) {
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
    static_assert(is_rmem<FrgTensorC>::value, "C tensor must be rmem resident.");
    static_assert(cute::rank(SmemLayoutA{}) == 3, "Smem layout must be rank 3.");
    static_assert(cute::rank(SmemLayoutB{}) == 3, "Smem layout must be rank 3.");
    static_assert(cute::rank(InternalSmemLayoutAtomA{}) == 2, "InternalSmemLayoutAtomA must be rank 2.");
    static_assert(cute::rank(InternalSmemLayoutAtomB{}) == 2, "InternalSmemLayoutAtomB must be rank 2.");
    static_assert(!cute::is_void_v<InternalSmemCopyAtomA>,
      "SM90 GMMA mainloops must specify a non-void copy atom for RF sourced instructions.");
    static_assert(cute::is_void_v<InternalSmemCopyAtomB>,
      "SM90 GMMA mainloops cannot have a non-void copy atom for smem sourced instructions.");

    // Obtain warp index
    int warp_idx = canonical_warp_idx_sync();
    [[maybe_unused]] int warp_group_thread_idx = thread_idx % 128;
    
    Tensor sA_ = make_tensor(make_smem_ptr(shared_tensors.smem_A.begin()), SmemLayoutA{});        // (BLK_M,BLK_K,PIPE)
    Tensor sA = as_position_independent_swizzle_tensor(sA_);                                      // (BLK_M,BLK_K,PIPE)
    
    Tensor sB = make_tensor(make_smem_ptr(shared_tensors.smem_B.begin()), SmemLayoutB{});         // (BLK_N,BLK_K,PIPE)

    //
    // Define C accumulators and A/B partitioning
    //

    // Layout of warp group to thread mapping

    static_assert(stride<0>(typename TiledMma::BLayout{}) == 0 and
                  size<0>(typename TiledMma::BLayout{}) == NumThreadsPerWarpGroup, 
                  "Stride of the first mode must be 0 and the size of the mode must be NumThreadsPerWarpGroup");

    constexpr int MmaWarpGroups = size(TiledMma{}) / NumThreadsPerWarpGroup;
    Layout warp_group_thread_layout = make_layout(Int<MmaWarpGroups>{}, 
                                                  Int<NumThreadsPerWarpGroup>{});

    int warp_group_idx = __shfl_sync(0xFFFFFFFF, thread_idx / NumThreadsPerWarpGroup, 0);

    TiledMma tiled_mma;
    auto mma_thread_slice = tiled_mma.get_thread_slice(thread_idx);
    Tensor tCsA = mma_thread_slice.partition_A(sA);
    auto mma_warpgroup_slice = tiled_mma.get_slice(warp_group_thread_layout(warp_group_idx));

    // Allocate fragments and descriptors
    Tensor tCrA_mma = mma_thread_slice.partition_fragment_A(sA(_,_,Int<0>{}));                // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tCrA_load = make_fragment_like<RealInternalElementA>(tCrA_mma);
    
    Tensor tCsB = mma_warpgroup_slice.partition_B(sB);                                        // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tCrB = mma_warpgroup_slice.make_fragment_B(tCsB);                                  // (MMA,MMA_N,MMA_K,PIPE)

    //
    // Copy Atom A retiling
    //
    auto smem_tiled_copy_A = make_tiled_copy_A(InternalSmemCopyAtomA{}, tiled_mma);
    auto smem_thr_copy_A   = smem_tiled_copy_A.get_thread_slice(warp_group_thread_idx);

    Tensor tCrA_copy_view  = smem_thr_copy_A.retile_D(tCrA_load);                                  // (CPY,CPY_M,CPY_K)

    // Partition of thread -> shared and thread -> RF
    auto partitioned_extra_info = partition_extra_mma_info(mma_thread_slice, shared_tensors);
    auto copy_partitions_extra_info = retile_extra_mma_info(tiled_mma, partitioned_extra_info, warp_group_thread_idx);

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

    warpgroup_fence_operand(accum);

    constexpr int K_BLOCK_MAX = size<2>(tCrA_load);
    
    ConsumerToken barrier_token = {BarrierStatus::WaitAgain};
    // first k tile
    {
      barrier_token = pipeline.consumer_try_wait(smem_pipe_read);
      pipeline.consumer_wait(smem_pipe_read, barrier_token);

      int read_stage = smem_pipe_read.index();

      ++smem_pipe_read;
      barrier_token = pipeline.consumer_try_wait(smem_pipe_read);

      // copy smem->rmem for A operand
      copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
        partitioned_extra_info, copy_partitions_extra_info, 0, read_stage);
      if (K_BLOCK_MAX > 1) { // prefetch next block
        copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
          partitioned_extra_info, copy_partitions_extra_info, 1, read_stage);
      }
      transform_A_kblock(tCrA_load, tCrA_mma, partitioned_extra_info, 0);
      
      // Unroll the K mode manually to set scale D to 1
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < K_BLOCK_MAX; ++k_block) {
        if (k_block < K_BLOCK_MAX - 2) { // prefetch next block
          copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
            partitioned_extra_info, copy_partitions_extra_info, k_block + 2, read_stage);
        }
        if (k_block < K_BLOCK_MAX - 1) {
          transform_A_kblock(tCrA_load, tCrA_mma, partitioned_extra_info, k_block + 1);
        }
        warpgroup_arrive();
        // (V,M) x (V,N) => (V,M,N)
        cute::gemm(tiled_mma, tCrA_mma(_,_,k_block), tCrB(_,_,k_block,read_stage), accum);
        tiled_mma.accumulate_ = GMMA::ScaleOut::One;
        warpgroup_commit_batch();
      }     

      --k_tile_count;
      if (k_tile_count > 0) {
        // Wait for K_BLOCK_MAX - 1 to be in flight to ensure that it is safe to overwrite the A registers for the first mma.
        pipeline.consumer_wait(smem_pipe_read, barrier_token);
        copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
          partitioned_extra_info, copy_partitions_extra_info, 0, smem_pipe_read.index());
        if (K_BLOCK_MAX > 1) { // prefetch next block
          copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
            partitioned_extra_info, copy_partitions_extra_info, 1, smem_pipe_read.index());
        }
        warpgroup_wait<K_BLOCK_MAX - 1>(); 
        transform_A_kblock(tCrA_load, tCrA_mma, partitioned_extra_info, 0);
      }
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
      for (int k_block = 0; k_block < K_BLOCK_MAX; ++k_block) {
        
        warpgroup_arrive();
        // (V,M) x (V,N) => (V,M,N)
        cute::gemm(tiled_mma, tCrA_mma(_,_,k_block), tCrB(_,_,k_block,read_stage), accum);
        tiled_mma.accumulate_ = GMMA::ScaleOut::One;
        warpgroup_commit_batch();

        if (k_block == K_BLOCK_MAX - 1) {
          warpgroup_wait<K_BLOCK_MAX - 1>(); // We have K_BLOCK_MAX - 1 GMMA instructions pending for this stage, so we can release prior barrier
          pipeline.consumer_release(smem_pipe_release);             // UNLOCK smem_pipe_release, done _computing_ on it
          ++smem_pipe_release;
        }

        if (k_block == 0) {
          barrier_token = pipeline.consumer_try_wait(smem_pipe_read);
        }

        if (k_block == K_BLOCK_MAX - 1) { 
          pipeline.consumer_wait(smem_pipe_read, barrier_token);
          copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
            partitioned_extra_info, copy_partitions_extra_info, 0, smem_pipe_read.index());
          if (K_BLOCK_MAX > 1) { // prefetch next block
            copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
              partitioned_extra_info, copy_partitions_extra_info, 1, smem_pipe_read.index());
          }
          transform_A_kblock(tCrA_load, tCrA_mma, partitioned_extra_info, 0);
        } 
        else {
          if (k_block < K_BLOCK_MAX - 2) { // prefetch next block
            copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
              partitioned_extra_info, copy_partitions_extra_info, k_block + 2, read_stage);
          }
          transform_A_kblock(tCrA_load, tCrA_mma, partitioned_extra_info, k_block + 1);
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
      for (int k_block = 0; k_block < K_BLOCK_MAX; ++k_block) {

        warpgroup_arrive();
        // (V,M) x (V,N) => (V,M,N)
        cute::gemm(tiled_mma, tCrA_mma(_,_,k_block), tCrB(_,_,k_block,read_stage), accum);
        tiled_mma.accumulate_ = GMMA::ScaleOut::One;
        warpgroup_commit_batch();
        if (k_block == K_BLOCK_MAX - 1) { // release prior barrier
          warpgroup_wait<K_BLOCK_MAX - 1>();
          pipeline.consumer_release(smem_pipe_release);             // UNLOCK smem_pipe_release, done _computing_ on it
          ++smem_pipe_release;
        }

        if (k_block < K_BLOCK_MAX - 2) { // prefetch next block
          copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
            partitioned_extra_info, copy_partitions_extra_info, k_block + 2, read_stage);
        }
        if (k_block < K_BLOCK_MAX - 1) {
          copy_A_and_extra_info(smem_tiled_copy_A, tCsA, tCrA_copy_view, 
            partitioned_extra_info, copy_partitions_extra_info, k_block + 1, read_stage);
          transform_A_kblock(tCrA_load, tCrA_mma, partitioned_extra_info, k_block + 1);
        }
      }
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
  /// Utilities for any additional inputs inside of the TMA load
  template <class... Ts>
  CUTLASS_DEVICE
  auto partition_extra_tma_inputs(
    Params const& mainloop_params,
    cute::tuple<Ts...> const& load_inputs,
    TensorStorage& shared_tensors,
    uint2 const& cluster_local_block_id,
    int const m_coord, 
    int const l_coord) {

    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      return cute::make_tuple();
    } 
    else if constexpr (ModeHasScales) {
      Tensor sS  = make_tensor(make_smem_ptr(shared_tensors.smem_scale.begin()), SmemLayoutScale{}); // (BLK_M,BLK_K,PIPE)
      Tensor gS_mkl = get<2>(load_inputs);
      auto block_tma_s = mainloop_params.tma_load_scale.get_slice(cluster_local_block_id.y);
      Tensor gS = gS_mkl(_,_,m_coord,_,l_coord);                                                  // (BLK_M,BLK_K,k)

      Tensor tSgS = block_tma_s.partition_S(gS);                                              // (TMA,TMA_M,TMA_K,k)
      Tensor tSsS = block_tma_s.partition_D(sS);                                              // (TMA,TMA_M,TMA_K,PIPE)
      if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
        return cute::make_tuple(tSgS, tSsS);
      } 
      else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
        Tensor sZ  = make_tensor(make_smem_ptr(shared_tensors.smem_zero.begin()), SmemLayoutScale{}); // (BLK_M,BLK_K,PIPE)
        Tensor gZ_mkl = get<3>(load_inputs);
        auto block_tma_z = mainloop_params.tma_load_zero.get_slice(cluster_local_block_id.y);
        Tensor gZ = gZ_mkl(_,_,m_coord,_,l_coord);                                            // (BLK_M,BLK_K,k)

        Tensor tZgZ = block_tma_z.partition_S(gZ);                                            // (TMA,TMA_M,TMA_K,k)
        Tensor tZsZ = block_tma_z.partition_D(sZ);                                            // (TMA,TMA_M,TMA_K,PIPE)
        return cute::make_tuple(tSgS, tSsS, tZgZ, tZsZ);          
      }
      else {
        static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled for input partitioning.");      
      }
    }
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled for input partitioning.");      
    }
  }

  /// Utilities for partitioning extra inputs for loading from smem in the mainloop.
  template <class ThreadMma>
  CUTLASS_DEVICE 
  auto partition_extra_mma_info(
    ThreadMma const& mma_thread_slice,
    TensorStorage& shared_tensors) {

    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      // nothing to do
      return cute::make_tuple();
    }
    else if constexpr (UseScaleLookupTable) {
      Tensor sS = make_tensor(make_smem_ptr(shared_tensors.smem_scale.begin()), SmemLayoutScale{});// (BLK_M,BLK_SCALE_K,PIPE)
      Tensor tCsS = mma_thread_slice.partition_A(sS);
      Tensor tCrS_neg = make_tensor<ElementScale>(mma_thread_slice.partition_fragment_A(sS(_,_,Int<0>{})).layout()); 
      Tensor tCrS_pos = make_tensor<ElementScale>(mma_thread_slice.partition_fragment_A(sS(_,_,Int<0>{})).layout()); 

      if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
        return cute::make_tuple(tCsS, tCrS_neg, tCrS_pos);
      }
    }
    else if constexpr (ModeHasScales) {
      Tensor sS = make_tensor(make_smem_ptr(shared_tensors.smem_scale.begin()), SmemLayoutScale{});// (BLK_M,BLK_SCALE_K,PIPE)
      Tensor tCsS = mma_thread_slice.partition_A(sS);
      Tensor tCrS = make_tensor<ElementScale>(mma_thread_slice.partition_fragment_A(sS(_,_,Int<0>{})).layout()); 

      if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
        return cute::make_tuple(tCsS, tCrS);
      }
      else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
        Tensor sZ = make_tensor(make_smem_ptr(shared_tensors.smem_zero.begin()), SmemLayoutScale{});// (BLK_M,BLK_SCALE_K,PIPE)
        Tensor tCsZ = mma_thread_slice.partition_A(sZ);
        Tensor tCrZ = make_tensor<ElementZero>(mma_thread_slice.partition_fragment_A(sZ(_,_,Int<0>{})).layout()); 
        return cute::make_tuple(tCsS, tCrS, tCsZ, tCrZ);
      }
      else {
        static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in A -> RF path.");
      }
    } 
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in A -> RF path.");
    }
  }

  /// Returns the tiled copy and copy views for the extra inputs.
  template <class TiledMma, class... Ts>
  CUTLASS_DEVICE
  auto retile_extra_mma_info(
    TiledMma const& tiled_mma,
    cute::tuple<Ts...>& partitioned_extra_info,
    int const warp_group_thread_idx) {

    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      // nothing to do
      return cute::make_tuple();
    }
    else if constexpr (ModeHasScales) {
      auto smem_tiled_copy_S = make_tiled_copy_A(SmemCopyAtomScale{}, tiled_mma);
      auto smem_thr_copy_S   = smem_tiled_copy_S.get_thread_slice(warp_group_thread_idx);
      Tensor tCrS_copy_view  = smem_thr_copy_S.retile_D(cute::get<1>(partitioned_extra_info));        // (CPY,CPY_M,CPY_K)
      
      if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
        return cute::make_tuple(smem_tiled_copy_S, tCrS_copy_view);
      } 
      else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
        Tensor tCrZ_copy_view  = smem_thr_copy_S.retile_D(cute::get<3>(partitioned_extra_info));      // (CPY,CPY_M,CPY_K)
        return cute::make_tuple(smem_tiled_copy_S, tCrS_copy_view, tCrZ_copy_view);
      } 
      else {
        static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in A -> RF path.");
      }
    } 
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in A -> RF path.");
    }
  }

  /// Utilities to copy A and extra inputs from smem to RF
  template <class SmemTiledCopyA,
            class TensorASmemView,
            class TensorACopyView,
            class... Ts,
            class... Us
            >
  CUTLASS_DEVICE
  void copy_A_and_extra_info(
    SmemTiledCopyA const& smem_tiled_copy_A,
    TensorASmemView const& tCsA,
    TensorACopyView& tCrA_copy_view,
    cute::tuple<Ts...> const& partitioned_mma_extra_info,
    cute::tuple<Us...> const& tiled_copy_and_views,
    int k_block,
    int read_stage) {

    copy(smem_tiled_copy_A, tCsA(_,_,k_block,read_stage), tCrA_copy_view(_,_,k_block));

    if (k_block == 0) {
      // We are starting a new k-tile so copy the scale
      if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
        // nothing to do
      } 
      else if constexpr (ModeHasScales) {
        auto smem_tiled_copy_S = cute::get<0>(tiled_copy_and_views);
        auto tCrS_copy_view    = cute::get<1>(tiled_copy_and_views);
        auto tCsS              = cute::get<0>(partitioned_mma_extra_info);
        copy(smem_tiled_copy_S, tCsS(_,_,k_block,read_stage), tCrS_copy_view(_,_,k_block));
        if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
          // Nothing extra to do
        } else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
          auto tCsZ              = cute::get<2>(partitioned_mma_extra_info);
          auto tCrZ_copy_view    = cute::get<2>(tiled_copy_and_views);
          copy(smem_tiled_copy_S, tCsZ(_,_,k_block,read_stage), tCrZ_copy_view(_,_,k_block));
        } else {
          static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in A -> RF path.");         
        }
      } 
      else {
        static_assert(cutlass::detail::dependent_false<KernelSchedule>, "Conversion mode not handled in A -> RF path.");
      }
    }
  }
  
  // Helper functions to select packing for conversion
  template <class SrcType,
            class DstType,
            int Cosize>
  struct select_packing { // Naive packing policy
    static constexpr auto value() {
      return Int<cute::gcd(Cosize, 32 / cute::min(sizeof_bits_v<SrcType>, sizeof_bits_v<DstType>))>{};
    }
  };
  template <int Cosize> struct select_packing<cutlass::float_e4m3_t, cutlass::bfloat16_t, Cosize> {
    static constexpr auto value() { return Int<cute::gcd(Cosize, 2)>{}; }
  };
  template <int Cosize> struct select_packing<cutlass::float_e5m2_t, cutlass::bfloat16_t, Cosize> {
    static constexpr auto value() { return Int<cute::gcd(Cosize, 2)>{}; }
  };
  template <int Cosize> struct select_packing<cutlass::float_e4m3_t, cutlass::half_t, Cosize> {
    static constexpr auto value() { return Int<cute::gcd(Cosize, 2)>{}; }
  };
  template <int Cosize> struct select_packing<cutlass::float_e5m2_t, cutlass::half_t, Cosize> {
    static constexpr auto value() { return Int<cute::gcd(Cosize, 2)>{}; }
  };
  template <int Cosize> struct select_packing<cutlass::int4b_t, cutlass::bfloat16_t, Cosize> {
    static constexpr auto value() { return Int<cute::gcd(Cosize, 4)>{}; }
  };
  template <int Cosize> struct select_packing<cutlass::int4b_t, cutlass::half_t, Cosize> {
    static constexpr auto value() { return Int<cute::gcd(Cosize, 4)>{}; }
  };

  CUTLASS_DEVICE
  static uint32_t to_reg(Array<cutlass::int4b_t, 4> const& source) {
    return static_cast<uint32_t>(
      reinterpret_cast<uint16_t const&>(source));
  }
  CUTLASS_DEVICE
  static uint32_t to_reg(Array<cutlass::int4b_t, 8> const& source) {
    return reinterpret_cast<uint32_t const&>(source);
  }
  // The core converter uses a lookup table to converts i4 -> 8 bit value.
  template <class TensorPos,
            class TensorNeg,
            int N>
  CUTLASS_DEVICE
  static Array<RealInternalElementB, N> lookup_table_convert(
    cute::Int<N> _,
    Array<cutlass::int4b_t, N> const& source,
    TensorPos const& scale_neg, 
    TensorNeg const& scale_pos, 
    int scale_idx) {

    static_assert(N == 4 || N == 8);
    uint32_t res[N / 4];

    // View the input as reg
    uint32_t reg = to_reg(source);

    // Determines if to get from the signed or unsigned candidates
    static constexpr uint32_t immLut = (0xf0 & 0xcc) | 0xaa;
    uint32_t sign; // ((reg & 0x88888888) | 0x64206420) >> 1 
    asm volatile(
      "{\n"
      "  lop3.b32 %0, %1, %2, %3, %4;\n" \
      "}\n"
      : "=r"(sign)
      : "r"(reg), "n"(0x88888888), "n"(0x64206420), "n"(immLut)
    );
    sign = sign >> 1;

    // Ignore sign bit when indexing into LUT
    uint32_t lut_idx = reg & 0x77777777;
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 4; ++i, lut_idx >>=16, sign >>=16) {
      Array<uint32_t, 2> const& _scale_neg = reinterpret_cast<Array<uint32_t, 2> const&>(scale_neg[scale_idx + i * 4]);
      Array<uint32_t, 2> const& _scale_pos = reinterpret_cast<Array<uint32_t, 2> const&>(scale_pos[scale_idx + i * 4]);
      asm volatile(
        "{\n"
        "  .reg .b32 pos, neg                    ;\n" \
        "  prmt .b32 neg, %3, %4, %1             ;\n" \
        "  prmt .b32 pos, %5, %6, %1             ;\n" \
        "  prmt .b32 %0, pos, neg, %2            ;\n" \
        "}\n"
        : "=r"(res[i])
        : "r"(lut_idx), "r"(sign), "r"(_scale_neg[0]), "r"(_scale_neg[1]), "r"(_scale_pos[0]), "r"(_scale_pos[1])
      );
    }
    return reinterpret_cast<Array<RealInternalElementB, N>&>(res);
  }

  template <class Layout>
  CUTLASS_DEVICE
  static void static_check_scale(Layout const& tensor) {
    static_assert(shape<0>(Layout{}) >= 4 && stride<0>(Layout{}) == 0, "At least 4 adjacent weights in a thread must share the same scale.");
  }
  template <class Engine,
            class Layout>
  CUTLASS_DEVICE
  static void static_check_scale(Tensor<Engine, Layout> const& tensor) {
    static_check_scale(flatten(Layout{}));
  }

  /// Utilities to transform A.
  template <class EngineIn,
            class EngineOut, 
            class LayoutIn,
            class LayoutOut,
            class... Ts>
  CUTLASS_DEVICE
  void transform_A_kblock(
    Tensor<EngineIn, LayoutIn> const& tCrA_load, 
    Tensor<EngineOut, LayoutOut>& tCrA_mma,
    cute::tuple<Ts...> const& partitioned_extra_info,
    int const k_block) {

    static_assert(is_rmem<EngineIn>::value, "Input tensor for A conversion must come from registers");
    static_assert(is_rmem<EngineOut>::value, "Output tensor for A conversion must come from registers");
    static_assert(cosize_v<LayoutIn> == cosize_v<LayoutOut>);
    static_assert(size_v<LayoutIn> == cosize_v<LayoutIn>);
    static_assert(size_v<LayoutOut> == cosize_v<LayoutOut>);
    using SrcType = typename EngineIn::value_type;
    using DstType = typename EngineOut::value_type;

    auto const& src = tCrA_load(_, _, k_block);
    auto const& dst = tCrA_mma(_, _, k_block);
    auto pSrc = raw_pointer_cast(src.data());
    auto pDst = const_cast<DstType*>(raw_pointer_cast(dst.data()));
    constexpr int num_elements = decltype(size(src))::value;

    if constexpr (KernelConversionMode == ConversionMode::DirectConvert) {
      constexpr int pack = decltype(select_packing<SrcType, DstType, num_elements>::value())::value;
      using Converter = cutlass::NumericArrayConverter<DstType, SrcType, pack, cutlass::FloatRoundStyle::round_to_nearest>;
      using SrcArray = cutlass::Array<SrcType, pack>;
      using DstArray = cutlass::Array<DstType, pack>;
      constexpr int iters = num_elements / pack;

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < iters; ++i) {
        SrcArray const* pSrcArr = reinterpret_cast<SrcArray const*>(pSrc) + i;
        DstArray* pDstArr = reinterpret_cast<DstArray*>(pDst) + i;
        *pDstArr = Converter::convert(*pSrcArr);
      }
    } 
    else if constexpr (UseScaleLookupTable) {
      static_assert(is_same_v<RealInternalElementA, cutlass::int4b_t>, "Lookup table only supports int4 being the quant type now.");
      static_assert(sizeof_bits_v<ElementScale> == 64, "Lookup table only supports 8 8bit scale values now.");
      static_assert(num_elements % 4 == 0 && num_elements >= 4, "Lookup table requires a vector size of 4x when converting.");
      constexpr int pack = num_elements % 8 == 0? 8 : 4;
      constexpr int iters = num_elements / pack;
      using SrcArray = cutlass::Array<SrcType, pack>;
      using DstArray = cutlass::Array<DstType, pack>;

      auto const& tCrS_neg = cute::get<1>(partitioned_extra_info);
      auto const& tCrS_pos = cute::get<2>(partitioned_extra_info);
      auto const& scale_neg = tCrS_neg(_, _, k_block);
      auto const& scale_pos = tCrS_pos(_, _, k_block);
      CUTE_STATIC_ASSERT_V(size(src) == size(scale_neg));

      static_check_scale(scale_neg);
      static_check_scale(scale_pos);
      if (k_block == 0) {
        auto pNeg = raw_pointer_cast(tCrS_neg.data());
        auto pPos = const_cast<ElementScale*>(raw_pointer_cast(tCrS_pos.data()));
        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < cosize(tCrS_neg.layout()); ++i)
        {
          // pPos[i] = pNeg[i] & 0x7F7F7F7F7F7F7F00;
          cutlass::Array<uint32_t, 2> const& _scale_neg = reinterpret_cast<cutlass::Array<uint32_t, 2> const&>(pNeg[i]);
          cutlass::Array<uint32_t, 2> & _scale_pos = reinterpret_cast<cutlass::Array<uint32_t, 2> &>(pPos[i]);
          asm volatile(
              "{\n"
              "  and  .b32 %0, %2, %4             ;\n" \
              "  and  .b32 %1, %3, %5             ;\n" \
              "}\n"
              : "=r"(_scale_pos[0]), "=r"(_scale_pos[1])
              : "r"(_scale_neg[0]), "r"(_scale_neg[1]), "n"(0x7F7F7F00), "n"(0x7F7F7F7F)
              );
        }
      }
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < iters; i ++) {
        SrcArray const* pSrcArr = reinterpret_cast<SrcArray const*>(raw_pointer_cast(src.data())) + i;
        DstArray* pDstArr = reinterpret_cast<DstArray*>(raw_pointer_cast(dst.data())) + i;
        
        *pDstArr = lookup_table_convert(Int<pack>{}, *pSrcArr, scale_neg, scale_pos, i * pack);
      }
    }
    else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScale) {
      auto const& scales = cute::get<1>(partitioned_extra_info)(_, _, k_block);
      CUTE_STATIC_ASSERT_V(size(src) == size(scales));

      if constexpr (is_same_v<DstType, ElementScale>) {
        constexpr int pack = decltype(select_packing<SrcType, DstType, num_elements>::value())::value;
        using Converter = cutlass::NumericArrayConverter<DstType, SrcType, pack, cutlass::FloatRoundStyle::round_to_nearest>;
        using SrcArray = cutlass::Array<SrcType, pack>;
        using DstArray = cutlass::Array<DstType, pack>;
        constexpr int iters = num_elements / pack;

        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < iters; ++i) {
          SrcArray const* pSrcArr = reinterpret_cast<SrcArray const*>(pSrc) + i;
          DstArray* pDstArr = reinterpret_cast<DstArray*>(pDst) + i;
          *pDstArr = Converter::convert(*pSrcArr);
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < pack; ++j) {
            (*pDstArr)[j] = (*pDstArr)[j] * scales[i*pack + j];
          }
        }
      }
      else {
        constexpr int pack1 = decltype(select_packing<SrcType, ElementScale, num_elements>::value())::value;
        constexpr int pack2 = decltype(select_packing<ElementScale, DstType, num_elements>::value())::value;
        constexpr int pack = cute::gcd(pack1, pack2);
        using Converter1 = cutlass::NumericArrayConverter<ElementScale, SrcType, pack, cutlass::FloatRoundStyle::round_to_nearest>;
        using Converter2 = cutlass::NumericArrayConverter<DstType, ElementScale, pack, cutlass::FloatRoundStyle::round_to_nearest>;
        using SrcArray = cutlass::Array<SrcType, pack>;
        using DstArray = cutlass::Array<DstType, pack>;
        using StageArray = cutlass::Array<ElementScale, pack>;
        constexpr int iters = num_elements / pack;

        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < iters; ++i) {
          SrcArray const* pSrcArr = reinterpret_cast<SrcArray const*>(pSrc) + i;
          DstArray* pDstArr = reinterpret_cast<DstArray*>(pDst) + i;
          StageArray stageArr;
          stageArr = Converter1::convert(*pSrcArr);
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < pack; ++j) {
            stageArr[j] = stageArr[j] *  scales[i*pack + j];
          }
          *pDstArr = Converter2::convert(stageArr);
        }
      }
    } 
    else if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero) {
      static_assert(is_same_v<ElementScale, ElementZero>, "ElementScale and ElementZero must be the same.");
      auto const& scales = cute::get<1>(partitioned_extra_info)(_, _, k_block);
      auto const& zeros = cute::get<3>(partitioned_extra_info)(_, _, k_block);
      CUTE_STATIC_ASSERT_V(size(src) == size(scales));
      CUTE_STATIC_ASSERT_V(size(src) == size(zeros));
      
      if constexpr (is_same_v<DstType, ElementScale>) {
        constexpr int pack = decltype(select_packing<SrcType, DstType, num_elements>::value())::value;
        using Converter = cutlass::NumericArrayConverter<DstType, SrcType, pack, cutlass::FloatRoundStyle::round_to_nearest>;
        using SrcArray = cutlass::Array<SrcType, pack>;
        using DstArray = cutlass::Array<DstType, pack>;
        constexpr int iters = num_elements / pack;

        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < iters; ++i) {
          SrcArray const* pSrcArr = reinterpret_cast<SrcArray const*>(pSrc) + i;
          DstArray* pDstArr = reinterpret_cast<DstArray*>(pDst) + i;
          *pDstArr = Converter::convert(*pSrcArr);
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < pack; ++j) {
            (*pDstArr)[j] = (*pDstArr)[j] * scales[i*pack + j] + zeros[i*pack + j];
          }
        }
      }
      else {
        constexpr int pack1 = decltype(select_packing<SrcType, ElementScale, num_elements>::value())::value;
        constexpr int pack2 = decltype(select_packing<ElementScale, DstType, num_elements>::value())::value;
        constexpr int pack = cute::gcd(pack1, pack2);
        using Converter1 = cutlass::NumericArrayConverter<ElementScale, SrcType, pack, cutlass::FloatRoundStyle::round_to_nearest>;
        using Converter2 = cutlass::NumericArrayConverter<DstType, ElementScale, pack, cutlass::FloatRoundStyle::round_to_nearest>;
        using SrcArray = cutlass::Array<SrcType, pack>;
        using DstArray = cutlass::Array<DstType, pack>;
        using StageArray = cutlass::Array<ElementScale, pack>;
        constexpr int iters = num_elements / pack;

        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < iters; ++i) {
          SrcArray const* pSrcArr = reinterpret_cast<SrcArray const*>(pSrc) + i;
          DstArray* pDstArr = reinterpret_cast<DstArray*>(pDst) + i;
          StageArray stageArr;
          stageArr = Converter1::convert(*pSrcArr);
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < pack; ++j) {
            stageArr[j] = stageArr[j] *  scales[i*pack + j] + zeros[i*pack + j];
          }
          *pDstArr = Converter2::convert(stageArr);
        }
      }
      return;
    }
    else {
      static_assert(cutlass::detail::dependent_false<KernelSchedule>, "No A data is loaded.");
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
