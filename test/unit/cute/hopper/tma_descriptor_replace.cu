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

#include "cutlass_unit_test.h"

#include <cstdint>

#include <thrust/device_vector.h>
#include <thrust/host_vector.h>

#include <cutlass/arch/barrier.h>
#include <cute/arch/cluster_sm90.hpp>
#include <cute/arch/copy_sm90_desc.hpp>
#include <cute/tensor.hpp>

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

namespace cutlass::test {

template <class T, class SmemLayout>
struct ReplaceSharedStorage {
  alignas(128) TmaDescriptor smem_desc;
  alignas(128) ArrayEngine<T, cosize_v<SmemLayout>> smem_tile;
  alignas(16) uint64_t mbar;
};

template <class T, class TiledCopy, class SmemLayout, class OutGmemLayout, bool BroadcastMode2>
__global__ void
tma_descriptor_replace_kernel(
    CUTE_GRID_CONSTANT TiledCopy const tma,
    TmaDescriptor* gmem_desc,
    T* g_out,
    OutGmemLayout out_layout,
    SmemLayout smem_layout,
    uint32_t dim0,
    uint32_t dim1,
    uint32_t dim2,
    uint64_t stride1_bytes,
    uint64_t stride2_bytes,
    int* executed)
{
#if defined(CUTE_ARCH_DEVICE_MODIFIABLE_TMA_SM90_ENABLED)
  using Storage = ReplaceSharedStorage<T, SmemLayout>;
  __shared__ Storage storage;

  int const tid = threadIdx.x;
  if (tid == 0) {
    storage.smem_desc = *tma.get_tma_descriptor();
  }
  __syncthreads();

  // Exercise compile-time 0 stride when BroadcastMode2 is true: if
  // tma_descriptor_replace_dims_strides_in_shared_mem writes to a read-only
  // `const uint64_t = 0` inline-asm operand, NVVM can alias that register with
  // the constant 0 stride and write `&smem_desc` into global_stride[1..3].
  array<uint32_t, 5> prob_shape = {dim0, dim1, dim2, 1u, 1u};
  array<uint64_t, 5> prob_stride = {
      0ull,
      stride1_bytes,
      BroadcastMode2 ? 0ull : stride2_bytes,
      0ull,
      0ull};

  if (tid < 32) {
    if (elect_one_sync()) {
      tma_descriptor_replace_dims_strides_in_shared_mem(storage.smem_desc, prob_shape, prob_stride);
    }
    __syncwarp();
    // Entire warp must execute tensormap.cp_fenceproxy.sync.aligned.
    tma_descriptor_cp_fence_release(gmem_desc, storage.smem_desc);
  }
  __syncthreads();

  tma_descriptor_fence_acquire(gmem_desc);

  Tensor sTile = make_tensor(make_smem_ptr(storage.smem_tile.begin()), smem_layout);
  Tensor mA = tma.get_tma_tensor(shape(out_layout));
  Tensor mOut = make_tensor(make_gmem_ptr(g_out), out_layout);

  auto cta_tiler = shape(smem_layout);
  Tensor gA = flat_divide(mA, cta_tiler);
  Tensor gOut = flat_divide(mOut, cta_tiler);

  auto cta_tma = tma.get_slice(Int<0>{});
  Tensor tAgA_x = cta_tma.partition_S(gA);
  Tensor tAsA_x = cta_tma.partition_D(sTile);
  Tensor tAgA = group_modes<1, rank(tAgA_x)>(tAgA_x);
  Tensor tAsA = group_modes<1, rank(tAsA_x)>(tAsA_x);
  constexpr int R = rank_v<decltype(cta_tiler)>;
  Tensor tBgB = group_modes<0, R>(group_modes<R, rank(gOut)>(gOut));

  constexpr int kTmaTransactionBytes = sizeof(make_tensor_like(tensor<0>(tAsA)));
  if (tid == 0) {
    storage.mbar = 0;
    initialize_barrier(storage.mbar, 1);
  }
  cutlass::arch::fence_barrier_init();
  __syncthreads();

  int phase = 0;
  for (int stage = 0; stage < size<1>(tAgA); ++stage) {
    if (tid == 0) {
      set_barrier_transaction_bytes(storage.mbar, kTmaTransactionBytes);
      copy(tma.with(gmem_desc, storage.mbar), tAgA(_, stage), tAsA(_, 0));
      wait_barrier(storage.mbar, phase);
      copy(sTile, tBgB(_, stage));
      // Order generic SMEM reads before the next async-proxy TMA load refills sTile.
      cutlass::arch::fence_view_async_shared();
    }
    phase ^= 1;
    __syncthreads();
  }

  if (tid == 0) {
    *executed = 1;
  }
#else
  (void)tma;
  (void)gmem_desc;
  (void)g_out;
  (void)out_layout;
  (void)smem_layout;
  (void)dim0;
  (void)dim1;
  (void)dim2;
  (void)stride1_bytes;
  (void)stride2_bytes;
  if (threadIdx.x == 0) {
    *executed = 0;
  }
#endif
}

bool
device_supports_modifiable_tma()
{
  int dev = 0;
  if (cudaGetDevice(&dev) != cudaSuccess) {
    return false;
  }
  cudaDeviceProp prop{};
  if (cudaGetDeviceProperties(&prop, dev) != cudaSuccess) {
    return false;
  }
  return prop.major >= 9;
}

template <bool BroadcastMode2, class InitLayout>
void
run_tma_descriptor_replace_test(
    InitLayout const& init_layout,
    uint32_t new_d0,
    uint32_t new_d1,
    uint32_t new_d2,
    int new_s1,
    int new_s2)
{
  if (!device_supports_modifiable_tma()) {
    GTEST_SKIP() << "Requires SM90+ GPU for modifiable TMA descriptors.";
  }

  using T = uint16_t;
  // Allocate 16 KiB backing memory with distinct values per element so any
  // corrupted mode-2 stride (such as &smem_desc) reads visibly wrong data
  // without faulting out of bounds.
  constexpr int kBackingElems = 8192;
  thrust::host_vector<T> h_in(kBackingElems);
  for (int i = 0; i < kBackingElems; ++i) {
    h_in[i] = static_cast<T>((i * 7 + 1) & 0xFFFF);
  }
  thrust::device_vector<T> d_in = h_in;

  auto smem_layout = Layout<Shape<_16, _16, _1>, Stride<_1, _16, _256>>{};
  Tensor g_init = make_tensor(make_gmem_ptr(raw_pointer_cast(d_in.data())), init_layout);
  auto tma = make_tma_copy(SM90_TMA_LOAD{}, g_init, smem_layout);

  auto out_layout = make_layout(
      make_shape(int(new_d0), int(new_d1), int(new_d2)),
      make_stride(Int<1>{}, int(new_d0), int(new_d0 * new_d1)));

  thrust::device_vector<TmaDescriptor> d_desc(1);
  thrust::device_vector<T> d_out(new_d0 * new_d1 * new_d2, T(0));
  thrust::device_vector<int> d_executed(1, 0);

  tma_descriptor_replace_kernel<T, decltype(tma), decltype(smem_layout), decltype(out_layout), BroadcastMode2>
      <<<1, 32>>>(
          tma,
          raw_pointer_cast(d_desc.data()),
          raw_pointer_cast(d_out.data()),
          out_layout,
          smem_layout,
          new_d0,
          new_d1,
          new_d2,
          uint64_t(new_s1) * sizeof(T),
          uint64_t(new_s2) * sizeof(T),
          raw_pointer_cast(d_executed.data()));
  ASSERT_EQ(cudaGetLastError(), cudaSuccess);
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  int h_executed = d_executed[0];
  if (h_executed == 0) {
    GTEST_SKIP() << "Binary not compiled with CUTE_ARCH_DEVICE_MODIFIABLE_TMA_SM90_ENABLED.";
  }

  thrust::host_vector<T> h_out = d_out;
  int const expected_s2 = BroadcastMode2 ? 0 : new_s2;
  for (int slice = 0; slice < int(new_d2); ++slice) {
    for (int j = 0; j < int(new_d1); ++j) {
      for (int i = 0; i < int(new_d0); ++i) {
        int out_idx = i + j * int(new_d0) + slice * int(new_d0 * new_d1);
        int expected_idx = i + j * new_s1 + slice * expected_s2;
        ASSERT_EQ(h_out[out_idx], h_in[expected_idx])
            << "Mismatch at (i=" << i << ", j=" << j << ", slice=" << slice << ")";
      }
    }
  }
}

} // namespace cutlass::test

using namespace cutlass::test;

TEST(CuTe_TmaDescriptor, ReplaceDimsStrides_BroadcastZeroStride)
{
  // Initial descriptor has non-zero mode-2 stride (512 bytes); the kernel updates
  // mode-2 stride to compile-time 0 so all 4 slices must read slice 0.
  auto init_layout = make_layout(make_shape(16, 16, 4), make_stride(Int<1>{}, 16, 256));
  run_tma_descriptor_replace_test<true>(init_layout, 16u, 16u, 4u, 16, 0);
}

TEST(CuTe_TmaDescriptor, ReplaceDimsStrides_ReshapeAndStride)
{
  // Initial descriptor covers (16, 16, 2) with strides (1, 16, 256); replace all
  // three active dims and both strides to (32, 32, 3) with padded strides (1, 48, 2048).
  auto init_layout = make_layout(make_shape(16, 16, 2), make_stride(Int<1>{}, 16, 256));
  run_tma_descriptor_replace_test<false>(init_layout, 32u, 32u, 3u, 48, 2048);
}

#endif // CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED
