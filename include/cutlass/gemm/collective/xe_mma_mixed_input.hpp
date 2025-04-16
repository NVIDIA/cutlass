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

#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cute/tensor_predicate.hpp"

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
    MainloopIntelPVCMixedPrecision<Stages>,
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

  using ScaleA = detail::deduce_mixed_width_dtype_t<1, ElementAOptionalTuple>;
  using ScaleB = detail::deduce_mixed_width_dtype_t<1, ElementBOptionalTuple>;
  using ZeroA = detail::deduce_mixed_width_dtype_t<2, ElementAOptionalTuple>;
  using ZeroB = detail::deduce_mixed_width_dtype_t<2, ElementBOptionalTuple>;

public:
  //
  // Type Aliases
  //
  using DispatchPolicy = MainloopIntelPVCMixedPrecision<Stages>;
  using WorkgroupTileShape = TileShape_;

  
  static_assert(cute::is_tuple<ElementAOptionalTuple>::value ^ cute::is_tuple<ElementBOptionalTuple>::value, 
    "Either A OR B must be a tuple. It must take the from {ElementOperand, [ElementScale],"
    "[ElementZero]}. Inputs in [] are optional.");

  using ElementA = detail::deduce_mixed_width_dtype_t<0, ElementAOptionalTuple>;
  using ElementB = detail::deduce_mixed_width_dtype_t<0, ElementBOptionalTuple>;
  static constexpr bool IsATransformed = cute::is_tuple<ElementAOptionalTuple>::value;
  using ElementScale = cute::conditional_t<IsATransformed, ScaleA, ScaleB>;
  using ElementZero = cute::conditional_t<IsATransformed, ZeroA, ZeroB>;
  using ElementMMA = cute::conditional_t<IsATransformed, ElementB, ElementA>;
  using ElementQuant = cute::conditional_t<IsATransformed, ElementA, ElementB>;

  static_assert(cute::is_same_v<ElementMMA, ElementScale> || cute::is_same_v<ElementScale, void>, "Quantization scale type must match MMA type.");
  static_assert(cute::is_same_v<ElementMMA, ElementZero> || cute::is_same_v<ElementZero, void>, "Quantization zero point must match MMA type.");

  // For cases where we can't have a void type, we can use this to allow the code to compile when the scale / zero is void.
  using NonVoidElementScale = cute::conditional_t<cute::is_void_v<ElementScale>, ElementMMA, ElementScale>;
  using NonVoidElementZero = cute::conditional_t<cute::is_void_v<ElementZero>, ElementMMA, ElementZero>;

  using StrideA = StrideA_;
  using StrideB = StrideB_;

  // These are always MN major, and we use the same for Scale and Zero
  using StrideScale = cute::Stride<_1, int64_t, int64_t>;
  using TiledMma = TiledMma_;
  using ElementAccumulator = typename TiledMma::ValTypeC;

  using GmemTiledCopyA = GmemTiledCopyA_;
  using GmemTiledCopyB = GmemTiledCopyB_;
  using GmemTiledCopyScale = XE_2D_U16x1x32_LD_N;  // TODO(Codeplay): generalize

  using SmemLayoutAtomA = SmemLayoutAtomA_;
  using SmemLayoutAtomB = SmemLayoutAtomB_;
  using SmemCopyAtomA = SmemCopyAtomA_;
  using SmemCopyAtomB = SmemCopyAtomB_;
  using TransformA = TransformA_;
  using TransformB = TransformB_;
  using ArchTag = typename DispatchPolicy::ArchTag;
  using MmaType = typename TiledMma::ValTypeA; // ValTypeA and ValTypeB are always same and reflects MMA type on intel Xe
  using LargerElementType = std::conditional_t<(cute::sizeof_bits_v<ElementA> > cute::sizeof_bits_v<ElementB>),
                                               ElementA,
                                               ElementB>;

  static_assert(!cute::is_same_v<ElementA, ElementB>, "Mixed precision GEMM requires different types for A and B!");
  static_assert(std::is_same_v<LargerElementType, MmaType>,
               "MainloopIntelPVCMixedPrecision has the restriction that mixed dtype always converts the "
               "narrower input type to the larger one and performs GEMM using the DPAS for the larger input type.");

  static_assert(std::is_same_v<TransformA, cute::identity>, "Transformation for A is not currently supported on Intel PVC");
  static_assert(std::is_same_v<TransformB, cute::identity>, "Transformation for B is not currently supported on Intel PVC");
  
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

  static_assert(!(sizeof_bits_v<ElementQuant> < 8 && ModeHasScales), "Dequantization with sub-byte quant type not yet supported in Xe mixed precision Gemm");

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
  
  static constexpr auto Num_SGs = ATOM_N * ATOM_M * ATOM_K;
  static constexpr uint32_t MaxThreadsPerBlock = size(TiledMma{});

  using CopyThreadShape = Shape<_1, Int<SubgroupSize>>;
  using CopyThreadShapeRev = decltype(cute::reverse(CopyThreadShape{}));

  using traits_load_A = Copy_Traits<GmemTiledCopyA, StrideA>;
  using atom_load_A = Copy_Atom<traits_load_A, ElementA>;
  using val_layout_load_A = decltype(make_layout(shape_div(typename traits_load_A::BlockShape{}, CopyThreadShape{})));
  using Copy_A = decltype(make_tiled_copy(atom_load_A{}, Layout<CopyThreadShape>{}, val_layout_load_A{}));

  using traits_load_B = Copy_Traits<GmemTiledCopyB, StrideB>;
  using atom_load_B = Copy_Atom<traits_load_B, ElementB>;
  using val_layout_load_B = decltype(make_layout(shape_div(typename traits_load_B::BlockShape{}, CopyThreadShape{})));
  using Copy_B = decltype(make_tiled_copy(atom_load_B{}, Layout<CopyThreadShape>{}, val_layout_load_B{}));

  using traits_load_scale = Copy_Traits<GmemTiledCopyScale, StrideScale>;
  using atom_load_scale = Copy_Atom<traits_load_scale, NonVoidElementScale>;
  using val_layout_load_scale = decltype(make_layout(shape_div(typename traits_load_scale::BlockShape{}, CopyThreadShapeRev{}))); 
  using Copy_Scale = decltype(make_tiled_copy(atom_load_scale{}, Layout<CopyThreadShapeRev>{}, val_layout_load_scale{}));
  using Copy_Zero = decltype(make_tiled_copy(atom_load_scale{}, Layout<CopyThreadShapeRev>{}, val_layout_load_scale{}));
  
  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A;
    StrideA dA;
    ElementB const* ptr_B;
    StrideB dB;
    ElementScale const* ptr_S = nullptr;
    StrideScale dS{};
    int group_size = 1;
    ElementZero const* ptr_Z = nullptr;
  };

  struct Params {
    Copy_A tiled_copy_a;
    Copy_B tiled_copy_b;
    Copy_Scale tiled_copy_scale;
    Copy_Zero tiled_copy_zero;
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
    auto mB_nkl =
        make_tensor(make_gmem_ptr(args.ptr_B), make_layout(make_shape(N, K, L), args.dB));

    Copy_A tiled_copy_a{Copy_A{}.with(mA_mkl)};
    Copy_B tiled_copy_b{Copy_B{}.with(mB_nkl)};

    if constexpr(KernelConversionMode == ConversionMode::DirectConvert){
      return Params{tiled_copy_a, tiled_copy_b, {}, {}, 0};
    }

    auto scale_k = cute::ceil_div(K, args.group_size);
    auto mScale = make_tensor(
        make_gmem_ptr(static_cast<NonVoidElementScale const *>(args.ptr_S)),
        make_layout(make_shape(IsATransformed ? M : N, scale_k, L), args.dS));
    Copy_Scale tiled_copy_scale{Copy_Scale{}.with(mScale)};

    if constexpr(KernelConversionMode == ConversionMode::ConvertAndScale){
      return Params{tiled_copy_a, tiled_copy_b, tiled_copy_scale, {}, args.group_size};
    }
    auto mZero =
        make_tensor(make_gmem_ptr(static_cast<NonVoidElementZero const *>(args.ptr_Z)),
                    make_layout(make_shape(IsATransformed ? M : N, scale_k, L), args.dS));
    Copy_Zero tiled_copy_zero{Copy_Zero{}.with(mZero)};

    return Params{tiled_copy_a, tiled_copy_b, tiled_copy_scale, tiled_copy_zero, args.group_size};
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
            class LayoutZeros,
            class... Ts>
  CUTLASS_DEVICE
  void transform_quant(
    Tensor<EngineIn, LayoutIn> const& tCrA_load, 
    Tensor<EngineOut, LayoutOut>& tCrA_mma,
    Tensor<EngineScales, LayoutScales>& tCrS_input,
    Tensor<EngineZeros, LayoutZeros>& tCrZ_input
  ) {

    static_assert(is_rmem<EngineIn>::value, "Input tensor for A conversion must come from registers");
    static_assert(size_v<LayoutIn> == cosize_v<LayoutIn>);
    static_assert(size_v<LayoutOut> == cosize_v<LayoutOut>);
    static_assert(std::is_same_v<typename EngineOut::value_type, typename EngineScales::value_type>);
    static_assert(std::is_same_v<typename EngineOut::value_type, typename EngineZeros::value_type>);
    static_assert(std::is_same_v<LayoutScales, LayoutZeros>);

    using SrcType = typename EngineIn::value_type;
    using DstType = typename EngineOut::value_type;

    if constexpr (sizeof_bits_v<SrcType> < 8) {
      // TODO (Codeplay): Current NumericArrayConverter doesn't work for int4 on intel Xe, just workaround and
      // hardcode here for functionality test, will remove this branch in the future.
      #pragma unroll
      for (int i = 0; i < decltype(size(tCrA_mma))::value; i++) {
        tCrA_mma[i] = static_cast<DstType>(tCrA_load[i].get());
      }
    } else {
      auto const& src = tCrA_load(_, _, _);
      auto const& dst = tCrA_mma(_, _, _);
      auto pSrc = const_cast<SrcType*>(raw_pointer_cast(src.data()));
      auto pDst = const_cast<DstType*>(raw_pointer_cast(dst.data()));
      constexpr int num_elements = decltype(size(src))::value;

    // TODO(Codeplay): (perf) consider replacing `pack` with `num_elements` here - See xe_flash_attn_mma.hpp
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

    if constexpr (ModeHasScales) {
      if constexpr(IsATransformed){
        // The current scale load atom (1x32) gives 2 scale values to
        // each thread. All threads need access to all other threads
        // scale values, and each scale value is reused twice (unrolled)
        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < 16; ++i) {
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < 2; ++j) {
            auto scale = shfl_sync(0xFFFFFFFF, tCrS_input(j), i);
            tCrA_mma(_, _, 0)[j * 16 + i] *= scale;
            tCrA_mma(_, _, 1)[j * 16 + i] *= scale;
            if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero){
              auto zero = shfl_sync(0xFFFFFFFF, tCrZ_input(j), i);
              tCrA_mma(_, _, 0)[j * 16 + i] += zero;
              tCrA_mma(_, _, 1)[j * 16 + i] += zero;
            }
          }
        }
      } else {
        // 16 x 4 x 2 values for B
        // 16 x 2 of these are same K
        // 4 different scale/zero values per thread, no exchange needed
        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < 4; ++i) {
          CUTLASS_PRAGMA_UNROLL
          for (int j = 0; j < 32; ++j) {
            tCrA_mma(_, i, _)[j] *= tCrS_input(i);
            if constexpr (KernelConversionMode == ConversionMode::ConvertAndScaleWithZero){
              tCrA_mma(_, i, _)[j] += tCrZ_input(i);
            }
          }
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
    auto thr_copy_scale = mainloop.tiled_copy_scale.get_slice(thread_idx);
    auto thr_copy_zero = mainloop.tiled_copy_zero.get_slice(thread_idx);

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
    using FragScaleLayout = std::conditional_t<IsATransformed,
                                               Layout<Shape<_2, _1, _1>>,
                                               Layout<Shape<_2, _2, _1>>>;
    Tensor fragment_scale_input = make_tensor<NonVoidElementScale>(FragScaleLayout{});
    Tensor fragment_zero_input =  make_tensor<NonVoidElementZero> (FragScaleLayout{});

    // narrow input fragment
    Tensor quant_frag = make_tensor<ElementQuant>(
        std::conditional_t<IsATransformed, decltype(mma_A.layout()),
                           decltype(mma_B.layout())>{});

    static_assert(std::is_same_v<typename decltype(quant_frag)::value_type, ElementQuant>);
    static_assert(std::is_same_v<typename decltype(mma_A)::value_type, ElementMMA>);
    static_assert(std::is_same_v<typename decltype(mma_B)::value_type, ElementMMA>);

    // Retile for copy
    auto [frag_copy_A, frag_copy_B] = [&](){
      if constexpr (IsATransformed) {
        return std::make_pair(thr_copy_A.retile_D(quant_frag), thr_copy_B.retile_D(mma_B));
      } else {
        return std::make_pair(thr_copy_A.retile_D(mma_A), thr_copy_B.retile_D(quant_frag));
      }
    }();

    Tensor copy_tCrS = thr_copy_scale.retile_D(fragment_scale_input);
    Tensor copy_tCrZ = thr_copy_zero.retile_D(fragment_zero_input);

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

    Tensor copy_iter_s = [&](){
      if constexpr(IsATransformed){
        return make_tensor(make_inttuple_iter(make_coord(m_coord, 0, l_coord)),
                           make_layout(make_shape(_2{}, _1{}, _1{}, k_tile_count), 
                                       make_stride(E<0>{} * _16{}, E<0>{} * _32{}, _0{}, E<1>{} * _1{})));
      }else{
        return make_tensor(make_inttuple_iter(make_coord(n_coord, 0, l_coord)),
                           make_layout(make_shape(_2{}, _2{}, _1{}, k_tile_count), 
                                       make_stride(E<0>{} * _16{}, E<0>{} * _32{}, _0{}, E<1>{} * _1{})));
      }
    }();

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
    int prefetch_k = 0;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < DispatchPolicy::Stages; i++, prefetch_k++) {
      prefetch(tiled_prefetch_a, pAgA(_,_,_,prefetch_k));
      prefetch(tiled_prefetch_b, pBgB(_,_,_,prefetch_k));
    }

    const int k_reload_factor = mainloop.group_size / BLK_K; 

    CUTLASS_PRAGMA_UNROLL
    for (int k_tile = 0, k = k_start_idx; k_tile < k_tile_count; ++k_tile, ++k, ++prefetch_k) {
      // Copy gmem to rmem for the first k_tile
      copy(mainloop.tiled_copy_a, tAgA(_,_,_,k), frag_copy_A);
      copy(mainloop.tiled_copy_b, tBgB(_,_,_,k), frag_copy_B);

      if constexpr(ModeHasScales){
        copy(mainloop.tiled_copy_scale, copy_iter_s(_, _, _, k_start_idx + (k_tile / k_reload_factor)), copy_tCrS);
      }
      if constexpr(KernelConversionMode == ConversionMode::ConvertAndScaleWithZero){
        copy(mainloop.tiled_copy_zero, copy_iter_s(_, _, _, k_start_idx + (k_tile / k_reload_factor)), copy_tCrZ);
      }
      if constexpr (IsATransformed) {
        transform_quant(quant_frag, mma_A, fragment_scale_input,
                        fragment_zero_input);
      } else {
        transform_quant(quant_frag, mma_B, fragment_scale_input,
                        fragment_zero_input);
      }

      if(prefetch_k < k_tile_count) {
        prefetch(tiled_prefetch_a, pAgA(_,_,_,prefetch_k));
        prefetch(tiled_prefetch_b, pBgB(_,_,_,prefetch_k));
      }

      cute::gemm(tiled_mma, mma_A, mma_B, accum);
    }
  }
};


} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
