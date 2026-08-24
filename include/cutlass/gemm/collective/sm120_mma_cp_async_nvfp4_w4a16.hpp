/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 *modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *this list of conditions and the following disclaimer in the documentation
 *and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *may be used to endorse or promote products derived from this software without
 *specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 *FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **************************************************************************************************/

/*! \file
    \brief SM120/SM121 cp.async collective for FP16 by block-scaled NVFP4 GEMM.

    This collective implements the mixed-input portion that is not covered by
   the native SM120 block-scaled MMA collectives: NVFP4 values and their
   block-16 UE4M3 scales are loaded together, expanded to FP16 register
   fragments, and consumed by FP16 Tensor Core MMA with FP32 accumulation. It
   deliberately keeps the conversion inside the K mainloop so that no expanded
    weight matrix is materialized in global or shared memory.
*/

#pragma once

#include "cute/arch/copy_sm75.hpp"
#include "cute/arch/copy_sm80.hpp"
#include "cute/arch/mma_sm80.hpp"
#include "cute/tensor.hpp"

#include "cutlass/array.h"
#include "cutlass/array_subbyte.h"
#include "cutlass/detail/layout.hpp"
#include "cutlass/float_subbyte.h"
#include "cutlass/gemm/collective/builders/sm90_common.inl"
#include "cutlass/gemm/collective/collective_mma_decl.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/gemm.h"
#include "cutlass/half.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/layout/nvfp4_w4a16.h"
#include "cutlass/numeric_conversion.h"

#include <cstdint>
#include <limits>

namespace cutlass::gemm::collective {

/// SM120/SM121 W4A16 collective specialization. TileN and TileK are fixed
/// because the register fragment mapping is coupled to the four-warp 64/128/64
/// CuTe MMA tile. TileM may be 16 or 64 so callers can avoid wasting work on
/// the small-M tail used by prefill.
template <int Stages_, class ClusterShape_, class TileShape_, class ElementA_,
          class StrideA_, class ElementBPair_, class StrideBPair_,
          class TiledMma_, class GmemTiledCopyA_, class SmemLayoutAtomA_,
          class SmemCopyAtomA_, class TransformA_, class GmemTiledCopyB_,
          class SmemLayoutAtomB_, class SmemCopyAtomB_, class TransformB_>
struct CollectiveMma<
    cutlass::gemm::MainloopSm120CpAsyncNvfp4W4A16<Stages_, ClusterShape_>,
    TileShape_, ElementA_, StrideA_, ElementBPair_, StrideBPair_, TiledMma_,
    GmemTiledCopyA_, SmemLayoutAtomA_, SmemCopyAtomA_, TransformA_,
    GmemTiledCopyB_, SmemLayoutAtomB_, SmemCopyAtomB_, TransformB_> {
  using DispatchPolicy =
      cutlass::gemm::MainloopSm120CpAsyncNvfp4W4A16<Stages_, ClusterShape_>;
  using TileShape = TileShape_;
  using CtaShape_MNK = TileShape;
  using ArchTag = typename DispatchPolicy::ArchTag;
  using ElementA = ElementA_;
  using StrideA = StrideA_;
  using ElementBPair = ElementBPair_;
  using StrideBPair = StrideBPair_;
  using ElementB = cute::tuple_element_t<0, ElementBPair>;
  using ElementScale = cute::tuple_element_t<1, ElementBPair>;
  using StrideB = cute::tuple_element_t<0, StrideBPair>;
  using LayoutScale = cute::tuple_element_t<1, StrideBPair>;
  using ElementAccumulator = float;
  using TiledMma = TiledMma_;
  using GmemTiledCopyA = GmemTiledCopyA_;
  using SmemLayoutAtomA = SmemLayoutAtomA_;
  using SmemCopyAtomA = SmemCopyAtomA_;
  using TransformA = TransformA_;
  using GmemTiledCopyB = GmemTiledCopyB_;
  using SmemLayoutAtomB = SmemLayoutAtomB_;
  using SmemCopyAtomB = SmemCopyAtomB_;
  using TransformB = TransformB_;

  static constexpr int TileM = cute::size<0>(TileShape{});
  static constexpr int TileN = cute::size<1>(TileShape{});
  static constexpr int TileK = cute::size<2>(TileShape{});
  static constexpr int ScaleGranularityK =
      layout::Nvfp4W4a16Weight::kScaleGranularityK;
  static constexpr int ScaleGroupN = layout::Nvfp4W4a16Weight::kScaleGroupN;
  static constexpr int ScaleBlocksPerTile = TileK / ScaleGranularityK;
  static constexpr int Stages = DispatchPolicy::Stages;
  static constexpr int Threads = cute::size(TiledMma{});
  static constexpr int PackedBBytesPerColumn = TileK / 2;

  static_assert(TileM == 16 || TileM == 64,
                "The tuned collective supports TileM 16 or 64");
  static_assert(TileN == 128 && TileK == 64,
                "The tuned collective requires a 128x64 N/K tile");
  static_assert(TileK % ScaleGranularityK == 0,
                "A K tile must contain complete scale blocks");
  static_assert(TileN % ScaleGroupN == 0,
                "A tile must contain complete scale groups");
  static_assert(Stages == 2,
                "The tuned collective requires two cp.async stages");
  static_assert(cute::is_same_v<ElementA, cutlass::half_t>,
                "The activation type must be FP16");
  static_assert(cute::is_same_v<ElementB, cutlass::float_e2m1_t>,
                "The weight type must be E2M1");
  static_assert(cute::is_same_v<ElementScale, cutlass::float_ue4m3_t>,
                "The scale type must be UE4M3");
  static_assert(
      cute::is_same_v<LayoutScale, layout::Nvfp4W4a16Weight::ScaleLayout>,
      "The scale layout must use the group-of-four W4A16 contract");

  using PackedPair = cutlass::Array<ElementB, 2>;

  // Ampere-compatible K=64 LDSM XOR swizzle. SM120 retains cp.async and the
  // FP16 MMA instruction used here, while the layout keeps every 128-bit A
  // vector contiguous and distributes adjacent rows across shared-memory banks.
  using SmemLayoutAtom = decltype(cute::composition(
      cute::Swizzle<3, 3, 3>{},
      cute::Layout<cute::Shape<cute::_8, cute::_64>,
                   cute::Stride<cute::_64, cute::_1>>{}));
  using SmemLayoutA = decltype(cute::tile_to_shape(
      SmemLayoutAtom{},
      cute::make_shape(cute::Int<TileM>{}, cute::Int<TileK>{})));

  static_assert(sizeof(PackedPair) == 1,
                "Two E2M1 values must occupy one byte");
  static_assert(sizeof(ElementScale) == 1,
                "A UE4M3 scale must occupy one byte");
  static_assert(sizeof(ElementA) == 2, "FP16 storage must occupy two bytes");

  struct Arguments {
    ElementA const *ptr_A = nullptr;
    StrideA dA{};
    ElementB const *ptr_B = nullptr;
    StrideB dB{};
    ElementScale const *ptr_S = nullptr;
    LayoutScale layout_S{};
  };

  struct Params {
    ElementA const *ptr_A = nullptr;
    StrideA dA{};
    uint8_t const *ptr_B = nullptr;
    StrideB dB{};
    ElementScale const *ptr_S = nullptr;
    LayoutScale layout_S{};
  };

  struct SharedStorage {
    alignas(16) ElementA a[Stages][cute::cosize_v<SmemLayoutA>];
    alignas(16) uint8_t packed_b[Stages][TileN * PackedBBytesPerColumn];
    alignas(16) ElementScale scales_b[Stages][ScaleBlocksPerTile * TileN];
  };

  template <class ProblemShape>
  CUTLASS_HOST_DEVICE static constexpr Params
  to_underlying_arguments(ProblemShape const &, Arguments const &args, void *) {
    return Params{
        args.ptr_A, args.dA,    reinterpret_cast<uint8_t const *>(args.ptr_B),
        args.dB,    args.ptr_S, args.layout_S};
  }

  template <class ProblemShape>
  CUTLASS_HOST_DEVICE static bool
  can_implement(ProblemShape const &problem_shape, Arguments const &args) {
    auto problem_shape_mnkl = cute::append<4>(problem_shape, cute::_1{});
    auto [m, n, k, l] = problem_shape_mnkl;
    if (m <= 0 || n <= 0 || k <= 0 || l != 1 ||
        m > std::numeric_limits<int>::max() ||
        n > std::numeric_limits<int>::max() ||
        k > std::numeric_limits<int>::max() || m % TileM != 0 ||
        n % TileN != 0 || k % TileK != 0 || cute::get<0>(args.dA) < k ||
        cute::get<0>(args.dA) % 8 != 0 || cute::get<0>(args.dB) < k ||
        cute::get<0>(args.dB) % 32 != 0 || cute::size<0>(args.layout_S) != n ||
        cute::size<1>(args.layout_S) != k / ScaleGranularityK ||
        cute::size<2>(args.layout_S) != l || args.ptr_A == nullptr ||
        args.ptr_B == nullptr || args.ptr_S == nullptr) {
      return false;
    }

#if !defined(__CUDA_ARCH__)
    constexpr uintptr_t alignment = 16;
    if ((reinterpret_cast<uintptr_t>(args.ptr_A) % alignment) != 0 ||
        (reinterpret_cast<uintptr_t>(args.ptr_B) % alignment) != 0 ||
        (reinterpret_cast<uintptr_t>(args.ptr_S) % alignment) != 0) {
      return false;
    }
#endif
    return true;
  }

  template <class ProblemShape>
  static constexpr size_t get_workspace_size(ProblemShape const &,
                                             Arguments const &) {
    return 0;
  }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const &, Arguments const &, void *,
                       cudaStream_t, cutlass::CudaHostAdapter * = nullptr) {
    return cutlass::Status::kSuccess;
  }

private:
  CUTLASS_DEVICE
  static void issue_async_stage(Params const &params, SharedStorage &storage,
                                int stage, int tile_k, int row_base,
                                int column_base) {
    int const thread = static_cast<int>(threadIdx.x);
    int const k_base = tile_k * TileK;
    int64_t const stride_a = cute::get<0>(params.dA);
    int64_t const stride_b_bytes = cute::get<0>(params.dB) / 2;
    SmemLayoutA layout_a;

    constexpr int a_vectors_per_row = TileK / 8;
    constexpr int a_vector_copies = TileM * a_vectors_per_row;
    for (int copy_linear = thread; copy_linear < a_vector_copies;
         copy_linear += Threads) {
      int const row = copy_linear / a_vectors_per_row;
      int const vector = copy_linear % a_vectors_per_row;
      auto const &source = *reinterpret_cast<cute::uint128_t const *>(
          params.ptr_A + static_cast<int64_t>(row_base + row) * stride_a +
          k_base + vector * 8);
      auto &destination = *reinterpret_cast<cute::uint128_t *>(
          storage.a[stage] + layout_a(row, vector * 8));
      cute::SM80_CP_ASYNC_CACHEALWAYS<cute::uint128_t>::copy(source,
                                                             destination);
    }

    constexpr int b_vectors_per_column = TileK / 32;
    constexpr int b_vector_copies = TileN * b_vectors_per_column;
    for (int copy_linear = thread; copy_linear < b_vector_copies;
         copy_linear += Threads) {
      int const column = copy_linear / b_vectors_per_column;
      int const vector = copy_linear % b_vectors_per_column;
      auto const &source = *reinterpret_cast<cute::uint128_t const *>(
          params.ptr_B +
          static_cast<int64_t>(column_base + column) * stride_b_bytes +
          k_base / 2 + vector * 16);
      auto &destination = *reinterpret_cast<cute::uint128_t *>(
          storage.packed_b[stage] + column * PackedBBytesPerColumn +
          vector * 16);
      cute::SM80_CP_ASYNC_CACHEALWAYS<cute::uint128_t>::copy(source,
                                                             destination);
    }

    // One thread owns a four-column scale group. Its four block-16 scale rows
    // for this K tile form one 16-byte transaction in Nvfp4W4a16Weight layout.
    constexpr int scale_group_copies = TileN / ScaleGroupN;
    if (thread < scale_group_copies) {
      int const global_group = column_base / ScaleGroupN + thread;
      int const global_column = global_group * ScaleGroupN;
      int64_t const scale_offset = layout::Nvfp4W4a16Weight::scale_offset(
          params.layout_S, global_column, tile_k * ScaleBlocksPerTile);
      auto const &source = *reinterpret_cast<cute::uint128_t const *>(
          params.ptr_S + scale_offset);
      auto &destination = *reinterpret_cast<cute::uint128_t *>(
          storage.scales_b[stage] + thread * ScaleBlocksPerTile * ScaleGroupN);
      cute::SM80_CP_ASYNC_CACHEALWAYS<cute::uint128_t>::copy(source,
                                                             destination);
    }

    cute::cp_async_fence();
  }

  template <class KBlock, class FragmentB, class FragmentCoordinatesB>
  CUTLASS_DEVICE static void
  decode_weight_kblock(SharedStorage &storage, int stage, KBlock k_block,
                       FragmentB &fragment_b,
                       FragmentCoordinatesB const &fragment_coordinates_b) {
    using WeightConverter = cutlass::NumericArrayConverter<
        ElementA, ElementB, 2, cutlass::FloatRoundStyle::round_to_nearest>;
    // UE4M3 uses the hardware E4M3 conversion encoding. Reinterpreting two raw
    // scale bytes through float_e4m3_t selects CUTLASS's packed FP8-to-FP16
    // converter without changing their bits.
    using ScaleInput = cutlass::Array<cutlass::float_e4m3_t, 2>;
    using ScaleConverter = cutlass::NumericArrayConverter<
        ElementA, cutlass::float_e4m3_t, 2,
        cutlass::FloatRoundStyle::round_to_nearest>;

    CUTE_UNROLL
    for (int i = 0; i < cute::size(fragment_b); i += 8) {
      auto const coordinate_low_0 = fragment_coordinates_b(i);
      auto const coordinate_high_0 = fragment_coordinates_b(i + 2);
      auto const coordinate_low_1 = fragment_coordinates_b(i + 4);
      auto const coordinate_high_1 = fragment_coordinates_b(i + 6);
      int const column_0 = cute::get<0>(coordinate_low_0);
      int const column_1 = cute::get<0>(coordinate_low_1);
      int const pair_k_low_0 =
          (int(k_block) * ScaleGranularityK + cute::get<1>(coordinate_low_0)) /
          2;
      int const pair_k_high_0 =
          (int(k_block) * ScaleGranularityK + cute::get<1>(coordinate_high_0)) /
          2;
      int const pair_k_low_1 =
          (int(k_block) * ScaleGranularityK + cute::get<1>(coordinate_low_1)) /
          2;
      int const pair_k_high_1 =
          (int(k_block) * ScaleGranularityK + cute::get<1>(coordinate_high_1)) /
          2;

      PackedPair pair_low_0;
      PackedPair pair_high_0;
      PackedPair pair_low_1;
      PackedPair pair_high_1;
      *reinterpret_cast<uint8_t *>(&pair_low_0) =
          storage
              .packed_b[stage][column_0 * PackedBBytesPerColumn + pair_k_low_0];
      *reinterpret_cast<uint8_t *>(&pair_high_0) =
          storage.packed_b[stage]
                          [column_0 * PackedBBytesPerColumn + pair_k_high_0];
      *reinterpret_cast<uint8_t *>(&pair_low_1) =
          storage
              .packed_b[stage][column_1 * PackedBBytesPerColumn + pair_k_low_1];
      *reinterpret_cast<uint8_t *>(&pair_high_1) =
          storage.packed_b[stage]
                          [column_1 * PackedBBytesPerColumn + pair_k_high_1];

      auto const converted_low_0 = WeightConverter::convert(pair_low_0);
      auto const converted_high_0 = WeightConverter::convert(pair_high_0);
      auto const converted_low_1 = WeightConverter::convert(pair_low_1);
      auto const converted_high_1 = WeightConverter::convert(pair_high_1);

      int const scale_index_0 =
          ((column_0 / ScaleGroupN) * ScaleBlocksPerTile + int(k_block)) *
              ScaleGroupN +
          column_0 % ScaleGroupN;
      int const scale_index_1 =
          ((column_1 / ScaleGroupN) * ScaleBlocksPerTile + int(k_block)) *
              ScaleGroupN +
          column_1 % ScaleGroupN;
      uint8_t const scale_bits_0 = *reinterpret_cast<uint8_t const *>(
          &storage.scales_b[stage][scale_index_0]);
      uint8_t const scale_bits_1 = *reinterpret_cast<uint8_t const *>(
          &storage.scales_b[stage][scale_index_1]);
      ScaleInput packed_scales;
      *reinterpret_cast<uint16_t *>(&packed_scales) =
          uint16_t(scale_bits_0) | (uint16_t(scale_bits_1) << 8);
      auto const converted_scale = ScaleConverter::convert(packed_scales);

      fragment_b(i) = converted_low_0[0] * converted_scale[0];
      fragment_b(i + 1) = converted_low_0[1] * converted_scale[0];
      fragment_b(i + 2) = converted_high_0[0] * converted_scale[0];
      fragment_b(i + 3) = converted_high_0[1] * converted_scale[0];
      fragment_b(i + 4) = converted_low_1[0] * converted_scale[1];
      fragment_b(i + 5) = converted_low_1[1] * converted_scale[1];
      fragment_b(i + 6) = converted_high_1[0] * converted_scale[1];
      fragment_b(i + 7) = converted_high_1[1] * converted_scale[1];
    }
  }

public:
  template <class AccumulatorFragment>
  CUTLASS_DEVICE void operator()(Params const &params, SharedStorage &storage,
                                 AccumulatorFragment &accumulators,
                                 int row_base, int column_base,
                                 int tile_count) const {
    TiledMma mma;
    auto thread_mma = mma.get_slice(threadIdx.x);
    auto tiled_copy_a = cute::make_tiled_copy_A(
        cute::Copy_Atom<cute::SM75_U32x4_LDSM_N, ElementA>{}, thread_mma);
    auto thread_copy_a = tiled_copy_a.get_thread_slice(threadIdx.x);

    // B coordinates are derived from the MMA partition itself. This keeps the
    // packed-byte decode tied to CuTe's fragment layout instead of duplicating
    // lane and warp formulas.
    auto fragment_layout_a = cute::make_tensor(
        cute::make_smem_ptr(storage.a[0]),
        cute::make_layout(cute::make_shape(cute::Int<TileM>{},
                                           cute::Int<ScaleGranularityK>{})));
    auto fragment_layout_b = cute::make_tensor(
        cute::make_smem_ptr(reinterpret_cast<ElementA *>(storage.packed_b[0])),
        cute::make_layout(cute::make_shape(cute::Int<TileN>{},
                                           cute::Int<ScaleGranularityK>{})));
    auto coordinate_b = cute::make_identity_tensor(
        cute::make_shape(cute::Int<TileN>{}, cute::Int<ScaleGranularityK>{}));
    auto fragment_coordinates_b = thread_mma.partition_B(coordinate_b);
    auto fragment_a_0 = thread_mma.partition_fragment_A(fragment_layout_a);
    auto fragment_a_1 = cute::make_fragment_like(fragment_a_0);
    auto fragment_b_0 = cute::make_fragment_like<ElementA>(
        thread_mma.partition_B(fragment_layout_b));
    auto fragment_b_1 = cute::make_fragment_like(fragment_b_0);

    issue_async_stage(params, storage, 0, 0, row_base, column_base);

    for (int tile_k = 0; tile_k < tile_count; ++tile_k) {
      int const stage = tile_k % Stages;
      cute::cp_async_wait<0>();
      __syncthreads();

      // Start the next global-to-shared transfer before decoding and consuming
      // the current tile. The alternate shared-memory stage remains in flight
      // while the four K blocks execute MMA.
      if (tile_k + 1 < tile_count) {
        issue_async_stage(params, storage, (tile_k + 1) % Stages, tile_k + 1,
                          row_base, column_base);
      }

      auto shared_a = cute::make_tensor(cute::make_smem_ptr(storage.a[stage]),
                                        SmemLayoutA{});
      auto copy_source_a = thread_copy_a.partition_S(shared_a);
      auto load_a_kblock = [&](auto k_block, auto &fragment_a) {
        auto copy_destination_a = thread_copy_a.retile_D(fragment_a);
        cute::copy(tiled_copy_a, copy_source_a(cute::_, cute::_, k_block),
                   copy_destination_a(cute::_, cute::_, cute::_0{}));
      };

      load_a_kblock(cute::_0{}, fragment_a_0);
      decode_weight_kblock(storage, stage, cute::_0{}, fragment_b_0,
                           fragment_coordinates_b);

      load_a_kblock(cute::_1{}, fragment_a_1);
      decode_weight_kblock(storage, stage, cute::_1{}, fragment_b_1,
                           fragment_coordinates_b);
      cute::gemm(mma, fragment_a_0, fragment_b_0, accumulators);

      load_a_kblock(cute::_2{}, fragment_a_0);
      decode_weight_kblock(storage, stage, cute::_2{}, fragment_b_0,
                           fragment_coordinates_b);
      cute::gemm(mma, fragment_a_1, fragment_b_1, accumulators);

      load_a_kblock(cute::_3{}, fragment_a_1);
      decode_weight_kblock(storage, stage, cute::_3{}, fragment_b_1,
                           fragment_coordinates_b);
      cute::gemm(mma, fragment_a_0, fragment_b_0, accumulators);
      cute::gemm(mma, fragment_a_1, fragment_b_1, accumulators);
    }
  }
};

namespace detail {

template <int TileM_> struct Sm120CpAsyncNvfp4W4a16Config {
  using DispatchPolicy = cutlass::gemm::MainloopSm120CpAsyncNvfp4W4A16<2>;
  using TileShape = cute::Shape<cute::Int<TileM_>, cute::_128, cute::_64>;
  using ElementA = cutlass::half_t;
  using StrideA = cutlass::detail::TagToStrideA_t<cutlass::layout::RowMajor>;
  using ElementB = cutlass::float_e2m1_t;
  using ElementScale = cutlass::float_ue4m3_t;
  using ElementBPair = cute::tuple<ElementB, ElementScale>;
  using StrideB = cutlass::detail::TagToStrideB_t<cutlass::layout::ColumnMajor>;
  using StrideBPair =
      cute::tuple<StrideB, cutlass::layout::Nvfp4W4a16Weight::ScaleLayout>;

  using TiledMma =
      cute::TiledMMA<cute::MMA_Atom<cute::SM80_16x8x16_F32F16F16F32_TN>,
                     cute::Layout<cute::Shape<cute::_1, cute::_4, cute::_1>,
                                  cute::Stride<cute::_1, cute::_1, cute::_0>>,
                     cute::Tile<cute::Int<TileM_>, cute::_128, cute::_16>>;

  using GmemTiledCopyA = decltype(cute::make_tiled_copy(
      cute::Copy_Atom<cute::SM80_CP_ASYNC_CACHEALWAYS<cute::uint128_t>,
                      ElementA>{},
      cute::Layout<cute::Shape<cute::_32, cute::_4>,
                   cute::Stride<cute::_4, cute::_1>>{},
      cute::Layout<cute::Shape<cute::_1, cute::_8>>{}));
  using SmemLayoutAtomA = decltype(cute::composition(
      cute::Swizzle<3, 3, 3>{},
      cute::Layout<cute::Shape<cute::_8, cute::_64>,
                   cute::Stride<cute::_64, cute::_1>>{}));
  using SmemCopyAtomA = cute::Copy_Atom<cute::SM75_U32x4_LDSM_N, ElementA>;

  static constexpr int AlignmentB = 32;
  using AlignmentTypeB =
      cute::uint_byte_t<cutlass::sizeof_bits<ElementB>::value * AlignmentB / 8>;
  using GmemCopyAtomB =
      cute::Copy_Atom<cute::SM80_CP_ASYNC_CACHEALWAYS<AlignmentTypeB>,
                      ElementB>;
  using GmemTiledCopyB =
      decltype(detail::make_simt_gmem_tiled_copy<GmemCopyAtomB, 128, AlignmentB,
                                                 StrideB, cute::_128,
                                                 cute::_64>());
};

} // namespace detail

template <int TileM_>
using Sm120CpAsyncNvfp4W4a16 = CollectiveMma<
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::DispatchPolicy,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::TileShape,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::ElementA,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::StrideA,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::ElementBPair,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::StrideBPair,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::TiledMma,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::GmemTiledCopyA,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::SmemLayoutAtomA,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::SmemCopyAtomA,
    cute::identity,
    typename detail::Sm120CpAsyncNvfp4W4a16Config<TileM_>::GmemTiledCopyB, void,
    void, cute::identity>;

} // namespace cutlass::gemm::collective
