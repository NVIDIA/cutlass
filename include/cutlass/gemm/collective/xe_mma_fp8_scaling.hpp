/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
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
#include "cutlass/fp8_to_fp16.h"

#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/gemm.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {
using namespace cute;

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int Stages,
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
    MainloopIntelXeXMX16FP8Scaling<Stages>,
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
  enum class ConversionMode {
    DirectConvert,
    ConvertAndScale,
    ConvertAndScaleWithZero
  };

public:
  //
  // Type Aliases
  //
  using DispatchPolicy = MainloopIntelXeXMX16FP8Scaling<Stages>;
  using WorkgroupTileShape = TileShape_;

  
  static_assert((cute::is_tuple<ElementAOptionalTuple>::value & cute::is_tuple<ElementAOptionalTuple>::value &
        (cute::is_any_of_v<detail::deduce_mixed_width_dtype_t<0, ElementAOptionalTuple>, float_e4m3_t, float_e5m2_t>)),
    "Either A and B must be a tuple. It must take the from {ElementOperand, [ElementScale],"
    "[ElementZero]}. Inputs in [] are optional.");

  using ElementA = detail::deduce_mixed_width_dtype_t<0, ElementAOptionalTuple>;
  using ElementB = detail::deduce_mixed_width_dtype_t<0, ElementBOptionalTuple>;

  static constexpr bool IsATransformed = cute::is_tuple<ElementAOptionalTuple>::value;
  static constexpr bool IsBTransformed = cute::is_tuple<ElementBOptionalTuple>::value;

  using ElementMMA = typename TiledMma_::ValTypeA;
  using ElementQuant = cute::conditional_t<IsATransformed, ElementA, ElementB>;

  // TODO(Codeplay): Create a ScaledTensor class to encapsulate scale logic
  using ElementScaleA = detail::deduce_mixed_width_dtype_t<1, ElementAOptionalTuple>;
  using StrideScaleA = detail::deduce_mixed_width_dtype_t<2, ElementAOptionalTuple>;
  using ElementZeroA = detail::deduce_mixed_width_dtype_t<3, ElementAOptionalTuple>;
  using StrideZeroA = detail::deduce_mixed_width_dtype_t<4, ElementAOptionalTuple>;

  using ElementScaleB = detail::deduce_mixed_width_dtype_t<1, ElementBOptionalTuple>;
  using StrideScaleB = detail::deduce_mixed_width_dtype_t<2, ElementBOptionalTuple>;
  using ElementZeroB = detail::deduce_mixed_width_dtype_t<3, ElementBOptionalTuple>;
  using StrideZeroB = detail::deduce_mixed_width_dtype_t<4, ElementBOptionalTuple>;

  // For cases where we can't have a void type, we can use this to allow the code to compile when the scale / zero is void.
  using NonVoidElementScaleA = cute::conditional_t<cute::is_void_v<ElementScaleA>, ElementMMA, ElementScaleA>;
  using NonVoidStrideScaleA = cute::conditional_t<cute::is_same_v<StrideScaleA, void>, cute::Stride<_1, int64_t, int64_t>, StrideScaleA>;
  using NonVoidElementZeroA = cute::conditional_t<cute::is_void_v<ElementZeroA>, ElementMMA, ElementZeroA>;
  using NonVoidStrideZeroA = cute::conditional_t<cute::is_same_v<StrideZeroA, void>, cute::Stride<_1, int64_t, int64_t>, StrideZeroA>;

  using NonVoidElementScaleB = cute::conditional_t<cute::is_void_v<ElementScaleB>, ElementMMA, ElementScaleB>;
  using NonVoidStrideScaleB = cute::conditional_t<cute::is_same_v<StrideScaleB, void>, cute::Stride<_1, int64_t, int64_t>, StrideScaleB>;
  using NonVoidElementZeroB = cute::conditional_t<cute::is_void_v<ElementZeroB>, ElementMMA, ElementZeroB>;
  using NonVoidStrideZeroB = cute::conditional_t<cute::is_same_v<StrideZeroB, void>, cute::Stride<_1, int64_t, int64_t>, StrideZeroB>;

  using StrideA = StrideA_;
  using StrideB = StrideB_;

  using TiledMma = TiledMma_;
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
  using MmaType = typename TiledMma::ValTypeA; // ValTypeA and ValTypeB are always same and reflects MMA type on intel Xe

  static_assert(std::is_same_v<TransformA, cute::identity>, "Transformation for A is not currently supported on Intel PVC");
  static_assert(std::is_same_v<TransformB, cute::identity>, "Transformation for B is not currently supported on Intel PVC");
  
private:
   
  static constexpr ConversionMode 
  get_conversion_modeA() {
    if constexpr (cute::is_void_v<ElementScaleA>) {
      return ConversionMode::DirectConvert;
    } 
    else if constexpr (cute::is_void_v<ElementZeroA>) {
      return ConversionMode::ConvertAndScale;
    }
    else {
      return ConversionMode::ConvertAndScaleWithZero;
    }
  }

  static constexpr ConversionMode
  get_conversion_modeB() {
    if constexpr (cute::is_void_v<ElementScaleB>) {
      return ConversionMode::DirectConvert;
    }
    else if constexpr (cute::is_void_v<ElementZeroB>) {
      return ConversionMode::ConvertAndScale;
    }
    else {
      return ConversionMode::ConvertAndScaleWithZero;
    }
  }

  static constexpr ConversionMode KernelConversionModeA = get_conversion_modeA();
  static constexpr ConversionMode KernelConversionModeB = get_conversion_modeB();
  static constexpr bool ModeHasScalesA = KernelConversionModeA == ConversionMode::ConvertAndScale ||
                                        KernelConversionModeA == ConversionMode::ConvertAndScaleWithZero;
  static constexpr bool ModeHasScalesZeroA = KernelConversionModeA == ConversionMode::ConvertAndScaleWithZero;

  static constexpr bool ModeHasScalesB = KernelConversionModeB == ConversionMode::ConvertAndScale ||
                                        KernelConversionModeB == ConversionMode::ConvertAndScaleWithZero;
  static constexpr bool ModeHasScalesZeroB = KernelConversionModeB == ConversionMode::ConvertAndScaleWithZero;

public:
  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  using MmaAtomShape = typename TiledMma::AtomShape_MNK;

  static constexpr auto BLK_M = get<0>(WorkgroupTileShape{});
  static constexpr auto BLK_N = get<1>(WorkgroupTileShape{});
  static constexpr auto BLK_K = get<2>(WorkgroupTileShape{});
  
  static constexpr auto ATOM_M = get<1>(typename TiledMma::ThrLayoutVMNK{}.shape());
  static constexpr auto ATOM_N = get<2>(typename TiledMma::ThrLayoutVMNK{}.shape());
  static constexpr auto ATOM_K = get<3>(typename TiledMma::ThrLayoutVMNK{}.shape());

  static constexpr auto SG_M = ceil_div(BLK_M, ATOM_M);
  static constexpr auto SG_N = ceil_div(BLK_N, ATOM_N);
  static constexpr auto SG_K = ceil_div(BLK_K, ATOM_K);
  using SubgroupTileShape = Shape<decltype(SG_M), decltype(SG_N), decltype(SG_K)>;
  
  using GmemTiledCopyScaleA = typename scale_zero_copy_traits<NonVoidElementScaleA, SG_N>::type;
  using GmemTiledCopyZeroA = typename scale_zero_copy_traits<NonVoidElementZeroA, SG_N>::type;
  using GmemTiledCopyScaleB = typename scale_zero_copy_traits<NonVoidElementScaleB, SG_N>::type;
  using GmemTiledCopyZeroB = typename scale_zero_copy_traits<NonVoidElementZeroB, SG_N>::type;

  static constexpr auto Num_SGs = ATOM_N * ATOM_M * ATOM_K;
  static constexpr uint32_t MaxThreadsPerBlock = size(TiledMma{});

  using CopyThreadShape = Shape<_1, Int<SubgroupSize>>;
  using CopyThreadShapeRev = decltype(cute::reverse(CopyThreadShape{}));
  
  using Copy_A = typename Copy_Traits<GmemTiledCopyA, StrideA>::template DefaultTiledCopy<ElementA>;
  using Copy_B = typename Copy_Traits<GmemTiledCopyB, StrideB>::template DefaultTiledCopy<ElementB>;

  using traits_load_scaleA = Copy_Traits<GmemTiledCopyScaleA, NonVoidStrideScaleA>;
  using atom_load_scaleA = Copy_Atom<traits_load_scaleA, NonVoidElementScaleA>;
  using val_layout_load_scaleA = decltype(make_layout(shape_div(typename traits_load_scaleA::BlockShape{}, CopyThreadShapeRev{})));
  using Copy_ScaleA = decltype(make_tiled_copy(atom_load_scaleA{}, Layout<CopyThreadShapeRev>{}, val_layout_load_scaleA{}));

  using traits_load_scaleB = Copy_Traits<GmemTiledCopyScaleB, NonVoidStrideScaleB>;
  using atom_load_scaleB = Copy_Atom<traits_load_scaleB, NonVoidElementScaleB>;
  using val_layout_load_scaleB = decltype(make_layout(shape_div(typename traits_load_scaleB::BlockShape{}, CopyThreadShapeRev{})));
  using Copy_ScaleB = decltype(make_tiled_copy(atom_load_scaleB{}, Layout<CopyThreadShapeRev>{}, val_layout_load_scaleB{}));

  using traits_load_zeroA = Copy_Traits<GmemTiledCopyZeroA, NonVoidStrideZeroA>;
  using atom_load_zeroA = Copy_Atom<traits_load_zeroA, NonVoidElementZeroA>;
  using val_layout_load_zeroA = decltype(make_layout(shape_div(typename traits_load_zeroA::BlockShape{}, CopyThreadShapeRev{})));
  using Copy_ZeroA = decltype(make_tiled_copy(atom_load_zeroA{}, Layout<CopyThreadShapeRev>{}, val_layout_load_zeroA{}));

  using traits_load_zeroB = Copy_Traits<GmemTiledCopyZeroB, NonVoidStrideZeroB>;
  using atom_load_zeroB = Copy_Atom<traits_load_zeroB, NonVoidElementZeroB>;
  using val_layout_load_zeroB = decltype(make_layout(shape_div(typename traits_load_zeroB::BlockShape{}, CopyThreadShapeRev{})));
  using Copy_ZeroB = decltype(make_tiled_copy(atom_load_zeroB{}, Layout<CopyThreadShapeRev>{}, val_layout_load_zeroB{}));

  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A;
    StrideA dA;
    ElementB const* ptr_B;
    StrideB dB;
    NonVoidElementScaleA const* ptr_SA = nullptr;
    NonVoidStrideScaleA dSA{};
    NonVoidElementScaleB const* ptr_SB = nullptr;
    NonVoidStrideScaleB dSB{};
    NonVoidElementZeroA const* ptr_ZA = nullptr;
    NonVoidStrideZeroA dZA{};
    NonVoidElementZeroB const* ptr_ZB = nullptr;
    NonVoidStrideZeroB dZB{};
    int group_size = 1;
  };

  struct Params {
    Copy_A tiled_copy_a;
    Copy_B tiled_copy_b;
    Copy_ScaleA tiled_copy_scaleA;
    Copy_ZeroA tiled_copy_zeroA;
    Copy_ScaleB tiled_copy_scaleB;
    Copy_ZeroB tiled_copy_zeroB;
    int group_size;
  };

  //
  // Methods
  //

  CollectiveMma() = default;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const &problem_shape,
                          Arguments const &args, void *workspace) {
    (void)workspace;

    auto [M, N, K, L] = problem_shape;

    auto mA_mkl =
        make_tensor(make_gmem_ptr(args.ptr_A), make_layout(make_shape(M, K, L), args.dA));

    auto ptr_B = [&]() {
      if constexpr (sizeof_bits_v<ElementB> < 8) {
        return cute::subbyte_iterator<const ElementB>(args.ptr_B);
      } else {
        return make_gmem_ptr(static_cast<ElementB const *>(args.ptr_B));
      }
    }();


    auto mB_nkl =
        make_tensor(ptr_B, make_layout(make_shape(N, K, L), args.dB));

    Copy_A tiled_copy_a{Copy_A{}.with(mA_mkl)};
    Copy_B tiled_copy_b{Copy_B{}.with(mB_nkl)};

    Copy_ScaleA tiled_copy_scaleA;
    Copy_ScaleB tiled_copy_scaleB;
    Copy_ZeroA tiled_copy_zeroA;
    Copy_ZeroB tiled_copy_zeroB;

    auto scale_k = cute::ceil_div(K, args.group_size);
    if constexpr(ModeHasScalesA) {
      auto mScale = make_tensor(
        make_gmem_ptr(static_cast<NonVoidElementScaleA const *>(args.ptr_SA)),
        make_layout(make_shape(M, scale_k, L), args.dSA));
      tiled_copy_scaleA = {Copy_ScaleA{}.with(mScale)};
    } else {
      tiled_copy_scaleA = {};
    }

    if constexpr(ModeHasScalesB) {
      auto mScale = make_tensor(
        make_gmem_ptr(static_cast<NonVoidElementScaleB const *>(args.ptr_SB)),
        make_layout(make_shape(N, scale_k, L), args.dSB));
      tiled_copy_scaleB = {Copy_ScaleB{}.with(mScale)};
    } else {
      tiled_copy_scaleB = {};
    }

    // TODO: Current examples/sycl/08_bmg_gemm_f8/08_bmg_gemm_f8_scaling.cpp doesn't cover this path
    static_assert(!ModeHasScalesZeroA && !ModeHasScalesZeroB);

    if constexpr(ModeHasScalesZeroA) {
      auto ptr_Z = [&]() {
        if constexpr (sizeof_bits_v<NonVoidElementZeroA> < 8) {
          return cute::subbyte_iterator<const NonVoidElementZeroA>(args.ptr_ZA);
        } else {
          return make_gmem_ptr(static_cast<NonVoidElementZeroA const *>(args.ptr_ZA));
        }
      }();

      auto mZero = make_tensor(ptr_Z,
                    make_layout(make_shape(M, scale_k, L),
                    make_stride(_1{}, M, M * scale_k)));
      tiled_copy_zeroA = {Copy_ZeroA{}.with(mZero)};
    }

    if constexpr(ModeHasScalesZeroB) {
      auto ptr_Z = [&]() {
        if constexpr (sizeof_bits_v<NonVoidElementZeroB> < 8) {
          return cute::subbyte_iterator<const NonVoidElementZeroB>(args.ptr_ZB);
        } else {
          return make_gmem_ptr(static_cast<NonVoidElementZeroB const *>(args.ptr_ZB));
        }
      }();

      auto mZero = make_tensor(ptr_Z,
                    make_layout(make_shape(N, scale_k, L),
                    make_stride(_1{}, N, N * scale_k)));
      tiled_copy_zeroB = {Copy_ZeroB{}.with(mZero)};
    }

    return Params{tiled_copy_a, tiled_copy_b, tiled_copy_scaleA, tiled_copy_zeroA, tiled_copy_scaleB,
            tiled_copy_zeroB, args.group_size};
  }

  template<class ProblemShape>
  static bool
  can_implement(
      ProblemShape problem_shapes,
      Arguments const& args) {
    constexpr int copy_alignment_bits = 128;
    constexpr int batch_alignment_bits = 512;
    auto problem_shape_MNKL = append<4>(problem_shapes, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    bool implementable = true;

    constexpr int min_aligned_elements_A = copy_alignment_bits / sizeof_bits<ElementA>::value;
    implementable &= cutlass::detail::check_alignment<min_aligned_elements_A>(cute::make_shape(M,K,L), args.dA);
    constexpr int min_aligned_elements_B = copy_alignment_bits / sizeof_bits<ElementB>::value;
    implementable &= cutlass::detail::check_alignment<min_aligned_elements_B>(cute::make_shape(N,K,L), args.dB);

    if (L > 1) {
      constexpr int min_batch_aligned_elements_A = batch_alignment_bits / sizeof_bits<ElementA>::value;
      implementable &= get<2>(args.dA) % min_batch_aligned_elements_A == 0;
      constexpr int min_batch_aligned_elements_B = batch_alignment_bits / sizeof_bits<ElementB>::value;
      implementable &= get<2>(args.dB) % min_batch_aligned_elements_B == 0;
    }

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for XE 2D copy.\n");
    }

    return implementable;
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

  /// Utilities to transform A.
  template <class EngineIn,
            class EngineOut, 
            class EngineScales, 
            class EngineZeros, 
            class LayoutIn,
            class LayoutOut,
            class LayoutScales,
            class LayoutZeros>
  CUTLASS_DEVICE typename std::enable_if_t<sizeof_bits_v<typename EngineIn::value_type> >= 8>
  transform_A(
    Tensor<EngineIn, LayoutIn> const& in,
    Tensor<EngineOut, LayoutOut>& out,
    Tensor<EngineScales, LayoutScales>& tCrS_input,
    Tensor<EngineZeros, LayoutZeros>& tCrZ_input
  ) {

    static_assert(is_rmem<EngineIn>::value, "Input tensor for A conversion must come from registers");
    static_assert(size_v<LayoutIn> == cosize_v<LayoutIn>);
    static_assert(size_v<LayoutOut> == cosize_v<LayoutOut>);

    using SrcType = typename EngineIn::value_type;
    using DstType = typename EngineOut::value_type;
    using ZeroType = typename EngineZeros::value_type;
    using ScaleType = typename EngineScales::value_type;
    using MmaType = DstType;

    convert_FP8_to_FP16<ElementQuant>(in, out);

    if constexpr (IsATransformed && ModeHasScalesA) {
      static constexpr auto M = decltype(size<1>(in))::value;
      static constexpr auto K = decltype(size(in))::value / 8 / M;
      CUTLASS_PRAGMA_NO_UNROLL
      for (int i = 0; i < 16; ++i) {
        // Example: for the scale load atom (1x32) gives 2 scale values to
        // each thread. All threads need access to all other threads
        // scale values, and each scale value is reused twice (k unrolled below)
        CUTLASS_PRAGMA_UNROLL
        for (int m = 0; m < M / 2; ++m) {
          auto scale = static_cast<DstType>(shfl_sync(0xFFFFFFFF, tCrS_input(m), i));
          auto zero = static_cast<DstType>(shfl_sync(0xFFFFFFFF, tCrZ_input(m), i));
          CUTLASS_PRAGMA_UNROLL
          for (int k = 0; k < K; k++) {
            if constexpr (ModeHasScalesZeroA) {
              out(_, _, k)[m * 16 + i] -= zero;
            }
            out(_, _, k)[m * 16 + i] *= scale;
          }
        }
      }
    }
  }

    /// Utilities to transform B.
  template <class EngineIn,
            class EngineOut,
            class EngineScales,
            class EngineZeros,
            class LayoutIn,
            class LayoutOut,
            class LayoutScales,
            class LayoutZeros>
  CUTLASS_DEVICE typename std::enable_if_t<sizeof_bits_v<typename EngineIn::value_type> >= 8>
  transform_B(
    Tensor<EngineIn, LayoutIn> const& in,
    Tensor<EngineOut, LayoutOut>& out,
    Tensor<EngineScales, LayoutScales>& tCrS_input,
    Tensor<EngineZeros, LayoutZeros>& tCrZ_input
  ) {

    static_assert(is_rmem<EngineIn>::value, "Input tensor for A conversion must come from registers");
    static_assert(size_v<LayoutIn> == cosize_v<LayoutIn>);
    static_assert(size_v<LayoutOut> == cosize_v<LayoutOut>);

    using SrcType = typename EngineIn::value_type;
    using DstType = typename EngineOut::value_type;
    using ZeroType = typename EngineZeros::value_type;
    using ScaleType = typename EngineScales::value_type;
    using MmaType = DstType;

    convert_FP8_to_FP16<ElementQuant>(in, out);

    if constexpr (IsBTransformed && ModeHasScalesB) {
      static constexpr auto N = decltype(size<1>(in))::value;
      CUTLASS_PRAGMA_UNROLL
      for (int n = 0; n < N; ++n) {
        auto zero = static_cast<DstType>(tCrZ_input(n));
        auto scale = static_cast<DstType>(tCrS_input(n));
        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < decltype(size(in))::value / N; ++i) {
          if constexpr (ModeHasScalesZeroB){
            out(_, n, _)[i] -= zero;
          }
          out(_, n, _)[i] *= scale;
        }
      }
    }
  }

  /// Perform a subgroup-scoped matrix multiply-accumulate
  template <class FrgTensorD,
    class TensorA,
    class TensorB,
    class FrgTensorC,
    class KTileIterator,
    class BlkCoord
  >
  CUTLASS_DEVICE void
  operator() (
      FrgTensorD &accum,
      TensorA gA,
      TensorB gB,
      FrgTensorC const &src_accum,
      KTileIterator k_tile_iter, int k_tile_count,
      BlkCoord const &blk_coord,
      int const &K_start,
      int thread_idx,
      Params const& mainloop) 
  {
    static_assert(is_rmem<FrgTensorD>::value, "D tensor must be rmem resident.");
    static_assert(is_rmem<FrgTensorC>::value, "C tensor must be rmem resident.");

    // Partition the copying of A and B tiles across the threads
    auto thr_copy_A = mainloop.tiled_copy_a.get_slice(thread_idx);
    auto thr_copy_B = mainloop.tiled_copy_b.get_slice(thread_idx);
    auto thr_copy_scaleA = mainloop.tiled_copy_scaleA.get_slice(thread_idx);
    auto thr_copy_zeroA = mainloop.tiled_copy_zeroA.get_slice(thread_idx);
    auto thr_copy_scaleB = mainloop.tiled_copy_scaleB.get_slice(thread_idx);
    auto thr_copy_zeroB = mainloop.tiled_copy_zeroB.get_slice(thread_idx);

    // Instantiate the MMA object and get thread slice
    TiledMma tiled_mma;
    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    auto first_thread_in_sg_idx = sg.get_group_linear_id() * DispatchPolicy::SubgroupSize;
    auto thr_mma = tiled_mma.get_slice(first_thread_in_sg_idx);

    // Partition
    Tensor tCgA = thr_mma.partition_A(gA);
    Tensor tCgB = thr_mma.partition_B(gB);

    // Create fragments
    Tensor mma_A = make_tensor<ElementMMA>(make_fragment_layout(mainloop.tiled_copy_a, tCgA(_,_,_,0).shape()));
    Tensor mma_B = make_tensor<ElementMMA>(make_fragment_layout(mainloop.tiled_copy_b, tCgB(_,_,_,0).shape()));

    // If IsATransformed, we need modes M_atom, and M_iter from fragment_A
    // layout else we need mode N_iter from fragment_B layout.
    static constexpr auto scaleA_traits_size = decltype(size(typename GmemTiledCopyScaleA::BlockShape{}))::value / SubgroupSize;
    static constexpr auto scaleA_traits_num = SG_M / size<1>(typename GmemTiledCopyScaleA::BlockShape{});
    using FragScaleALayout = Layout<Shape<Int<scaleA_traits_size>, Int<scaleA_traits_num>, _1>>;
    Tensor fragment_scaleA_input = make_tensor<NonVoidElementScaleA>(FragScaleALayout{});

    static constexpr auto scaleB_traits_size = decltype(size(typename GmemTiledCopyScaleB::BlockShape{}))::value / SubgroupSize;
    static constexpr auto scaleB_traits_num = SG_N / size<1>(typename GmemTiledCopyScaleB::BlockShape{});
    using FragScaleBLayout = Layout<Shape<Int<scaleB_traits_size>, Int<scaleB_traits_num>, _1>>;
    Tensor fragment_scaleB_input = make_tensor<NonVoidElementScaleB>(FragScaleBLayout{});

    static constexpr auto zeroA_traits_size = decltype(size(typename GmemTiledCopyZeroA::BlockShape{}))::value / SubgroupSize;
    static constexpr auto zeroA_traits_num = SG_M / size<1>(typename GmemTiledCopyZeroA::BlockShape{});
    using FragZeroALayout = Layout<Shape<Int<zeroA_traits_size>, Int<zeroA_traits_num>, _1>>;
    Tensor fragment_zeroA_input =  make_tensor<NonVoidElementZeroA> (FragZeroALayout{});

    static constexpr auto zeroB_traits_size = decltype(size(typename GmemTiledCopyZeroB::BlockShape{}))::value / SubgroupSize;
    static constexpr auto zeroB_traits_num = SG_N / size<1>(typename GmemTiledCopyZeroB::BlockShape{});
    using FragZeroBLayout = Layout<Shape<Int<zeroB_traits_size>, Int<zeroB_traits_num>, _1>>;
    Tensor fragment_zeroB_input =  make_tensor<NonVoidElementZeroB> (FragZeroBLayout{});

    // narrow input fragment
    Tensor quantA_frag = make_tensor<uint8_t>(mma_A.layout());
    Tensor quantB_frag = make_tensor<uint8_t>(mma_B.layout());

    static_assert(std::is_same_v<typename decltype(mma_A)::value_type, ElementMMA>);
    static_assert(std::is_same_v<typename decltype(mma_B)::value_type, ElementMMA>);

    // Retile for copy
    auto frag_copy_A = thr_copy_A.retile_D(quantA_frag);
    auto frag_copy_B = thr_copy_B.retile_D(quantB_frag);

    Tensor copy_tCrSA = thr_copy_scaleA.retile_D(fragment_scaleA_input);
    Tensor copy_tCrSB = thr_copy_scaleB.retile_D(fragment_scaleB_input);
    Tensor copy_tCrZA = thr_copy_zeroA.retile_D(fragment_zeroA_input);
    Tensor copy_tCrZB = thr_copy_zeroB.retile_D(fragment_zeroB_input);

    // Retile global tile for copies
    Tensor tAgA = thr_copy_A.retile_S(tCgA);
    Tensor tBgB = thr_copy_B.retile_S(tCgB);

    auto tiled_prefetch_a = cute::prefetch_selector<Shape<Int<BLK_M>,Int<BLK_K>>, Num_SGs>(mainloop.tiled_copy_a);;
    auto tiled_prefetch_b = cute::prefetch_selector<Shape<Int<BLK_N>,Int<BLK_K>>, Num_SGs>(mainloop.tiled_copy_b);;
    auto thr_prefetch_A = tiled_prefetch_a.get_slice(thread_idx);
    auto thr_prefetch_B = tiled_prefetch_b.get_slice(thread_idx);

    // Partition global tile for prefetch
    auto pAgA = thr_prefetch_A.partition_S(gA);
    auto pBgB = thr_prefetch_B.partition_S(gB);

    //
    // Mainloop
    //
    // TODO(Codeplay): Define these coord tensors using proper cute logic 
    auto [m_idx, n_idx, k_idx, l_idx] = blk_coord;
    const int m_coord = m_idx * BLK_M + (get_sub_group_id() / ATOM_N) * SG_M;
    const int n_coord = n_idx * BLK_N + (get_sub_group_id() % ATOM_N) * SG_N;
    const int l_coord = l_idx;

    Tensor copy_iter_sA = make_tensor(make_inttuple_iter(make_coord(m_coord, 0, l_coord)),
                                      make_layout(make_shape(Int<scaleA_traits_size>{}, Int<scaleA_traits_num>{}, _1{}, k_tile_count),
                                      make_stride(E<0>{} * _16{}, E<0>{} * size<1>(typename GmemTiledCopyScaleA::BlockShape{}), _0{}, E<1>{} * _1{})));

    Tensor copy_iter_sB = make_tensor(make_inttuple_iter(make_coord(n_coord, 0, l_coord)),
                           make_layout(make_shape(Int<scaleB_traits_size>{}, Int<scaleB_traits_num>{}, _1{}, k_tile_count),
                                       make_stride(E<0>{} * _16{}, E<0>{} * size<1>(typename GmemTiledCopyScaleB::BlockShape{}), _0{}, E<1>{} * _1{})));

    Tensor copy_iter_zA = make_tensor(make_inttuple_iter(make_coord(m_coord, 0, l_coord)),
                                      make_layout(make_shape(Int<zeroA_traits_size>{}, Int<zeroA_traits_num>{}, _1{}, k_tile_count),
                                      make_stride(E<0>{} * _16{}, E<0>{} * size<1>(typename GmemTiledCopyZeroA::BlockShape{}), _0{}, E<1>{} * _1{})));

    Tensor copy_iter_zB = make_tensor(make_inttuple_iter(make_coord(n_coord, 0, l_coord)),
                           make_layout(make_shape(Int<zeroB_traits_size>{}, Int<zeroB_traits_num>{}, _1{}, k_tile_count),
                                       make_stride(E<0>{} * _16{}, E<0>{} * size<1>(typename GmemTiledCopyZeroB::BlockShape{}), _0{}, E<1>{} * _1{})));

  #define LOG_GROUP 0
  #define LOG_THREAD 0
  #define CUTLASS_ENABLE_DEBUG_PRINTS 0
  #if CUTLASS_ENABLE_DEBUG_PRINTS
  #define PRINT(x) print(#x ": "); print(x); print("\n");
    if (cutlass::thread(LOG_THREAD, LOG_GROUP)) {
        print("======================= A: \n");
        print("  gA   : "); print(gA);   print("\n");
        print("  tCgA : "); print(tCgA); print("\n");
        print("  tAgA : "); print(tAgA); print("\n");
        print("  mma_A : "); print(mma_A); print("\n");
        print("  frag_copy_A : "); print(frag_copy_A); print("\n");

        print("=====================  B :\n");
        print("  gB : ");   print(gB);   print("\n");
        print("  tCgB : "); print(tCgB); print("\n");
        print("  tBgB : "); print(tBgB); print("\n");
        print("  mma_B : "); print(mma_B); print("\n");
        print("  frag_copy_B : "); print(frag_copy_B); print("\n");

        print("=====================  Config: \n");
        print("  threads per workgroup : "); print(MaxThreadsPerBlock);  print("\n");
        print("  SubgroupTileShape     : "); print(SubgroupTileShape{}); print("\n");

        print("  tiled_prefetch_a :    "); print(tiled_prefetch_a); print("\n");
        print("  tiled_prefetch_b :    "); print(tiled_prefetch_b); print("\n");
        print("  pAgA :    "); print(pAgA); print("\n");
        print("  pBgB :    "); print(pBgB); print("\n");
      }
  #undef PRINT
  #endif

    const int k_start_idx = crd2idx((*k_tile_iter), make_shape(K_start));
    constexpr int barrier_scope = 2;
    int prefetch_k = k_start_idx;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < DispatchPolicy::Stages; i++, prefetch_k++) {
      prefetch(tiled_prefetch_a, pAgA(_,_,_,prefetch_k));
      prefetch(tiled_prefetch_b, pBgB(_,_,_,prefetch_k));
    }

    const int k_reload_factor = mainloop.group_size / BLK_K; 

    for (int k_tile = k_start_idx; k_tile < k_tile_count + k_start_idx; k_tile++, prefetch_k++) {
      barrier_arrive(barrier_scope);

      // Copy gmem to rmem for the first k_tile
      copy(mainloop.tiled_copy_a, tAgA(_,_,_,k_tile), frag_copy_A);
      copy(mainloop.tiled_copy_b, tBgB(_,_,_,k_tile), frag_copy_B);

      if constexpr(ModeHasScalesA){
        copy(mainloop.tiled_copy_scaleA, copy_iter_sA(_, _, _, k_tile / k_reload_factor), copy_tCrSA);
      }
      if constexpr(ModeHasScalesB){
        copy(mainloop.tiled_copy_scaleB, copy_iter_sB(_, _, _, k_tile / k_reload_factor), copy_tCrSB);
      }

      if constexpr(ModeHasScalesZeroA){
        copy(mainloop.tiled_copy_zeroA, copy_iter_zA(_, _, _, k_tile / k_reload_factor), copy_tCrZA);
      }
      if constexpr(ModeHasScalesZeroB){
        copy(mainloop.tiled_copy_zeroB, copy_iter_zB(_, _, _, k_tile / k_reload_factor), copy_tCrZB);
      }

      if(prefetch_k < k_tile_count) {
        prefetch(tiled_prefetch_a, pAgA(_,_,_,prefetch_k));
        prefetch(tiled_prefetch_b, pBgB(_,_,_,prefetch_k));
      }

      transform_A(quantA_frag, mma_A, fragment_scaleA_input, fragment_zeroA_input);
      transform_B(quantB_frag, mma_B, fragment_scaleB_input, fragment_zeroB_input);

      cute::gemm(tiled_mma, mma_A, mma_B, accum);
      barrier_wait(barrier_scope);
    }
  }
};

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
