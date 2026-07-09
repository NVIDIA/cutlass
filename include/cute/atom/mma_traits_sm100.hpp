/***************************************************************************************************
 * Copyright (c) 2022 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include <cute/pointer_sparse.hpp>
#include <cute/tensor_impl.hpp>
#include <cute/arch/mma_sm100.hpp>
#include <cute/arch/mma_sm100_desc.hpp>
#include <cute/arch/mma_sm100_umma.hpp>
#include <cute/arch/tmem_allocator_sm100.hpp>         // cute::TMEM::

#include <cute/atom/mma_traits.hpp>
#include <cute/atom/mma_traits_sm90_gmma.hpp>         // cute::GMMA::
#include <cute/atom/mma_traits_sm90_gmma_sparse.hpp>  // cute::GMMA::
#include <cute/atom/copy_traits_sm100.hpp>            // UTCCP smem desc

#include <cute/numeric/numeric_types.hpp>
#include <cute/atom/mma_traits_sm100_frag.hpp>  // UMMA::TmemAllocMode, tmem_frg, tmem_e_frg, tmem_sf_frg, tmem_frg_ws

// Check that aggregate initialization in .with() initializes all fields
#if defined(__GNUG__)
#pragma GCC diagnostic warning "-Wmissing-field-initializers"
#pragma GCC diagnostic error "-Wmissing-field-initializers"
#endif

namespace cute {

namespace UMMA {

//////////////////////////////////////////////////
// Common layouts for UMMA Shared Memory //
//////////////////////////////////////////////////

using cute::GMMA::Layout_MN_INTER_Atom;
using cute::GMMA::Layout_MN_SW32_Atom;
using cute::GMMA::Layout_MN_SW64_Atom;
using cute::GMMA::Layout_MN_SW128_Atom;
using cute::GMMA::Layout_K_INTER_Atom;
using cute::GMMA::Layout_K_SW32_Atom;
using cute::GMMA::Layout_K_SW64_Atom;
using cute::GMMA::Layout_K_SW128_Atom;

using Layout_MN_SW128_32B_Atom_Bits = ComposedLayout<Swizzle<2,5,2>, smem_ptr_flag, Layout<Shape< _1024,_4>,Stride<_1, _1024>>>;

template <class Type>
using Layout_MN_SW128_32B_Atom = decltype(upcast<sizeof_bits<Type>::value>(Layout_MN_SW128_32B_Atom_Bits{}));

//////////////////////////////////////////////////
// Common layouts for Sparse UMMA Shared Memory //
//////////////////////////////////////////////////

using cute::GMMA::Layout_MN_INTER_SpAtom;
using cute::GMMA::Layout_MN_SW32_SpAtom;
using cute::GMMA::Layout_MN_SW64_SpAtom;
using cute::GMMA::Layout_MN_SW128_SpAtom;
using cute::GMMA::Layout_K_INTER_SpAtom;
using cute::GMMA::Layout_K_SW32_SpAtom;
using cute::GMMA::Layout_K_SW64_SpAtom;
using cute::GMMA::Layout_K_SW128_SpAtom;

template <class Type, int S>
using Layout_MN_SW128_32B_SpAtom = ComposedLayout<Swizzle<2,5,2>, smem_sparse_ptr_flag_bits<S,sizeof_bits_v<Type>>,
                                                  decltype(blocked_product(Layout<Shape<_1,Int<S>>>{}, Layout_MN_SW128_32B_Atom<Type>{}.layout_b()))>;

// With UMMA::Major param
template <class Type, int S, UMMA::Major tnsp>
using Layout_INTER_SpAtom = typename conditional<tnsp == UMMA::Major::MN,
                                                 Layout_MN_INTER_SpAtom<Type,S>,
                                                 Layout_K_INTER_SpAtom<Type,S>>::type;
template <class Type, int S, UMMA::Major tnsp>
using Layout_SW32_SpAtom = typename conditional<tnsp == UMMA::Major::MN,
                                                Layout_MN_SW32_SpAtom<Type,S>,
                                                Layout_K_SW32_SpAtom<Type,S>>::type;
template <class Type, int S, UMMA::Major tnsp>
using Layout_SW64_SpAtom = typename conditional<tnsp == UMMA::Major::MN,
                                                Layout_MN_SW64_SpAtom<Type,S>,
                                                Layout_K_SW64_SpAtom<Type,S>>::type;
template <class Type, int S, UMMA::Major tnsp>
using Layout_SW128_SpAtom = typename conditional<tnsp == UMMA::Major::MN,
                                                 Layout_MN_SW128_SpAtom<Type,S>,
                                                 Layout_K_SW128_SpAtom<Type,S>>::type;

// Tile a MN-logical layout atom to an MMA Tile Shape ((MMA_M,MMA_N),M_MMAs,N_MMAs,...)
template <class LayoutAtom, class MMATileShape, class ModeOrder = GenColMajor>
CUTE_HOST_DEVICE constexpr
auto
tile_to_mma_shape(LayoutAtom const& atom, MMATileShape const& mma_tile_shape, ModeOrder const& order = {})
{
  constexpr int R = decltype(rank(mma_tile_shape))::value;
  auto mn_shape = cute::tuple_cat(zip(shape<0>(mma_tile_shape), take<1,3>(mma_tile_shape)), take<3,R>(mma_tile_shape));
  auto mn_tiled = tile_to_shape(atom, mn_shape, order);                      // (BLK_M,BLK_N,...)
  return tiled_divide(mn_tiled, product_each(shape<0>(mma_tile_shape)));     // ((MMA_M,MMA_N),M_MMAs,N_MMAs,...)
}

} // end namespace UMMA

// Special smem_desc_iter tensor entry for UTCCP copy.
template <class UtccpOp, class TEngine, class TLayout>
constexpr auto get_utccp_smem_desc_tensor(Tensor<TEngine, TLayout> const& smem_utccp_partitioned_tensor) {
  using VecLayout = decltype(layout<0>(TLayout{}));
  static_assert(VecLayout::rank == 2 && shape<1>(VecLayout{}) == 1, "Mismatched vec_mode tensor.");
  static_assert(is_smem<TEngine>::value, "Expect vec_mode smem_tesnor.");
  static_assert(is_static<VecLayout>::value, "Utccp copy tensor's vec_mode should be static.");

  using value_type = typename TEngine::value_type;
  using UtccpTaits = Copy_Traits<UtccpOp>;

  // UtccpTaits::ValID: logical_bit_idx -> tmem_offset.
  // We arrange the logical_bit_idx in order of (core_matrix_strided, core_matrix_leading, repeat(only in 64dplw01), broadcast).
  // So we only need the first two modes for src smem_tensor.
  auto utccp_core_matrix_shape = take<0,2>(upcast<sizeof_bits_v<value_type>>(typename UtccpTaits::ValID{}).shape());
  // logical_bit_idx -> smem_addr
  Layout vec_v_layout = flatten(layout<0>(VecLayout{}));
  Layout utccp_core_matrix_layout = vec_v_layout.with_shape(utccp_core_matrix_shape);
  Tensor utccp_core_matrix_tensor = group_modes<0,2>(make_tensor(smem_utccp_partitioned_tensor.data(), utccp_core_matrix_layout));
  Tensor core_matrix_desc_tensor = make_tensor<UMMA::smem_desc<UMMA::Major::K>>(utccp_core_matrix_tensor);
  return make_tensor(core_matrix_desc_tensor.data(), recast_layout<value_type, uint128_t>(smem_utccp_partitioned_tensor.layout()));
}

///////////////////////////////////////////////////////////////////////////////
//////////////////////////// MMA_TRAITS ///////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_TF32_SS<a_type, b_type, c_type,
                                M, N, a_major, b_major,
                                a_neg, b_neg>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 32, "SM100_MMA_TF32_SS supports 32bit types");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  // Logical shape-K is always 256bits, transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_TF32_SS<a_type, b_type, c_type,
                   M, N, a_major, b_major,
                   a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_F16BF16_SS<a_type, b_type, c_type,
                                M, N, a_major, b_major,
                                a_neg, b_neg>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;

  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_SS supports 16bit types");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  // Logical shape-K is always 256bits, transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_SS<a_type, b_type, c_type,
                  M, N, a_major, b_major,
                  a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_TF32_TS<a_type, b_type, c_type,
                                M, N,
                                a_major, b_major,
                                a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 32, "SM100_MMA_TF32_TS supports 32bit types");

  using FrgTypeA = UMMA::tmem_frg_1sm<a_type, a_type, UMMA::TmemAllocMode::NonInterleaved>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type, int32_t, UMMA::TmemAllocMode::NonInterleaved>;

  // Logical shape-K is always 256 bits; transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint32_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_TF32_TS<a_type, b_type, c_type,
                   M, N,
                   a_major, b_major,
                   a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_F16BF16_TS<a_type, b_type, c_type,
                                M, N,
                                a_major, b_major,
                                a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_TS supports 16bit types");

  using FrgTypeA = UMMA::tmem_frg_1sm<a_type, a_type, UMMA::TmemAllocMode::NonInterleaved>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type, int32_t, UMMA::TmemAllocMode::NonInterleaved>;

  // Logical shape-K is always 256 bits; transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint32_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_TS<a_type, b_type, c_type,
                  M, N,
                  a_major, b_major,
                  a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_F16BF16_SS_SCALED<a_type, b_type, c_type,
                                M, N, a_major, b_major,
                                ScaleC, a_neg, b_neg>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_SS_SCALED supports 16bit types");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  // Logical shape-K is always 256bits, transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  static constexpr uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_SS_SCALED<a_type, b_type, c_type,
                         M, N, a_major, b_major,
                         ScaleC, a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);

  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_SS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  NewScaleC, a_neg, b_neg>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_SS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  ScaleC, new_a_neg, b_neg>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, new_a_neg, b_neg>()};
  }
};

// Special instantiation for interleaved complex (emulated)
template <class ab_vtype, int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_F16BF16_SS_SCALED<cutlass::complex<ab_vtype>, cutlass::complex<ab_vtype>, float,
                                M, N, a_major, b_major,
                                ScaleC, a_neg, b_neg>>
{
  static_assert(cute::sizeof_bits_v<ab_vtype> == 16, "Only supports 16bit base types");
  using a_type = complex<ab_vtype>;
  using b_type = complex<ab_vtype>;
  using c_type = float;

  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  // Logical shape-K is always 256bits, transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  static constexpr uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    ab_vtype, ab_vtype, float, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_SS_SCALED<a_type, b_type, c_type,
                         M, N, a_major, b_major,
                         ScaleC, a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);

  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_SS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  NewScaleC, a_neg, b_neg>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_SS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  ScaleC, new_a_neg, b_neg>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<ab_vtype, ab_vtype, float, M, N, a_major, b_major, new_a_neg, b_neg>()};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg, UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_TF32_TS_SCALED<a_type, b_type, c_type,
                                M, N, a_major, b_major,
                                ScaleC, a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 32, "SM100_MMA_TF32_TS_SCALED supports 32bit types");

  using FrgTypeA = UMMA::tmem_frg_1sm<a_type, a_type, UMMA::TmemAllocMode::NonInterleaved>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type, int32_t, UMMA::TmemAllocMode::NonInterleaved>;

  // Logical shape-K is always 256 bits; transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  static constexpr uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint32_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_TF32_TS_SCALED<a_type, b_type, c_type,
                          M, N, a_major, b_major,
                          ScaleC, a_neg, b_neg>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_TF32_TS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  NewScaleC, a_neg, b_neg, c_sat>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_TF32_TS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  ScaleC, new_a_neg, b_neg, c_sat>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, new_a_neg, b_neg, c_sat>()};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg, UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_F16BF16_TS_SCALED<a_type, b_type, c_type,
                                M, N, a_major, b_major,
                                ScaleC, a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_TS_SCALED supports 16bit types");

  using FrgTypeA = UMMA::tmem_frg_1sm<a_type, a_type, UMMA::TmemAllocMode::NonInterleaved>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type, int32_t, UMMA::TmemAllocMode::NonInterleaved>;

  // Logical shape-K is always 256 bits; transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  static constexpr uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint32_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_TS_SCALED<a_type, b_type, c_type,
                         M, N, a_major, b_major,
                         ScaleC, a_neg, b_neg>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_TS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  NewScaleC, a_neg, b_neg, c_sat>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_TS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  ScaleC, new_a_neg, b_neg, c_sat>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, new_a_neg, b_neg, c_sat>()};
  }
};

// Special instantiation for interleaved complex (emulated)
template <class ab_vtype, int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg, UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_F16BF16_TS_SCALED<cutlass::complex<ab_vtype>, cutlass::complex<ab_vtype>, float,
                                M, N, a_major, b_major,
                                ScaleC, a_neg, b_neg, c_sat>>
{
  static_assert(cute::sizeof_bits_v<ab_vtype> == 16, "Only supports 16bit base types");
  using a_type = complex<ab_vtype>;
  using b_type = complex<ab_vtype>;
  using c_type = float;

  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;

  using FrgTypeA = UMMA::tmem_frg_1sm<a_type, a_type, UMMA::TmemAllocMode::NonInterleaved>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type, int32_t, UMMA::TmemAllocMode::NonInterleaved>;

  // Logical shape-K is always 256 bits; transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  static constexpr uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    ab_vtype, ab_vtype, float, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint32_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_TS_SCALED<a_type, b_type, c_type,
                         M, N, a_major, b_major,
                         ScaleC, a_neg, b_neg>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_TS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  NewScaleC, a_neg, b_neg, c_sat>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_TS_SCALED<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  ScaleC, new_a_neg, b_neg, c_sat>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<ab_vtype, ab_vtype, float, M, N, a_major, b_major, new_a_neg, b_neg, c_sat>()};
  }
};


template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_TF32_SS_SPARSE<a_type, b_type, c_type,
                                       M, N, a_major, b_major,
                                       a_neg, b_neg>, sparse_args...>
{
  using ValTypeD = c_type;
  static_assert(sizeof(a_type) == 4);
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<4, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 32, "SM100_MMA_TF32_SS_SPARSE supports 32bit types");

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<a_type>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  // SparseMma consume double mma-k bits
  static constexpr int K = 512 / cute::sizeof_bits<a_type>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, UMMA::Saturate::False, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_same<cute::tuple<sparse_args...>, cute::tuple<uint32_t>>::value,
                  "Params must be set via .with()?");
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint32_t id2 = tmem_e &  0x00000001;
    tmem_e       = tmem_e & ~0x00000001;

    uint64_t idesc = UMMA::make_runtime_instr_desc<true>(traits.idesc_, static_cast<uint16_t>(id2), tmem_e);

    SM100_MMA_TF32_SS_SPARSE<a_type, b_type, c_type,
                          M, N, a_major, b_major,
                          a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class ELayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_TF32_SS_SPARSE<a_type, b_type, c_type,
                                   M, N, a_major, b_major,
                                   a_neg, b_neg>, uint32_t>
  with(Tensor<TE, ELayout> const& E) const {
    // Check sparse_ptr, check sparsity, check shape/layout?
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());     // Move to a CoupledTensor rather than a .with()?
    return {accumulate_, {tmem_e_addr}, idesc_};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_F16BF16_SS_SPARSE<a_type, b_type, c_type,
                                       M, N, a_major, b_major,
                                       a_neg, b_neg>, sparse_args...>
{
  using ValTypeD = c_type;
  static_assert(sizeof(a_type) == 2);
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<8, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_SS_SPARSE supports 16bit types");

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<a_type>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  // SparseMma consume double mma-k bits
  static constexpr int K = 512 / cute::sizeof_bits<a_type>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, UMMA::Saturate::False, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_same<cute::tuple<sparse_args...>, cute::tuple<uint32_t>>::value,
                  "Params must be set via .with()?");
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint32_t id2 = tmem_e &  0x00000001;
    tmem_e       = tmem_e & ~0x00000001;

    uint64_t idesc = UMMA::make_runtime_instr_desc<true>(traits.idesc_, static_cast<uint16_t>(id2), tmem_e);

    SM100_MMA_F16BF16_SS_SPARSE<a_type, b_type, c_type,
                         M, N, a_major, b_major,
                         a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class ELayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_SS_SPARSE<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  a_neg, b_neg>, uint32_t>
  with(Tensor<TE, ELayout> const& E) const {
    // Check sparse_ptr, check sparsity, check shape/layout?
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());     // Move to a CoupledTensor rather than a .with()?
    return {accumulate_, {tmem_e_addr}, idesc_};
  }
};

template <int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_TF32_TS_INTERLEAVED_CF32CTF32CTF32CF32_TN<
                                M, N,
                                a_major, b_major,
                                a_neg, b_neg, c_sat>>
{
  using a_type = complex<tfloat32_t>;
  using b_type = complex<tfloat32_t>;
  using c_type = float;

  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;

  using FrgTypeA = UMMA::tmem_frg_1sm<a_type, a_type, UMMA::TmemAllocMode::NonInterleaved>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type, int32_t, UMMA::TmemAllocMode::NonInterleaved>;

  // Logical shape-K is always 256 bits; transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  // MMA based interleaved complex GEMM calculates realAcc and imagAcc separately.
  // This MMA_traits is used to calculate 1 of the GEMMs below :
  // 1. realAcc = realA * realB + (-imagA) * imagB
  // 2. imagAcc = imagA * realB +   realA  * imagB
  // So it requires complex<tfloat32_t> type operand A&B and float type operand Acc.
  static_assert(a_major == UMMA::Major::K,    "SM100_MMA_TF32_TS_INTERLEAVED_CF32CTF32CTF32CF32_TN A from TMEM can't be transposed");
  static_assert(b_major == UMMA::Major::K, "SM100_MMA_TF32_TS_INTERLEAVED_CF32CTF32CTF32CF32_TN B from SMEM requires non-transpose");

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    tfloat32_t, tfloat32_t, float, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint32_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_TF32_TS_INTERLEAVED_CF32CTF32CTF32CF32_TN<
                  M, N,
                  a_major, b_major,
                  a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_TF32_2x1SM_SS<a_type, b_type, c_type,
                                     M, N, a_major, b_major,
                                     a_neg, b_neg>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 32, "SM100_MMA_TF32_2x1SM_SS supports 32bit types");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions's K extent is always 256bits, convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_TF32_2x1SM_SS<a_type, b_type, c_type,
                         M, N,
                         a_major, b_major,
                         a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_F16BF16_2x1SM_SS<a_type, b_type, c_type,
                                     M, N, a_major, b_major,
                                     a_neg, b_neg>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_2x1SM_SS supports 16bit types");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions's K extent is always 256bits, convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_2x1SM_SS<a_type, b_type, c_type,
                       M, N,
                       a_major, b_major,
                       a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_TF32_2x1SM_TS<a_type, b_type, c_type,
                                     M, N,
                                     a_major, b_major,
                                     a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 32, "SM100_MMA_TF32_2x1SM_TS supports 32bit types");

  using FrgTypeA = UMMA::tmem_frg_2sm<a_type, a_type, UMMA::TmemAllocMode::Duplicated>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions' K extent is always 256 bits; convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_TF32_2x1SM_TS<a_type, b_type, c_type,
                       M, N,
                       a_major, b_major,
                       a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_F16BF16_2x1SM_TS<a_type, b_type, c_type,
                                     M, N,
                                     a_major, b_major,
                                     a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_2x1SM_TS supports 16bit types");

  using FrgTypeA = UMMA::tmem_frg_2sm<a_type, a_type, UMMA::TmemAllocMode::Duplicated>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions' K extent is always 256 bits; convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_2x1SM_TS<a_type, b_type, c_type,
                       M, N,
                       a_major, b_major,
                       a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_F16BF16_2x1SM_SS_SCALED<a_type, b_type, c_type,
                                     M, N, a_major, b_major,
                                     ScaleC, a_neg, b_neg>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_2x1SM_SS_SCALED supports 16bit types");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions's K extent is always 256bits, convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;
  constexpr static uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_2x1SM_SS_SCALED<a_type, b_type, c_type,
                               M, N, a_major, b_major,
                               ScaleC, a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_2x1SM_SS_SCALED<a_type, b_type, c_type,
                                     M, N, a_major, b_major,
                                     NewScaleC, a_neg, b_neg>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_2x1SM_SS_SCALED<a_type, b_type, c_type,
                                     M, N, a_major, b_major,
                                     ScaleC, new_a_neg, b_neg>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, new_a_neg, b_neg>()};
  }
};


// Special instantiation for interleaved complex (emulated)
template <class ab_vtype, int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_F16BF16_2x1SM_SS_SCALED<cutlass::complex<ab_vtype>, cutlass::complex<ab_vtype>, float,
                                     M, N, a_major, b_major,
                                     ScaleC, a_neg, b_neg>>
{
  static_assert(cute::sizeof_bits_v<ab_vtype> == 16, "Only supports 16bit base types");
  using a_type = complex<ab_vtype>;
  using b_type = complex<ab_vtype>;
  using c_type = float;

  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions's K extent is always 256bits, convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;
  constexpr static uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    ab_vtype, ab_vtype, float, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_2x1SM_SS_SCALED<a_type, b_type, c_type,
                               M, N, a_major, b_major,
                               ScaleC, a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_2x1SM_SS_SCALED<a_type, b_type, c_type,
                                     M, N, a_major, b_major,
                                     NewScaleC, a_neg, b_neg>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_2x1SM_SS_SCALED<a_type, b_type, c_type,
                                     M, N, a_major, b_major,
                                     ScaleC, new_a_neg, b_neg>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<ab_vtype, ab_vtype, float, M, N, a_major, b_major, new_a_neg, b_neg>()};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg, UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_TF32_2x1SM_TS_SCALED<a_type, b_type, c_type,
                                     M, N, a_major, b_major,
                                     ScaleC, a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 32, "SM100_MMA_TF32_2x1SM_TS_SCALED supports 32bit types");

  using FrgTypeA = UMMA::tmem_frg_2sm<a_type, a_type, UMMA::TmemAllocMode::Duplicated>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions' K extent is always 256 bits; convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;
  constexpr static uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_TF32_2x1SM_TS_SCALED<a_type, b_type, c_type,
                               M, N, a_major, b_major,
                               ScaleC, a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_TF32_2x1SM_TS_SCALED<a_type, b_type, c_type,
                                        M, N, a_major, b_major,
                                        NewScaleC, a_neg, b_neg, c_sat>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_TF32_2x1SM_TS_SCALED<a_type, b_type, c_type,
                                        M, N, a_major, b_major,
                                        ScaleC, new_a_neg, b_neg, c_sat>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, new_a_neg, b_neg, c_sat>()};
  }
};


template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg, UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_F16BF16_2x1SM_TS_SCALED<a_type, b_type, c_type,
                                     M, N, a_major, b_major,
                                     ScaleC, a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_2x1SM_TS_SCALED supports 16bit types");

  using FrgTypeA = UMMA::tmem_frg_2sm<a_type, a_type, UMMA::TmemAllocMode::Duplicated>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions' K extent is always 256 bits; convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;
  constexpr static uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_2x1SM_TS_SCALED<a_type, b_type, c_type,
                               M, N, a_major, b_major,
                               ScaleC, a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_2x1SM_TS_SCALED<a_type, b_type, c_type,
                                        M, N, a_major, b_major,
                                        NewScaleC, a_neg, b_neg, c_sat>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_2x1SM_TS_SCALED<a_type, b_type, c_type,
                                        M, N, a_major, b_major,
                                        ScaleC, new_a_neg, b_neg, c_sat>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, new_a_neg, b_neg, c_sat>()};
  }
};


// Special instantiation for interleaved complex (emulated)
template <class ab_vtype, int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          uint32_t ScaleC, UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg, UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_F16BF16_2x1SM_TS_SCALED<cutlass::complex<ab_vtype>, cutlass::complex<ab_vtype>, float,
                                     M, N, a_major, b_major,
                                     ScaleC, a_neg, b_neg, c_sat>>
{
  static_assert(cute::sizeof_bits_v<ab_vtype> == 16, "Only supports 16bit base types");
  using a_type = complex<ab_vtype>;
  using b_type = complex<ab_vtype>;
  using c_type = float;

  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;

  using FrgTypeA = UMMA::tmem_frg_2sm<a_type, a_type, UMMA::TmemAllocMode::Duplicated>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions' K extent is always 256 bits; convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;
  constexpr static uint32_t ScalingFactor = ScaleC;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    ab_vtype, ab_vtype, float, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F16BF16_2x1SM_TS_SCALED<a_type, b_type, c_type,
                               M, N, a_major, b_major,
                               ScaleC, a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }

  template <uint32_t NewScaleC>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_2x1SM_TS_SCALED<a_type, b_type, c_type,
                                        M, N, a_major, b_major,
                                        NewScaleC, a_neg, b_neg, c_sat>>
  with(UMMA::ScaleOut accumulate, cute::integral_constant<uint32_t, NewScaleC> scaleC) const {
    return {accumulate, idesc_};
  }

  template <UMMA::ScaleIn new_a_neg>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_2x1SM_TS_SCALED<a_type, b_type, c_type,
                                        M, N, a_major, b_major,
                                        ScaleC, new_a_neg, b_neg, c_sat>>
  with(cute::integral_constant<UMMA::ScaleIn, new_a_neg>) const {
    return {accumulate_, UMMA::make_instr_desc<ab_vtype, ab_vtype, float, M, N, a_major, b_major, new_a_neg, b_neg, c_sat>()};
  }
};


template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_TF32_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                                             M, N, a_major, b_major,
                                             a_neg, b_neg>, sparse_args...>
{
  using ValTypeD = c_type;
  static_assert(sizeof(a_type) == 4);
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<4, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 32, "SM100_MMA_TF32_2x1SM_SS_SPARSE supports 32bit types");

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<a_type>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // SparseMma consume double mma-k bits
  constexpr static int K = 512 / cute::sizeof_bits<a_type>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, UMMA::Saturate::False, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_same<cute::tuple<sparse_args...>, cute::tuple<uint32_t>>::value,
                  "Params must be set via .with()?");
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint32_t id2 = tmem_e &  0x00000001;
    tmem_e       = tmem_e & ~0x00000001;

    uint64_t idesc = UMMA::make_runtime_instr_desc<true>(traits.idesc_, static_cast<uint16_t>(id2), tmem_e);

    SM100_MMA_TF32_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                              M, N, a_major, b_major,
                              a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class ELayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_TF32_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                                       M, N, a_major, b_major,
                                       a_neg, b_neg>, uint32_t>
  with(Tensor<TE, ELayout> const& E, uint32_t id2 = 0) const {
    // Check sparse_ptr, check sparsity, check shape/layout?
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());
    return {accumulate_, {tmem_e_addr}, idesc_};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_F16BF16_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                                             M, N, a_major, b_major,
                                             a_neg, b_neg>, sparse_args...>
{
  using ValTypeD = c_type;
  static_assert(sizeof(a_type) == 2);
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<8, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 16, "SM100_MMA_F16BF16_2x1SM_SS_SPARSE supports 16bit types");

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<a_type>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // SparseMma consume double mma-k bits
  constexpr static int K = 512 / cute::sizeof_bits<a_type>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, UMMA::Saturate::False, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_same<cute::tuple<sparse_args...>, cute::tuple<uint32_t>>::value,
                  "Params must be set via .with()?");
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint32_t id2 = tmem_e &  0x00000001;
    tmem_e       = tmem_e & ~0x00000001;

    uint64_t idesc = UMMA::make_runtime_instr_desc<true>(traits.idesc_, static_cast<uint16_t>(id2), tmem_e);

    SM100_MMA_F16BF16_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                              M, N, a_major, b_major,
                              a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class ELayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F16BF16_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                                       M, N, a_major, b_major,
                                       a_neg, b_neg>, uint32_t>
  with(Tensor<TE, ELayout> const& E, uint32_t id2 = 0) const {
    // Check sparse_ptr, check sparsity, check shape/layout?
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());
    return {accumulate_, {tmem_e_addr}, idesc_};
  }
};

template <int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_TF32_2x1SM_TS_INTERLEAVED_CF32CTF32CTF32CF32_TN<
                                     M, N,
                                     a_major, b_major,
                                     a_neg, b_neg, c_sat>>
{
  using a_type = complex<tfloat32_t>;
  using b_type = complex<tfloat32_t>;
  using c_type = float;

  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;

  using FrgTypeA = UMMA::tmem_frg_2sm<a_type, a_type, UMMA::TmemAllocMode::Duplicated>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions' K extent is always 256 bits; convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  // Interleaved complex GEMM calculates realAcc and imagAcc separately.
  // This MMA_traits is used to calculate 1 of the GEMMs below :
  // 1. realAcc = realA * realB + (-imagA) * imagB
  // 2. imagAcc = imagA * realB +   realA  * imagB
  // So it requires complex<tfloat32_t> type operand A&B and float type operand Acc.
  static_assert(a_major == UMMA::Major::K,    "SM100_MMA_TF32_2x1SM_TS_INTERLEAVED_CF32CTF32CTF32CF32_TN A from TMEM can't be transposed");
  static_assert(b_major == UMMA::Major::K, "SM100_MMA_TF32_2x1SM_TS_INTERLEAVED_CF32CTF32CTF32CF32_TN B from SMEM requires non-transpose");

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    tfloat32_t, tfloat32_t, float, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_TF32_2x1SM_TS_INTERLEAVED_CF32CTF32CTF32CF32_TN<
                       M, N,
                       a_major, b_major,
                       a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_S8_SS<a_type, b_type, c_type,
                                M, N, a_major, b_major,
                                c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 8, "SM100_MMA_S8_SS supports 8bit types");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  // Logical shape-K is always 256bits, transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, UMMA::ScaleIn::One, UMMA::ScaleIn::One, c_sat>();

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_S8_SS<a_type, b_type, c_type,
                  M, N, a_major, b_major,
                  c_sat>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_S8_TS<a_type, b_type, c_type,
                                M, N,
                                a_major, b_major,
                                a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 8, "SM100_MMA_S8_TS supports 8bit types");

  using FrgTypeA = UMMA::tmem_frg_1sm<a_type, a_type, UMMA::TmemAllocMode::NonInterleaved>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type, int32_t, UMMA::TmemAllocMode::NonInterleaved>;

  // Logical shape-K is always 256 bits; transform to units of elements
  static constexpr int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, UMMA::ScaleIn::One, UMMA::ScaleIn::One, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_S8_TS<a_type, b_type, c_type,
                  M, N,
                  a_major, b_major,
                  a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::Saturate c_sat,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_S8_SS_SPARSE<a_type, b_type, c_type,
                                       M, N, a_major, b_major,
                                       c_sat>, sparse_args...>
{
  using ValTypeD = c_type;
  static_assert(sizeof(a_type) == 1);
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<8, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 8, "SM100_MMA_S8_SS_SPARSE supports 8bit types");

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<a_type>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  // SparseMma consume double mma-k bits
  static constexpr int K = 512 / cute::sizeof_bits<a_type>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, UMMA::ScaleIn::One, UMMA::ScaleIn::One, c_sat, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_same<cute::tuple<sparse_args...>, cute::tuple<uint32_t>>::value,
                  "Params must be set via .with()?");
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint32_t id2 = 0;

    uint64_t idesc = UMMA::make_runtime_instr_desc<true>(traits.idesc_, static_cast<uint16_t>(id2), tmem_e);

    SM100_MMA_S8_SS_SPARSE<a_type, b_type, c_type,
                         M, N, a_major, b_major,
                         c_sat>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class ELayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_S8_SS_SPARSE<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  c_sat>, uint32_t>
  with(Tensor<TE, ELayout> const& E, uint32_t id2 = 0) const {
    // Check sparse_ptr, check sparsity, check shape/layout?
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());
    return {accumulate_, {tmem_e_addr}, idesc_};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_S8_2x1SM_SS<a_type, b_type, c_type,
                                      M, N, a_major, b_major,
                                      c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 8, "SM100_MMA_S8_2x1SM_SS supports 8bit types");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions's K extent is always 256bits, convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, UMMA::ScaleIn::One, UMMA::ScaleIn::One, c_sat>();

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_S8_2x1SM_SS<a_type, b_type, c_type,
                       M, N, a_major, b_major,
                       c_sat>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_S8_2x1SM_TS<a_type, b_type, c_type,
                                     M, N,
                                     a_major, b_major,
                                     a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 8, "SM100_MMA_S8_2x1SM_TS supports 8bit types");

  using FrgTypeA = UMMA::tmem_frg_2sm<a_type, a_type, UMMA::TmemAllocMode::Duplicated>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Size of instructions' K extent is always 256 bits; convert to units of element
  constexpr static int K = 256 / cute::sizeof_bits<ValTypeA>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
      a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_S8_2x1SM_TS<a_type, b_type, c_type,
                        M, N,
                        a_major, b_major,
                        a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::Saturate c_sat,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_S8_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                                             M, N, a_major, b_major,
                                             c_sat>, sparse_args...>
{
  using ValTypeD = c_type;
  static_assert(sizeof(a_type) == 1);
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<8, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> == cute::sizeof_bits_v<b_type> && cute::sizeof_bits_v<b_type> == 8, "SM100_MMA_S8_2x1SM_SS_SPARSE supports 8bit types");

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<a_type>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // SparseMma consume double mma-k bits
  constexpr static int K = 512 / cute::sizeof_bits<a_type>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, UMMA::ScaleIn::One, UMMA::ScaleIn::One, c_sat, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_same<cute::tuple<sparse_args...>, cute::tuple<uint32_t>>::value,
                  "Params must be set via .with()?");
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint16_t id2    = 0u;

    uint64_t idesc = UMMA::make_runtime_instr_desc<true>(traits.idesc_, id2, tmem_e);

    SM100_MMA_S8_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                              M, N, a_major, b_major,
                              c_sat>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class ELayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_S8_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                                       M, N, a_major, b_major,
                                       c_sat>, uint32_t>
  with(Tensor<TE, ELayout> const& E, uint32_t id2 = 0) const {
    // Check sparse_ptr, check sparsity, check shape/layout?
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());
    return {accumulate_, {tmem_e_addr}, idesc_};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_F8F6F4_SS<a_type, b_type, c_type,
                                      M, N, a_major, b_major,
                                      a_neg, b_neg>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_F8F6F4_SS supports types with leq 8bit types");
  static_assert(M == 64 || M == 128, "SM100_MMA_F8F6F4_SS M-mode size should be 64 or 128 for 1 CTA cluster MMA.");
  static_assert(((b_major == UMMA::Major::K) && ((N % 8 == 0) && (8 <= N) && (N <= 256))) ||
                ((b_major == UMMA::Major::MN) && ((N % 16 == 0) && (16 <= N) && (N <= 256))),
                "SM100_MMA_F8F6F4_SS N-mode size should be a multiple of 8 between 8 and 256 when B is K major. \
                 SM100_MMA_F8F6F4_SS N-mode size should be a multiple of 16 between 16 and 256 when B is MN major.");
  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  static_assert(sizeof_bits_v<ValTypeA> <= sizeof_bits_v<uint8_t> &&
                sizeof_bits_v<ValTypeB> <= sizeof_bits_v<uint8_t>);

  // Logical shape-K is always 256bits, transform to units of elements
  constexpr static int K = 32;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F8F6F4_SS<a_type, b_type, c_type,
                        M, N, a_major, b_major,
                        a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};


template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                                M, N, a_major, b_major,
                                a_neg, b_neg>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_MXF8F6F4_SS supports types with leq 8bit types");

  // Logical shape-K is always 256bits, transform to units of elements
  constexpr static int K = 32;
  constexpr static int SFVecSize = 32;

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, true>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, false>;

  static_assert(sizeof_bits_v<ValTypeA> <= sizeof_bits_v<uint8_t> &&
                sizeof_bits_v<ValTypeB> <= sizeof_bits_v<uint8_t>);


  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using MMA_ScaleFactor = SM100_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                                M, (round_up(N, 128)), a_major, b_major,
                                a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  uint32_t tsfa_addr_ = 0;
  uint32_t tsfb_addr_ = 0;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc_block_scaled<>(traits.idesc_, traits.tsfa_addr_, traits.tsfb_addr_);

    SM100_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                  M, N,
                  a_major, b_major,
                  a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, traits.tsfa_addr_, traits.tsfb_addr_);
  }

  // Construct an executable MMA_traits with sp into set.
  template <class TSFA, class TSFALayout, class TSFB, class TSFBLayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                              M, N, a_major, b_major, a_neg, b_neg>>
  with(UMMA::ScaleOut accumulate, Tensor<TSFA, TSFALayout> const& SFA, Tensor<TSFB, TSFBLayout> const& SFB) const {
    uint32_t tmem_sfa_addr = raw_pointer_cast(SFA.data());
    uint32_t tmem_sfb_addr = raw_pointer_cast(SFB.data());
    return {accumulate, tmem_sfa_addr, tmem_sfb_addr, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_MXF8F6F4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                                          M, N, a_major, b_major,
                                          a_neg, b_neg>, sparse_args...>
{
  using ValTypeD = c_type;
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<8, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_MXF8F6F4_SS_SPARSE supports types with leq 8bit types");

  // Logical shape-K is always 512bits, transform to units of elements
  constexpr static int K = 64;
  constexpr static int SFVecSize = 64;

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<uint8_t>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, true>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, false>;

  static_assert(sizeof_bits_v<ValTypeA> <= sizeof_bits_v<uint8_t> &&
                sizeof_bits_v<ValTypeB> <= sizeof_bits_v<uint8_t>);


  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using MMA_ScaleFactor = SM100_MMA_MXF8F6F4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                                M, (round_up(N, 128)), a_major, b_major,
                                a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  uint32_t tsfa_addr_ = 0;
  uint32_t tsfb_addr_ = 0;

  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_same<cute::tuple<sparse_args...>, cute::tuple<uint32_t>>::value,
              "Params must be set via .with()?");
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint16_t id2    = 0u;

    uint64_t idesc = UMMA::make_runtime_instr_desc_block_scaled<true>(traits.idesc_, traits.tsfa_addr_, traits.tsfb_addr_, id2, tmem_e);

    SM100_MMA_MXF8F6F4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                            M, N,
                            a_major, b_major,
                            a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, traits.tsfa_addr_, traits.tsfb_addr_, tmem_e);
  }

  // Construct an executable MMA_traits with sp into set.
  template <class TE, class TELayout, class TSFA, class TSFALayout, class TSFB, class TSFBLayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_MXF8F6F4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                              M, N, a_major, b_major, a_neg, b_neg>, uint32_t>
  with(UMMA::ScaleOut accumulate, Tensor<TE, TELayout> const& E, Tensor<TSFA, TSFALayout> const& SFA, Tensor<TSFB, TSFBLayout> const& SFB) const {
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());
    uint32_t tmem_sfa_addr = raw_pointer_cast(SFA.data());
    uint32_t tmem_sfb_addr = raw_pointer_cast(SFB.data());
    return {accumulate, tmem_sfa_addr, tmem_sfb_addr, {tmem_e_addr}, idesc_};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_F8F6F4_TS<a_type, b_type, c_type,
                                M, N,
                                a_major, b_major,
                                a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_F8F6F4_TS supports types with leq 8bit types");

  using FrgTypeA = UMMA::tmem_frg_1sm<a_type, a_type, UMMA::TmemAllocMode::NonInterleaved>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type, int32_t, UMMA::TmemAllocMode::NonInterleaved>;

  static_assert(sizeof_bits_v<ValTypeA> <= sizeof_bits_v<uint8_t> &&
                sizeof_bits_v<ValTypeB> <= sizeof_bits_v<uint8_t>);
  // Logical shape-K is always 256 bits; transform to units of elements
  static constexpr int K = 32;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F8F6F4_TS<a_type, b_type, c_type,
                  M, N,
                  a_major, b_major,
                  a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_F8F6F4_SS_SPARSE<a_type, b_type, c_type,
                                       M, N, a_major, b_major,
                                       a_neg, b_neg>, sparse_args...>
{
  using ValTypeD = c_type;
  static_assert(sizeof(a_type) == 1);
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<8, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_F8F6F4_SS_SPARSE supports types with leq 8bit types");

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<uint8_t>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  // SparseMma consume double mma-k bits
  static constexpr int K = 512 / cute::sizeof_bits<uint8_t>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, UMMA::Saturate::False, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_same<cute::tuple<sparse_args...>, cute::tuple<uint32_t>>::value,
                  "Params must be set via .with()?");
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint16_t id2    = 0u;

    uint64_t idesc = UMMA::make_runtime_instr_desc<true>(traits.idesc_, id2, tmem_e);

    SM100_MMA_F8F6F4_SS_SPARSE<a_type, b_type, c_type,
                         M, N, a_major, b_major,
                         a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class ELayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F8F6F4_SS_SPARSE<a_type, b_type, c_type,
                                  M, N, a_major, b_major,
                                  a_neg, b_neg>, uint32_t>
  with(Tensor<TE, ELayout> const& E, uint32_t id2 = 0) const {
    // Check sparse_ptr, check sparsity, check shape/layout?
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());
    return {accumulate_, {tmem_e_addr}, idesc_};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_F8F6F4_2x1SM_SS<a_type, b_type, c_type,
                                            M, N, a_major, b_major,
                                            a_neg, b_neg>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_F8F6F4_2x1SM_SS supports types with leq 8bit types");
  static_assert(M == 128 || M == 256, "SM100_MMA_F8F6F4_2x1SM_SS M-mode size should be 64 or 128 for 1 CTA cluster MMA.");
  static_assert(((b_major == UMMA::Major::K) && ((N % 16 == 0) && (16 <= N) && (N <= 256))) ||
                ((b_major == UMMA::Major::MN) && ((N % 32 == 0) && (32 <= N) && (N <= 256))),
                "SM100_MMA_F8F6F4_2x1SM_SS N-mode size should be a multiple of 16 between 16 and 256 when B is K major. \
                 SM100_MMA_F8F6F4_2x1SM_SS N-mode size should be a multiple of 32 between 32 and 256 when B is MN major.");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  static_assert(sizeof_bits_v<ValTypeA> <= sizeof_bits_v<uint8_t> &&
                sizeof_bits_v<ValTypeB> <= sizeof_bits_v<uint8_t>);
  // Size of instructions's K extent is always 256bits, convert to units of element
  constexpr static int K = 32;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F8F6F4_2x1SM_SS<a_type, b_type, c_type,
                              M, N, a_major, b_major,
                              a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::Saturate c_sat>
struct MMA_Traits<SM100_MMA_F8F6F4_2x1SM_TS<a_type, b_type, c_type,
                                     M, N,
                                     a_major, b_major,
                                     a_neg, b_neg, c_sat>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_F8F6F4_2x1SM_TS supports types with leq 8bit types");

  using FrgTypeA = UMMA::tmem_frg_2sm<a_type, a_type, UMMA::TmemAllocMode::Duplicated>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  static_assert(sizeof_bits_v<ValTypeA> <= sizeof_bits_v<uint8_t> &&
                sizeof_bits_v<ValTypeB> <= sizeof_bits_v<uint8_t>);
  // Size of instructions' K extent is always 256 bits; convert to units of element
  constexpr static int K = 32;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t tmem_a = raw_pointer_cast(A.data());
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM100_MMA_F8F6F4_2x1SM_TS<a_type, b_type, c_type,
                       M, N,
                       a_major, b_major,
                       a_neg, b_neg, c_sat>::fma(tmem_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc);
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_F8F6F4_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                                             M, N, a_major, b_major,
                                             a_neg, b_neg>, sparse_args...>
{
  using ValTypeD = c_type;
  static_assert(sizeof(a_type) == 1);
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<8, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_F8F6F4_2x1SM_SS_SPARSE supports types with leq 8bit types");

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<uint8_t>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // SparseMma consume double mma-k bits
  constexpr static int K = 512 / cute::sizeof_bits<uint8_t>::value;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptor idesc_ = UMMA::make_instr_desc<
    a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, UMMA::Saturate::False, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_same<cute::tuple<sparse_args...>, cute::tuple<uint32_t>>::value,
                  "Params must be set via .with()?");
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint16_t id2    = 0u;

    uint64_t idesc = UMMA::make_runtime_instr_desc<true>(traits.idesc_, id2, tmem_e);

    SM100_MMA_F8F6F4_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                              M, N, a_major, b_major,
                              a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class ELayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_F8F6F4_2x1SM_SS_SPARSE<a_type, b_type, c_type,
                                       M, N, a_major, b_major,
                                       a_neg, b_neg>, uint32_t>
  with(Tensor<TE, ELayout> const& E, uint32_t id2 = 0) const {
    // Check sparse_ptr, check sparsity, check shape/layout?
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());
    return {accumulate_, {tmem_e_addr}, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_MXF8F6F4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                      M, N, a_major, b_major,
                                      a_neg, b_neg>>
{
  using ValTypeD   = c_type;
  using ValTypeA   = a_type;
  using ValTypeB   = b_type;
  using ValTypeC   = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_MXF8F6F4_2x1SM_SS supports types with leq 8bit types");

  using FrgTypeA   = UMMA::smem_desc<a_major>;
  using FrgTypeB   = UMMA::smem_desc<b_major>;
  using FrgTypeC   = UMMA::tmem_frg_2sm<c_type>;

  // Logical shape-K is always 256bits, transform to units of elements
  constexpr static int K = 32;
  constexpr static int SFVecSize = 32;

  constexpr static UMMA::TmemAllocMode TmemAlloc = M == 128 ?
      UMMA::TmemAllocMode::ScaleFactorDuplicated2by2 : UMMA::TmemAllocMode::ScaleFactorDuplicated4by1;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2,  true, TmemAlloc>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2, false, TmemAlloc>;

  static_assert(sizeof_bits_v<ValTypeA> <= sizeof_bits_v<uint8_t> &&
                sizeof_bits_v<ValTypeB> <= sizeof_bits_v<uint8_t>);

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using MMA_ScaleFactor = SM100_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                                (M/2 > 64 ? M/2 : M), (round_up(N, 128)), a_major, b_major,
                                a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  uint32_t tsfa_addr_ = 0;
  uint32_t tsfb_addr_ = 0;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc_block_scaled<>(traits.idesc_, traits.tsfa_addr_, traits.tsfb_addr_);

    SM100_MMA_MXF8F6F4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                          M, N,
                          a_major, b_major,
                          a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, traits.tsfa_addr_, traits.tsfb_addr_);
  }

  // Construct an executable MMA_traits with sp into set.
  template <class TSFA, class TSFALayout, class TSFB, class TSFBLayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_MXF8F6F4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                M, N, a_major, b_major, a_neg, b_neg>>
  with(UMMA::ScaleOut accumulate, Tensor<TSFA, TSFALayout> const& SFA, Tensor<TSFB, TSFBLayout> const& SFB) const {
    uint32_t tmem_sfa_addr = raw_pointer_cast(SFA.data());
    uint32_t tmem_sfb_addr = raw_pointer_cast(SFB.data());
    return {accumulate, tmem_sfa_addr, tmem_sfb_addr, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_MXF8F6F4_2x1SM_SS_SPARSE<a_type, b_type, c_type, sf_type,
                                      M, N, a_major, b_major,
                                      a_neg, b_neg>, sparse_args...>
{
  using ValTypeD = c_type;
  static_assert(sizeof(a_type) == 1);
  using ValTypeA = sparse_elem<2, a_type>;
  using ValTypeE = sparse_elem<8, uint8_t>;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8, "SM100_MMA_MXF8F6F4_2x1SM_SS_SPARSE supports types with leq 8bit types");

  using FrgTypeA = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE = UMMA::tmem_e_frg<uint8_t>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // SparseMma consume double mma-k bits
  constexpr static int K = 64;
  constexpr static int SFVecSize = 64;

  constexpr static UMMA::TmemAllocMode TmemAlloc = M == 128 ?
      UMMA::TmemAllocMode::ScaleFactorDuplicated2by2 : UMMA::TmemAllocMode::ScaleFactorDuplicated4by1;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2,  true, TmemAlloc>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2, false, TmemAlloc>;

  static_assert(sizeof_bits_v<ValTypeA> <= sizeof_bits_v<uint8_t> &&
                sizeof_bits_v<ValTypeB> <= sizeof_bits_v<uint8_t>);

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using MMA_ScaleFactor = SM100_MMA_MXF8F6F4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                                (M/2 > 64 ? M/2 : M), (round_up(N, 128)), a_major, b_major,
                                a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  uint32_t tsfa_addr_ = 0;
  uint32_t tsfb_addr_ = 0;

  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint16_t id2    = 0u;

    uint64_t idesc = UMMA::make_runtime_instr_desc_block_scaled<true>(traits.idesc_, traits.tsfa_addr_, traits.tsfb_addr_, id2, tmem_e);

    SM100_MMA_MXF8F6F4_2x1SM_SS_SPARSE<a_type, b_type, c_type, sf_type,
                          M, N,
                          a_major, b_major,
                          a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, traits.tsfa_addr_, traits.tsfb_addr_, tmem_e);
  }

  // Construct an executable MMA_traits with sp into set.
  template <class TE, class TELayout, class TSFA, class TSFALayout, class TSFB, class TSFBLayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_MXF8F6F4_2x1SM_SS_SPARSE<a_type, b_type, c_type, sf_type,
                                M, N, a_major, b_major, a_neg, b_neg>, uint32_t>
  with(UMMA::ScaleOut accumulate, Tensor<TE, TELayout> const& E, Tensor<TSFA, TSFALayout> const& SFA, Tensor<TSFB, TSFBLayout> const& SFB) const {
    uint32_t tmem_e_addr = raw_pointer_cast(E.data());
    uint32_t tmem_sfa_addr = raw_pointer_cast(SFA.data());
    uint32_t tmem_sfb_addr = raw_pointer_cast(SFB.data());
    return {accumulate, tmem_sfa_addr, tmem_sfb_addr, {tmem_e_addr}, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_MXF4_SS<a_type, b_type, c_type, sf_type,
                                M, N, VS, a_major, b_major,
                                a_neg, b_neg>>
{
  using ValTypeD   = c_type;
  using ValTypeA   = a_type;
  using ValTypeB   = b_type;
  using ValTypeC   = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> == 4 && cute::sizeof_bits_v<b_type> == 4, "SM100_MMA_MXF4_SS supports 4bit types");

  // Logical shape-K is always 256bits, transform to units of elements
  constexpr static int K = 64;
  constexpr static int SFVecSize = VS;

  using FrgTypeA   = UMMA::smem_desc<a_major>;
  using FrgTypeB   = UMMA::smem_desc<b_major>;
  using FrgTypeC   = UMMA::tmem_frg_1sm<c_type>;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, true>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, false>;

  static_assert((VS == 32 && ((is_same_v<a_type, cutlass::float_e2m1_t> || is_same_v<a_type, cutlass::type_erased_dynamic_float4_t>) &&
                              (is_same_v<b_type, cutlass::float_e2m1_t> || is_same_v<b_type, cutlass::type_erased_dynamic_float4_t>))
                          &&   is_same_v<sf_type, cutlass::float_ue8m0_t>)
             || (VS == 16),
       "2x mode (VectorSize=32) only supports a_type and b_type=float_e2m1_t or cutlass::type_erased_dynamic_float4_t and sf_type=ue8m0_t");

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using MMA_ScaleFactor = SM100_MMA_MXF4_SS<a_type, b_type, c_type, sf_type,
                                M, (round_up(N, 128)), VS, a_major, b_major,
                                a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  uint32_t tsfa_addr_ = 0;
  uint32_t tsfb_addr_ = 0;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc_block_scaled<>(traits.idesc_, traits.tsfa_addr_, traits.tsfb_addr_);

    SM100_MMA_MXF4_SS<a_type, b_type, c_type, sf_type,
                  M, N, VS,
                  a_major, b_major,
                  a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, traits.tsfa_addr_, traits.tsfb_addr_);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TSFA, class TSFALayout, class TSFB, class TSFBLayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_MXF4_SS<a_type, b_type, c_type, sf_type,
                              M, N, VS, a_major, b_major, a_neg, b_neg>>
  with(UMMA::ScaleOut accumulate, Tensor<TSFA, TSFALayout> const& SFA, Tensor<TSFB, TSFBLayout> const& SFB) const {
    uint32_t tmem_sfa_addr = raw_pointer_cast(SFA.data());     // Move to a CoupledTensor rather than a .with()?
    uint32_t tmem_sfb_addr = raw_pointer_cast(SFB.data());     // Move to a CoupledTensor rather than a .with()?
    return {accumulate, tmem_sfa_addr, tmem_sfb_addr, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_MXF4NVF4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                                M, N, VS, a_major, b_major,
                                a_neg, b_neg>, sparse_args...>
{
  using ValTypeD   = c_type;
  using ValTypeA   = sparse_elem<4, uint8_t>;
  using ValTypeE   = sparse_elem<16, uint8_t>;
  using ValTypeB   = b_type;
  using ValTypeC   = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> == 4 && cute::sizeof_bits_v<b_type> == 4, "SM100_MMA_MXF4NVF4_SS_SPARSE supports 4bit types");

  // Logical shape-K is always 256bits, transform to units of elements
  constexpr static int K = 128;
  constexpr static int SFVecSize = VS;

  using FrgTypeA   = UMMA::sparse_smem_desc<a_major>;
  using FrgTypeE   = UMMA::tmem_e_frg<a_type>;
  using FrgTypeB   = UMMA::smem_desc<b_major>;
  using FrgTypeC   = UMMA::tmem_frg_1sm<c_type>;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, true>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, false>;

  static_assert((VS == 64 && ((is_same_v<a_type, cutlass::float_e2m1_t> || is_same_v<a_type, cutlass::type_erased_dynamic_float4_t>) &&
                              (is_same_v<b_type, cutlass::float_e2m1_t> || is_same_v<b_type, cutlass::type_erased_dynamic_float4_t>))
                          &&   is_same_v<sf_type, cutlass::float_ue8m0_t>)
             || (VS == 32),
       "2x mode (VectorSize=64) only supports a_type and b_type=float_e2m1_t or cutlass::type_erased_dynamic_float4_t and sf_type=ue8m0_t");

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using MMA_ScaleFactor = SM100_MMA_MXF4NVF4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                                M, (round_up(N, 128)), VS, a_major, b_major,
                                a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  uint32_t tsfa_addr_ = 0;
  uint32_t tsfb_addr_ = 0;

  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint16_t id2    = 0u;

    uint64_t idesc = UMMA::make_runtime_instr_desc_block_scaled<true>(traits.idesc_, traits.tsfa_addr_, traits.tsfb_addr_, id2, tmem_e);

    SM100_MMA_MXF4NVF4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                  M, N, VS,
                  a_major, b_major,
                  a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, traits.tsfa_addr_, traits.tsfb_addr_, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class TELayout, class TSFA, class TSFALayout, class TSFB, class TSFBLayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_MXF4NVF4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                              M, N, VS, a_major, b_major, a_neg, b_neg>, uint32_t>
  with(UMMA::ScaleOut accumulate, Tensor<TE, TELayout> const& E, Tensor<TSFA, TSFALayout> const& SFA, Tensor<TSFB, TSFBLayout> const& SFB) const {
    uint32_t tmem_e_addr   = raw_pointer_cast(E.data());
    uint32_t tmem_sfa_addr = raw_pointer_cast(SFA.data());     // Move to a CoupledTensor rather than a .with()?
    uint32_t tmem_sfb_addr = raw_pointer_cast(SFB.data());     // Move to a CoupledTensor rather than a .with()?
    return {accumulate, tmem_sfa_addr, tmem_sfb_addr, {tmem_e_addr}, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM100_MMA_MXF4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                      M, N, VS, a_major, b_major,
                                      a_neg, b_neg>>
{
  using ValTypeD   = c_type;
  using ValTypeA   = a_type;
  using ValTypeB   = b_type;
  using ValTypeC   = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> == 4 && cute::sizeof_bits_v<b_type> == 4, "SM100_MMA_MXF4_2x1SM_SS supports 4bit types");

  // Logical shape-K is always 256bits, transform to units of elements
  constexpr static int K = 64;
  constexpr static int SFVecSize = VS;

  using FrgTypeA   = UMMA::smem_desc<a_major>;
  using FrgTypeB   = UMMA::smem_desc<b_major>;
  using FrgTypeC   = UMMA::tmem_frg_2sm<c_type>;

  constexpr static UMMA::TmemAllocMode TmemAlloc = M == 128 ?
      UMMA::TmemAllocMode::ScaleFactorDuplicated2by2 : UMMA::TmemAllocMode::ScaleFactorDuplicated4by1;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2,  true, TmemAlloc>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2, false, TmemAlloc>;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using MMA_ScaleFactor = SM100_MMA_MXF4_SS<a_type, b_type, c_type, sf_type,
                                (M/2 > 64 ? M/2 : M), (round_up(N, 128)), VS, a_major, b_major,
                                a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  uint32_t tsfa_addr_ = 0;
  uint32_t tsfb_addr_ = 0;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc_block_scaled<>(traits.idesc_, traits.tsfa_addr_, traits.tsfb_addr_);

    SM100_MMA_MXF4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                          M, N, VS,
                          a_major, b_major,
                          a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, traits.tsfa_addr_, traits.tsfb_addr_);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TSFA, class TSFALayout, class TSFB, class TSFBLayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_MXF4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                M, N, VS, a_major, b_major, a_neg, b_neg>>
  with(UMMA::ScaleOut accumulate, Tensor<TSFA, TSFALayout> const& SFA, Tensor<TSFB, TSFBLayout> const& SFB) const {
    // Check sparse_ptr, check sparsity, check shape/layout?
    uint32_t tmem_sfa_addr = raw_pointer_cast(SFA.data());     // Move to a CoupledTensor rather than a .with()?
    uint32_t tmem_sfb_addr = raw_pointer_cast(SFB.data());     // Move to a CoupledTensor rather than a .with()?
    return {accumulate, tmem_sfa_addr, tmem_sfb_addr, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          class... sparse_args>
struct MMA_Traits<SM100_MMA_MXF4NVF4_2x1SM_SS_SPARSE<a_type, b_type, c_type, sf_type,
                                M, N, VS, a_major, b_major,
                                a_neg, b_neg>, sparse_args...>
{
  using ValTypeD   = c_type;
  using ValTypeA = sparse_elem<4, uint8_t>;
  using ValTypeE = sparse_elem<16, uint8_t>;
  using ValTypeB   = b_type;
  using ValTypeC   = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> == 4 && cute::sizeof_bits_v<b_type> == 4, "SM100_MMA_MXF4NVF4_2x1SM_SS_SPARSE supports 4bit types");

  // Logical shape-K is always 256bits, transform to units of elements
  constexpr static int K = 128;
  constexpr static int SFVecSize = VS;

  constexpr static UMMA::TmemAllocMode TmemAlloc = M == 128 ?
      UMMA::TmemAllocMode::ScaleFactorDuplicated2by2 : UMMA::TmemAllocMode::ScaleFactorDuplicated4by1;
  using FrgTypeA   = UMMA::sparse_smem_desc<a_major>;
  // using FrgTypeE = UMMA::tmem_e_frg<uint8_t>;
  using FrgTypeE   = UMMA::tmem_e_frg<a_type>;
  using FrgTypeB   = UMMA::smem_desc<b_major>;
  using FrgTypeC   = UMMA::tmem_frg_2sm<c_type>;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2,  true, TmemAlloc>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2, false, TmemAlloc>;

  static_assert((VS == 64 && ((is_same_v<a_type, cutlass::float_e2m1_t> || is_same_v<a_type, cutlass::type_erased_dynamic_float4_t>) &&
                              (is_same_v<b_type, cutlass::float_e2m1_t> || is_same_v<b_type, cutlass::type_erased_dynamic_float4_t>))
                          &&   is_same_v<sf_type, cutlass::float_ue8m0_t>)
             || (VS == 32),
       "2x mode (VectorSize=64) only supports a_type and b_type=float_e2m1_t or cutlass::type_erased_dynamic_float4_t and sf_type=ue8m0_t");

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using MMA_ScaleFactor = SM100_MMA_MXF4NVF4_SS_SPARSE<a_type, b_type, c_type, sf_type,
                                (M/2 > 64 ? M/2 : M), (round_up(N, 128)), VS, a_major, b_major,
                                a_neg, b_neg>;


  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  uint32_t tsfa_addr_ = 0;
  uint32_t tsfb_addr_ = 0;

  // uint32_t tmem_e: Metadata tmem address.
  cute::tuple<sparse_args...> sparse_args_;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg, true>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& A,
             Tensor<TB, BLayout> const& B,
             Tensor<TC, CLayout> const& C)
  {
    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());

    uint32_t tmem_e = get<0>(traits.sparse_args_);
    uint16_t id2    = 0u;

    uint64_t idesc = UMMA::make_runtime_instr_desc_block_scaled<true>(traits.idesc_, traits.tsfa_addr_, traits.tsfb_addr_, id2, tmem_e);

    SM100_MMA_MXF4NVF4_2x1SM_SS_SPARSE<a_type, b_type, c_type, sf_type,
                  M, N, VS,
                  a_major, b_major,
                  a_neg, b_neg>::fma(desc_a, desc_b, tmem_c, uint32_t(traits.accumulate_), idesc, traits.tsfa_addr_, traits.tsfb_addr_, tmem_e);
  }

  // Construct an executable sparse MMA_traits with sp into set.
  template <class TE, class TELayout, class TSFA, class TSFALayout, class TSFB, class TSFBLayout>
  CUTE_HOST_DEVICE constexpr
  MMA_Traits<SM100_MMA_MXF4NVF4_2x1SM_SS_SPARSE<a_type, b_type, c_type, sf_type,
                              M, N, VS, a_major, b_major, a_neg, b_neg>, uint32_t>
  with(UMMA::ScaleOut accumulate, Tensor<TE, TELayout> const& E, Tensor<TSFA, TSFALayout> const& SFA, Tensor<TSFB, TSFBLayout> const& SFB) const {
    uint32_t tmem_e_addr   = raw_pointer_cast(E.data());
    uint32_t tmem_sfa_addr = raw_pointer_cast(SFA.data());     // Move to a CoupledTensor rather than a .with()?
    uint32_t tmem_sfb_addr = raw_pointer_cast(SFB.data());     // Move to a CoupledTensor rather than a .with()?
    return {accumulate, tmem_sfa_addr, tmem_sfb_addr, {tmem_e_addr}, idesc_};
  }
};

/**
 * Specialization for a vectorized FMA per thread.
 */
template <>
struct MMA_Traits<SM100_2x1x1_F32F32F32F32>
{
  using ValTypeD = float;
  using ValTypeA = float;
  using ValTypeB = float;
  using ValTypeC = float;

  using Shape_MNK = Shape<_2,_1,_1>;
  using ThrID   = Layout<_1>;

  using ALayout = Layout<Shape<_1,_2>>;
  using BLayout = Layout<Shape<_1,_1>>;
  using CLayout = Layout<Shape<_1,_2>>;
};

template <>
struct MMA_Traits<SM100_1x2x1_F32F32F32F32>
{
  using ValTypeD = float;
  using ValTypeA = float;
  using ValTypeB = float;
  using ValTypeC = float;

  using Shape_MNK = Shape<_1,_2,_1>;
  using ThrID   = Layout<_1>;

  using ALayout = Layout<Shape<_1,_1>>;
  using BLayout = Layout<Shape<_1,_2>>;
  using CLayout = Layout<Shape<_1,_2>>;
};

namespace SM103 {
  // Common mma_unpack for all MMA_Ops in cute::SM103
template <class MMA_Op,
          class TD, class DLayout,
          class TA, class ALayout,
          class TB, class BLayout,
          class TC, class CLayout>
CUTE_HOST_DEVICE constexpr
void
mma_unpack(MMA_Traits<MMA_Op> const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& zA,
             Tensor<TB, BLayout> const& zB,
             Tensor<TC, CLayout> const& C)
  {
    auto [A, next_A, SFA] = unzip_tensor(zA);
    auto [B, next_B, SFB] = unzip_tensor(zB);

    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<TA>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_next_a = next_A[0];
    uint64_t desc_b = B[0];
    uint64_t desc_next_b = next_B[0];

    auto desc_a_temp = reinterpret_cast<UMMA::SmemDescriptor &>(desc_a);
    auto desc_next_a_temp = reinterpret_cast<UMMA::SmemDescriptor &>(desc_next_a);
    desc_a_temp.lbo_mode_ = 1;
    desc_a_temp.leading_byte_offset_ = desc_next_a_temp.start_address_;

    auto desc_b_temp = reinterpret_cast<UMMA::SmemDescriptor &>(desc_b);
    auto desc_next_b_temp = reinterpret_cast<UMMA::SmemDescriptor &>(desc_next_b);
    desc_b_temp.lbo_mode_ = 1;
    desc_b_temp.leading_byte_offset_ = desc_next_b_temp.start_address_;

    uint32_t tmem_c = raw_pointer_cast(D.data());
    UMMA::InstrDescriptorBlockScaled instr_desc =  traits.idesc_;
    instr_desc.k_size_ = 1;
    auto tsfa_addr = raw_pointer_cast(SFA.data());
    auto tsfb_addr = raw_pointer_cast(SFB.data());

    uint64_t idesc = UMMA::make_runtime_instr_desc_block_scaled<>(instr_desc, tsfa_addr, tsfb_addr);
    // print("a: "); print(A); print("\n");
    // print("b: "); print(B); print("\n");

    MMA_Op::fma(reinterpret_cast<uint64_t &>(desc_a_temp), reinterpret_cast<uint64_t &>(desc_b_temp), tmem_c, uint32_t(traits.accumulate_), idesc, tsfa_addr, tsfb_addr);
  }
} // end namespace SM103


template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM103::SM103_MXF4_ULTRA_SS_VS<a_type, b_type, c_type, sf_type,
                                M, N, VS, a_major, b_major,
                                a_neg, b_neg>>
{
  using ValTypeD   = c_type;
  using ValTypeA   = a_type;
  using ValTypeB   = b_type;
  using ValTypeC   = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;

  // Logical shape-K is always 256bits, transform to units of elements
  constexpr static int K = 96;
  constexpr static int SFVecSize = VS;

  static_assert(a_major == UMMA::Major::K && b_major == UMMA::Major::K, "This MMA does not support transpose");

  using FrgTypeA   = UMMA::smem_desc<a_major>;
  using FrgTypeB   = UMMA::smem_desc<b_major>;
  using FrgTypeC   = UMMA::tmem_frg_1sm<c_type>;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, true>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 1, false>;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;

  using MMA_ScaleFactor = SM100_MMA_MXF4_SS<a_type, b_type, c_type, sf_type,
                              M, (round_up(N, 128)), VS, a_major, b_major,
                              a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg>
struct MMA_Traits<SM103::SM103_MXF4_ULTRA_2x1SM_SS_VS<a_type, b_type, c_type, sf_type,
                                M, N, VS, a_major, b_major,
                                a_neg, b_neg>>
{
  using ValTypeD   = c_type;
  using ValTypeA   = a_type;
  using ValTypeB   = b_type;
  using ValTypeC   = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;

  // Logical shape-K is always 256bits, transform to units of elements
  constexpr static int K = 96;
  constexpr static int SFVecSize = VS;

  static_assert(a_major == UMMA::Major::K && b_major == UMMA::Major::K, "This MMA does not support transpose");

  using FrgTypeA   = UMMA::smem_desc<a_major>;
  using FrgTypeB   = UMMA::smem_desc<b_major>;
  using FrgTypeC   = UMMA::tmem_frg_2sm<c_type>;
  constexpr static UMMA::TmemAllocMode TmemAlloc = M == 128 ?
      UMMA::TmemAllocMode::ScaleFactorDuplicated2by2 : UMMA::TmemAllocMode::ScaleFactorDuplicated4by1;
  using FrgTypeSFA = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2,  true, TmemAlloc>;
  using FrgTypeSFB = UMMA::tmem_sf_frg<sf_type, SFVecSize, 2, false, TmemAlloc>;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  using MMA_ScaleFactor = SM100_MMA_MXF4_SS<a_type, b_type, c_type, sf_type,
                                (M/2 > 64 ? M/2 : M), (round_up(N, 128)), VS, a_major, b_major,
                                a_neg, b_neg>;


  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::InstrDescriptorBlockScaled idesc_ = UMMA::make_instr_desc_block_scaled<
    a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();
};

} // end namespace cute
