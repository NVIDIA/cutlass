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

#include <cute/arch/mma_sm100_desc.hpp>

namespace cute {

namespace UMMA {

CUTE_HOST_DEVICE constexpr
uint32_t
set_sm107_runtime_scale_factor_ids(uint32_t desc,
                                   uint32_t const tmem_sfa_addr,
                                   uint32_t const tmem_sfb_addr)
{
  constexpr uint32_t a_sf_id_mask = uint32_t(0x3) << 29;
  constexpr uint32_t b_sf_id_mask = uint32_t(0x3) << 4;
  uint32_t const a_sf_id = (tmem_sfa_addr >> 30) & uint32_t(0x3);
  uint32_t const b_sf_id = (tmem_sfb_addr >> 30) & uint32_t(0x3);
  return (desc & ~(a_sf_id_mask | b_sf_id_mask)) |
         (a_sf_id << 29) | (b_sf_id << 4);
}

union Sm107MXF8F6F4InstrDescriptor
{
  uint32_t desc_;

  struct {
    // Bitfield implementation avoids the need for shifts in assignment
    uint16_t reserved_      : 2,  // bit [ 0, 2) : reserved
             sparse_flag_   : 1,  // bit [ 2, 3) : 0 = dense, 1 = sparse
                            : 1,  // bit [ 3, 4) : reserved
             b_sf_id_       : 2,  // bit [ 4, 6) : Matrix B Scale Factor ID (SFB_ID)
                            : 1,  // reserved
             a_format_      : 3,  // bit [7, 10) : MXF8F6F4Format:0 = E4M3, 1 = E5M2, 2 = invalid, 3 = E2M3, 4 = E3M2, 5 = E2M1.
             b_format_      : 3,  // bit [10,13) : MXF8F6F4Format:0 = E4M3, 1 = E5M2, 2 = invalid, 3 = E2M3, 4 = E3M2, 5 = E2M1.
             a_negate_      : 1,  // bit [13,14) : 0 = no negate. 1 = negate.
             b_negate_      : 1,  // bit [14,15) : 0 = no negate. 1 = negate.
             a_major_       : 1;  // bit [15,16) : 0 = K-major. 1 = MN-major.
    uint16_t b_major_       : 1,  // bit [16,17) : 0 = K-major. 1 = MN-major.
             n_dim_         : 6,  // bit [17,23) : 3 LSBs not included. Valid values range from 1 (N=8) to 32 (N=256).
             scale_format_  : 2,  // bit [23,25) : Format for both SF_A and SF_B. 0=invalid, 1=E8, 2=invalid.
                            : 1,  // bit [25,26) : reserved
                            : 1,  // bit [26,27) : reserved
             m_dim_         : 2,  // bit [27,29) : 7 LSBs not included. Valid values are: 1 (M=128), 2 (M=256)
             a_sf_id_       : 2,  // bit [29,31) : Matrix A Scale Factor ID
             k_size_        : 1;  // bit [31,32) : K size. 0=[dense: K32, sparse: K64], 1=[dense: K64, sparse: K128].
  };

  // Decay to a uint32_t
  CUTE_HOST_DEVICE constexpr
  operator uint32_t() const noexcept { return desc_; }
};

// Specialized helper to create instruction descriptor for SM107 (K=64)
template <class a_type, class b_type, class c_type, class sf_type, int M, int N,
          Major a_major, Major b_major,
          ScaleIn a_neg = ScaleIn::One,
          ScaleIn b_neg = ScaleIn::One, bool is_sparse = false
          >
CUTE_HOST_DEVICE constexpr
Sm107MXF8F6F4InstrDescriptor
make_sm107_mxf8f6f4_instr_desc()
{
  Sm107MXF8F6F4InstrDescriptor desc_i = {};

  desc_i.a_format_ = uint8_t(to_UMMAFormat<a_type>());
  desc_i.b_format_ = uint8_t(to_UMMAFormat<b_type>());

  desc_i.scale_format_ = uint8_t(to_ScaleFormat<sf_type>());
  desc_i.m_dim_ = (M >> 7); // 7 LSBs not included
  desc_i.n_dim_ = (N >> 3); // 3 LSBs not included
  desc_i.k_size_ = uint8_t(1); // dense: K64, sparse: K128

  desc_i.a_major_ = uint8_t(a_major);
  desc_i.b_major_ = uint8_t(b_major);

  desc_i.a_negate_ = uint8_t(a_neg);
  desc_i.b_negate_ = uint8_t(b_neg);

  desc_i.sparse_flag_   = uint8_t(is_sparse);    // 1 = Sparse
  return desc_i;
}

CUTE_HOST_DEVICE
constexpr uint64_t
make_runtime_sm107_mxf8f6f4_instr_desc(Sm107MXF8F6F4InstrDescriptor desc_i,
                                       uint32_t const tmem_sfa_addr,
                                       uint32_t const tmem_sfb_addr)
{
  // The first 2-bits of TMEM address includes byte address.
  desc_i.desc_ = set_sm107_runtime_scale_factor_ids(
      desc_i.desc_, tmem_sfa_addr, tmem_sfb_addr);

  // In current compiler exposure, idescE is a uint64_t. It should contain:
  // -  Lower 32b URe: Specifies the tmem address that stores the sparse metadata.
  //                   Only needed for Sparse MMA instructions. Otherwise, ignored.
  // -  Upper 32b URh: Specifies the instruction descriptor.
  uint64_t idescE =  (static_cast<uint64_t>(static_cast<uint32_t>(desc_i)) << 32);

  return idescE;
}

union Sm107MXF4NVF4InstrDescriptor {
  uint32_t desc_;

  struct {
    // Bitfield implementation avoids the need for shifts in assignment
    uint16_t reserved_      : 2,  // bit [ 0, 2) : reserved
             sparse_flag_   : 1,  // bit [ 2, 3) : 0 = dense, 1 = sparse
             k_size_upper_  : 1,  // bit [ 3, 4) : K size upper bit. Combined with k_size_lower_ at bit 31.
             b_sf_id_       : 2,  // bit [ 4, 6) : Matrix B Scale Factor ID (SFB_ID)
                            : 1,  // reserved
             a_format_      : 3,  // bit [ 7,10) : 0=invalid, 1=E2M1.
             b_format_      : 2,  // bit [10,12) : 0=invalid, 1=E2M1.
             sparsity_ver_  : 1,  // bit [12,13) : 0 = Blackwell (invalid if Sparse=1), 1 = Rubin.
             a_negate_      : 1,  // bit [13,14) : 0 = no negate. 1 = negate.
             b_negate_      : 1,  // bit [14,15) : 0 = no negate. 1 = negate.
             a_major_       : 1;  // bit [15,16) : 0 = K-major. 1 = invalid.
    uint16_t b_major_       : 1,  // bit [16,17) : 0 = K-major. 1 = invalid.
             n_dim_         : 6,  // bit [17,23) : 3 LSBs not included. Valid values range from 1 (N=8) to 32 (N=256).
             scale_format_  : 2,  // bit [23,25) : Format for both SF_A and SF_B. 0=UE4M3, 1=E8, 2=UE5M3.
                            : 1,  // bit [25,26) : reserved
                            : 1,  // bit [26,27) : reserved
             m_dim_         : 2,  // bit [27,29) : 7 LSBs not included. Valid values are: 1 (M=128), 2 (M=256).
             a_sf_id_       : 2,  // bit [29,31) : Matrix A Scale Factor ID.
             k_size_lower_  : 1;  // bit [31,32) : K size lower bit. Combined with k_size_upper_ at bit 3:
                                  //   {upper,lower}=0 -> dense:K64/sparse:K128
                                  //   {upper,lower}=1 -> dense:K96/sparse:K192
                                  //   {upper,lower}=2 -> dense:K128/sparse:invalid
  };

  // Decay to a uint32_t
  CUTE_HOST_DEVICE constexpr
  operator uint32_t() const noexcept { return desc_; }
};

// Scale format mapping for Sm107MXF4NVF4InstrDescriptor: 0=UE4M3, 1=UE8M0(E8), 2=UE5M3
template <class T>
CUTE_HOST_DEVICE constexpr uint8_t
to_Sm107MXF4NVF4ScaleFormat() {
  if constexpr (is_same_v<T, cutlass::float_ue4m3_t>) { return 0; } else
  if constexpr (is_same_v<T, cutlass::float_ue8m0_t>) { return 1; } else
  if constexpr (is_same_v<T, cutlass::float_ue5m3_t>) { return 2; } else
  { static_assert(sizeof(T) == 0, "Unknown scale type for Sm107MXF4NVF4ScaleFormat"); }
}

// Builder for SM107 MXF4NVF4 instruction descriptor (K=128, 4-bit x 128 = 512-bit operands)
template <class a_type, class b_type, class c_type, class sf_type, int M, int N,
          Major a_major, Major b_major,
          ScaleIn a_neg = ScaleIn::One,
          ScaleIn b_neg = ScaleIn::One, bool is_sparse = false>
CUTE_HOST_DEVICE constexpr
Sm107MXF4NVF4InstrDescriptor
make_sm107_mxf4nvf4_instr_desc()
{
  Sm107MXF4NVF4InstrDescriptor desc_i = {};
  static_assert(is_same_v<a_type, cutlass::float_e2m1_t> && is_same_v<b_type, cutlass::float_e2m1_t>,
                "");
  desc_i.a_format_      = uint8_t(to_UMMAFormat<a_type>());
  desc_i.b_format_      = uint8_t(to_UMMAFormat<b_type>());

  desc_i.scale_format_  = to_Sm107MXF4NVF4ScaleFormat<sf_type>();
  desc_i.m_dim_         = (M >> 7);  // 7 LSBs not included
  desc_i.n_dim_         = (N >> 3);  // 3 LSBs not included

  // K=128 for SM107 dense MXF4NVF4 (4-bit x 128 = 512 bits): {upper,lower} = 2 = {1,0}
  desc_i.k_size_upper_  = uint8_t(1);
  desc_i.k_size_lower_  = uint8_t(0);

  desc_i.a_major_       = uint8_t(a_major);
  desc_i.b_major_       = uint8_t(b_major);

  desc_i.a_negate_      = uint8_t(a_neg);
  desc_i.b_negate_      = uint8_t(b_neg);

  desc_i.sparse_flag_   = uint8_t(is_sparse);
  desc_i.sparsity_ver_  = uint8_t(is_sparse); // Rubin
  return desc_i;
}

CUTE_HOST_DEVICE
constexpr uint64_t
make_runtime_sm107_mxf4nvf4_instr_desc(Sm107MXF4NVF4InstrDescriptor desc_i,
                                       uint32_t const tmem_sfa_addr,
                                       uint32_t const tmem_sfb_addr)
{
  // The first 2-bits of TMEM address encode the byte address within the 4-byte word.
  desc_i.desc_ = set_sm107_runtime_scale_factor_ids(
      desc_i.desc_, tmem_sfa_addr, tmem_sfb_addr);

  // idescE layout: upper 32b = instruction descriptor, lower 32b = sparse metadata TMEM addr.
  uint64_t idescE = (static_cast<uint64_t>(static_cast<uint32_t>(desc_i)) << 32);

  return idescE;
}

} // namespace UMMA

} // namespace cute
