/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cuda_runtime.h"

#include <cutlass/cutlass.h>

#include <cute/tensor.hpp>
#include <cute/arch/copy_sm90_desc.hpp>

#include <iostream>
#include <type_traits>

#ifndef gpuErrChk
#define gpuErrChk(ans) { gpuAssert2((ans), __FILE__, __LINE__); }
inline void gpuAssert2(cudaError_t code, const char *file, int line, bool abort=true) {
  if (code != cudaSuccess) {
    fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
    if (abort) exit(code);
  }
}
#endif

namespace TGV {

using namespace cute;

// Store value to remote shared memory in the cluster
CUTE_DEVICE void
store_shared_remote_f32(float value, uint32_t dsmem_addr, uint32_t remote_barrier_addr) {
  asm volatile("st.async.shared::cluster.mbarrier::complete_tx::bytes.f32 [%0], %1, [%2];"
               : : "r"(dsmem_addr), "f"(value), "r"(remote_barrier_addr));
}

// given a smem tensor, return the dsmem tensor for the given rank, the tensor addr is in smem addr space (not generic addr space)
template <class Tensor>
CUTE_DEVICE auto
get_dsmem_tensor(Tensor tensor, int rank) {
  using T = typename decltype(tensor)::value_type;
  // tensor.data().get() is the smem addr in the generic addr space, in the generic addr space a region is reserved for smem
  // doing ld/st to this region of the generic addr space will be converted into ld.shared/st.shared to the smem addr space by the compiler
  // the mapa (and many inline ptx) instruction's input and output addr are in the smem/dsmem addr space, so we need to explicitly convert from generic to shared addr space
  uint32_t smem_addr = __cvta_generic_to_shared(tensor.data().get()); // smem addr space
  // mapa to get the dsmem addr of this tensor in another CTA
  uint32_t dsmem_addr = set_block_rank(smem_addr, rank); // smem addr space
  return make_tensor(make_smem_ptr((T*)dsmem_addr), tensor.layout());
}

// copied from SM100::TMEM::LOAD::copy_unpack cutlass/include/cute/atom/copy_traits_sm100.hpp
// what it does is given a tmem address, load the data into rmem tensor with the given tcgen05.ld copy op
template <
  class CopyOp,
  class TD, class DLayout>
CUTLASS_DEVICE void
tmem_load(
  uint32_t tmem_addr,
  Tensor<TD,DLayout>& dst
) {
  static_assert(is_rmem<TD>::value, "Expected RMEM dst.");

  using RegTypeDst = typename remove_extent<typename CopyOp::DRegisters>::type;
  Tensor rD = recast<RegTypeDst>(dst);

  constexpr int RegNumDst = extent<typename CopyOp::DRegisters>::value;
  CUTE_STATIC_ASSERT_V(size(rD) == Int<RegNumDst>{},
  "The tcgen05.ld CopyOp's size does not match the destination tensor size.");

  detail::explode(CopyOp::copy,
                  &tmem_addr, seq<0>{},
                  rD, make_seq<RegNumDst>{});
}

// copied from SM100::TMEM::STORE::copy_unpack cutlass/include/cute/atom/copy_traits_sm100.hpp
// what it does is given a tmem address, store the data in rmem tensor to the tmem address with the given tcgen05.st copy op
template <
  class CopyOp,
  class TS, class SLayout>
CUTLASS_DEVICE void
tmem_store(
  Tensor<TS,SLayout>& src,
  uint32_t tmem_addr
) {
  static_assert(is_rmem<TS>::value, "Expected RMEM src.");

  using RegTypeSrc = typename remove_extent<typename CopyOp::SRegisters>::type;
  Tensor rS = recast<RegTypeSrc>(src);

  constexpr int RegNumSrc = extent<typename CopyOp::SRegisters>::value;
  CUTE_STATIC_ASSERT_V(size(rS) == Int<RegNumSrc>{},
      "The tcgen05.st CopyOp's size does not match the source tensor size.");

  detail::explode(CopyOp::copy,
                  rS, make_seq<RegNumSrc>{},
                  &tmem_addr, seq<0>{});
}

// issue cp.async to load 4 bytes (one int) from gmem to smem
CUTLASS_DEVICE void
cp_async(
  int* gmem_addr,
  int* smem_addr
) {
  uint32_t smem_int_ptr = cute::cast_smem_ptr_to_uint(smem_addr);
  asm volatile("cp.async.ca.shared.global.L2::128B [%0], [%1], %2;\n"
      :: "r"(smem_int_ptr),
          "l"(gmem_addr),
          "n"(sizeof(int)));
}

} // namespace TGV
