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

/*! \file
    \brief Regression test verifying that cutlass::arch::fence_view_async_shared_read()
           orders generic-proxy SMEM reads (ldmatrix / ld.shared) before async-proxy TMA
           refills across PipelineTmaAsync::consumer_release().
*/

#include "../common/cutlass_unit_test.h"

#include <cstdint>
#include <vector>
#include <cuda_runtime.h>

#include "cutlass/cutlass.h"
#include "cutlass/arch/barrier.h"
#include "cutlass/arch/config.h"
#include "cutlass/pipeline/sm90_pipeline.hpp"

#if (defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED) ||  \
     defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED) || \
     defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED) || \
     defined(CUTLASS_ARCH_MMA_SM121_SUPPORTED))

namespace pipeline_tma_async_generic_read_fence_test {

static constexpr uint32_t kStageWords = 4096; // 16 KiB per stage
[[maybe_unused]] static constexpr uint32_t kStageBytes =
    kStageWords * static_cast<uint32_t>(sizeof(uint32_t));
[[maybe_unused]] static constexpr uint32_t kNumKTiles  = 128;
static constexpr uint32_t kBankTiles  = 8;
static constexpr uint32_t kNumConsumers = 128; // 4 consumer warps (matches SM120 pingpong warpgroup)
static constexpr uint32_t kNumThreads   = 160; // 1 producer warp + 4 consumer warps
static constexpr uint32_t kNumBlocks    = 72;
static constexpr uint32_t kLaunchIters  = 32;

template <uint32_t Stages>
struct SharedStorage {
  alignas(128) uint32_t data[Stages][kStageWords];
  typename cutlass::PipelineTmaAsync<Stages>::SharedStorage pipeline;
};

enum class ReadKind {
  kLdMatrix,
  kLdShared
};

template <uint32_t Stages, ReadKind Kind>
__global__ void __launch_bounds__(kNumThreads, 2)
generic_read_tma_refill_kernel(
    uint32_t const* __restrict__ gmem_bank,
    uint32_t* __restrict__ error_count,
    uint32_t* __restrict__ sink) {
#if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 900)
  extern __shared__ char smem_raw[];
  SharedStorage<Stages>& smem = *reinterpret_cast<SharedStorage<Stages>*>(smem_raw);

  uint32_t const tid      = threadIdx.x;
  uint32_t const warp_idx = tid / 32u;
  uint32_t const lane_idx = tid % 32u;

  using Pipeline = cutlass::PipelineTmaAsync<Stages>;
  typename Pipeline::Params params;
  params.role = (warp_idx == 0u) ? Pipeline::ThreadCategory::Producer : Pipeline::ThreadCategory::Consumer;
  params.is_leader = (tid == 0u);
  params.num_consumers = kNumConsumers;
  params.transaction_bytes = kStageBytes;

  Pipeline pipeline(smem.pipeline, params, cute::Shape<cute::_1, cute::_1, cute::_1>{});
  __syncthreads();

  if (warp_idx == 0u) {
    auto write_state = cutlass::make_producer_start_state<Pipeline>();
    for (uint32_t k = 0; k < kNumKTiles; ++k) {
      pipeline.producer_acquire(write_state);
      if (cute::elect_one_sync()) {
        uint32_t const s = write_state.index();
        uint32_t const dst_smem = static_cast<uint32_t>(__cvta_generic_to_shared(&smem.data[s][0]));
        uint64_t const src_gmem = reinterpret_cast<uint64_t>(
            &gmem_bank[static_cast<size_t>(k % kBankTiles) * kStageWords]);
        uint32_t const mbar_addr = static_cast<uint32_t>(
            __cvta_generic_to_shared(pipeline.producer_get_barrier(write_state)));
        asm volatile(
            "cp.async.bulk.shared::cluster.global.mbarrier::complete_tx::bytes [%0], [%1], %2, [%3];\n"
            :: "r"(dst_smem), "l"(src_gmem), "r"(kStageBytes), "r"(mbar_addr)
            : "memory");
      }
      ++write_state;
    }
    pipeline.producer_tail(write_state);
  }
  else {
    uint32_t const ctid = tid - 32u;
    auto read_state = cutlass::PipelineState<Stages>{};
    uint32_t acc = 0u;

    for (uint32_t k = 0; k < kNumKTiles; ++k) {
      pipeline.consumer_wait(read_state);
      uint32_t const s = read_state.index();
      uint32_t const expected_tag = 0xA0000000u | ((k % kBankTiles) << 16u);

      if constexpr (Kind == ReadKind::kLdMatrix) {
        uint32_t r[8][4];
        CUTLASS_PRAGMA_UNROLL
        for (uint32_t u = 0; u < 8u; ++u) {
          // Stride-32-word rows keep generic-proxy ldmatrix loads queued across barrier release
          // if the read-only generic->async proxy fence is omitted.
          uint32_t const widx = (lane_idx * 32u + u * 128u + (warp_idx - 1u) * 32u) & (kStageWords - 1u);
          uint32_t const addr = static_cast<uint32_t>(__cvta_generic_to_shared(&smem.data[s][widx]));
          asm volatile(
              "ldmatrix.sync.aligned.m8n8.x4.shared.b16 {%0, %1, %2, %3}, [%4];\n"
              : "=r"(r[u][0]), "=r"(r[u][1]), "=r"(r[u][2]), "=r"(r[u][3])
              : "r"(addr));
        }

        cutlass::arch::NamedBarrier::sync(
            kNumConsumers, cutlass::arch::ReservedNamedBarriers::Sm120MainloopBarrier);
        cutlass::arch::fence_view_async_shared_read();
        pipeline.consumer_release(read_state);
        ++read_state;

        CUTLASS_PRAGMA_UNROLL
        for (uint32_t u = 0; u < 8u; ++u) {
          CUTLASS_PRAGMA_UNROLL
          for (uint32_t j = 0; j < 4u; ++j) {
            uint32_t const val = r[u][j];
            acc ^= val;
            if ((val & 0xFFFF0000u) != expected_tag) {
              atomicAdd(error_count, 1u);
            }
          }
        }
      }
      else {
        uint32_t v[16];
        CUTLASS_PRAGMA_UNROLL
        for (uint32_t u = 0; u < 16u; ++u) {
          uint32_t const widx = (lane_idx * 32u + u * 128u + (warp_idx - 1u) * 32u) & (kStageWords - 1u);
          uint32_t const addr = static_cast<uint32_t>(__cvta_generic_to_shared(&smem.data[s][widx]));
          asm volatile("ld.shared.u32 %0, [%1];\n" : "=r"(v[u]) : "r"(addr));
        }

        cutlass::arch::NamedBarrier::sync(
            kNumConsumers, cutlass::arch::ReservedNamedBarriers::Sm120MainloopBarrier);
        cutlass::arch::fence_view_async_shared_read();
        pipeline.consumer_release(read_state);
        ++read_state;

        CUTLASS_PRAGMA_UNROLL
        for (uint32_t u = 0; u < 16u; ++u) {
          uint32_t const val = v[u];
          acc ^= val;
          if ((val & 0xFFFF0000u) != expected_tag) {
            atomicAdd(error_count, 1u);
          }
        }
      }
    }

    if (acc == 0xdeadbeefu) {
      sink[blockIdx.x * kNumConsumers + ctid] = acc;
    }
  }
#else
  CUTLASS_UNUSED(gmem_bank);
  CUTLASS_UNUSED(error_count);
  CUTLASS_UNUSED(sink);
#endif
}

template <uint32_t Stages, ReadKind Kind>
void run_generic_read_fence_test() {
  int device_id = 0;
  ASSERT_EQ(cudaGetDevice(&device_id), cudaSuccess);
  cudaDeviceProp props{};
  ASSERT_EQ(cudaGetDeviceProperties(&props, device_id), cudaSuccess);
  if (props.major < 9) {
    GTEST_SKIP() << "Requires SM90+ (TMA + PipelineTmaAsync).";
  }

  std::vector<uint32_t> h_gmem(static_cast<size_t>(kBankTiles) * kStageWords);
  for (uint32_t k = 0; k < kBankTiles; ++k) {
    uint32_t const tag = 0xA0000000u | (k << 16u);
    for (uint32_t w = 0; w < kStageWords; ++w) {
      h_gmem[static_cast<size_t>(k) * kStageWords + w] = tag | w;
    }
  }

  uint32_t* d_gmem = nullptr;
  uint32_t* d_errs = nullptr;
  uint32_t* d_sink = nullptr;
  ASSERT_EQ(cudaMalloc(&d_gmem, h_gmem.size() * sizeof(uint32_t)), cudaSuccess);
  ASSERT_EQ(cudaMalloc(&d_errs, sizeof(uint32_t)), cudaSuccess);
  ASSERT_EQ(cudaMalloc(&d_sink, static_cast<size_t>(kNumBlocks) * kNumConsumers * sizeof(uint32_t)), cudaSuccess);
  ASSERT_EQ(cudaMemcpy(d_gmem, h_gmem.data(), h_gmem.size() * sizeof(uint32_t), cudaMemcpyHostToDevice), cudaSuccess);

  size_t const smem_bytes = sizeof(SharedStorage<Stages>);
  ASSERT_EQ(
      cudaFuncSetAttribute(
          generic_read_tma_refill_kernel<Stages, Kind>,
          cudaFuncAttributeMaxDynamicSharedMemorySize,
          static_cast<int>(smem_bytes)),
      cudaSuccess);

  uint64_t total_corrupted_words = 0;
  for (uint32_t it = 0; it < kLaunchIters; ++it) {
    ASSERT_EQ(cudaMemset(d_errs, 0, sizeof(uint32_t)), cudaSuccess);
    generic_read_tma_refill_kernel<Stages, Kind><<<kNumBlocks, kNumThreads, smem_bytes>>>(
        d_gmem, d_errs, d_sink);
    ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);
    uint32_t h_errs = 0;
    ASSERT_EQ(cudaMemcpy(&h_errs, d_errs, sizeof(uint32_t), cudaMemcpyDeviceToHost), cudaSuccess);
    total_corrupted_words += h_errs;
  }

  cudaFree(d_gmem);
  cudaFree(d_errs);
  cudaFree(d_sink);

  EXPECT_EQ(total_corrupted_words, 0u)
      << "Detected generic-proxy SMEM read overwritten by next-lap async-proxy TMA refill.";
}

} // namespace pipeline_tma_async_generic_read_fence_test

TEST(PipelineTmaAsync_GenericReadFence, LdMatrix_Stages2) {
  pipeline_tma_async_generic_read_fence_test::run_generic_read_fence_test<
      2, pipeline_tma_async_generic_read_fence_test::ReadKind::kLdMatrix>();
}

TEST(PipelineTmaAsync_GenericReadFence, LdShared_Stages2) {
  pipeline_tma_async_generic_read_fence_test::run_generic_read_fence_test<
      2, pipeline_tma_async_generic_read_fence_test::ReadKind::kLdShared>();
}

TEST(PipelineTmaAsync_GenericReadFence, LdMatrix_Stages3) {
  pipeline_tma_async_generic_read_fence_test::run_generic_read_fence_test<
      3, pipeline_tma_async_generic_read_fence_test::ReadKind::kLdMatrix>();
}

#endif // SM90 / SM100 / SM120 / SM121
