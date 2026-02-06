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

#include "cute/numeric/integral_constant.hpp"
#include "cute/arch/cluster_sm90.hpp"
#include "cutlass/arch/barrier.h"
#include "cutlass/pipeline/sm90_pipeline.hpp"

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {

using namespace cute;

// Producer-consumer pipeline implementation
// for TMA producer. In this case, Multi-consumers 
// (UMMAs, TransformWarps, ...)
// will arrive at the same empty barrier.
// A naive implement without mcast support.
template <int Stages_, class ClusterShape = Shape<int,int,_1>, class AtomThrShape_MNK_ = Shape<_1,_1,_1>>
class PipelineTmaMultiConsumersAsync {
public:
  static constexpr uint32_t Stages = Stages_;
  using AtomThrShape_MNK = AtomThrShape_MNK_;
private:
  using Impl = PipelineTmaAsync<Stages>;
public:
  using FullBarrier  = typename Impl::FullBarrier;
  using EmptyBarrier = typename Impl::EmptyBarrier;
  using ProducerBarrierType = typename Impl::ProducerBarrierType;
  using ConsumerBarrierType = typename Impl::ConsumerBarrierType;
  using PipelineState = typename Impl::PipelineState;
  using SharedStorage = typename Impl::SharedStorage;
  using ThreadCategory = typename Impl::ThreadCategory;
  using Params = typename Impl::Params;

  // Helper function to initialize barriers
  static
  CUTLASS_DEVICE
  void
  init_barriers(SharedStorage& storage, Params params, ClusterShape cluster_shape) {
    int warp_idx = canonical_warp_idx_sync();
    if (warp_idx == params.initializing_warp) {
      constexpr int producer_arv_cnt = 1;
      int const consumer_arv_cnt = params.num_consumers;
      cutlass::arch::detail::initialize_barrier_array_pair_aligned<decltype(storage.full_barrier_), decltype(storage.empty_barrier_), Stages>(
          storage.full_barrier_, storage.empty_barrier_, producer_arv_cnt, consumer_arv_cnt);
    }
    cutlass::arch::fence_barrier_init();
  }

  CUTLASS_DEVICE
  void init_masks(ClusterShape cluster_shape) {
    // Calculate consumer mask
    if (params_.role == ThreadCategory::Consumer) {
      is_signalling_thread_ = 1;
      dst_blockid_ = 0;
    }
  }

  // Constructor by default initializes barriers and calculates masks. 
  // These operations can be explicity deferred by specifying InitBarriers and InitMasks. 
  // If deferred, user code needs to guarantee init_masks and/or init_barriers is/are called. 
  template<typename InitBarriers = cute::true_type, typename InitMasks = cute::true_type>
  CUTLASS_DEVICE
  PipelineTmaMultiConsumersAsync(SharedStorage& storage, Params params, ClusterShape cluster_shape, InitBarriers = {}, InitMasks = {})
      : impl_(storage, params, cluster_shape)
      , params_(params)
      , empty_barrier_ptr_(&storage.empty_barrier_[0])
      , full_barrier_ptr_(&storage.full_barrier_[0]) {
    static_assert(cute::is_same_v<InitBarriers, cute::true_type> || cute::is_same_v<InitBarriers, cute::false_type>);
    static_assert(size(cluster_shape) == 1, "PipelineTmaMultiConsumersAsync only supports 1x1x1 cluster shape now");
    if constexpr (cute::is_same_v<InitBarriers, cute::true_type>) {
      init_barriers(storage, params_, cluster_shape);
    }

    static_assert(cute::is_same_v<InitMasks, cute::true_type> || cute::is_same_v<InitMasks, cute::false_type>);
    if constexpr (cute::is_same_v<InitMasks, cute::true_type>) {
      init_masks(cluster_shape);
    }
  }

  ////////////////////
  // Producer APIs
  ////////////////////
  // Four member functions are always used in pairs:
  //
  // * producer_try_acquire and producer_acquire, and
  // * consumer_try_wait and consumer_wait.
  //
  // The two functions with "try" in their names are called "try" functions,
  // and the other two are conceptually "finalize" functions.
  // The "try" function in each pair starts the process of waiting on the barrier to flip.
  // It opportunistically waits for an implementation-dependent timeout.
  // Whether or not the barrier has flipped yet, the try function will return a token.
  // If the token indicates that the barrier has not flipped,
  // then the token must be passed into the corresponding "finalize" function.
  // The finalize function will then block until the barrier has flipped.
  // If the token indicates that the barrier _has_ flipped,
  // then it is still correct to pass it into the finalize function.
  // The finalize function will return immediately in that case.
  CUTLASS_DEVICE
  ProducerToken producer_try_acquire(PipelineState state, uint32_t skip_wait = false) {
    return impl_.producer_try_acquire(state, skip_wait);
  }

  CUTLASS_DEVICE
  void producer_acquire(PipelineState state, ProducerToken barrier_token = {BarrierStatus::WaitAgain}) {
    impl_.producer_acquire(state, barrier_token);
  }

  // NOP for TMA based mainloop
  CUTLASS_DEVICE
  void producer_commit(PipelineState state, uint32_t bytes) {
    impl_.producer_commit(state, bytes);
  }

  // Prevents early exit of producer blocks in Cluster.
  // This should be called once before kernel exits.
  CUTLASS_DEVICE
  void producer_tail(PipelineState state) {
    impl_.producer_tail(state);
  }

  CUTLASS_DEVICE
  ProducerBarrierType* producer_get_barrier(PipelineState state) {
    return impl_.producer_get_barrier(state);
  }

  ////////////////////
  // Consumer APIs
  ////////////////////
  CUTLASS_DEVICE
  ConsumerToken consumer_try_wait(PipelineState state, uint32_t skip_wait = false) {
    return impl_.consumer_try_wait(state, skip_wait);
  }

  CUTLASS_DEVICE
  void consumer_wait(PipelineState state, ConsumerToken barrier_token = {BarrierStatus::WaitAgain}) {
    impl_.consumer_wait(state, barrier_token);
  }

  CUTLASS_DEVICE
  void consumer_release_from_umma(PipelineState state) {
    consumer_release_from_umma(state.index(), false);
  }

  CUTLASS_DEVICE
  void consumer_release_from_threads(PipelineState state) {
    consumer_release_from_threads(state.index());
  }

private:
  Impl impl_;
  Params params_;
  uint32_t dst_blockid_ = 0;
  uint32_t is_signalling_thread_ = 0;
  EmptyBarrier *empty_barrier_ptr_;
  FullBarrier *full_barrier_ptr_;
  uint16_t block_id_mask_ = 0;
  static constexpr bool is_2sm_mma = size(AtomThrShape_MNK{}) > 1;

  // Consumer signalling Producer of completion
  // Ensures all blocks in the Same Row and Column get notifed.
  CUTLASS_DEVICE
  void consumer_release_from_umma(uint32_t stage, uint32_t skip) {
    uint64_t* smem_ptr = reinterpret_cast<uint64_t*>(&empty_barrier_ptr_[stage]);
    if constexpr (is_2sm_mma) { // Mma cluster shape is 2x1
      if (!skip) {
        cutlass::arch::umma_arrive_multicast_2x1SM(smem_ptr, block_id_mask_);
      }
    }
    else {
      if (!skip) {
        if constexpr (cute::is_static_v<ClusterShape> and size(ClusterShape{}) == 1) {
          cutlass::arch::umma_arrive(smem_ptr);
        }
        else {
          cutlass::arch::umma_arrive_multicast(smem_ptr, block_id_mask_);
        }
      }
    }
  }

  CUTLASS_DEVICE
  void consumer_release_from_threads(uint32_t stage, uint32_t skip = false) {
    empty_barrier_ptr_[stage].arrive(dst_blockid_, is_signalling_thread_ & (!skip));
    #ifndef NDEBUG
    if (params_.role == ThreadCategory::Producer || params_.role == ThreadCategory::NonParticipant) {
      asm volatile ("brkpt;\n" ::);
    }
    #endif
  }
};

}
