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

#include "cutlass/pipeline/sm100_pipeline.hpp"
#include "cutlass/arch/barrier.h"
#include "cute/arch/cluster_sm90.hpp"  // cute::store_shared_remote

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {

using namespace cute;

namespace detail {

// 128-bit version of cute::store_shared_remote (32 bit).
template <class T>
CUTLASS_DEVICE
void
store_shared_remote_128b(T const& value, uint32_t smem_addr, uint32_t mbarrier_addr, uint32_t dst_cta_rank)
{
  static_assert(sizeof(T) == 16, "store_shared_remote_128b requires a 16-byte value type.");
#if defined(CUTE_ARCH_CLUSTER_SM90_ENABLED)
  uint32_t dsmem_addr = cute::set_block_rank(smem_addr, dst_cta_rank);
  uint32_t remote_barrier_addr = cute::set_block_rank(mbarrier_addr, dst_cta_rank);
  uint32_t const *v = reinterpret_cast<uint32_t const *>(&value);
  asm volatile(
      "{\n\t"
      ".reg .b64 lo64, hi64;\n\t"
      ".reg .b128 v128;\n\t"
      "mov.b64 lo64, {%1, %2};\n\t"
      "mov.b64 hi64, {%3, %4};\n\t"
      "mov.b128 v128, {lo64, hi64};\n\t"
      "st.async.shared::cluster.mbarrier::complete_tx::bytes.b128 [%0], v128, [%5];\n\t"
      "}\n\t"
      :
      : "r"(dsmem_addr), "r"(v[0]), "r"(v[1]), "r"(v[2]), "r"(v[3]),
        "r"(remote_barrier_addr)
      : "memory");
#endif
}

// Cluster synchronization state for multicast TMA retries.
// Each stage has an mbarrier for synchronization ahead of multicast retries. Without it, one CTA
// in the multicast can re-issue a TMA prior to peer CTAs completing their copies & phase updates.
template <uint32_t Stages>
struct RetryWarpMulticastPipelineState {
  bool phases_[Stages];  // barrier phase
  bool ready_[Stages];   // success && invalid have been observed (ready to issue retry)
};

template <>
struct RetryWarpMulticastPipelineState<0> {};

} // end namespace detail

////////////////////////////////////////////////////////////////////////////////////////////////////

// Retry warp pipeline state
// Tracks phases and counts independently per stage.
// Unlike PipelineState (single global phase/count), each stage progresses independently.
// Pipeline index is also tracked independently by the collective via an unrolled loop, which avoid
// excessive register spilling.
// Used by the retry warp, where stages complete out of order due to TMA report valid retries.
template<uint32_t Stages_, bool HasMulticast_ = false>
struct RetryWarpPipelineState {

  static constexpr uint32_t Stages = Stages_;
  static constexpr bool HasMulticast = HasMulticast_;

  bool phases_[Stages];
  uint32_t counts_[Stages];

  detail::RetryWarpMulticastPipelineState<HasMulticast ? Stages : 0> retry_multicast_state_;

  // 2SM communication barrier phase
  uint32_t retry_2sm_phase_;

  CUTLASS_DEVICE
  RetryWarpPipelineState(bool is_leader_cta)
    : retry_2sm_phase_(is_leader_cta ? 1 : 0) {
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < Stages; ++i) {
      phases_[i] = false;
      counts_[i] = 0;
      if constexpr (HasMulticast) {
        retry_multicast_state_.phases_[i] = false;
        retry_multicast_state_.ready_[i] = false;
      }
    }
  }

  CUTLASS_DEVICE
  uint32_t phase(int index) const {
    return static_cast<uint32_t>(phases_[index]);
  }

  CUTLASS_DEVICE
  uint32_t count(int index) const {
    return counts_[index];
  }

  CUTLASS_DEVICE
  void mark_invalid(int index) {
    phases_[index] ^= true;
  }

  CUTLASS_DEVICE
  void mark_valid(int index) {
    phases_[index] ^= true;
    counts_[index] += 1;
  }

  CUTLASS_DEVICE
  uint32_t retry_multicast_phase(int index) const {
    if constexpr (HasMulticast) {
      return static_cast<uint32_t>(retry_multicast_state_.phases_[index]);
    }
    return 0;
  }

  CUTLASS_DEVICE
  bool retry_multicast_ready(int index) const {
    if constexpr (HasMulticast) {
      return static_cast<uint32_t>(retry_multicast_state_.ready_[index]);
    }
    return false;
  }

  CUTLASS_DEVICE
  void set_retry_multicast_ready(int index) {
    if constexpr (HasMulticast) {
      retry_multicast_state_.ready_[index] = true;
    }
  }

  CUTLASS_DEVICE
  void retry_multicast_advance(int index) {
    if constexpr (HasMulticast) {
      retry_multicast_state_.phases_[index] ^= true;
      retry_multicast_state_.ready_[index] = false;
    }
  }

  CUTLASS_DEVICE
  uint32_t retry_2sm_phase() const {
    return retry_2sm_phase_;
  }

  CUTLASS_DEVICE
  void retry_2sm_advance() {
    retry_2sm_phase_ ^= 1;
  }

  // Reset all counts for a new work tile
  CUTLASS_DEVICE
  void reset_count() {
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < Stages; ++i) {
      counts_[i] = 0;
    }
  }

  // Compute which k_tile the given stage is processing.
  //   stage_idx:    Current stage index
  //   stage_count:  Rounds completed for this stage
  //   stage_offset: Which stage k_tile 0 maps to (for this work tile)
  CUTLASS_DEVICE
  static int compute_k_tile(int stage_idx, int stage_count, int stage_offset) {
    constexpr int kNumStages = static_cast<int>(Stages);
    // Avoid modulo: safe since x < 2 * num_stages
    int x = stage_idx - stage_offset + kNumStages;
    int pos_in_round = x < kNumStages ? x : x - kNumStages;
    return pos_in_round + stage_count * kNumStages;
  }

  CUTLASS_DEVICE
  RetryWarpPipelineState& operator=(RetryWarpPipelineState const& other) {
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < Stages; ++i) {
      phases_[i] = other.phase(i);
      counts_[i] = other.count(i);
    }
    retry_multicast_state_ = other.retry_multicast_state_;
    retry_2sm_phase_ = other.retry_2sm_phase_;
    return *this;
  }

  // advance, ++, +=, and make_pipeline_state are not defined for RetryWarpPipelineState
};

///////////////////////////////////////////////////////////////////////////////////////////////////
//
// TMA (consumer) Async Pipeline classes for Rubin UMMA, with TMA valid check support
//
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

// Number of participants in the checked operand's multicast group, at MMA-atom granularity.
template <class ClusterShape, class AtomThrShape_MNK>
constexpr uint32_t multicast_group_size(McastDirection direction) {
  return direction == McastDirection::kCol
    ? cute::size<0>(ClusterShape{}) / cute::size<0>(AtomThrShape_MNK{})
    : cute::size<1>(ClusterShape{}) / cute::size<1>(AtomThrShape_MNK{});
}

// Retry warps in the 2SM case need to communicate via distributed shared memory, because only the
// leader CTA's mbarrier will be updated after the TMA load. However, both leader and follower CTAs
// must issue the retry copy, therefore leader CTA must communicate retries, the stage, and coordinates.
template <bool Is2Sm>
struct PipelineRetry2SmComm {
  using Coord = cute::tuple<int, int, int, int>; // m, n, k_tile, l

  cutlass::arch::ClusterTransactionBarrier full;
  cutlass::arch::ClusterBarrier empty;

  Coord coord;
  alignas(16) int stage;
};

template <>
struct PipelineRetry2SmComm<false> {};

} // end namespace detail

//
// Extends PipelineTmaUmmaAsync with TMA valid check support.
//
//  * Full barriers are initialized with the V1 mbarrier layout, and therefore have conditional and
//    primary phase, as well as distinct APIs for checking them.
//
//  * producer_reacquire allows retry warp to re-arms a load stage and re-issue the load when
//    invalid.
//
//  * retry_consumer_release must be called from retry warp when valid data is detected, which
//    arrives on the empty barrier. Once both retry warp and MMA warp have arrived on that barrier,
//    the main TMA load warp can issue the next k tile load for that stage.
//
//  * When valid-checked operand is multicast, and invalid data is detected, retry warps in each
//    multicast group must arrive and wait on an additional barrier to guarantee that the previous
//    load is complete for all, before issuing a retry.
//
template <
  int Stages_,
  class ClusterShape_ = Shape<int,int,_1>,
  class AtomThrShape_MNK_ = Shape<_1,_1,_1>,
  McastDirection Mcast = McastDirection::kCol
>
class PipelineTmaUmmaReportValidAsync
  : public PipelineTmaUmmaAsync<Stages_, ClusterShape_, AtomThrShape_MNK_,
                                cutlass::arch::ClusterTransactionBarrierWithConditionalPhase> {
public:
  using Base = PipelineTmaUmmaAsync<Stages_, ClusterShape_, AtomThrShape_MNK_,
                                    cutlass::arch::ClusterTransactionBarrierWithConditionalPhase>;
  using ClusterShape = ClusterShape_;
  using AtomThrShape_MNK = AtomThrShape_MNK_;
  using FullBarrier = typename Base::FullBarrier;
  using EmptyBarrier = typename Base::EmptyBarrier;
  using ProducerBarrierType = typename Base::ProducerBarrierType;
  using PipelineState = typename Base::PipelineState;
  using ThreadCategory = typename Base::ThreadCategory;
  using Params = typename Base::Params;
  static constexpr uint32_t Stages = Stages_;

  static_assert(cute::is_static_v<ClusterShape>,
                "PipelineTmaUmmaReportValidAsync requires a static cluster shape.");

  static_assert(Mcast == McastDirection::kCol || Mcast == McastDirection::kRow,
      "Multicast in PipelineTmaUmmaReportValidAsync is only supported for kRow and kCol.");

  static constexpr uint32_t MulticastGroupSize =
      detail::multicast_group_size<ClusterShape, AtomThrShape_MNK>(Mcast);
  static constexpr bool HasMulticast = MulticastGroupSize > 1;
  static constexpr bool Is2Sm = cute::size<0>(AtomThrShape_MNK{}) > 1;

  using PipelineStateRetry = cutlass::RetryWarpPipelineState<Stages, HasMulticast>;

  using Pipeline2SmComm = detail::PipelineRetry2SmComm<Is2Sm>;

private:
  using Base::full_barrier_ptr_;
  using Base::empty_barrier_ptr_;

public:

  struct SharedStorageDefault {
    typename Base::SharedStorage base;
    Pipeline2SmComm retry_2sm_;
  };

  struct SharedStorageMulticast {
    typename Base::SharedStorage base;
    EmptyBarrier retry_multicast_barrier_[Stages];
    Pipeline2SmComm retry_2sm_;
  };

  using SharedStorage = cute::conditional_t<HasMulticast, SharedStorageMulticast, SharedStorageDefault>;

  // Helper function to initialize barriers
  static
  CUTLASS_DEVICE
  void
  init_barriers(SharedStorage& storage, Params params, ClusterShape cluster_shape) {
    int warp_idx = canonical_warp_idx_sync();
    if (warp_idx == params.initializing_warp) {
      // Barrier FULL and EMPTY init
      constexpr int producer_arv_cnt = 1;
      auto atom_thr_shape = AtomThrShape_MNK{};
      uint32_t multicast_count =
        (cute::size<0>(cluster_shape) / cute::size<0>(atom_thr_shape)) +
        (cute::size<1>(cluster_shape) / cute::size<1>(atom_thr_shape)) - 1;

      // Both the MMA consumer and the retry warp release each stage, and each signals the
      // row-or-col CTA set (multicast_count arrives apiece) — see init_retry.
      uint32_t const multicast_consumer_arrival_count = multicast_count * 2;

      CUTLASS_ASSERT(multicast_consumer_arrival_count > 0 && "Multicast consumer arrival count must be non-zero");
      cutlass::arch::detail::initialize_barrier_array_pair_aligned<
          decltype(storage.base.full_barrier_), decltype(storage.base.empty_barrier_), Stages>(
          storage.base.full_barrier_, storage.base.empty_barrier_, producer_arv_cnt, multicast_consumer_arrival_count);

      if constexpr (HasMulticast) {
        // One arrival per peer CTA
        cutlass::arch::detail::initialize_barrier_array_aligned<
            decltype(storage.retry_multicast_barrier_), Stages>(
            storage.retry_multicast_barrier_, MulticastGroupSize - 1);
      }

      // 2SM: full expects one arrive (leader's elected thread) plus the
      // coord bytes; empty expects the follower's whole retry warp.
      if constexpr (Is2Sm) {
        if (cute::elect_one_sync()) {
          storage.retry_2sm_.full.init(1);
          storage.retry_2sm_.empty.init(NumThreadsPerWarp);
        }
      }
    }
    cutlass::arch::fence_barrier_init();
  }

  template<typename InitBarriers = cute::true_type, typename InitMasks = cute::true_type>
  CUTLASS_DEVICE
  PipelineTmaUmmaReportValidAsync(SharedStorage& storage, Params params, ClusterShape cluster_shape, InitBarriers = {}, InitMasks = {})
      : Base(storage.base, params, cluster_shape, cute::false_type{}, InitMasks{}) {
    if constexpr (HasMulticast) {
      retry_multicast_barrier_ptr_ = &storage.retry_multicast_barrier_[0];
    }
    if constexpr (Is2Sm) {
      retry_2sm_ptr_ = &storage.retry_2sm_;
      cta_2sm_rel_rank_ = cute::block_rank_in_cluster() ^ 1;
    }
    static_assert(cute::is_same_v<InitBarriers, cute::true_type> || cute::is_same_v<InitBarriers, cute::false_type>);
    if constexpr (cute::is_same_v<InitBarriers, cute::true_type>) {
      init_barriers(storage, params, cluster_shape);
    }

    init_retry(cluster_shape);
    init_retry_multicast(cluster_shape);
  }

  ////////////////////
  // Retry warp APIs
  ////////////////////

  // Non-blocking test for TMA transaction completion and data validity.
  CUTLASS_DEVICE
  auto consumer_test_valid(PipelineStateRetry state, int index) {
    bool invalid = true;
    bool success = full_barrier_ptr_[index].test_wait_primary(state.phase(index), /*pred=*/true, invalid);
    return cute::make_tuple(success, not invalid);
  }

  // Release a valid stage on behalf of the retry warp. Separate from the MMA consumer's
  // release; the empty barrier expects both.
  CUTLASS_DEVICE
  void retry_consumer_release(PipelineStateRetry state, int index) {
    empty_barrier_ptr_[index].arrive(dst_blockid_, is_signaling_thread_);
  }

  // Call arrive_and_expect_tx on full barrier for TMA retry.
  // Called by retry warp after detecting invalid data. Unlike producer_acquire(),
  // does not wait on empty barrier (buffer was never released).
  CUTLASS_DEVICE
  void producer_reacquire(PipelineStateRetry state, int index, uint32_t transaction_bytes) {
    if (cute::elect_one_sync()) {
      full_barrier_ptr_[index].arrive_and_expect_tx(transaction_bytes);
    }
  }

  using Base::producer_get_barrier;

  CUTLASS_DEVICE
  ProducerBarrierType* producer_get_barrier(PipelineStateRetry state, int index) {
    return reinterpret_cast<ProducerBarrierType*>(&full_barrier_ptr_[index]);
  }

  // Announce to all peers in the mcast group that this CTA observed invalid data for this
  // stage. Must be called at most once per sync round (see RetryWarpPipelineState).
  CUTLASS_DEVICE
  void retry_multicast_arrive(PipelineStateRetry state, int index) {
    if constexpr (HasMulticast) {
      retry_multicast_barrier_ptr_[index].arrive(retry_multicast_dst_blockid_, retry_multicast_is_signaling_);
    }
  }

  // True once every peer in the mcast group announced invalid data for this stage's
  // current sync round, i.e. no peer can still have the previous TMA in flight.
  // Trivially true when the checked operand is not multicast (no peers to wait for).
  CUTLASS_DEVICE
  bool retry_multicast_test_wait(PipelineStateRetry state, int index) {
    if constexpr (HasMulticast) {
      return retry_multicast_barrier_ptr_[index].test_wait(state.retry_multicast_phase(index));
    }
    return true;
  }

  CUTLASS_DEVICE
  ProducerBarrierType* producer_get_barrier(uint32_t stage) {
    return reinterpret_cast<ProducerBarrierType*>(&full_barrier_ptr_[stage]);
  }

  ////////////////////
  // 2SM pipeline APIs
  ////////////////////

  CUTLASS_DEVICE
  void retry_2sm_acquire(uint32_t phase) {
    if constexpr (Is2Sm) {
      retry_2sm_ptr_->empty.wait(phase);
    }
  }

  CUTLASS_DEVICE
  void retry_2sm_send(int stage, int m, int n, int k_tile, int l) {
    if constexpr (Is2Sm) {
      if (cute::elect_one_sync()) {
        auto coord = cute::make_tuple(m, n, k_tile, l);

        constexpr uint32_t tx_bytes = sizeof(Pipeline2SmComm::Coord) + sizeof(int);
        retry_2sm_ptr_->full.arrive_and_expect_tx_relaxed_cluster(tx_bytes, cta_2sm_rel_rank_);

        uint32_t stage_addr = cast_smem_ptr_to_uint(&retry_2sm_ptr_->stage);
        uint32_t coord_addr = cast_smem_ptr_to_uint(&retry_2sm_ptr_->coord);
        uint32_t mbar_addr  = cast_smem_ptr_to_uint(&retry_2sm_ptr_->full);

        detail::store_shared_remote_128b(coord, coord_addr, mbar_addr, cta_2sm_rel_rank_);
        cute::store_shared_remote(static_cast<uint32_t>(stage), stage_addr, mbar_addr, cta_2sm_rel_rank_);
      }
    }
  }

  CUTLASS_DEVICE
  void retry_2sm_send_exit() {
    if constexpr (Is2Sm) {
      if (cute::elect_one_sync()) {
        retry_2sm_ptr_->full.arrive_and_expect_tx_relaxed_cluster(sizeof(int), cta_2sm_rel_rank_);

        uint32_t stage_addr = cast_smem_ptr_to_uint(&retry_2sm_ptr_->stage);
        uint32_t mbar_addr  = cast_smem_ptr_to_uint(&retry_2sm_ptr_->full);

        cute::store_shared_remote(static_cast<uint32_t>(-1), stage_addr, mbar_addr, cta_2sm_rel_rank_);
      }
    }
  }

  CUTLASS_DEVICE
  void retry_2sm_wait(uint32_t phase) {
    if constexpr (Is2Sm) {
      retry_2sm_ptr_->full.wait(phase);
    }
  }

  CUTLASS_DEVICE
  auto retry_2sm_receive() {
    if constexpr (Is2Sm) {
      return cute::make_tuple(retry_2sm_ptr_->stage, retry_2sm_ptr_->coord);
    }
    else {
      return cute::make_tuple(0, cute::make_tuple(0, 0, 0, 0));
    }
  }

  CUTLASS_DEVICE
  void retry_2sm_release() {
    if constexpr (Is2Sm) {
      cutlass::arch::fence_view_shared();
      retry_2sm_ptr_->empty.arrive_relaxed_cluster(cta_2sm_rel_rank_);
    }
  }

private:
  CUTLASS_DEVICE
  void init_retry(ClusterShape cluster_shape) {
    // predicate and destination CTA init for retry_consumer_release.
    // This is an arrival on the TMA load empty barrier in addition to MMA consumption.
    // This is an all-to-all synchronization: every CTA must arrive on all CTAs' empty barriers to
    // ensure new TMA loads are not issued while another CTA's retry warp is inspecting the barrier.
    uint32_t cta_rank = cute::block_rank_in_cluster();
    uint32_t cluster_size = cute::size(cluster_shape);
    uint32_t cluster_m = cute::size<0>(cluster_shape);
    uint32_t atom_m = cute::size<0>(AtomThrShape_MNK{});
    int lane_idx = threadIdx.x % NumThreadsPerWarp;

    uint32_t dst = lane_idx;
    uint32_t dst_m = (dst % cluster_m) / atom_m;
    uint32_t dst_n = dst / cluster_m;
    uint32_t cur_m = (cta_rank % cluster_m) / atom_m;
    uint32_t cur_n = cta_rank / cluster_m;

    is_signaling_thread_ = lane_idx < cluster_size && (dst_m == cur_m || dst_n == cur_n);
    dst_blockid_ = dst;
  }

  CUTLASS_DEVICE
  void init_retry_multicast(ClusterShape cluster_shape) {
    // predicate and destination CTA init for retry_multicast_arrive.
    // This is for synchronizing multicast retries to ensure retry loads are only issued once all
    // CTAs in the multicast group have inspected the barrier.
    // Unlike retry_consumer_release (init_retry), which prevents a race between TMA load warps and
    // retry warps, this barrier prevents a race among the retry warps in a multicast group.
    if constexpr (HasMulticast) {
      uint32_t cta_rank = cute::block_rank_in_cluster();
      uint32_t cluster_m = cute::size<0>(cluster_shape);
      uint32_t atom_m = cute::size<0>(AtomThrShape_MNK{});
      int lane_idx = threadIdx.x % NumThreadsPerWarp;

      uint32_t dst = lane_idx;
      uint32_t dst_m = dst % cluster_m;
      uint32_t dst_n = dst / cluster_m;
      uint32_t cur_m = cta_rank % cluster_m;
      uint32_t cur_n = cta_rank / cluster_m;

      bool is_signaling = lane_idx < cute::size(cluster_shape);
      if constexpr (Mcast == McastDirection::kCol) {
        // Group spans cluster-M at atom granularity: same CTA-rank-in-atom, same N.
        is_signaling &= (dst_m % atom_m) == (cur_m % atom_m) && dst_n == cur_n;
      }
      else {
        // Group spans cluster-N: same M.
        is_signaling &= dst_m == cur_m;
      }
      // Peers only.
      is_signaling &= dst != cta_rank;

      retry_multicast_dst_blockid_ = dst;
      retry_multicast_is_signaling_ = is_signaling;
    }
  }

  uint32_t is_signaling_thread_ = 0;
  uint32_t dst_blockid_ = 0;

  // Retry multicast
  EmptyBarrier *retry_multicast_barrier_ptr_ = nullptr;
  uint32_t retry_multicast_is_signaling_ = 0;
  uint32_t retry_multicast_dst_blockid_ = 0;

  // 2SM sync
  Pipeline2SmComm *retry_2sm_ptr_ = nullptr;
  uint32_t cta_2sm_rel_rank_ = 0;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // end namespace cutlass
