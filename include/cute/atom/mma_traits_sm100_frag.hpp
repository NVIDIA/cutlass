/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <cute/config.hpp>
#include <cute/tensor_impl.hpp>
#include <cute/arch/mma_sm100_desc.hpp>         // UMMA::Major, SmemDescriptor, DescriptorIterator
#include <cute/arch/tmem_allocator_sm100.hpp>   // cute::TMEM::, make_tmem_ptr
#include <cute/numeric/numeric_types.hpp>       // sizeof_bits_v

namespace cute {

namespace UMMA {

// Import TMEM constants
namespace TMEM = cute::TMEM;

enum class TmemAllocMode {
  // Default allocation mode.
  // If a TMEM Atom uses a half-subpartition (16DPs), then multiple atoms can be
  // interleaved by using the top-half-subpartition and the bottom-half-subpartition.
  // Full utilization of TMEM capacity.
  Interleaved = 0,
  // Prevents interleaving.
  // If a TMEM Atom uses a half-subpartition (16DPs), then multiple atoms will not be
  // interleaved.
  // Required for DP-address equivalence in TMEM-A and TMEM-C allocations in UMMA_TS.
  NonInterleaved = 1,
  // Duplicates the TMEM allocation across subpartitions.
  // E.g. UMMA_2SM_128xNx16_TS uses a "2x2 DP" TMEM Layout, but the TMEM allocation is
  // actually doubled and the input data must be duplicated between the
  // subpartitions [0,1]<->[2,3], i.e., each subpartition holds all columns
  // of the A matrix needed for a single UMMA operation.
  // For UMMA_2SM_128xNx16_TS, the distribution of the data is as follows.
  // SM0:
  //    Subpart0 = A[0:32, 0:16], Subpart1 = A[32:64, 0:16],
  //    Subpart2 = A[0:32, 0:16], Subpart3 = A[32:64, 0:16]
  // SM1:
  //    Subpart0 = A[64:96, 0:16], Subpart1 = A[96:128, 0:16],
  //    Subpart2 = A[64:96, 0:16], Subpart3 = A[96:128, 0:16]
  Duplicated = 2,
  // Duplicates the TMEM allocation across subpartitions for scale factor.
  // Scale factor TMEM allocation for 4x1 data path
  ScaleFactorDuplicated4by1 = 3,
  // Scale factor TMEM allocation for 2x2 data path
  ScaleFactorDuplicated2by2 = 4
};

struct tmem_frg_base {};

// The UMMA Traits below have custom fragment type flags for their tmem tensors.
// These flags specialize a MakeTensor customization point to correctly make the fragment that is desired.
template <class ValueType, class StorageType, int N_SM, UMMA::TmemAllocMode TmemAlloc = UMMA::TmemAllocMode::Interleaved>
struct tmem_frg : tmem_frg_base
{
  static_assert(sizeof_bits_v<ValueType> <= sizeof_bits_v<StorageType>, "TMEM MMA allocations require StorageType big enough for ValueType.");

  // UMMA TMEM Allocator
  //   Each UMMA expects a specific MxN layout of TMEM for accumulators
  //   and sometimes a specific MxK layout of TMEM for A-values.
  // @tparam ValueType The value type of the TMEM Tensor to allocate.
  // @tparam StorageType The storage type of the TMEM Tensor to allocate.
  //                     "Sparse" allocations often allocate ValueType=half_t within StorageType=uint32_t.
  //                     "Dense"  allocations often allocate ValueType=half_t within StorageType=half_t.
  // @tparam N_SM The number of SMs in this UMMA_XSM instruction.
  // @tparam TmemAlloc UMMA-specific allocation modifier for special cases.
  //                   Some UMMA instructions expect strange atoms or tilings of atoms.
  // @param tmem_shape ((M_MMA_SM,N_MMA_SM),MMA_M,MMA_N,...)
  //                   The post-MMA-partitioned shape of TMEM to allocate.
  //                   Note for UMMA_2SM_128xNx16, that M_MMA_SM will be 64, for example.
  template <class TmemShape>
  CUTE_HOST_DEVICE constexpr static auto
  make(TmemShape const& tmem_shape)
  {
    CUTE_STATIC_ASSERT_V(size(tmem_shape)*Int<int(sizeof_bits_v<StorageType>)>{} <= TMEM::MAX_CAPACITY_BITS{},
                        "Requesting more TMEM than is available.");
    CUTE_STATIC_ASSERT_V(rank<0>(tmem_shape) == Int<2>{}, "Expected post-partitioned shape ((M_MMA,N_MMA),...).");
    constexpr int R     = decltype(rank(tmem_shape))::value;
    constexpr int M_MMA = decltype(size<0,0>(tmem_shape))::value;
    constexpr int N_MMA = decltype(size<0,1>(tmem_shape))::value;

    // It's convenient to use "virtual tensor memory addressing"
    //   with DP_STRIDE=1, COL_STRIDE=128 to define the tmem_atom,
    //   then convert to "logical tensor memory addressing" on return.
    using COL_ADDR = C<sizeof_bits<StorageType>::value / sizeof_bits<ValueType>::value>;
    Layout tmem_restride = Layout<Shape <               _128,   _16384>,
                                  Stride<TMEM::DP<ValueType>, COL_ADDR>>{};

    static_assert(N_SM == 1 || N_SM == 2, "UMMA expects N_SM == 1 or N_SM == 2");
    if constexpr (N_SM == 1)
    {
      static_assert(TmemAlloc == UMMA::TmemAllocMode::Interleaved || TmemAlloc == UMMA::TmemAllocMode::NonInterleaved,
                    "UMMA_1SM only accepts Interleaved or NonInterleaved");
      static_assert(M_MMA == 64 || M_MMA == 128, "UMMA_1SM M-mode size should be 64 or 128.");

      if constexpr (M_MMA == 64)
      {
        // Half subpartitions layout atom: (M,N) -> tmem_addr
        Layout tmem_atom = Layout<Shape <Shape <_16,  _4>, Int<N_MMA>>,
                                  Stride<Stride< _1, _32>,      _128>>{};
        // tile_stride = 2 causes the tiling to "skip" the first tile in DPs
        constexpr int tile_stride = TmemAlloc == UMMA::TmemAllocMode::Interleaved ? 1 : 2;
        // This will tile in DPs first, then COLs
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape),
                                                                          compact_col_major(take<1,R>(tmem_shape),Int<tile_stride>{})));
        // Restride for the DP/COL addressing and return
        return make_tensor(make_tmem_ptr<ValueType>(), composition(tmem_restride, tmem_logical_layout));
      } else
      if constexpr (M_MMA == 128)
      {
        // For M_MMA = 128, all datapaths are occupied. TmemAllocMode doesn't change the allocation.
        // Full subpartitions layout atom: (M,N) -> tmem_addr
        Layout tmem_atom = Layout<Shape <_128,Int<N_MMA>>,
                                  Stride<  _1,     _128>>{};
        // This will tile in DPs first, then COLs
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Restride for the DP/COL addressing and return
        return make_tensor(make_tmem_ptr<ValueType>(), composition(tmem_restride, tmem_logical_layout));
      }

    } else
    if constexpr (N_SM == 2)
    {
      static_assert(TmemAlloc == UMMA::TmemAllocMode::Interleaved || TmemAlloc == UMMA::TmemAllocMode::Duplicated,
                    "UMMA_2SM only accepts Interleaved or Duplicated");
      static_assert(M_MMA == 32 || M_MMA == 64 || M_MMA == 128, "UMMA_2SM M-mode size should be 32 or 64 or 128.");

      if constexpr (M_MMA == 32)
      {
        static_assert(TmemAlloc == UMMA::TmemAllocMode::Interleaved, "Only TmemAllocMode::Interleaved is supported for UMMA_2SM M_MMA=32");
        // The "1x4" layout atom: (M,N) -> tmem_addr
        Layout tmem_atom = Layout<Shape <_32,Shape <Int<N_MMA/4>, _4>>,
                                  Stride< _1,Stride<        _128,_32>>>{};
        // This will tile in DPs first, then COLs
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Restride for the DP/COL addressing and return
        return make_tensor(make_tmem_ptr<ValueType>(), composition(tmem_restride, tmem_logical_layout));
      } else
      if constexpr (M_MMA == 64 && TmemAlloc == UMMA::TmemAllocMode::Interleaved)
      {
        // The "2x2" layout atom: (M,N) -> tmem_addr
        Layout tmem_atom = Layout<Shape <_64,Shape <Int<N_MMA/2>, _2>>,
                                  Stride< _1,Stride<        _128,_64>>>{};
        // This will tile in DPs first, then COLs
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Restride for the DP/COL addressing and return
        return make_tensor(make_tmem_ptr<ValueType>(), composition(tmem_restride, tmem_logical_layout));

      } else
      if constexpr (M_MMA == 64 && TmemAlloc == UMMA::TmemAllocMode::Duplicated)
      {
        // The "2x2" duplicated layout atom: (M,N) -> tmem_addr
        Layout tmem_atom = Layout<Shape <_128,Int<N_MMA>>,
                                  Stride< _1,      _128>>{};
        // This will tile in DPs first, then COLs
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Restride for the DP/COL addressing and return
        return make_tensor(make_tmem_ptr<ValueType>(), composition(tmem_restride, tmem_logical_layout));
      } else
      if constexpr (M_MMA == 128)
      {
        // For M_MMA = 128, all datapaths are occupied. TmemAllocMode doesn't change the allocation.
        // The "4x1" layout atom: (M,N) -> tmem_addr
        Layout tmem_atom = Layout<Shape <_128,Int<N_MMA>>,
                                  Stride<  _1,     _128>>{};
        // This will tile in DPs first, then COLs
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Restride for the DP/COL addressing and return
        return make_tensor(make_tmem_ptr<ValueType>(), composition(tmem_restride, tmem_logical_layout));
      }
    }

    CUTE_GCC_UNREACHABLE;
  }
};

// Convenient aliases for common cases in the UMMA::ElementXFrg below
template <class ValueType, class StorageType = uint32_t, UMMA::TmemAllocMode TmemAlloc = UMMA::TmemAllocMode::Interleaved>
using tmem_frg_1sm = tmem_frg<ValueType, StorageType, 1, TmemAlloc>;
template <class ValueType, class StorageType = uint32_t, UMMA::TmemAllocMode TmemAlloc = UMMA::TmemAllocMode::Interleaved>
using tmem_frg_2sm = tmem_frg<ValueType, StorageType, 2, TmemAlloc>;

// Make metadata TMEM fragments for sparse MMAs.
// Also note that the TMEM fragment addresses are assumed to be COL-4 aligned -- working with arch to remove this condition
template <class ValueType>
struct tmem_e_frg : tmem_frg_base
{
  template <class TmemShape>
  CUTE_HOST_DEVICE constexpr static auto
  make(TmemShape const& tmem_shape)
  {
    CUTE_STATIC_ASSERT_V(rank<0>(tmem_shape) == Int<2>{}, "Expected post-partitioned shape ((M_MMA,N_MMA),...).");
    constexpr int R     = decltype(rank(tmem_shape))::value;
    constexpr int M_MMA = decltype(size<0,0>(tmem_shape))::value;
    constexpr int N_MMA = decltype(size<0,1>(tmem_shape))::value;

    static_assert(M_MMA == 128, "Only 128 implemented right now.");

    // It's convenient to use "virtual tensor memory addressing"
    //   with DP_STRIDE=1, COL_STRIDE=128 to define the tmem_atom,
    //   then convert to "logical tensor memory addressing" on return.
    [[maybe_unused]] Layout tmem_restride = Layout<Shape <      _128, _16384>,
                                                   Stride<TMEM::DP_b,     _1>>{};

    if constexpr (sizeof_bits<ValueType>::value == 32)     // TF32: 128x16 atom
    {
      static_assert(N_MMA == 16);
      Layout tmem_atom = Layout<Shape <Shape <_8,   _2, _8>, Shape <  _8,_2>>,
                                Stride<Stride<_1,_1024,_16>, Stride<_128,_8>>>{};
      // Tile to MMA tiling
      Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
      // Address transformations with upcast<2> for 2-bit base types
      Layout tmem_layout = composition(upcast<2>(tmem_restride), tmem_logical_layout);
      // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
      return make_tensor(make_tmem_ptr<sparse_elem<4,uint8_t>>(), tmem_layout);
    } else
    if constexpr (sizeof_bits<ValueType>::value == 16)     // FP16: 128x32 atom
    {
      static_assert(N_MMA == 32);
      Layout tmem_atom = Layout<Shape <Shape <_8,   _2, _8>, Shape < _16,_2>>,
                                Stride<Stride<_1,_2048,_16>, Stride<_128,_8>>>{};
      // Tile to MMA tiling
      Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
      // Address transformations
      Layout tmem_layout = composition(tmem_restride, tmem_logical_layout);
      // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
      return make_tensor(make_tmem_ptr<sparse_elem<8,uint8_t>>(), tmem_layout);
    } else
    if constexpr (sizeof_bits<ValueType>::value ==  8)     // S8|Mix.F4/F6/F8: 128x64 atom
    {
      // For Mix 8bit f4/f6/f8, will pass in ValueType = uint8_t
      static_assert(N_MMA == 64);
      Layout tmem_atom = Layout<Shape <_128, _64>,
                                Stride<  _1,_128>>{};
      // Tile to MMA tiling
      Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
      // Address transformations
      Layout tmem_layout = composition(tmem_restride, tmem_logical_layout);
      // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
      return make_tensor(make_tmem_ptr<sparse_elem<8,uint8_t>>(), tmem_layout);
    }
    if constexpr (sizeof_bits<ValueType>::value ==  4)     // F4: 128x128 atom
    {
      // For F4, will pass in ValueType = fp4
      Layout tmem_restride1 = Layout<Shape <                     _128, Int<32768>>,
                                     Stride<cute::C<int32_t(1) << 22>,         _1>>{};
      // F4 has roughly same TMEM layout as Mix8bit.F4/F6/F8, the only difference is that K is multiplied by two
      static_assert(N_MMA == 128);
      Layout tmem_atom = Layout<Shape <_128, _128>,
                                Stride<  _1, _128>>{};
      // Tile to MMA tiling
      Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
      // Address transformations
      Layout tmem_layout = composition(tmem_restride1, tmem_logical_layout);
      // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
      return make_tensor(make_tmem_ptr<sparse_elem<16,uint8_t>>(), tmem_layout);
    }

    CUTE_GCC_UNREACHABLE;
  }
};

template <class ValueType>
struct tmem_e_frg_ws : tmem_frg_base
{
  template <class TmemShape>
  CUTE_HOST_DEVICE constexpr static auto
  make(TmemShape const& tmem_shape)
  {
    CUTE_STATIC_ASSERT_V(rank<0>(tmem_shape) == Int<2>{}, "Expected post-partitioned shape ((M_MMA,N_MMA),...).");
    constexpr int R     = decltype(rank(tmem_shape))::value;
    constexpr int M_MMA = decltype(size<0,0>(tmem_shape))::value;
    constexpr int N_MMA = decltype(size<0,1>(tmem_shape))::value;

    static_assert(M_MMA == 128 || M_MMA == 64 || M_MMA == 32, "Weight stationary UMMA_1SM M-mode size should be 32 or 64 or 128.");

    // It's convenient to use "virtual tensor memory addressing"
    //   with DP_STRIDE=1, COL_STRIDE=128 to define the tmem_atom,
    //   then convert to "logical tensor memory addressing" on return.
    Layout tmem_restride = Layout<Shape <      _128, _16384>,
                                  Stride<TMEM::DP_b,     _1>>{};

    if constexpr (sizeof_bits<ValueType>::value == 32)     // TF32
    {
      // MMA_M x MMA_K: 128x16 atom / 64x16 atom / 32x16 atom
      static_assert(N_MMA == 16);
      if constexpr (M_MMA == 128) {
        Layout tmem_atom = Layout<Shape <Shape <_8,   _2, _8>, Shape <  _8,_2>>,
                                  Stride<Stride<_1,_1024,_16>, Stride<_128,_8>>>{};
        // Tile to MMA tiling
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Address transformations with upcast<2> for 2-bit base types
        Layout tmem_layout = composition(upcast<2>(tmem_restride), tmem_logical_layout);
        // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
        return make_tensor(make_tmem_ptr<sparse_elem<4,uint8_t>>(), tmem_layout);
      }
      else if constexpr (M_MMA == 64) {
        Layout tmem_atom = Layout<Shape <Shape <_8,   _2, _4>, Shape <  _8,_2>, _2>,
                                  Stride<Stride<_1,_1024,_16>, Stride<_128,_8>,_64>>{};
        // Tile to MMA tiling
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Address transformations with upcast<2> for 2-bit base types
        Layout tmem_layout = composition(upcast<2>(tmem_restride), tmem_logical_layout);
        // Sparsity wrap, no sparse_ptr because tmem_ptr handles its own subword addressing
        return make_tensor(make_tmem_ptr<sparse_elem<4,uint8_t>>(), tmem_layout);
      }
      else if constexpr (M_MMA == 32) {
        Layout tmem_atom = Layout<Shape <Shape <_8,   _2, _2>, Shape <  _8,_2>, _4>,
                                  Stride<Stride<_1,_1024,_16>, Stride<_128,_8>,_32>>{};
        // Tile to MMA tiling
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Address transformations with upcast<2> for 2-bit base types
        Layout tmem_layout = composition(upcast<2>(tmem_restride), tmem_logical_layout);
        // Sparsity wrap, no sparse_ptr because tmem_ptr handles its own subword addressing
        return make_tensor(make_tmem_ptr<sparse_elem<4,uint8_t>>(), tmem_layout);
      }
      else {
        static_assert(dependent_false<TmemShape>, "Invalid M_MMA value");
      }
    }
    else if constexpr (sizeof_bits<ValueType>::value == 16)     // FP16
    {
      // MMA_M x MMA_K: 128x32 atom / 64x32 atom / 32x32 atom
      static_assert(N_MMA == 32);
      if constexpr (M_MMA == 128) {
        Layout tmem_atom = Layout<Shape <Shape <_8,   _2, _8>, Shape < _16,_2>>,
                                  Stride<Stride<_1,_2048,_16>, Stride<_128,_8>>>{};
        // Tile to MMA tiling
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Address transformations
        Layout tmem_layout = composition(tmem_restride, tmem_logical_layout);
        // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
        return make_tensor(make_tmem_ptr<sparse_elem<8,uint8_t>>(), tmem_layout);
      }
      else if constexpr (M_MMA == 64) {
        Layout tmem_atom = Layout<Shape <Shape <_8,   _2, _4>, Shape < _16,_2>, _2>,
                                  Stride<Stride<_1,_2048,_16>, Stride<_128,_8>,_64>>{};
        // Tile to MMA tiling
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Address transformations
        Layout tmem_layout = composition(tmem_restride, tmem_logical_layout);
        // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
        return make_tensor(make_tmem_ptr<sparse_elem<8,uint8_t>>(), tmem_layout);
      }
      else if constexpr (M_MMA == 32) {
        Layout tmem_atom = Layout<Shape <Shape <_8,   _2, _2>, Shape < _16,_2>, _4>,
                                  Stride<Stride<_1,_2048,_16>, Stride<_128,_8>,_32>>{};
        // Tile to MMA tiling
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Address transformations
        Layout tmem_layout = composition(tmem_restride, tmem_logical_layout);
        // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
        return make_tensor(make_tmem_ptr<sparse_elem<8,uint8_t>>(), tmem_layout);
      }
      else {
        static_assert(dependent_false<TmemShape>, "Invalid M_MMA value");
      }
    }
    else if constexpr (sizeof_bits<ValueType>::value ==  8)     // I8|F8
    {
      // MMA_M x MMA_K: 128x64 atom / 64x64 atom / 32x64 atom
      static_assert(N_MMA == 64);
      if constexpr (M_MMA == 128) {
        Layout tmem_atom = Layout<Shape <_128, _64>,
                                  Stride<  _1,_128>>{};
        // Tile to MMA tiling
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Address transformations
        Layout tmem_layout = composition(tmem_restride, tmem_logical_layout);
        // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
        return make_tensor(make_tmem_ptr<sparse_elem<8,uint8_t>>(), tmem_layout);
      }
      else if constexpr (M_MMA == 64) {
        Layout tmem_atom = Layout<Shape <_64, Shape < _64,  _2>>,
                                  Stride< _1, Stride<_128, _64>>>{};
        // Tile to MMA tiling
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Address transformations
        Layout tmem_layout = composition(tmem_restride, tmem_logical_layout);
        // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
        return make_tensor(make_tmem_ptr<sparse_elem<8,uint8_t>>(), tmem_layout);
      }
      else if constexpr (M_MMA == 32) {
        Layout tmem_atom = Layout<Shape <_32, Shape < _64,  _4>>,
                                  Stride< _1, Stride<_128, _32>>>{};
        // Tile to MMA tiling
        Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
        // Address transformations
        Layout tmem_layout = composition(tmem_restride, tmem_logical_layout);
        // Sparsity wrap, no sparse_ptr because tmem_ptr handles it's own subword addressing
        return make_tensor(make_tmem_ptr<sparse_elem<8,uint8_t>>(), tmem_layout);
      }
      else {
        static_assert(dependent_false<TmemShape>, "Invalid M_MMA value");
      }
    }
    else {
      static_assert(dependent_false<TmemShape>, "Invalid ValueType");
    }

    CUTE_GCC_UNREACHABLE;
  }
};

template <class ValueType, int SFVecSize, int N_SM, bool Is_SFA,
    UMMA::TmemAllocMode TmemAlloc = UMMA::TmemAllocMode::ScaleFactorDuplicated4by1>
struct tmem_sf_frg: tmem_frg_base
{
  // UMMA TMEM Allocator for Scale Factor A for Mxf4Nvf4 and Mxf8f6f4 instructions
  //  We expect a tensor that has the same layout as A matrix
  //  @tparam ValueType: data type of scaling factor
  //    Note that the StorageType is the same as ValueType, i.e., we always use a compact allocation
  //  @tparam SFVecSize: The number of values that is scaled by a single scaling factor.
  //    Valid values are (16, 32)
  //  @tparam N_SM: Number of SMs in UMMA instruction
  //  @param tmem_shape: An MMA partitioned shape where first mode encodes, A layout of the MMA instruction.
  //    Note that the shape doesn't match the actual allocation. size<0,1>(tmem_shape) will give us the number of
  //    elements in K-mode of MMA rather than the number of scaling factors.
  template <class TmemShape>
  CUTE_HOST_DEVICE constexpr static auto
  make(TmemShape const& tmem_shape)
  {
    CUTE_STATIC_ASSERT_V(rank<0>(tmem_shape) == Int<2>{}, "Expected post-partitioned shape ((M_MMA,N_MMA),...).");
    constexpr int MMA_MN  = decltype(size<0,0>(tmem_shape))::value;
    constexpr int MMA_VS  = decltype(size<0,1,0>(tmem_shape))::value;
    constexpr int MMA_NSF = decltype(size<0,1,1>(tmem_shape))::value;
    constexpr int R_MMA_K = decltype(rank(get<0,1>(tmem_shape)))::value;
    constexpr int R = decltype(rank(tmem_shape))::value;

    // We expect an MMA-SF partitioned tensor
    // ((MMA_MN, (VecSize, NSF)), num_MMA_MN, num_MMA_K, ...)
    //   where VecSize*NSF = MMA_K
    static_assert(R >= 3,       "Expected an MMA partitioned tensor");                            // ((MMA), num_MMA_MN, num_MMA_K, ...)
    static_assert(R_MMA_K == 2, "Expected an MMA-SF partitioned tensor");                         // (VecSize, NSF)
    using REP = _4;               // Replication factor. Data is always replicated across subpartitions
    constexpr int SUBPART_DPs = 32;      // Number of DPs in a subpartition

    using COL_ADDR = C<sizeof_bits<ValueType>::value / sizeof_bits<ValueType>::value>;
    Layout tmem_restride = Layout<Shape <               _128,   _16384>,
                                  Stride<TMEM::DP<ValueType>, COL_ADDR>>{};

    if constexpr (Is_SFA || (!Is_SFA && TmemAlloc == UMMA::TmemAllocMode::ScaleFactorDuplicated4by1)) {
      // SFA, 2x2 and 4x1 data path
      // SFB,         4x1 data path
      auto tmem_atom = Layout < Shape< Shape< Shape<Int<SUBPART_DPs>, Int<MMA_MN/SUBPART_DPs>>, REP>,  Shape<Int<MMA_VS>, Int<MMA_NSF>>>,
                              Stride<Stride<Stride<              _1,                    _512>, _32>, Stride<         _0,         _128>>>{};

      Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
      auto final_tmem_layout = composition(tmem_restride, tmem_logical_layout);
      return make_tensor(make_tmem_ptr<ValueType>(), final_tmem_layout);
    }
    else {
      // SFB, 2x2 datapath
      static_assert(!Is_SFA and TmemAlloc == UMMA::TmemAllocMode::ScaleFactorDuplicated2by2);
      static_assert(N_SM == 2, "Should be 2x2 Datapath");
      // 2x2 Datapth
      auto tmem_atom = Layout < Shape< Shape< Shape<Int<SUBPART_DPs>, Int<MMA_MN/2/SUBPART_DPs>>,     _2,  _2>,  Shape<Int<MMA_VS>, Int<MMA_NSF>>>,
                                Stride<Stride<Stride<    _1         ,                      _512>,    _64, _32>, Stride<         _0,        _128>>>{};

      Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
      auto final_tmem_layout = composition(tmem_restride, tmem_logical_layout);
      return make_tensor(make_tmem_ptr<ValueType>(), final_tmem_layout);
    }
  }
};

// Make C/D Tmem fragment for weight-stationary MMAs
template <class ValueType, class StorageType, int N_SM>
struct tmem_frg_ws : tmem_frg_base
{
  static_assert(sizeof_bits_v<ValueType> <= sizeof_bits_v<StorageType>, "TMEM MMA allocations require StorageType big enough for ValueType.");

  // UMMA TMEM Allocator
  //   Each UMMA expects a specific MxN layout of TMEM for accumulators
  //   and sometimes a specific MxK layout of TMEM for A-values.
  // @tparam ValueType The value type of the TMEM Tensor to allocate.
  // @tparam StorageType The storage type of the TMEM Tensor to allocate.
  //                     "Sparse" allocations often allocate ValueType=half_t within StorageType=uint32_t.
  //                     "Dense"  allocations often allocate ValueType=half_t within StorageType=half_t.
  // @tparam N_SM The number of SMs in this UMMA_XSM instruction.
  // @tparam TmemAlloc UMMA-specific allocation modifier for special cases.
  //                   Some UMMA instructions expect strange atoms or tilings of atoms.
  // @param tmem_shape ((M_MMA_SM,N_MMA_SM),MMA_M,MMA_N,...)
  //                   The post-MMA-partitioned shape of TMEM to allocate.
  //                   Note for UMMA_2SM_128xNx16, that M_MMA_SM will be 64, for example.
  template <class TmemShape>
  CUTE_HOST_DEVICE constexpr static auto
  make(TmemShape const& tmem_shape)
  {
    CUTE_STATIC_ASSERT_V(size(tmem_shape)*Int<int(sizeof_bits_v<StorageType>)>{} <= TMEM::MAX_CAPACITY_BITS{},
                        "Requesting more TMEM than is available.");
    CUTE_STATIC_ASSERT_V(rank<0>(tmem_shape) == Int<2>{}, "Expected post-partitioned shape ((M_MMA,N_MMA),...).");
    constexpr int R     = decltype(rank(tmem_shape))::value;
    constexpr int M_MMA = decltype(size<0,0>(tmem_shape))::value;
    constexpr int N_MMA = decltype(size<0,1>(tmem_shape))::value;

    // It's convenient to use "virtual tensor memory addressing"
    //   with DP_STRIDE=1, COL_STRIDE=128 to define the tmem_atom,
    //   then convert to "logical tensor memory addressing" on return.
    using COL_ADDR = C<sizeof_bits<StorageType>::value / sizeof_bits<ValueType>::value>;
    Layout tmem_restride = Layout<Shape <               _128,   _16384>,
                                  Stride<TMEM::DP<ValueType>, COL_ADDR>>{};

    static_assert(N_SM == 1, "UMMA.WS expects N_SM == 1");

    static_assert(M_MMA == 32 || M_MMA == 64 || M_MMA == 128,
                  "Weight stationary UMMA_1SM M-mode size should be 32 or 64 or 128.");
    static_assert(N_MMA == 64 || N_MMA == 128 || N_MMA == 256,
                  "Dense weight stationary UMMA_1SM N-mode size should be 64 or 128 or 256.");
    // Weight Stationary MMA config
    if constexpr (M_MMA == 32)
    {
      // 1x4 datapath
      Layout tmem_atom = Layout<Shape <_32, Shape<Int<N_MMA/4>, _4>>,
                                Stride< _1, Stride<       _128,_32>>
                              >{};
      constexpr int tile_stride = 1;
      // This will tile in DPs first, then COLs
      Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape),
                                                                        compact_col_major(take<1,R>(tmem_shape), Int<tile_stride>{})));
      // Restride for the DP/COL addressing and return
      return make_tensor(make_tmem_ptr<ValueType>(), composition(tmem_restride, tmem_logical_layout));
    } else
    if constexpr (M_MMA == 64)
    {
      // 2x2 datapath
      Layout tmem_atom = Layout<Shape <_64, Shape<Int<N_MMA/2>, _2>>,
                                Stride< _1, Stride<       _128,_64>>
                              >{};
      constexpr int tile_stride = 1;
      // This will tile in DPs first, then COLs
      Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape),
                                                                        compact_col_major(take<1,R>(tmem_shape), Int<tile_stride>{})));
      // Restride for the DP/COL addressing and return
      return make_tensor(make_tmem_ptr<ValueType>(), composition(tmem_restride, tmem_logical_layout));
    } else
    if constexpr (M_MMA == 128)
    {
      // For M_MMA = 128, all datapaths are occupied. TmemAllocMode doesn't change the allocation.
      // Full subpartitions layout atom: (M,N) -> tmem_addr
      Layout tmem_atom = Layout<Shape <_128,Int<N_MMA>>,
                                Stride<  _1,     _128>>{};
      // This will tile in DPs first, then COLs
      Layout tmem_logical_layout = tiled_product(tmem_atom, make_layout(take<1,R>(tmem_shape)));
      // Restride for the DP/COL addressing and return
      return make_tensor(make_tmem_ptr<ValueType>(), composition(tmem_restride, tmem_logical_layout));
    }

    CUTE_GCC_UNREACHABLE;
  }
};

// Convenient aliases for common cases in the UMMA::ElementXFrg below
template <class ValueType, class StorageType = uint32_t>
using tmem_frg_ws_1sm = tmem_frg_ws<ValueType, StorageType, 1>;

} // end namespace UMMA

// Customization point for creating a UMMA::tmem_frg Tensor
template <class ValueType, class StorageType, int N_SM, UMMA::TmemAllocMode TmemAlloc>
struct MakeTensor<UMMA::tmem_frg<ValueType, StorageType, N_SM, TmemAlloc>>
{
  template <class Shape>
  CUTE_HOST_DEVICE constexpr auto
  operator()(Shape const& tmem_shape) {
    return UMMA::tmem_frg<ValueType, StorageType, N_SM, TmemAlloc>::make(shape(tmem_shape));
  }
};

template <class ValueType, class StorageType, int N_SM>
struct MakeTensor<UMMA::tmem_frg_ws<ValueType, StorageType, N_SM>>
{
  template <class Shape>
  CUTE_HOST_DEVICE constexpr auto
  operator()(Shape const& tmem_shape) {
    return UMMA::tmem_frg_ws<ValueType, StorageType, N_SM>::make(shape(tmem_shape));
  }
};

// Customization point for creating a UMMA::tmem_e_frg Tensor
template <class ValueType>
struct MakeTensor<UMMA::tmem_e_frg<ValueType>>
{
  template <class Shape>
  CUTE_HOST_DEVICE constexpr auto
  operator()(Shape const& tmem_shape) {
    return UMMA::tmem_e_frg<ValueType>::make(shape(tmem_shape));
  }
};

template <class ValueType>
struct MakeTensor<UMMA::tmem_e_frg_ws<ValueType>>
{
  template <class Shape>
  CUTE_HOST_DEVICE constexpr auto
  operator()(Shape const& tmem_shape) {
    return UMMA::tmem_e_frg_ws<ValueType>::make(shape(tmem_shape));
  }
};

template <class ValueType, int SFVecSize, int N_SM, bool Is_SFA, UMMA::TmemAllocMode TmemAlloc>
struct MakeTensor<UMMA::tmem_sf_frg<ValueType, SFVecSize, N_SM, Is_SFA, TmemAlloc>>
{
  template <class Shape>
  CUTE_HOST_DEVICE constexpr auto
  operator()(Shape const& tmem_shape) {
    return UMMA::tmem_sf_frg<ValueType, SFVecSize, N_SM, Is_SFA, TmemAlloc>::make(shape(tmem_shape));
  }
};

} // namespace cute
