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
#include <cute/arch/mma_sm107_desc.hpp>
#include <cute/arch/mma_sm107_umma.hpp>
#include <cute/atom/mma_traits_sm100_frag.hpp>  // UMMA::smem_desc, tmem_frg_1sm/2sm
#include <cute/atom/mma_traits_sm100.hpp>       // UMMA::make_runtime_instr_desc, MMA_Traits<>
#include <cute/tensor_zip.hpp>

namespace cute {

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::BMatrixBufferReuse b_reuse>
struct MMA_Traits<SM107_MMA_F8F6F4_SS<a_type, b_type, c_type,
                                      M, N, a_major, b_major,
                                      a_neg, b_neg, b_reuse>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8,
                "SM107_MMA_F8F6F4_SS supports types with 8bit types");
  static_assert(M == 128, "SM107_MMA_F8F6F4_SS M-mode size should be 128 for 1 CTA cluster MMA.");
  static_assert((N % 16 == 0) && (16 <= N) && (N <= 256),
                "SM107_MMA_F8F6F4_SS N-mode size should be a multiple of 16 between 16 and 256.");
  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;

  constexpr static int K = 64;

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

  UMMA::InstrDescriptor idesc_ = UMMA::make_sm107_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

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
    static_assert(is_rmem<TA>::value,
                  "Expected desc registers in MMA_Atom::call");
    static_assert(is_rmem<TB>::value,
                  "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_instr_desc<>(traits.idesc_);

    SM107_MMA_F8F6F4_SS<a_type, b_type, c_type, M, N, a_major, b_major, a_neg,
                        b_neg, b_reuse>::fma(desc_a, desc_b, tmem_c,
                                    uint32_t(traits.accumulate_), idesc);
  }

  template <UMMA::BMatrixBufferReuse new_b_reuse>
  CUTE_HOST_DEVICE constexpr
  auto with(C<new_b_reuse>) const {
      return MMA_Traits<SM107_MMA_F8F6F4_SS<a_type, b_type, c_type,
                                            M, N, a_major, b_major,
                                            a_neg, b_neg, new_b_reuse>>{accumulate_, idesc_};
  }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::BMatrixBufferReuse b_reuse>
struct MMA_Traits<SM107_MMA_F8F6F4_2x1SM_SS<a_type, b_type, c_type,
                                            M, N, a_major, b_major,
                                            a_neg, b_neg, b_reuse>>
{

  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8,
                "SM107_MMA_F8F6F4_2x1SM_SS supports types with 8bit types");
  static_assert(M == 256, "SM107_MMA_F8F6F4_2x1SM_SS M-mode size should be 256 for 2 CTA cluster MMA.");
  static_assert((N % 32 == 0) && (32 <= N) && (N <= 256),
                "SM107_MMA_F8F6F4_2x1SM_SS N-mode size should be a multiple of 32 between 32 and 256.");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  constexpr static int K = 64;

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

  UMMA::InstrDescriptor idesc_ = UMMA::make_sm107_instr_desc<a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg>();

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

    SM107_MMA_F8F6F4_2x1SM_SS<a_type, b_type, c_type, M, N, a_major, b_major, a_neg,
                        b_neg, b_reuse>::fma(desc_a, desc_b, tmem_c,
                                    uint32_t(traits.accumulate_), idesc);
  }

  template <UMMA::BMatrixBufferReuse new_b_reuse>
  CUTE_HOST_DEVICE constexpr
  auto with(C<new_b_reuse>) const {
      return MMA_Traits<SM107_MMA_F8F6F4_2x1SM_SS<a_type, b_type, c_type,
                                                  M, N, a_major, b_major,
                                                  a_neg, b_neg, new_b_reuse>>{accumulate_, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::BMatrixBufferReuse b_reuse>
struct MMA_Traits<SM107_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                                        M, N, a_major, b_major,
                                        a_neg, b_neg, b_reuse>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8,
                "SM107_MMA_MXF8F6F4_SS supports types with leq 8bit types");

  // Logical shape-K is always 512bits for SM107, transform to units of elements
  constexpr static int K = 64;
  constexpr static int SFVecSize = 32;

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;
  using FrgTypeSFA = UMMA::sm107_tmem_sf_frg<sf_type, SFVecSize, 1, true>;
  using FrgTypeSFB = UMMA::sm107_tmem_sf_frg<sf_type, SFVecSize, 1, false>;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using MMA_ScaleFactor = SM107_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                              M, (round_up(N, 128)), a_major, b_major,
                              a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::Sm107MXF8F6F4InstrDescriptor idesc_ = UMMA::make_sm107_mxf8f6f4_instr_desc<
        a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& zA,
             Tensor<TB, BLayout> const& zB,
             Tensor<TC, CLayout> const& C)
  {
    auto [A, SFA] = unzip_tensor(zA);
    auto [B, SFB] = unzip_tensor(zB);

    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<decltype(A)>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<decltype(SFA)>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<decltype(B)>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<decltype(SFB)>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tsfa_addr = raw_pointer_cast(SFA.data());
    uint32_t tsfb_addr = raw_pointer_cast(SFB.data());
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_sm107_mxf8f6f4_instr_desc(
        traits.idesc_, tsfa_addr, tsfb_addr);

    SM107_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                          M, N, a_major, b_major,
                          a_neg, b_neg, b_reuse>::fma(desc_a, desc_b, tmem_c,
                                                      uint32_t(traits.accumulate_), idesc,
                                                      tsfa_addr, tsfb_addr);
  }

  template <UMMA::BMatrixBufferReuse new_b_reuse>
  CUTE_HOST_DEVICE constexpr
  auto with(C<new_b_reuse>) const {
    return MMA_Traits<SM107_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                                            M, N, a_major, b_major,
                                            a_neg, b_neg, new_b_reuse>>{
        accumulate_, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::BMatrixBufferReuse b_reuse>
struct MMA_Traits<SM107_MMA_MXF8F6F4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                              M, N, a_major, b_major,
                                              a_neg, b_neg, b_reuse>>
{
  using ValTypeD   = c_type;
  using ValTypeA   = a_type;
  using ValTypeB   = b_type;
  using ValTypeC   = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> <= 8 && cute::sizeof_bits_v<b_type> <= 8,
                "SM107_MMA_MXF8F6F4_2x1SM_SS supports types with leq 8bit types");

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  // Logical shape-K is always 512bits for SM107, transform to units of elements
  constexpr static int K = 64;
  constexpr static int SFVecSize = 32;

  using FrgTypeSFA = UMMA::sm107_tmem_sf_frg<sf_type, SFVecSize, 2,  true>;
  using FrgTypeSFB = UMMA::sm107_tmem_sf_frg<sf_type, SFVecSize, 2, false>;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using MMA_ScaleFactor = SM107_MMA_MXF8F6F4_SS<a_type, b_type, c_type, sf_type,
                              (M/2 > 64 ? M/2 : M), (round_up(N, 128)), a_major, b_major,
                              a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::Sm107MXF8F6F4InstrDescriptor idesc_ = UMMA::make_sm107_mxf8f6f4_instr_desc<
        a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& zA,
             Tensor<TB, BLayout> const& zB,
             Tensor<TC, CLayout> const& C)
  {
    auto [A, SFA] = unzip_tensor(zA);
    auto [B, SFB] = unzip_tensor(zB);

    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<decltype(A)>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<decltype(SFA)>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<decltype(B)>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<decltype(SFB)>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tsfa_addr = raw_pointer_cast(SFA.data());
    uint32_t tsfb_addr = raw_pointer_cast(SFB.data());
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_sm107_mxf8f6f4_instr_desc(
        traits.idesc_, tsfa_addr, tsfb_addr);

    SM107_MMA_MXF8F6F4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                 M, N, a_major, b_major,
                                 a_neg, b_neg, b_reuse>::fma(desc_a, desc_b, tmem_c,
                                                             uint32_t(traits.accumulate_), idesc,
                                                             tsfa_addr, tsfb_addr);
  }

  template <UMMA::BMatrixBufferReuse new_b_reuse>
  CUTE_HOST_DEVICE constexpr
  auto with(C<new_b_reuse>) const {
    return MMA_Traits<SM107_MMA_MXF8F6F4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                                   M, N, a_major, b_major,
                                                   a_neg, b_neg, new_b_reuse>>{
        accumulate_, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::BMatrixBufferReuse b_reuse>
struct MMA_Traits<SM107_MMA_MXF4NVF4_SS<a_type, b_type, c_type, sf_type,
                                        M, N, VS, a_major, b_major,
                                        a_neg, b_neg, b_reuse>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> == 4 && cute::sizeof_bits_v<b_type> == 4,
                "SM107_MMA_MXF4NVF4_SS supports types with 4bit types");

  constexpr static int K = 128;
  constexpr static int SFVecSize = VS;

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_1sm<c_type>;
  using FrgTypeSFA = UMMA::sm107_tmem_sf_frg<sf_type, SFVecSize, 1, true>;
  using FrgTypeSFB = UMMA::sm107_tmem_sf_frg<sf_type, SFVecSize, 1, false>;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_1>;
  using ALayout = Layout<Shape <_1,Shape <Int<M>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using BLayout = Layout<Shape <_1,Shape <Int<N>,Int<K>>>,
                         Stride<_0,Stride<    _1,Int<N>>>>;
  using CLayout = Layout<Shape <_1,Shape <Int<M>,Int<N>>>,
                         Stride<_0,Stride<    _1,Int<M>>>>;
  using MMA_ScaleFactor = SM107_MMA_MXF4NVF4_SS<a_type, b_type, c_type, sf_type,
                              M, (round_up(N, 128)), SFVecSize, a_major, b_major,
                              a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;

  UMMA::Sm107MXF4NVF4InstrDescriptor idesc_ = UMMA::make_sm107_mxf4nvf4_instr_desc<
      a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& zA,
             Tensor<TB, BLayout> const& zB,
             Tensor<TC, CLayout> const& C)
  {
    auto [A, SFA] = unzip_tensor(zA);
    auto [B, SFB] = unzip_tensor(zB);

    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<decltype(A)>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<decltype(SFA)>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<decltype(B)>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<decltype(SFB)>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tsfa_addr = raw_pointer_cast(SFA.data());
    uint32_t tsfb_addr = raw_pointer_cast(SFB.data());
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_sm107_mxf4nvf4_instr_desc(
        traits.idesc_, tsfa_addr, tsfb_addr);

    SM107_MMA_MXF4NVF4_SS<a_type, b_type, c_type, sf_type,
                          M, N, VS, a_major, b_major,
                          a_neg, b_neg, b_reuse>::fma(desc_a, desc_b, tmem_c,
                                                      uint32_t(traits.accumulate_), idesc,
                                                      tsfa_addr, tsfb_addr);
  }

  template <UMMA::BMatrixBufferReuse new_b_reuse>
  CUTE_HOST_DEVICE constexpr
  auto with(C<new_b_reuse>) const {
    return MMA_Traits<SM107_MMA_MXF4NVF4_SS<a_type, b_type, c_type, sf_type,
                                            M, N, VS, a_major, b_major,
                                            a_neg, b_neg, new_b_reuse>>{
        accumulate_, idesc_};
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg, UMMA::ScaleIn b_neg,
          UMMA::BMatrixBufferReuse b_reuse>
struct MMA_Traits<SM107_MMA_MXF4NVF4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                              M, N, VS, a_major, b_major,
                                              a_neg, b_neg, b_reuse>>
{
  using ValTypeD = c_type;
  using ValTypeA = a_type;
  using ValTypeB = b_type;
  using ValTypeC = c_type;
  using ValTypeSFA = sf_type;
  using ValTypeSFB = sf_type;
  static_assert(cute::sizeof_bits_v<a_type> == 4 && cute::sizeof_bits_v<b_type> == 4,
                "SM107_MMA_MXF4NVF4_2x1SM_SS supports types with 4bit types");

  constexpr static int K = 128;
  constexpr static int SFVecSize = VS;

  using FrgTypeA = UMMA::smem_desc<a_major>;
  using FrgTypeB = UMMA::smem_desc<b_major>;
  using FrgTypeC = UMMA::tmem_frg_2sm<c_type>;

  using FrgTypeSFA = UMMA::sm107_tmem_sf_frg<sf_type, SFVecSize, 2, true>;
  using FrgTypeSFB = UMMA::sm107_tmem_sf_frg<sf_type, SFVecSize, 2, false>;

  using Shape_MNK = Shape<Int<M>,Int<N>,Int<K>>;
  using ThrID   = Layout<_2>;
  using ALayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<K>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;
  using BLayout = Layout<Shape <      _2,Shape <Int<N/2>,Int<K>>>,
                         Stride<Int<N/2>,Stride<      _1,Int<N>>>>;
  using CLayout = Layout<Shape <      _2,Shape <Int<M/2>,Int<N>>>,
                         Stride<Int<M/2>,Stride<      _1,Int<M>>>>;

  using MMA_ScaleFactor = SM107_MMA_MXF4NVF4_SS<a_type, b_type, c_type, sf_type,
                              M/2, (round_up(N, 128)), VS, a_major, b_major,
                              a_neg, b_neg>;

  // Accumulate or overwrite C.   1: read C, 0: ignore C [clear accumulators]
  UMMA::ScaleOut accumulate_ = UMMA::ScaleOut::One;
  uint32_t tsfa_addr_ = 0;
  uint32_t tsfb_addr_ = 0;

  UMMA::Sm107MXF4NVF4InstrDescriptor idesc_ = UMMA::make_sm107_mxf4nvf4_instr_desc<
      a_type, b_type, c_type, sf_type, M, N, a_major, b_major, a_neg, b_neg>();

  template <class TD, class DLayout,
            class TA, class ALayout,
            class TB, class BLayout,
            class TC, class CLayout>
  CUTE_HOST_DEVICE constexpr friend
  void
  mma_unpack(MMA_Traits          const& traits,
             Tensor<TD, DLayout>      & D,
             Tensor<TA, ALayout> const& zA,
             Tensor<TB, BLayout> const& zB,
             Tensor<TC, CLayout> const& C)
  {
    auto [A, SFA] = unzip_tensor(zA);
    auto [B, SFB] = unzip_tensor(zB);

    static_assert(is_tmem<TD>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<decltype(A)>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<decltype(SFA)>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_rmem<decltype(B)>::value, "Expected desc registers in MMA_Atom::call");
    static_assert(is_tmem<decltype(SFB)>::value, "Expected tmem in MMA_Atom::call");
    static_assert(is_tmem<TC>::value, "Expected tmem in MMA_Atom::call");

    uint64_t desc_a = A[0];
    uint64_t desc_b = B[0];
    uint32_t tsfa_addr = raw_pointer_cast(SFA.data());
    uint32_t tsfb_addr = raw_pointer_cast(SFB.data());
    uint32_t tmem_c = raw_pointer_cast(D.data());
    uint64_t idesc = UMMA::make_runtime_sm107_mxf4nvf4_instr_desc(
        traits.idesc_, tsfa_addr, tsfb_addr);

    SM107_MMA_MXF4NVF4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                M, N, VS, a_major, b_major,
                                a_neg, b_neg, b_reuse>::fma(desc_a, desc_b, tmem_c,
                                                      uint32_t(traits.accumulate_), idesc,
                                                      tsfa_addr, tsfb_addr);
  }

  template <UMMA::BMatrixBufferReuse new_b_reuse>
  CUTE_HOST_DEVICE constexpr
  auto with(C<new_b_reuse>) const {
    return MMA_Traits<SM107_MMA_MXF4NVF4_2x1SM_SS<a_type, b_type, c_type, sf_type,
                                                  M, N, VS, a_major, b_major,
                                                  a_neg, b_neg, new_b_reuse>>{
        accumulate_, tsfa_addr_, tsfb_addr_, idesc_};
  }
};


} // end namespace cute
