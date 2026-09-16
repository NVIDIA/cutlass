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

#include <cute/arch/config.hpp>
#include <cute/arch/mma.hpp>
#include <cute/arch/mma_sm100.hpp>
#include <cute/arch/mma_sm107_desc.hpp>
#include <cute/arch/cluster_sm90.hpp>
#include <cute/numeric/numeric_types.hpp>

namespace cute
{

template <class a_type, class b_type, class c_type, int M, int N,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One,
          UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          UMMA::BMatrixBufferReuse b_reuse = UMMA::BMatrixBufferReuse::None>
struct SM107_MMA_F8F6F4_SS
{
  using DRegisters = void;
  using ARegisters = uint64_t[1];
  using BRegisters = uint64_t[1];
  using CRegisters = uint32_t[1];

  CUTE_HOST_DEVICE static void
  fma(uint64_t const& desc_a,
      uint64_t const& desc_b,
      uint32_t const& tmem_c,
      uint32_t const& scaleC,
      uint64_t const& idescE)
  {
#if defined(CUTE_ARCH_TCGEN05_RUBIN_F8F6F4_MMA_ENABLED)
    if (cute::elect_one_sync()) {
      static_assert(b_reuse == UMMA::BMatrixBufferReuse::None ||
                    b_reuse == UMMA::BMatrixBufferReuse::Keep ||
                    b_reuse == UMMA::BMatrixBufferReuse::Reuse,
                    "SM107_MMA_F8F6F4_SS::fma only expects b_reuse in {None, Keep, Reuse}.");

      uint32_t mask[4] = {0, 0, 0, 0};
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Keep) {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::1.kind::f8f6f4.collector::b::fill [%0], %1, %2, %3, {%5, %6, %7, %8}, p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(mask[0]), "r"(mask[1]), "r"(mask[2]), "r"(mask[3]));
      } else
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Reuse) {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::1.kind::f8f6f4.collector::b::lastuse [%0], %1, %2, %3, {%5, %6, %7, %8}, p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(mask[0]), "r"(mask[1]), "r"(mask[2]), "r"(mask[3]));
      } else {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::1.kind::f8f6f4 [%0], %1, %2, %3, {%5, %6, %7, %8}, p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(mask[0]), "r"(mask[1]), "r"(mask[2]), "r"(mask[3]));
      }
    }
#else
    CUTE_INVALID_CONTROL_PATH("Attempting to use SM107_MMA_F8F6F4_SS without CUTE_ARCH_TCGEN05_RUBIN_F8F6F4_MMA_ENABLED");
#endif
  }
};

template <class a_type, class b_type, class c_type, int M, int N,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One,
          UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          UMMA::BMatrixBufferReuse b_reuse = UMMA::BMatrixBufferReuse::None>
struct SM107_MMA_F8F6F4_2x1SM_SS
{
  using DRegisters = void;
  using ARegisters = uint64_t[1];
  using BRegisters = uint64_t[1];
  using CRegisters = uint32_t[1];

  CUTE_HOST_DEVICE static void
  fma(uint64_t const& desc_a,
      uint64_t const& desc_b,
      uint32_t const& tmem_c,
      uint32_t const& scaleC,
      uint64_t const& idescE)
  {
#if defined(CUTE_ARCH_TCGEN05_RUBIN_F8F6F4_MMA_ENABLED)
    if (cute::elect_one_sync()) {
      static_assert(b_reuse == UMMA::BMatrixBufferReuse::None ||
                    b_reuse == UMMA::BMatrixBufferReuse::Keep ||
                    b_reuse == UMMA::BMatrixBufferReuse::Reuse,
                    "SM107_MMA_F8F6F4_2x1SM_SS::fma only expects b_reuse in {None, Keep, Reuse}.");
      uint32_t mask[8] = {0, 0, 0, 0, 0, 0, 0, 0};
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Keep) {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::2.kind::f8f6f4.collector::b::fill [%0], %1, %2, %3, {%5, %6, %7, %8, %9, %10, %11, %12}, p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(mask[0]), "r"(mask[1]), "r"(mask[2]), "r"(mask[3]),
            "r"(mask[4]), "r"(mask[5]), "r"(mask[6]), "r"(mask[7]));
      } else
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Reuse) {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::2.kind::f8f6f4.collector::b::lastuse [%0], %1, %2, %3, {%5, %6, %7, %8, %9, %10, %11, %12}, p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(mask[0]), "r"(mask[1]), "r"(mask[2]), "r"(mask[3]),
            "r"(mask[4]), "r"(mask[5]), "r"(mask[6]), "r"(mask[7]));
      } else {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::2.kind::f8f6f4 [%0], %1, %2, %3, {%5, %6, %7, %8, %9, %10, %11, %12}, p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(mask[0]), "r"(mask[1]), "r"(mask[2]), "r"(mask[3]),
            "r"(mask[4]), "r"(mask[5]), "r"(mask[6]), "r"(mask[7]));
      }
    }
#else
    CUTE_INVALID_CONTROL_PATH("Attempting to use SM107_MMA_F8F6F4_2x1SM_SS without CUTE_ARCH_TCGEN05_RUBIN_F8F6F4_MMA_ENABLED");
#endif
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One,
          UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          UMMA::BMatrixBufferReuse b_reuse = UMMA::BMatrixBufferReuse::None>
struct SM107_MMA_MXF8F6F4_SS
{
  static_assert(M == 128, "SM107_MMA_MXF8F6F4_SS M-mode size should be 128 for 1 CTA cluster MMA.");
  static_assert((N % 8 == 0) && (8 <= N) && (N <= 256), "SM107_MMA_MXF8F6F4_SS N-mode size should be a multiple of 8 between 8 and 256.");

  using DRegisters   = void;
  using ARegisters   = uint64_t[1];
  using BRegisters   = uint64_t[1];
  using CRegisters   = uint32_t[1];
  using SFARegisters = uint32_t[1];
  using SFBRegisters = uint32_t[1];

  CUTE_HOST_DEVICE static void
  fma(uint64_t const& desc_a,
      uint64_t const& desc_b,
      uint32_t const& tmem_c,
      uint32_t const& scaleC,
      uint64_t const& idescE,
      uint32_t const& tsfa_addr,
      uint32_t const& tsfb_addr)
  {
#if defined(CUTE_ARCH_TCGEN05_RUBIN_F8F6F4_MMA_ENABLED)
    if (cute::elect_one_sync()) {
      static_assert(b_reuse == UMMA::BMatrixBufferReuse::None ||
                    b_reuse == UMMA::BMatrixBufferReuse::Keep ||
                    b_reuse == UMMA::BMatrixBufferReuse::Reuse,
                    "SM107_MMA_MXF8F6F4_SS::fma only expects b_reuse in {None, Keep, Reuse}.");
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Keep) {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::1.kind::mxf8f6f4.block_scale.collector::b::fill [%0], %1, %2, %3, [%5], [%6], p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(tsfa_addr), "r"(tsfb_addr));
      } else
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Reuse) {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::1.kind::mxf8f6f4.block_scale.collector::b::lastuse [%0], %1, %2, %3, [%5], [%6], p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(tsfa_addr), "r"(tsfb_addr));
      } else {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::1.kind::mxf8f6f4.block_scale [%0], %1, %2, %3, [%5], [%6], p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(tsfa_addr), "r"(tsfb_addr));
      }
    }
#else
    CUTE_INVALID_CONTROL_PATH("Attempting to use SM107_MMA_MXF8F6F4_SS without CUTE_ARCH_TCGEN05_RUBIN_F8F6F4_MMA_ENABLED");
#endif
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One,
          UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          UMMA::BMatrixBufferReuse b_reuse = UMMA::BMatrixBufferReuse::None>
struct SM107_MMA_MXF8F6F4_2x1SM_SS
{
  static_assert(M == 256, "SM107_MMA_MXF8F6F4_2x1SM_SS M-mode size should be 256 for 2 CTA cluster MMA.");
  static_assert((N % 16 == 0) && (16 <= N) && (N <= 256), "SM107_MMA_MXF8F6F4_2x1SM_SS N-mode size should be a multiple of 16 between 16 and 256.");

  using DRegisters   = void;
  using ARegisters   = uint64_t[1];
  using BRegisters   = uint64_t[1];
  using CRegisters   = uint32_t[1];
  using SFARegisters = uint32_t[1];
  using SFBRegisters = uint32_t[1];

  CUTE_HOST_DEVICE static void
  fma(uint64_t const& desc_a,
      uint64_t const& desc_b,
      uint32_t const& tmem_c,
      uint32_t const& scaleC,
      uint64_t const& idescE,
      uint32_t const& tsfa_addr,
      uint32_t const& tsfb_addr)
  {
#if defined(CUTE_ARCH_TCGEN05_RUBIN_F8F6F4_MMA_ENABLED)
    if (cute::elect_one_sync()) {
      static_assert(b_reuse == UMMA::BMatrixBufferReuse::None ||
                    b_reuse == UMMA::BMatrixBufferReuse::Keep ||
                    b_reuse == UMMA::BMatrixBufferReuse::Reuse,
                    "SM107_MMA_MXF8F6F4_2x1SM_SS::fma only expects b_reuse in {None, Keep, Reuse}.");
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Keep) {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::2.kind::mxf8f6f4.block_scale.collector::b::fill [%0], %1, %2, %3, [%5], [%6], p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(tsfa_addr), "r"(tsfb_addr));
      } else
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Reuse) {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::2.kind::mxf8f6f4.block_scale.collector::b::lastuse [%0], %1, %2, %3, [%5], [%6], p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(tsfa_addr), "r"(tsfb_addr));
      } else {
        asm volatile(
          "{\n\t"
          ".reg .pred p;\n\t"
          "setp.ne.b32 p, %4, 0;\n\t"
          "tcgen05.mma.cta_group::2.kind::mxf8f6f4.block_scale [%0], %1, %2, %3, [%5], [%6], p; \n\t"
          "}\n"
          :
          : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
            "r"(tsfa_addr), "r"(tsfb_addr));
      }
    }
#else
    CUTE_INVALID_CONTROL_PATH("Attempting to use SM107_MMA_MXF8F6F4_2x1SM_SS without CUTE_ARCH_TCGEN05_RUBIN_F8F6F4_MMA_ENABLED");
#endif
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One,
          UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          UMMA::BMatrixBufferReuse b_reuse = UMMA::BMatrixBufferReuse::None>
struct SM107_MMA_MXF4NVF4_SS
{
  static_assert(M == 128, "SM107_MMA_MXF4NVF4_SS M-mode size should be 128 for 1 CTA cluster MMA.");
  static_assert((N % 8 == 0) && (8 <= N) && (N <= 256),
                "SM107_MMA_MXF4NVF4_SS N-mode size should be a multiple of 8 between 8 and 256.");
  static_assert((VS == 16) || (VS == 32),
                "SM107_MMA_MXF4NVF4_SS Vector size can only be 16 or 32.");
  static_assert(is_same_v<sf_type, cutlass::float_ue8m0_t> ||
                is_same_v<sf_type, cutlass::float_e4m3_t > ||
                is_same_v<sf_type, cutlass::float_ue5m3_t>,
                "SF data type can only be one of {ue8m0, e4m3, or ue5m3}.");

  using DRegisters   = void;
  using ARegisters   = uint64_t[1];
  using BRegisters   = uint64_t[1];
  using CRegisters   = uint32_t[1];
  using SFARegisters = uint32_t[1];
  using SFBRegisters = uint32_t[1];

  CUTE_HOST_DEVICE static void
  fma(uint64_t const& desc_a,
      uint64_t const& desc_b,
      uint32_t const& tmem_c,
      uint32_t const& scaleC,
      uint64_t const& idescE,
      uint32_t const& tsfa_addr,
      uint32_t const& tsfb_addr)
  {
#if defined(CUTE_ARCH_TCGEN05_RUBIN_MXF4NVF4_MMA_ENABLED)
    if (cute::elect_one_sync()) {
      static_assert(b_reuse == UMMA::BMatrixBufferReuse::None ||
                    b_reuse == UMMA::BMatrixBufferReuse::Keep ||
                    b_reuse == UMMA::BMatrixBufferReuse::Reuse,
                    "SM107_MMA_MXF4NVF4_SS::fma only expects b_reuse in {None, Keep, Reuse}.");
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Keep) {
        if constexpr (VS == 16) {
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::1.kind::mxf4nvf4.block_scale.block16.collector::b::fill [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        } else { // VS == 32
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::1.kind::mxf4nvf4.block_scale.block32.collector::b::fill [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        }
      } else
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Reuse) {
        if constexpr (VS == 16) {
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::1.kind::mxf4nvf4.block_scale.block16.collector::b::lastuse [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        } else { // VS == 32
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::1.kind::mxf4nvf4.block_scale.block32.collector::b::lastuse [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        }
      } else {
        if constexpr (VS == 16) {
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::1.kind::mxf4nvf4.block_scale.block16 [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        } else { // VS == 32
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::1.kind::mxf4nvf4.block_scale.block32 [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        }
      }
    }
#else
    CUTE_INVALID_CONTROL_PATH("Attempting to use SM107_MMA_MXF4NVF4_SS without CUTE_ARCH_TCGEN05_RUBIN_MXF4NVF4_MMA_ENABLED");
#endif
  }
};

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, int VS,
          UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One,
          UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          UMMA::BMatrixBufferReuse b_reuse = UMMA::BMatrixBufferReuse::None>
struct SM107_MMA_MXF4NVF4_2x1SM_SS
{
  static_assert(M == 256,
                "SM107_MMA_MXF4NVF4_2x1SM_SS M-mode size should be 256 for 2 CTA cluster MMA.");
  static_assert((N % 8 == 0) && (8 <= N) && (N <= 256),
                "SM107_MMA_MXF4NVF4_2x1SM_SS N-mode size should be a multiple of 8 between 8 and 256.");
  static_assert((VS == 16) || (VS == 32),
                "SM107_MMA_MXF4NVF4_2x1SM_SS Vector size can only be 16 or 32.");
  static_assert(is_same_v<sf_type, cutlass::float_ue8m0_t> ||
                is_same_v<sf_type, cutlass::float_e4m3_t > ||
                is_same_v<sf_type, cutlass::float_ue5m3_t>,
                "SF data type can only be one of {ue8m0, e4m3, or ue5m3}.");

  using DRegisters   = void;
  using ARegisters   = uint64_t[1];
  using BRegisters   = uint64_t[1];
  using CRegisters   = uint32_t[1];
  using SFARegisters = uint32_t[1];
  using SFBRegisters = uint32_t[1];

  CUTE_HOST_DEVICE static void
  fma(uint64_t const& desc_a,
      uint64_t const& desc_b,
      uint32_t const& tmem_c,
      uint32_t const& scaleC,
      uint64_t const& idescE,
      uint32_t const& tsfa_addr,
      uint32_t const& tsfb_addr)
  {
#if defined(CUTE_ARCH_TCGEN05_RUBIN_MXF4NVF4_MMA_ENABLED)
    if (cute::elect_one_sync()) {
      static_assert(b_reuse == UMMA::BMatrixBufferReuse::None ||
                    b_reuse == UMMA::BMatrixBufferReuse::Keep ||
                    b_reuse == UMMA::BMatrixBufferReuse::Reuse,
                    "SM107_MMA_MXF4NVF4_2x1SM_SS::fma only expects b_reuse in {None, Keep, Reuse}.");
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Keep) {
        if constexpr (VS == 16) {
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::2.kind::mxf4nvf4.block_scale.block16.collector::b::fill [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        } else { // VS == 32
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::2.kind::mxf4nvf4.block_scale.block32.collector::b::fill [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        }
      } else
      if constexpr (b_reuse == UMMA::BMatrixBufferReuse::Reuse) {
        if constexpr (VS == 16) {
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::2.kind::mxf4nvf4.block_scale.block16.collector::b::lastuse [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        } else { // VS == 32
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::2.kind::mxf4nvf4.block_scale.block32.collector::b::lastuse [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        }
      } else {
        if constexpr (VS == 16) {
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::2.kind::mxf4nvf4.block_scale.block16 [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        } else { // VS == 32
          asm volatile(
            "{\n\t"
            ".reg .pred p;\n\t"
            "setp.ne.b32 p, %4, 0;\n\t"
            "tcgen05.mma.cta_group::2.kind::mxf4nvf4.block_scale.block32 [%0], %1, %2, %3, [%5], [%6], p; \n\t"
            "}\n"
            :
            : "r"(tmem_c), "l"(desc_a), "l"(desc_b), "r"(uint32_t(idescE>>32)), "r"(scaleC),
              "r"(tsfa_addr), "r"(tsfb_addr));
        }
      }
    }
#else
    CUTE_INVALID_CONTROL_PATH("Attempting to use SM107_MMA_MXF4NVF4_2x1SM_SS without CUTE_ARCH_TCGEN05_RUBIN_MXF4NVF4_MMA_ENABLED");
#endif
  }
};

} // end namespace cute
