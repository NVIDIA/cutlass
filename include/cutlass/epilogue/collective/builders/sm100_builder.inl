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
//

//

#include "cute/layout.hpp"     // cute::Shape
#include "cute/numeric/numeric_types.hpp" // cute::sizeof_bits_v
#include "cutlass/arch/mma.h"  // cutlass::arch::OpClassTensorOp, cutlass::OpClassSparseTensorOp
#include "cute/atom/copy_traits_sm100.hpp"
#include "cute/atom/mma_traits_sm100.hpp"
#include "cute/util/type_traits.hpp" // cute::is_same_v

#include "cutlass/detail/dependent_false.hpp" // cutlass::detail::dependent_false
#include "cutlass/detail/layout.hpp"
#include "cutlass/numeric_size.h" // cutlass::bytes_to_bits
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/collective/builders/sm100_common.inl"
#include "cutlass/epilogue/collective/builders/sm90_common.inl"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/epilogue/thread/linear_combination_planar_complex.h"
#include "cutlass/epilogue/fusion/callbacks.hpp"
#include "cutlass/epilogue/fusion/operations.hpp" // detail::is_sfd_epilogue_v
#include "cutlass/epilogue/fusion/sm100_callbacks_tma_warpspecialized.hpp"

#if defined(__CUDACC_RTC__)
#include <cuda/std/type_traits>
#else
#include <type_traits>
#endif

///////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::collective {

///////////////////////////////////////////////////////////////////////////////

namespace detail {

// Returns the smem layout atom to be used for C or D matrix
template<class GmemStrideType, class Element, class EpilogueTile_MN>
constexpr auto
sm100_get_epilogue_smem_swizzle_layout_atom() {
  using namespace cute;

  // Get the max contiguous tile usable by TMA
  [[maybe_unused]] auto tma_tile = cute::transform(EpilogueTile_MN{},
    [](auto const& epi_tile) {
        // assumes get<0>(epi_tile) is coalesced and unit stride
        return size<0>(coalesce(right_inverse(make_layout(get<0>(epi_tile)))));
    });

  // ColMajor C/D (M-major)
  if constexpr (cutlass::detail::is_major<0>(GmemStrideType{})) {
    return cutlass::gemm::collective::detail::sm100_smem_selector<
      UMMA::Major::MN, Element, decltype(get<0>(tma_tile)), decltype(get<1>(tma_tile))
    >();
  }
  // RowMajor C/D (N-major)
  else if constexpr (cutlass::detail::is_major<1>(GmemStrideType{})) {
    return cutlass::gemm::collective::detail::sm100_smem_selector<
      UMMA::Major::K , Element, decltype(get<0>(tma_tile)), decltype(get<1>(tma_tile))
    >();
  }
  else {
    static_assert(cutlass::detail::dependent_false<GmemStrideType>, "Unsupported gmem layout.");
  }
}

// Attempts to compute a reasonable epilogue tile based on block tile shape or allows the user to provide one.
template <
  class OpClass,
  class CtaTileShape_MNK,
  class EpilogueTileType,
  class TmemWarpShape_MN,
  class ElementC,
  class StrideC,
  class ElementD,
  class StrideD,
  class FusionOp
>
constexpr auto
sm100_compute_tile_shape_or_override() {
  using namespace cute;

  if constexpr (cute::is_same_v<EpilogueTileType, EpilogueTileAuto>  && 
                cute::is_same_v<OpClass, arch::OpClassBlockScaledTensorOp> && 
                size<1>(CtaTileShape_MNK{}) == 256) {
    constexpr int CtaM = size<0>(CtaTileShape_MNK{});
    constexpr int WarpM = size<0>(TmemWarpShape_MN{});
    constexpr int DpFull = 32;
    constexpr int M = cute::min(CtaM, DpFull * WarpM); // target 32dp tmem load
    // Note: 
    // Set Epi_Tile_N to 128 support OverlappingAccum for the largest tile.
    // This is a general workable epi_tile_N which does not promise best perf.
    return make_tile(Int<M>{}, Int<128>{}); 
  }
  else if constexpr (cute::is_same_v<EpilogueTileType, EpilogueTileAuto>) {
    constexpr int CtaM = size<0>(CtaTileShape_MNK{});
    constexpr int CtaN = size<1>(CtaTileShape_MNK{});
    constexpr int WarpM = size<0>(TmemWarpShape_MN{});
    constexpr int WarpN = size<1>(TmemWarpShape_MN{});
    constexpr bool DisableSource = is_void_v<ElementC>;
    constexpr int MaxBits = cute::max(sizeof_bits_v<ElementC>, sizeof_bits_v<ElementD>);

    constexpr int DpFull = 32; // tmem datapaths in 1 subpartition
    constexpr int M = cute::min(CtaM, DpFull * WarpM); // target 32dp tmem load
    constexpr int N_perf = [&]() constexpr { // Known subtile sizes tested for perf
      // Epilogues w/o residual load are less sensitive to smem allocation
      // Target a fixed amount of compute per epilogue iteration
      if (DisableSource) {
        if (MaxBits == 4) {
          // Make epilogue tile larger to reduce the epilogue iterations.
          // 64 is the experimental value. It will minimize epilogue iterations but keep the number of A/B buffers the same.
          constexpr int ComputeElts = 8192;
          return ComputeElts / M;
        }
        constexpr int ComputeElts = 4096;
        return ComputeElts / M;
      }
      // Epilogues w/ residual load are more sensitive to smem allocation
      // Target optimal smem distribution between epilogue+mainloop based on datatype+tilesize
      else {
        if (MaxBits == 32) {
          return (CtaM > 64 && CtaN <= 128) ? 16 : 32;
        }
        // Per-column scaling is high register pressure, reduce tile to prevent spills
        else if (FusionOp::IsPerColScaleSupported) {
          return 32;
        }
        else if (MaxBits == 16) {
          return (CtaN <= 128) ? 32 : 64;
        }
        else {
          return 64;
        }
      }
    }();
    constexpr int N_min_C = (DisableSource || detail::is_m_major<StrideC>()) ? 8 * WarpN
                              : (sizeof_bits_v<ElementC> == 6) ? 128 * WarpN // TMA store only supports SW128B for FP6 data type
                                                               : 128 / sizeof_bits_v<ElementC> * WarpN;
    constexpr int N_min_D = (detail::is_m_major<StrideD>()) ? 8 * WarpN
                              : (sizeof_bits_v<ElementD> == 6) ? 128 * WarpN // TMA store only supports SW128B for FP6 data type
                                                               : 128 / sizeof_bits_v<ElementD> * WarpN;
    constexpr int N = cute::min(CtaN, cute::max(N_perf, N_min_C, N_min_D));
    static_assert(CtaN >= N_min_C && CtaN >= N_min_D, "CTA tile too small");

    // stride by tmem warp layout and return a by-mode tiler
    auto tile_m = Layout<Int<M>>{};
    auto tile_n = Layout<Shape <Int<N / WarpN>,Int<        WarpN>>,
                         Stride<Int<         1>,Int<CtaN / WarpN>>>{};

    return make_tile(tile_m, coalesce(tile_n));
  }
  else if constexpr (cute::is_tuple<EpilogueTileType>::value) {
    EpilogueTileType epi_tile;
    constexpr int M = size<0>(shape(epi_tile));
    constexpr int N = size<1>(shape(epi_tile));

    static_assert(!is_layout<EpilogueTileType>::value, "EpilogueTile must be a cute::Tile or cute::Shape");
    static_assert(TmemWarpShape_MN{} == Shape<_2,_2>{} && (M == 32 || M == 64) ||
                  TmemWarpShape_MN{} == Shape<_4,_1>{} && (M == 64 || M == 128), "Unsupported tile shape");
    static_assert(N % 8 == 0, "Unsupported tile shape");

    return epi_tile;
  }
  else {
    static_assert(cutlass::detail::dependent_false<EpilogueTileType>, "Invalid type for EpilogueTileType.");
  }
}

template <class EpilogueScheduleType>
static constexpr bool IsPtrArrayDispatchPolicy =
  cute::is_same_v<EpilogueScheduleType, PtrArrayTmaWarpSpecialized1Sm> ||
  cute::is_same_v<EpilogueScheduleType, PtrArrayTmaWarpSpecialized2Sm>;


template <
  class CtaTileShape_MNK,
  class EpilogueTile_MN,
  class ElementC,
  class ElementD,
  class Schedule
>
constexpr auto
sm100_get_tma_dispatch_policy() {
  using EpilogueTileShape_MN = decltype(product_each(shape(EpilogueTile_MN{})));
  constexpr int EpiTiles = size(shape_div(take<0,2>(CtaTileShape_MNK{}), EpilogueTileShape_MN{}));
  constexpr int FragmentSize = size(EpilogueTileShape_MN{}) / NumThreadsPerWarpGroup;
  // 8b residuals load fast and consume little smem, so the perf cost of waiting on stores to finish outweighs the cost of extra allocation
  constexpr bool ReuseSmem = sizeof_bits_v<ElementC> > 8;
  constexpr bool DelayTmaStore = false;
  constexpr int StagesD = cute::min(EpiTiles, 2);
  constexpr int StagesC = ReuseSmem ? cute::max(cute::min(EpiTiles, 4), StagesD+1)
                                    : cute::min(EpiTiles, 4);

    if constexpr (detail::IsPtrArrayDispatchPolicy<Schedule>) {
      return Sm100PtrArrayTmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmem, DelayTmaStore>{};
    }
    else
    {
      return Sm100TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmem, DelayTmaStore>{};
    }
}

/*
 * Returns the TMEM_LOAD copy op to be used for the epilogue
 * Returned TMEM_LOAD op is such that the thread-value ownership matches the widest available
 * smem storage vectorization, subject to the constraints of data types and gmem layout
 * Selected op also maximizes the TMEM_LOAD shape in order to minimize TMEM_LOADs issued,
 * subject to the constraint of the provided per-warp tmem subpartition shape
**/
template<class GmemStrideTypeD, class ElementAccumulator, class ElementD, class TmemShape_MN, class FusionOp>
constexpr auto
sm100_get_tmem_load_op() {
  using namespace cute;

  // Number of datapaths (dp) available in this warp's tmem subpartition.
  // If only 16dp are available then we must use 16dp TMEM_LOAD variants
  // otherwise we prefer 32dp variants as those have higher throughput

  // For those fused patterns which have RowReduction or RowBroadcast
  // 16dp tmem load op can effectively reduce the usage of registers & shuffle instrs
  // Compared to TMEM_LOAD throughput, it's more critical
  constexpr int num_dp = size<0>(TmemShape_MN{});
  static_assert(num_dp == 16 || num_dp == 32, "Unsupported tmem datapath count");

  // Number of columns in this tmem subpartition, in bits
  // Used to select the widest cross variant TMEM_LOAD available
  constexpr int num_col_bits = size<1>(TmemShape_MN{}) * sizeof_bits_v<ElementAccumulator>;

  // Layout information, determines max available smem store vectorization
  // For M-major layouts we tend to target stmatrix_t (UMMA stores tmem accumulator in N-Major)
  constexpr bool is_m_major = cutlass::detail::is_major<0>(GmemStrideTypeD{});
  constexpr bool is_n_major = cutlass::detail::is_major<1>(GmemStrideTypeD{});
  static_assert(is_m_major || is_n_major, "Unsupported gmem layout");

  // dispatch on data types as this determines the correspondence
  // between TMEM_LOAD thread-bit ownership patterns and logical values
  if constexpr (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 32) {
    if constexpr (num_dp == 16) {
      if constexpr (is_m_major) {
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp256b1x, num_col_bits>(); // 32b stores to smem
      }
      else {
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp128b1x, num_col_bits>(); // stmatrix_n
        // return TMEM::op_repeater<SM100_TMEM_LOAD_16dp256b1x, num_col_bits>(); // 64b stores to smem
        // return TMEM::op_repeater<SM100_TMEM_LOAD_16dp32b1x, num_col_bits>(); // 128b stores to smem
      }
    }
    else {
      return TMEM::op_repeater<SM100_TMEM_LOAD_32dp32b1x, num_col_bits>(); // 32b or 128b stores to smem
    }
  }

  else if constexpr (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 16) {
    if constexpr (num_dp == 16) {
      if constexpr (is_m_major) {
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp256b1x, num_col_bits>(); // stmatrix_t
      }
      else {
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp256b1x, num_col_bits>(); // stmatrix_n
        // return TMEM::op_repeater<SM100_TMEM_LOAD_16dp32b1x, num_col_bits>(); // 128b stores to smem
      }
    }
    else {
      if constexpr (is_m_major) {
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp256b1x, num_col_bits>(); // stmatrix_t
      }
      else {
        return TMEM::op_repeater<SM100_TMEM_LOAD_32dp32b1x, num_col_bits>(); // 128b stores to smem
      }
    }
  }

  // For int8 kernels where accumulation is 32b but result store may be back to int8
  else if constexpr (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 8) {
    if constexpr (num_dp == 16) {
      if constexpr (is_m_major) {
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp256b1x, num_col_bits>(); // stmatrix_t m16n8
      }
      else {
        // return TMEM::op_repeater<SM100_TMEM_LOAD_16dp256b1x, num_col_bits>(); // 16b stores to smem
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp32b1x, num_col_bits>(); // 128b stores to smem
      }
    }
    else {
      // To use the HW instruction to find amax along the row/column of acc, the TMEM_LOAD pattern needs to be 32dp32bit.
        return TMEM::op_repeater<SM100_TMEM_LOAD_32dp32b1x, num_col_bits>(); // 128b stores to smem
    }
  }

  // For 16b accumulation we use pack16b TMEM_LOAD variants as UMMA stores these values sparsely in tmem
  else if constexpr (sizeof_bits_v<ElementAccumulator> == 16 && sizeof_bits_v<ElementD> == 16) {
    if constexpr (num_dp == 16) {
      if constexpr (is_m_major) {
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp128b1x_16b, num_col_bits>(); // stmatrix_t
      }
      else {
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp128b1x_16b, num_col_bits>(); // stmatrix_n
        // return TMEM::op_repeater<SM100_TMEM_LOAD_16dp32b1x_16b, num_col_bits>(); // 128b stores to smem
      }
    }
    else {
      if constexpr (is_m_major) {
        return TMEM::op_repeater<SM100_TMEM_LOAD_16dp128b1x_16b, num_col_bits>(); // stmatrix_t
      }
      else {
        return TMEM::op_repeater<SM100_TMEM_LOAD_32dp32b1x_16b, num_col_bits>(); // 128b stores to smem
      }
    }
  }
  // For complex TF32 kernels
  else if constexpr (sizeof_bits_v<ElementAccumulator> == 64 && sizeof_bits_v<ElementD> == 64) {
    if constexpr (num_dp == 16) {
      return TMEM::op_repeater<SM100_TMEM_LOAD_16dp256b1x, num_col_bits>();
    }
    else {
      return TMEM::op_repeater<SM100_TMEM_LOAD_32dp32b1x, num_col_bits>();
    }
  }
  // For narrow precision output
  else if constexpr (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 6) {
    static_assert(num_dp == 32);
    return TMEM::op_repeater<SM100_TMEM_LOAD_32dp32b1x, num_col_bits>();
  }
  else if constexpr (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 4) {
    static_assert(num_dp == 32);
    return TMEM::op_repeater<SM100_TMEM_LOAD_32dp32b1x, num_col_bits>();
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAccumulator, ElementD>, "Unsupported data types");
  }
}

// Selects the largest vectorized smem store atom available
// subject to constraint of gmem layout and chosen TMEM_LOAD's thread-value ownership
template <class GmemStrideTypeD, class ElementD, class ElementAccumulator, class AccLoadOp>
constexpr auto
sm100_get_smem_store_op() {
  using namespace cute;

  [[maybe_unused]] constexpr bool is_m_major = cutlass::detail::is_major<0>(GmemStrideTypeD{});
  [[maybe_unused]] constexpr bool is_n_major = cutlass::detail::is_major<1>(GmemStrideTypeD{});
  static_assert(is_m_major || is_n_major, "Unsupported gmem layout");

  // Check for TMEM_LOAD layouts that match the thread-value ownership pattern of stmatrix
  // TODO: check copy vectorization instead!
  constexpr bool use_stmatrix_m8n8_4x =
    (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 32 && is_n_major &&
      ( cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b2x>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b4x>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b8x>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b16x> ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b32x> ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b64x>   )    ) ||
    (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 16 &&
      ( cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b2x>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b4x>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b8x>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b16x> ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b32x>   )    ) ||
    (sizeof_bits_v<ElementAccumulator> == 16 && sizeof_bits_v<ElementD> == 16 &&
      ( cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b2x_16b>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b4x_16b>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b8x_16b>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b16x_16b> ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b32x_16b> ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b64x_16b>   ));
  [[maybe_unused]] constexpr bool use_stmatrix_m16n8_4x =
    (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 8 && is_m_major &&
      ( cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b4x>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b8x>  ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b16x> ||
        cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b32x>   )    );

  // 1x TMEM_LOAD doesn't have enough values to use largest stmatrix variants
  [[maybe_unused]]  constexpr bool use_stmatrix_m8n8_2x =
    (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 32 && is_n_major &&
      cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b1x>           ) ||
    (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 16 &&
      cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b1x>           ) ||
    (sizeof_bits_v<ElementAccumulator> == 16 && sizeof_bits_v<ElementD> == 16 &&
      cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp128b1x_16b>       );
  [[maybe_unused]] constexpr bool use_stmatrix_m16n8_2x =
    (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 8 && is_m_major &&
      cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b2x>           );
  [[maybe_unused]] constexpr bool use_stmatrix_m16n8_1x =
    (sizeof_bits_v<ElementAccumulator> == 32 && sizeof_bits_v<ElementD> == 8 && is_m_major &&
      cute::is_same_v<AccLoadOp, SM100_TMEM_LOAD_16dp256b1x>           );

  if constexpr (use_stmatrix_m8n8_4x) {
    if constexpr (is_n_major) {
      return SM90_U32x4_STSM_N{};
    }
    else if constexpr (is_m_major) {
      return SM90_U16x8_STSM_T{};
    }
  }
  else if constexpr (use_stmatrix_m8n8_2x) {
    if constexpr (is_n_major) {
      return SM90_U32x2_STSM_N{};
    }
    else if constexpr (is_m_major) {
      return SM90_U16x4_STSM_T{};
    }
  }
  else if constexpr (use_stmatrix_m16n8_4x) {
    return SM100_U8x16_STSM_T{};
  }
  else if constexpr (use_stmatrix_m16n8_2x) {
    return SM100_U8x8_STSM_T{};
  }
  else if constexpr (use_stmatrix_m16n8_1x) {
    return SM100_U8x4_STSM_T{};
  }
  else {
    // auto-vectorizing store
    return AutoVectorizingCopyWithAssumedAlignment<128>{};
  }
}

template <class GmemStrideTypeD, class ElementD>
constexpr auto
sm100_get_register_transform_op() {
  using namespace cute;

  [[maybe_unused]] constexpr bool is_m_major = cutlass::detail::is_major<0>(GmemStrideTypeD{});
  [[maybe_unused]] constexpr bool is_n_major = cutlass::detail::is_major<1>(GmemStrideTypeD{});
  static_assert(is_m_major || is_n_major, "Unsupported gmem layout");

  if constexpr (sizeof_bits_v<ElementD> == 4 && is_m_major) {
    return SM50_Shuffle_U32_2x2Trans_XOR1{};
  }
  else {
    return AutoVectorizingCopyWithAssumedAlignment<128>{};
  }
}

// Selects the largest vectorized smem load atom available
// subject to constraint of gmem layout and chosen TMEM_LOAD's thread-value ownership
template <class GmemStrideTypeC, class ElementC, class ElementAccumulator, class AccLoadOp>
constexpr auto
sm100_get_smem_load_op() {
  using namespace cute;

  // Reuse the logic from smem store selector
  using SmemStoreOp = decltype(sm100_get_smem_store_op<
      GmemStrideTypeC, ElementC, ElementAccumulator, AccLoadOp>());

  if constexpr (cute::is_same_v<SmemStoreOp, SM90_U32x4_STSM_N>) {
    return SM75_U32x4_LDSM_N{};
  }
  else if constexpr (cute::is_same_v<SmemStoreOp, SM90_U16x8_STSM_T>) {
    return SM75_U16x8_LDSM_T{};
  }
  else if constexpr (cute::is_same_v<SmemStoreOp, SM90_U32x2_STSM_N>) {
    return SM75_U32x2_LDSM_N{};
  }
  else if constexpr (cute::is_same_v<SmemStoreOp, SM90_U16x4_STSM_T>) {
    return SM75_U16x4_LDSM_T{};
  }
  else if constexpr (cute::is_same_v<SmemStoreOp, SM100_U8x16_STSM_T>) {
    return SM100_U8x16_LDSM_T{};
  }
  else if constexpr (cute::is_same_v<SmemStoreOp, SM100_U8x8_STSM_T>) {
    return SM100_U8x8_LDSM_T{};
  }
  else {
    // auto-vectorizing load
    return AutoVectorizingCopyWithAssumedAlignment{};
  }
}

template <class Schedule, class LayoutTag>
constexpr auto
sm100_get_gmem_load_op() {
  if constexpr (detail::is_im2col_mode<LayoutTag>) {
    return SM90_TMA_LOAD_IM2COL{};
  }
  else {
  
    return SM90_TMA_LOAD{};
  } 
}

template <class Schedule, class LayoutTag>
constexpr auto
sm100_get_gmem_store_op() {
  if constexpr (detail::is_im2col_mode<LayoutTag>) {
    return SM90_TMA_STORE_IM2COL{};
  }
  else {
  
    return SM90_TMA_STORE{};
  } 
}

// aux fusion callbacks builder for sm100 tma epilogue
template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  class FusionOp,
  class CtaTileShape_MNK,
  class EpilogueTile_MN,
  class ElementAccumulator,
  class AccLoadOp
>
struct CallbacksBuilder<
  Sm100TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
  FusionOp,
  CtaTileShape_MNK,
  EpilogueTile_MN,
  ElementAccumulator,
  AccLoadOp,
  cute::enable_if_t<(FusionOp::IsAuxOutSupported ^ FusionOp::IsAuxInSupported) // only one aux tensor
              && not cute::is_subbyte_v<typename FusionOp::ElementAux>>
> {
  using GmemStrideTypeAux = gemm::TagToStrideC_t<typename FusionOp::GmemLayoutTagAux>;
  using SmemLayoutAtomAux = decltype(detail::sm100_get_epilogue_smem_swizzle_layout_atom<
    GmemStrideTypeAux, typename FusionOp::ElementAux, EpilogueTile_MN>());
  using CopyOpR2S = decltype(detail::sm100_get_smem_store_op<
    GmemStrideTypeAux, typename FusionOp::ElementAux, ElementAccumulator, AccLoadOp>());
  using CopyOpS2R = decltype(detail::sm100_get_smem_load_op<
    GmemStrideTypeAux, typename FusionOp::ElementAux, ElementAccumulator, AccLoadOp>());
  using SmemCopyOpAux = cute::conditional_t<FusionOp::IsAuxOutSupported, CopyOpR2S, CopyOpS2R>;

  using Callbacks = fusion::FusionCallbacks<
    Sm100TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
    FusionOp, CtaTileShape_MNK, EpilogueTile_MN,
    SmemLayoutAtomAux, SmemCopyOpAux
  >;
};

template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  class FusionOp,
  class CtaTileShape_MNK,
  class EpilogueTile_MN,
  class ElementAccumulator,
  class AccLoadOp
>
struct CallbacksBuilder<
  Sm100TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
  FusionOp,
  CtaTileShape_MNK,
  EpilogueTile_MN,
  ElementAccumulator,
  AccLoadOp,
  cute::enable_if_t<(FusionOp::IsAuxOutSupported ^ FusionOp::IsAuxInSupported) // only one aux tensor
              && sizeof_bits_v<typename FusionOp::ElementAux> == 1>
> {
  using Callbacks = fusion::FusionCallbacks<
    Sm100TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
    FusionOp, CtaTileShape_MNK, EpilogueTile_MN,
    Layout<_1,_0>, DefaultCopy // aux bit tensor doesn't use smem
  >;
};

// aux fusion callbacks builder for sm100 direct store epilogue
template <
  class FusionOp,
  class TileShape_MNK,
  class EpilogueTile_MN,
  class AccLoadOp,
  class ElementAccumulator
>
struct CallbacksBuilder<
  Sm100NoSmemWarpSpecialized,
  FusionOp,
  TileShape_MNK,
  EpilogueTile_MN,
  ElementAccumulator,
  AccLoadOp,
  cute::enable_if_t<(FusionOp::IsAuxOutSupported ^ FusionOp::IsAuxInSupported)> // only one aux tensor
> {
  using Callbacks = fusion::FusionCallbacks<
    Sm100NoSmemWarpSpecialized, FusionOp, TileShape_MNK, EpilogueTile_MN,
    Layout<_1,_0>, DefaultCopy // aux tensor doesn't use tma
  >;
};

// Helper for building TMA warp-specialized collective epilogues, specialized by
// the fusion operation performed and the dispatch policy to use.
template <
  class OpClass,
  class CtaTileShape_MNK,
  class EpilogueTileType,
  class TmemWarpShape_MN,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC_,
  class GmemLayoutTagC_,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class Schedule,
  class FusionOpOrCallbacks
>
struct Sm100TmaBuilderImpl {
  // Passing void C disables source load + smem allocation
  using ElementC = cute::conditional_t<cute::is_void_v<ElementC_>,ElementD,ElementC_>; // prevents void ref breakages
  using GmemLayoutTagC = cute::conditional_t<cute::is_void_v<ElementC_>,GmemLayoutTagD,GmemLayoutTagC_>;

  using GmemStrideTypeC = cutlass::detail::TagToStrideC_t<GmemLayoutTagC>;
  using GmemStrideTypeD = cutlass::detail::TagToStrideC_t<GmemLayoutTagD>;

  using CopyOpS2G = decltype(detail::sm100_get_gmem_store_op<Schedule,GmemLayoutTagD>());
  using CopyOpG2S = decltype(detail::sm100_get_gmem_load_op<Schedule,GmemLayoutTagC>());

  using FusionOp = conditional_t<is_base_of_v<epilogue::fusion::FusionOperation, FusionOpOrCallbacks>,
                                  FusionOpOrCallbacks, epilogue::fusion::FusionOperation>;

  using EpilogueTile_MN = decltype(detail::sm100_compute_tile_shape_or_override<
      OpClass, CtaTileShape_MNK, EpilogueTileType, TmemWarpShape_MN,
      ElementC_, GmemStrideTypeC, ElementD, GmemStrideTypeD, FusionOp>());
  using EpilogueTileShape_MN = decltype(product_each(shape(EpilogueTile_MN{})));
  using EpilogueWarpTileShape_MN = decltype(shape_div(EpilogueTileShape_MN{}, TmemWarpShape_MN{}));
  using AccLoadOp = decltype(detail::sm100_get_tmem_load_op<
      GmemStrideTypeD, ElementAccumulator, ElementD, EpilogueWarpTileShape_MN, FusionOp>());

  using InternalSmemElementC = typename cutlass::detail::get_unpacked_element_type<ElementC>::type;
  using InternalSmemElementD = typename cutlass::detail::get_unpacked_element_type<ElementD>::type;

  using DispatchPolicy = decltype(detail::sm100_get_tma_dispatch_policy<
      CtaTileShape_MNK, EpilogueTile_MN, ElementC_, ElementD, Schedule>());
  // TMA builder allows for passing callbacks directly, which is either a fusion::FusionCallbacks
  // instance or a direct visitor implementation, e.g. fusion::Sm90LinearCombination
  using FusionCallbacks =
    typename CallbacksBuilder<
      DispatchPolicy,
      FusionOpOrCallbacks,
      CtaTileShape_MNK,
      EpilogueTile_MN,
      ElementAccumulator,
      AccLoadOp
    >::Callbacks;

  using CollectiveOp =
    cutlass::epilogue::collective::CollectiveEpilogue<
      DispatchPolicy,
      CtaTileShape_MNK,
      EpilogueTile_MN,
      ElementC_, // Need to pass void through to expose via GemmUniversal
      GmemStrideTypeC,
      ElementD,
      GmemStrideTypeD,
      FusionCallbacks,
      AccLoadOp,
      CopyOpG2S,
      decltype(detail::sm100_get_epilogue_smem_swizzle_layout_atom<GmemStrideTypeC, InternalSmemElementC, EpilogueTile_MN>()),
      decltype(detail::sm100_get_smem_load_op<GmemStrideTypeC, InternalSmemElementC, ElementAccumulator, AccLoadOp>()),
      CopyOpS2G,
      decltype(detail::sm100_get_epilogue_smem_swizzle_layout_atom<GmemStrideTypeD, InternalSmemElementD, EpilogueTile_MN>()),
      decltype(detail::sm100_get_smem_store_op<GmemStrideTypeD, InternalSmemElementD, ElementAccumulator, AccLoadOp>()),
      decltype(detail::sm100_get_register_transform_op<GmemStrideTypeD, InternalSmemElementD>())
    >;
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////

// No smem builder
template <
  class CtaTileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC_,
  class GmemLayoutTagC_,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class EpilogueScheduleType,
  class FusionOpOrCallbacks
>
struct CollectiveBuilder<
    arch::Sm100,
    arch::OpClassTensorOp,
    CtaTileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC_,
    GmemLayoutTagC_,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    EpilogueScheduleType,
    FusionOpOrCallbacks,
    cute::enable_if_t<cute::is_same_v<EpilogueScheduleType, NoSmemWarpSpecialized> ||
                      cute::is_same_v<EpilogueScheduleType, PtrArrayNoSmemWarpSpecialized> >> {

  static_assert(cute::is_same_v<EpilogueTileType, EpilogueTileAuto>, "Epilogue subtiling requires smem");
  static_assert(cute::sizeof_bits_v<ElementD> != 4 and cute::sizeof_bits_v<ElementD> != 6, "Output element requires smem");

  static constexpr bool DisableSource = cute::is_void_v<ElementC_>;
  using ElementC = cute::conditional_t<DisableSource, ElementD, ElementC_>; // prevents void ref breakages
  using GmemLayoutTagC = cute::conditional_t<DisableSource, GmemLayoutTagD, GmemLayoutTagC_>;
  using GmemStrideTypeC = cutlass::detail::TagToStrideC_t<GmemLayoutTagC>;
  using GmemStrideTypeD = cutlass::detail::TagToStrideC_t<GmemLayoutTagD>;

  using FusionOp = conditional_t<is_base_of_v<epilogue::fusion::FusionOperation, FusionOpOrCallbacks>,
                                  FusionOpOrCallbacks, epilogue::fusion::FusionOperation>;

  // use a 4x2 division to select tmem load shape in order to maintain compatability with both (4,1) and (2,2) layouts
  using EpilogueTile = decltype(take<0,2>(CtaTileShape_MNK{}));
  using EpilogueWarpTileShape_MN = decltype(shape_div(EpilogueTile{}, Shape<_4,_2>{}));
  using AccLoadOp = decltype(detail::sm100_get_tmem_load_op<
      GmemStrideTypeD, ElementAccumulator, ElementD, EpilogueWarpTileShape_MN, FusionOp>());

  using DispatchPolicy = cutlass::epilogue::Sm100NoSmemWarpSpecialized;

  using AlignmentCType = Int<AlignmentC>;
  using AlignmentDType = Int<AlignmentD>;

  static constexpr FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest;
  static constexpr thread::ScaleType::Kind ScaleType = DisableSource ?
      thread::ScaleType::OnlyAlphaScaling : thread::ScaleType::Default;

  using FusionCallbacks = cute::conditional_t<
    IsDefaultFusionOp<FusionOp>::value,
    // Legacy codepath using thread::LinearCombination, do not expect this to be stable
    thread::LinearCombination<
      ElementD, 1, ElementAccumulator, ElementCompute,
      ScaleType, RoundStyle, ElementC>
    ,
    typename detail::CallbacksBuilder<
      DispatchPolicy,
      FusionOpOrCallbacks,
      CtaTileShape_MNK,
      EpilogueTile,
      ElementAccumulator,
      AccLoadOp
    >::Callbacks
  >;

  using CollectiveOp = cute::conditional_t<
    cute::is_same_v<EpilogueScheduleType, NoSmemWarpSpecialized>,
    cutlass::epilogue::collective::CollectiveEpilogue<
      cutlass::epilogue::Sm100NoSmemWarpSpecialized,
      EpilogueTile,
      ElementC_,
      GmemStrideTypeC,
      ElementD,
      GmemStrideTypeD,
      FusionCallbacks,
      AccLoadOp,
      AlignmentCType,
      AlignmentDType
    >,
    cutlass::epilogue::collective::CollectiveEpilogue<
      cutlass::epilogue::Sm100PtrArrayNoSmemWarpSpecialized,
      EpilogueTile,
      ElementC_,
      GmemStrideTypeC,
      ElementD,
      GmemStrideTypeD,
      FusionCallbacks,
      AccLoadOp
    >
  >;
};

// No smem builder for OpClassBlockScaledTensorOp
template <
  class CtaTileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC_,
  class GmemLayoutTagC_,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class EpilogueScheduleType,
  class FusionOp
>
struct CollectiveBuilder<
    arch::Sm100,
    arch::OpClassBlockScaledTensorOp,
    CtaTileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC_,
    GmemLayoutTagC_,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    EpilogueScheduleType,
    FusionOp,
    cute::enable_if_t<cute::is_same_v<EpilogueScheduleType, NoSmemWarpSpecialized> ||
                      cute::is_same_v<EpilogueScheduleType, PtrArrayNoSmemWarpSpecialized> >> {

  static_assert(cute::sizeof_bits_v<ElementD> != 6, "Output element requires smem");
  
  static constexpr bool DisableSource = cute::is_void_v<ElementC_>;
  using ElementC = cute::conditional_t<DisableSource, ElementD, ElementC_>; // prevents void ref breakages
  using GmemLayoutTagC = cute::conditional_t<DisableSource, GmemLayoutTagD, GmemLayoutTagC_>;
  static constexpr thread::ScaleType::Kind ScaleType = DisableSource ?
      thread::ScaleType::OnlyAlphaScaling : thread::ScaleType::Default;
  using GmemStrideTypeC = cutlass::detail::TagToStrideC_t<GmemLayoutTagC>;
  using GmemStrideTypeD = cutlass::detail::TagToStrideC_t<GmemLayoutTagD>;

  static_assert(cute::is_tuple<EpilogueTileType>::value || cute::is_same_v<EpilogueTileType, EpilogueTileAuto>);
  using EpilogueTile = cute::conditional_t<cute::is_same_v<EpilogueTileType, EpilogueTileAuto>,
                          cute::Shape<_128, _64>,
                          EpilogueTileType           
                        >;

  using EpilogueWarpTileShape_MN = decltype(shape_div(EpilogueTile{}, Shape<_4,_1>{}));
  using AccLoadOp = decltype(detail::sm100_get_tmem_load_op<
      GmemStrideTypeD, ElementAccumulator, ElementD, EpilogueWarpTileShape_MN, FusionOp>());

  using DispatchPolicy = cutlass::epilogue::Sm100NoSmemWarpSpecialized;

  using AlignmentCType = Int<AlignmentC>;
  using AlignmentDType = Int<AlignmentD>;

  static constexpr FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest;

  static_assert(is_base_of_v<fusion::FusionOperation, FusionOp>, "only support EVT fusions");
  using FusionCallbacks =
    typename detail::CallbacksBuilder<
      DispatchPolicy,
      FusionOp,
      CtaTileShape_MNK,
      EpilogueTile,
      ElementAccumulator,
      AccLoadOp
    >::Callbacks;

  using CollectiveOp = cute::conditional_t<
    cute::is_same_v<EpilogueScheduleType, NoSmemWarpSpecialized>,
    cutlass::epilogue::collective::CollectiveEpilogue<
      cutlass::epilogue::Sm100NoSmemWarpSpecialized,
      EpilogueTile,
      ElementC_,
      GmemStrideTypeC,
      ElementD,
      GmemStrideTypeD,
      FusionCallbacks,
      AccLoadOp,
      AlignmentCType,
      AlignmentDType
    >,
    cutlass::epilogue::collective::CollectiveEpilogue<
      cutlass::epilogue::Sm100PtrArrayNoSmemWarpSpecialized,
      EpilogueTile,
      ElementC_,
      GmemStrideTypeC,
      ElementD,
      GmemStrideTypeD,
      FusionCallbacks,
      AccLoadOp
    >
  >;
};

// TMA epilogue builder
template <
  class OpClass,
  class CtaTileShape_MNK,    // Static CTA tile shape
  class ClusterShape_MNK,    // Static cluster shape or dynamic (int, int, _1)
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class EpilogueScheduleType,
  class FusionOp
>
struct CollectiveBuilder<
    arch::Sm100,
    OpClass,
    CtaTileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    GmemLayoutTagC,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    EpilogueScheduleType,
    FusionOp,
    cute::enable_if_t<
      // OpClass
      ( cute::is_same_v<OpClass, arch::OpClassTensorOp>
        || cute::is_same_v<OpClass, arch::OpClassBlockScaledTensorOp>
      ) &&
      // Epilogue Schedule Type
      ( cute::is_base_of_v<TmaWarpSpecialized1Sm, EpilogueScheduleType> ||
        cute::is_base_of_v<TmaWarpSpecialized2Sm, EpilogueScheduleType>
        || detail::IsPtrArrayDispatchPolicy<EpilogueScheduleType>
      )>>
 {
private:
  using TmemWarpShape_MN = cute::conditional_t<size<0>(CtaTileShape_MNK{}) == 64 &&
                                               (cute::is_base_of_v<TmaWarpSpecialized2Sm, EpilogueScheduleType>
                                               || cute::is_same_v<EpilogueScheduleType, PtrArrayTmaWarpSpecialized2Sm>
                                               ),
                                               Shape<_2,_2>, Shape<_4,_1>>;

public:
  using CollectiveOp =
    typename detail::Sm100TmaBuilderImpl<
      OpClass,
      CtaTileShape_MNK,
      EpilogueTileType,
      TmemWarpShape_MN,
      ElementAccumulator,
      ElementCompute,
      ElementC,
      GmemLayoutTagC,
      AlignmentC,
      ElementD,
      GmemLayoutTagD,
      AlignmentD,
      EpilogueScheduleType,
      FusionOp
    >::CollectiveOp;
};

// Auto builder
template <
  class OpClass,
  class CtaTileShape_MNK,     // Static CTA tile shape
  class ClusterShape_MNK,     // Static cluster shape or dynamic (int, int, _1)
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class EpilogueScheduleType,
  class FusionOp
>
struct CollectiveBuilder<
    arch::Sm100,
    OpClass,
    CtaTileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    GmemLayoutTagC,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    EpilogueScheduleType,
    FusionOp,
    cute::enable_if_t<
      // OpClass
      ( cute::is_same_v<OpClass, arch::OpClassTensorOp>
        || cute::is_same_v<OpClass, arch::OpClassBlockScaledTensorOp>
      )
      // Epilogue Schedule Type
      && cute::is_same_v<EpilogueScheduleType, EpilogueScheduleAuto>>
>
 {
private:
  static_assert(cute::is_same_v<EpilogueTileType, EpilogueTileAuto>, "Don't specify epilogue tile with auto schedule");
  using TmemWarpShape_MN = cute::conditional_t<size<0>(CtaTileShape_MNK{}) == 64 &&
                                               size<0>(ClusterShape_MNK{}) % 2 == 0
                                               ,
                                              Shape<_2,_2>, Shape<_4,_1>>;
public:
  using CollectiveOp =
    typename detail::Sm100TmaBuilderImpl<
      OpClass,
      CtaTileShape_MNK,
      EpilogueTileType,
      TmemWarpShape_MN,
      ElementAccumulator,
      ElementCompute,
      ElementC,
      GmemLayoutTagC,
      AlignmentC,
      ElementD,
      GmemLayoutTagD,
      AlignmentD,
      EpilogueScheduleType,
      FusionOp
    >::CollectiveOp;
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::epilogue::collective
