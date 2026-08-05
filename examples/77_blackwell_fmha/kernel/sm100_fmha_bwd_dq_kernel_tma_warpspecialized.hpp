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

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "cute/arch/simd_sm100.hpp"

#include "cutlass/arch/arch.h"
#include "cutlass/arch/memory_sm80.h"
#include "cutlass/gemm/collective/collective_builder.hpp"

#include "collective/fmha_common.hpp"

#include <cmath>

namespace cutlass::fmha::kernel {

using namespace cutlass::fmha::collective;

using namespace cute;

template<
    class ProblemShape,
    class Element,
    class ElementAcc,
    class TileShape,
    class Mask
>
struct Sm100FmhaBwdDQKernelTmaWarpSpecialized {

  static_assert(std::is_same_v<decltype(get<2>(TileShape{})), decltype(get<3>(TileShape{}))>);
  using TileShapeQ = decltype(get<0>(TileShape{})); // dim. Q
  static_assert(std::is_same_v<TileShapeQ, _256>, "tile shape Q must be 256"); 
  using TileShapeK = decltype(get<1>(TileShape{})); // dim. K
  using TileShapeDQK = decltype(get<2>(TileShape{})); // dim. D
  using TileShapeDDOV = decltype(get<3>(TileShape{})); // dim. D

  using ClusterShape = Shape<_2, _1, _1>;
  using TmemAllocator = cute::TMEM::Allocator2Sm;
  using Schedule = cutlass::gemm::KernelTmaWarpSpecialized2SmSm100;

  struct TmemAllocation {
    static constexpr uint32_t kSizeS  = TileShapeK{} * sizeof(ElementAcc) / _4{};
    static constexpr uint32_t kSizeDP = kSizeS;
    static constexpr uint32_t kSizeDS = kSizeDP;
    static constexpr uint32_t kSizeDQ = TileShapeDQK{} * sizeof(ElementAcc) / _4{};

    static constexpr uint32_t kS0 = 0;
    static constexpr uint32_t kDP0 = kS0;
    static constexpr uint32_t kDS0 = kDP0;

    static constexpr uint32_t kS1  = kDS0 + kSizeDS;
    static constexpr uint32_t kDP1 = kS1;
    static constexpr uint32_t kDS1 = kDP1;

    static constexpr uint32_t kDQ0 = kDS1 + kSizeDS;
    static constexpr uint32_t kDQ1 = kDQ0 + kSizeDQ;
    static constexpr uint32_t kTotal = kDQ1 + kSizeDQ;
  };

  static_assert(
      static_cast<int>(TmemAllocation::kTotal) <= TmemAllocator::Sm100TmemCapacityColumns,
      "using too much tmem"
  );

  enum class WarpRole {
    Empty = 0x0, Load = 0x1, Mma = 0x2, Compute = 0x3
  };

  static constexpr unsigned long long kWarpAssignment = 0x12'3333ull;
  static constexpr int kNumComputeWarps = 4;
  CUTLASS_DEVICE WarpRole warp_idx_to_role(int warp_idx) {
    return static_cast<WarpRole>((kWarpAssignment >> (4 * warp_idx)) & 0xF);
  }

  struct RegisterAllocation {
    static constexpr int kWarpgroup0 = 240;
    static constexpr int kWarpgroup1 = 64;
    static constexpr int kCompute = kWarpgroup0;
    static constexpr int kMma = kWarpgroup1;
    static constexpr int kEmpty = kWarpgroup0;
    static constexpr int kLoad = kWarpgroup1;

    static_assert(kWarpgroup0 + kWarpgroup1 <= 512);
  };

  using ArchTag = cutlass::arch::Sm100;

  static constexpr int MinBlocksPerMultiprocessor = 1;
  static constexpr int kNumWarps = kNumComputeWarps + 4;
  static constexpr int MaxThreadsPerBlock = NumThreadsPerWarp * kNumWarps;

  static constexpr int Alignment = 128 / sizeof_bits_v<Element>;
  static constexpr int kStages = 2;

  using TensorStrideContiguousK = Stride<int, _1, Stride<Stride<int,int>, int>>;
  using TensorStrideContiguousK_GQA = Stride<int, _1, Stride<Stride<_0,int>, int>>;
  using TensorStrideContiguousMN = Stride<_1, int, Stride<Stride<int,int>, int>>;
  using TensorStrideContiguousMN_GQA = Stride<_1, int, Stride<Stride<_0,int>, int>>;

  // compute S
  using CollectiveMmaQK = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      Element, TensorStrideContiguousK, Alignment,
      Element, TensorStrideContiguousK_GQA, Alignment,
      ElementAcc,
      Shape<TileShapeQ, TileShapeK, TileShapeDQK>,
      ClusterShape, cutlass::gemm::collective::StageCount<kStages>,
      Schedule>::CollectiveOp;
  using TileShapeQK = typename CollectiveMmaQK::TileShape;
  using CtaShapeQK = typename CollectiveMmaQK::CtaShape_MNK;
  using TiledMmaQK = typename CollectiveMmaQK::TiledMma;

  // compute dP
  using CollectiveMmaDOV = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      Element, TensorStrideContiguousK, Alignment,
      Element, TensorStrideContiguousK_GQA, Alignment,
      ElementAcc,
      Shape<TileShapeQ, TileShapeK, TileShapeDDOV>,
      ClusterShape, cutlass::gemm::collective::StageCount<kStages>,
      Schedule>::CollectiveOp;
  using TileShapeDOV = typename CollectiveMmaDOV::TileShape;
  using CtaShapeDOV = typename CollectiveMmaDOV::CtaShape_MNK;
  using TiledMmaDOV = typename CollectiveMmaDOV::TiledMma;

  // compute dQ
  using CollectiveMmaDSK = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      Element, TensorStrideContiguousK, Alignment,
      Element, TensorStrideContiguousMN_GQA, Alignment,
      ElementAcc,
      Shape<TileShapeQ, TileShapeDQK, TileShapeK>,
      ClusterShape, cutlass::gemm::collective::StageCount<kStages>,
      Schedule>::CollectiveOp;
  using TileShapeDSK = typename CollectiveMmaDSK::TileShape;
  using CtaShapeDSK  = typename CollectiveMmaDSK::CtaShape_MNK;
  using TiledMmaDSK =  decltype(to_tiled_mma_sm100_ts(typename CollectiveMmaDSK::TiledMma{}));

  using AtomThrShapeMNK = typename CollectiveMmaQK::AtomThrShapeMNK;

  static_assert(size(AtomThrShapeMNK{}) == _2{}, "Only 2 SM supported");

  using PipelineLoadMmaK = PipelineTmaUmmaAsync<1, ClusterShape, AtomThrShapeMNK>;
  using PipelineLoadMmaKT = PipelineTmaUmmaAsync<1, ClusterShape, AtomThrShapeMNK>;
  using PipelineLoadMmaV = PipelineTmaUmmaAsync<1, ClusterShape, AtomThrShapeMNK>;
  using PipelineMmaComputeS = PipelineUmmaAsync<1, AtomThrShapeMNK>;
  using PipelineComputeMmaDS = PipelineUmmaConsumerAsync<1, AtomThrShapeMNK>;
  using PipelineMmaComputeDQ = PipelineUmmaAsync<2, AtomThrShapeMNK>;
  using PipelineLoadComputeSumOdOLSE = PipelineAsync<1>;

  struct PipelineStorage {
    alignas(16) typename PipelineLoadMmaK::SharedStorage load_mma_k;
    alignas(16) typename PipelineLoadMmaKT::SharedStorage load_mma_kt;
    alignas(16) typename PipelineLoadMmaV::SharedStorage load_mma_v;
    alignas(16) typename PipelineMmaComputeS::SharedStorage mma_compute_s0;
    alignas(16) typename PipelineComputeMmaDS::SharedStorage compute_mma_ds0;
    alignas(16) typename PipelineMmaComputeS::SharedStorage mma_compute_s1;
    alignas(16) typename PipelineComputeMmaDS::SharedStorage compute_mma_ds1;
    alignas(16) typename PipelineMmaComputeDQ::SharedStorage mma_compute_dq0;
    alignas(16) typename PipelineMmaComputeDQ::SharedStorage mma_compute_dq1;
    alignas(16) typename PipelineLoadComputeSumOdOLSE::SharedStorage load_compute_sum_odo_lse;
  };

  template<class Layout, class Stages = _1>
  static CUTE_DEVICE constexpr auto restage(Layout const& layout, Stages stages = {}) {
    return composition(layout, make_tuple(_, _, _, make_layout(stages)));
  }

  using SmemLayoutQ = decltype(restage(typename CollectiveMmaQK::SmemLayoutA{}, _2{}));
  using SmemLayoutK = decltype(restage(typename CollectiveMmaQK::SmemLayoutB{}, _1{}));
  using SmemLayoutDO = decltype(restage(typename CollectiveMmaDOV::SmemLayoutA{}, _2{}));
  using SmemLayoutV = decltype(restage(typename CollectiveMmaDOV::SmemLayoutB{}, _1{}));
  using SmemLayoutLSE = Layout<Shape<decltype(TileShapeQ{}/_2{}), _2>>;
  using SmemLayoutSumOdO = Layout<Shape<decltype(TileShapeQ{}/_2{}), _2>>;
  using SmemLayoutKT = decltype(restage(typename CollectiveMmaDSK::SmemLayoutB{}, _1{}));

  struct TensorStorage {
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutK>> smem_k;
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutKT>> smem_kt;
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutV>> smem_v;
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutQ>> smem_q;
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutDO>> smem_do;
    alignas(16) cute::array<ElementAcc, cute::cosize_v<SmemLayoutLSE>> smem_lse;
    alignas(16) cute::array<ElementAcc, cute::cosize_v<SmemLayoutSumOdO>> smem_sum_odo;
  };

  static constexpr int kTransactionsBytesLoadQ = size(AtomThrShapeMNK{}) * cutlass::bits_to_bytes(cosize(take<0,3>(SmemLayoutQ{})) * cute::sizeof_bits_v<Element>);
  static constexpr int kTransactionsBytesLoadDO = size(AtomThrShapeMNK{}) * cutlass::bits_to_bytes(cosize(take<0,3>(SmemLayoutDO{})) * cute::sizeof_bits_v<Element>);

  static constexpr int kTransactionsBytesLoadK = size(AtomThrShapeMNK{}) *  cutlass::bits_to_bytes(cosize(take<0,3>(SmemLayoutK{})) * cute::sizeof_bits_v<Element>);
  static constexpr int kTransactionsBytesLoadV = size(AtomThrShapeMNK{}) * cutlass::bits_to_bytes(cosize(take<0,3>(SmemLayoutV{})) * cute::sizeof_bits_v<Element>);

  struct SharedStorage {
    TensorStorage tensors;
    PipelineStorage pipelines;
    uint32_t tmem_base_ptr;
  };

  // this is tight enough that it won't work with sizeof due to padding for alignment
  static constexpr int SharedStorageSize = offsetof(SharedStorage, tmem_base_ptr) + sizeof(uint32_t);
  static_assert(SharedStorageSize <= cutlass::arch::sm100_smem_capacity_bytes, "using too much smem");

  using TensorStride = TensorStrideContiguousK;  // S D (H B)
  using TensorStride_GQA = TensorStrideContiguousK_GQA;
  using RowTensorStride = Stride<_1, Stride<Stride<int, int>, int>>;    // S (H B)

  struct MainloopArguments {
    const Element* ptr_q;
    TensorStride stride_q;
    const Element* ptr_k;
    TensorStride_GQA stride_k;
    const Element* ptr_v;
    TensorStride_GQA stride_v;
    const Element* ptr_do;
    TensorStride stride_do;
    
    const ElementAcc* ptr_lse;
    RowTensorStride stride_lse;

    const ElementAcc* ptr_sum_odo;
    RowTensorStride stride_sum_odo;

    ElementAcc softmax_scale = 1.0f / sqrtf(TileShapeDQK{});
  };

  using TMA_Q = typename CollectiveMmaQK::Params::TMA_A;
  using TMA_DO = typename CollectiveMmaDOV::Params::TMA_A;
  using TMA_K = typename CollectiveMmaQK::Params::TMA_B;
  using TMA_V = typename CollectiveMmaDOV::Params::TMA_B;
  using TMA_KT = typename CollectiveMmaDSK::Params::TMA_B;

  struct MainloopParams {
    TMA_Q tma_load_q;
    TMA_DO tma_load_do;
    TMA_K tma_load_k;
    TMA_V tma_load_v;
    TMA_KT tma_load_kt;
  };

  struct EpilogueArguments {
    Element* ptr_dq;
    TensorStride stride_dq;
  };

  struct Arguments {
    ProblemShape problem_shape;
    MainloopArguments mainloop;
    EpilogueArguments epilogue;
    KernelHardwareInfo hw_info;
  };

  struct Params {
    ProblemShape problem_shape;
    MainloopArguments mainloop;
    MainloopParams mainloop_params;
    EpilogueArguments epilogue;
    KernelHardwareInfo hw_info;
  };


  static bool can_implement(Arguments const& args) {
    auto [Q, K, D, D_VO, HB] = args.problem_shape;
    auto [H, B] = HB;
    auto [H_R, H_K] = H;
    if (Q <= 0 || K <= 0 || D <= 0 || D_VO <= 0 || H_R <= 0 || H_K <= 0 || B <= 0) {
      return false;
    }
    if (D % Alignment != 0 || D_VO % Alignment != 0) {
      return false;
    }
    return true;
  }


  static Status initialize_workspace(Arguments const&, void*, cudaStream_t) {
    return Status::kSuccess;
  }


  static Params to_underlying_arguments(Arguments const& args, void*) {
    auto [Q_, K_, D, D_VO, HB] = args.problem_shape;
    int Q = Q_;
    int K = K_;

    if constexpr (is_variable_length_v<decltype(Q_)>) {
      Q = Q_.total_length;
    }
    if constexpr (is_variable_length_v<decltype(K_)>) {
      K = K_.total_length;
    }

    auto params_qk = CollectiveMmaQK::to_underlying_arguments(
      make_shape(Q, K, D, HB),
      typename CollectiveMmaQK::Arguments {
        args.mainloop.ptr_q, args.mainloop.stride_q,
        args.mainloop.ptr_k, args.mainloop.stride_k,
      }, /*workspace=*/nullptr);

    auto params_dov = CollectiveMmaDOV::to_underlying_arguments(
      make_shape(Q, K, D_VO, HB),
      typename CollectiveMmaDOV::Arguments {
        args.mainloop.ptr_do, args.mainloop.stride_do,
        args.mainloop.ptr_v, args.mainloop.stride_v,
      }, /*workspace=*/nullptr);

    // construct TMA descriptor for KT
    auto cluster_layout_vmnk = tiled_divide(make_layout(ClusterShape{}), make_tile(typename TiledMmaDSK::AtomThrID{}));
    auto tensor_kt = make_tensor(args.mainloop.ptr_k, make_layout(make_shape(D, K, HB),
    make_stride(get<1>(args.mainloop.stride_k), get<0>(args.mainloop.stride_k), get<2>(args.mainloop.stride_k))));

    TMA_KT dsk_tma_load_b = make_tma_atom_B_sm100<typename TiledMmaDSK::ValTypeB>(
        typename CollectiveMmaDSK::GmemTiledCopyB{},
        tensor_kt,
        SmemLayoutKT{}(_,_,_,_0{}),
        TileShapeDSK{},
        TiledMmaDSK{},
        cluster_layout_vmnk);

    return Params{
      args.problem_shape,
      args.mainloop,
      MainloopParams{
        params_qk.tma_load_a,
        params_dov.tma_load_a,
        params_qk.tma_load_b,
        params_dov.tma_load_b,
	dsk_tma_load_b
      },
      args.epilogue,
      args.hw_info
    };
  }


  template<class T>
  static CUTLASS_DEVICE auto quantize(T const& input) {
    constexpr int AlignmentS = 4;
    auto output = make_tensor<Element>(shape(input));
    auto input_vec = recast<Array<ElementAcc, AlignmentS>>(input);
    auto output_vec = recast<Array<Element, AlignmentS>>(output);

    cutlass::NumericArrayConverter<Element, ElementAcc, AlignmentS> epilogue_op;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size(input_vec); i++) {
      output_vec(i) = epilogue_op(input_vec(i));
    }

    return output;
  }


  template<class BlkCoord, class BlkOffset, class ProblemShape_>
  CUTLASS_DEVICE void load(
      BlkCoord const& blk_coord,
      BlkOffset const& blk_offset,
      ProblemShape_ const& problem_shape,
      int iter_count,
      MainloopArguments const& mainloop_args,
      MainloopParams const& mainloop_params,
      TensorStorage& shared_tensors,
      PipelineLoadMmaK& pipeline_load_mma_k,
      typename PipelineLoadMmaK::PipelineState& pipeline_load_mma_k_producer_state,
      PipelineLoadMmaKT& pipeline_load_mma_kt,
      typename PipelineLoadMmaKT::PipelineState& pipeline_load_mma_kt_producer_state,
      PipelineLoadMmaV& pipeline_load_mma_v,
      typename PipelineLoadMmaV::PipelineState& pipeline_load_mma_v_producer_state,
      PipelineLoadComputeSumOdOLSE& pipeline_load_compute_sum_odo_lse,
      typename PipelineLoadComputeSumOdOLSE::PipelineState& pipeline_load_compute_sum_odo_lse_producer_state) {

    auto [Q, K, D, D_VO, HB] = problem_shape;

    using X = Underscore;

    uint16_t mcast_mask = 0;
    auto [blk_coord_q, blk_coord_k, blk_coord_d, blk_coord_dv, blk_coord_batch] = blk_coord;

    auto mK_in = mainloop_params.tma_load_k.get_tma_tensor(make_shape(K, D, HB));
    auto mV_in = mainloop_params.tma_load_v.get_tma_tensor(make_shape(K, D_VO, HB));
    auto mQ_in = mainloop_params.tma_load_q.get_tma_tensor(make_shape(Q, D, HB));
    auto mDO_in = mainloop_params.tma_load_do.get_tma_tensor(make_shape(Q, D_VO, HB));

    auto mKT_in = mainloop_params.tma_load_kt.get_tma_tensor(make_shape(D, K, HB));

    auto mK = domain_offset(select<1,2,4>(blk_offset), mK_in);
    auto mV = domain_offset(select<1,3,4>(blk_offset), mV_in);
    auto mQ = domain_offset(select<0,2,4>(blk_offset), mQ_in);
    auto mDO = domain_offset(select<0,3,4>(blk_offset), mDO_in);
    auto mKT = domain_offset(select<2,1,4>(blk_offset), mKT_in);

    auto gQ = local_tile(mQ, TileShapeQK{}, make_coord(_,_,_), Step<_1, X, _1>{});
    auto gK = local_tile(mK, TileShapeQK{}, make_coord(_,_,_), Step<X, _1, _1>{});
    auto gDO = local_tile(mDO, TileShapeDOV{}, make_coord(_,_,_), Step<_1, X, _1>{});
    auto gV = local_tile(mV, TileShapeDOV{}, make_coord(_,_,_), Step<X, _1, _1>{});
    auto gKT = local_tile(mKT, TileShapeDSK{}, make_coord(_,_,_), Step<X, _1, _1>{});

    ThrMMA cta_mma_qk = TiledMmaQK{}.get_slice(blk_coord_q % size(AtomThrShapeMNK{}));
    ThrMMA cta_mma_dov = TiledMmaDOV{}.get_slice(blk_coord_q % size(AtomThrShapeMNK{}));
    ThrMMA cta_mma_dsk = TiledMmaDSK{}.get_slice(blk_coord_q % size(AtomThrShapeMNK{}));

    auto tSgQ = cta_mma_qk.partition_A(gQ);
    auto tSgK = cta_mma_qk.partition_B(gK);
    auto tDPgDO = cta_mma_dov.partition_A(gDO);
    auto tDPgV = cta_mma_dov.partition_B(gV);
    auto tDQgKT = cta_mma_dsk.partition_B(gKT);

    auto sQ = make_tensor(make_smem_ptr(shared_tensors.smem_q.begin()), SmemLayoutQ{});
    auto sK = make_tensor(make_smem_ptr(shared_tensors.smem_k.begin()), SmemLayoutK{});
    auto sV = make_tensor(make_smem_ptr(shared_tensors.smem_v.begin()), SmemLayoutV{});
    auto sDO = make_tensor(make_smem_ptr(shared_tensors.smem_do.begin()), SmemLayoutDO{});
    auto sKT = make_tensor(make_smem_ptr(shared_tensors.smem_kt.begin()), SmemLayoutKT{});

    auto [tKgK_mkl, tKsK] = tma_partition(
        mainloop_params.tma_load_k, _0{}, make_layout(_1{}),
        group_modes<0,3>(sK), group_modes<0,3>(tSgK));
    auto [tQgQ_mkl, tQsQ] = tma_partition(
        mainloop_params.tma_load_q, _0{}, make_layout(_1{}),
        group_modes<0,3>(sQ), group_modes<0,3>(tSgQ));
    auto [tVgV_mkl, tVsV] = tma_partition(
        mainloop_params.tma_load_v, _0{}, make_layout(_1{}),
        group_modes<0,3>(sV), group_modes<0,3>(tDPgV));
    auto [tDOgDO_mkl, tDOsDO] = tma_partition(
        mainloop_params.tma_load_do, _0{}, make_layout(_1{}),
        group_modes<0,3>(sDO), group_modes<0,3>(tDPgDO));
    auto [tKTgKT_mkl, tKTsKT] = tma_partition(
        mainloop_params.tma_load_kt, _0{}, make_layout(_1{}),
        group_modes<0,3>(sKT), group_modes<0,3>(tDQgKT));

    // load LSE
    auto blk_coord_q0 = (blk_coord_q / _2{} * _2{} + _0{}) * _2{} + (blk_coord_q % size(AtomThrShapeMNK{}));
    auto blk_coord_q1 = (blk_coord_q / _2{} * _2{} + _1{}) * _2{} + (blk_coord_q % size(AtomThrShapeMNK{}));

    constexpr int num_per_threads = get<0>(CtaShapeQK{}) / NumThreadsPerWarp;
    int thread_idx = threadIdx.x % NumThreadsPerWarp;

    pipeline_load_compute_sum_odo_lse.producer_acquire(pipeline_load_compute_sum_odo_lse_producer_state);

    int smem_idx = thread_idx * num_per_threads;
    int gmem_idx = get<0>(CtaShapeQK{}) * blk_coord_q0 + thread_idx * num_per_threads;
    auto mLSE = make_tensor(mainloop_args.ptr_lse, make_shape(Q, HB), mainloop_args.stride_lse);
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < num_per_threads; i++) {
      cutlass::arch::cp_async_zfill<4>(
          shared_tensors.smem_lse.begin() + smem_idx + i,
          &mLSE(gmem_idx + i, blk_coord_batch),
          gmem_idx + i < Q
      );
    }

    smem_idx = thread_idx * num_per_threads + get<0>(CtaShapeQK{});
    gmem_idx = get<0>(CtaShapeQK{}) * blk_coord_q1 + thread_idx * num_per_threads;
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < num_per_threads; i++) {
      cutlass::arch::cp_async_zfill<4>(
          shared_tensors.smem_lse.begin() + smem_idx + i,
          &mLSE(gmem_idx + i, blk_coord_batch),
          gmem_idx + i < Q
      );
    }

    pipeline_load_mma_k.producer_acquire(pipeline_load_mma_k_producer_state);
    auto tma_barrier = pipeline_load_mma_k.producer_get_barrier(pipeline_load_mma_k_producer_state);

    pipeline_load_mma_k.producer_expect_transaction(pipeline_load_mma_k_producer_state, kTransactionsBytesLoadQ * 2);
    
    // load Q
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_q.with(*tma_barrier, mcast_mask),
          tQgQ_mkl(_, blk_coord_q0/_2{}, _0{}, blk_coord_batch),
          tQsQ(_, _0{})
      );
      cute::copy(
          mainloop_params.tma_load_q.with(*tma_barrier, mcast_mask),
          tQgQ_mkl(_, blk_coord_q1/_2{}, _0{}, blk_coord_batch),
          tQsQ(_, _1{})
      );
    }
  
    int iter_index = 0;
    // load K
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_k.with(*tma_barrier, mcast_mask),
          tKgK_mkl(_, iter_index, _0{}, blk_coord_batch),
          tKsK(_, pipeline_load_mma_k_producer_state.index())
      );
    }

    ++pipeline_load_mma_k_producer_state;

    // load sum_OdO
    smem_idx = thread_idx * num_per_threads;
    gmem_idx = get<0>(CtaShapeQK{}) * blk_coord_q0 + thread_idx * num_per_threads;
    auto mSumOdO = make_tensor(mainloop_args.ptr_sum_odo, make_shape(Q, HB), mainloop_args.stride_sum_odo);
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < num_per_threads; i++) {
      cutlass::arch::cp_async_zfill<4>(
          shared_tensors.smem_sum_odo.begin() + smem_idx + i,
          &mSumOdO(gmem_idx + i, blk_coord_batch),
          gmem_idx + i < Q
      );
    }

    smem_idx = thread_idx * num_per_threads + get<0>(CtaShapeQK{});
    gmem_idx = get<0>(CtaShapeQK{}) * blk_coord_q1 + thread_idx * num_per_threads;
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < num_per_threads; i++) {
      cutlass::arch::cp_async_zfill<4>(
          shared_tensors.smem_sum_odo.begin() + smem_idx + i,
          &mSumOdO(gmem_idx + i, blk_coord_batch),
          gmem_idx + i < Q
      );
    }

    pipeline_load_mma_v.producer_acquire(pipeline_load_mma_v_producer_state);
    tma_barrier = pipeline_load_mma_v.producer_get_barrier(pipeline_load_mma_v_producer_state);

    pipeline_load_mma_v.producer_expect_transaction(pipeline_load_mma_v_producer_state, 2 * kTransactionsBytesLoadDO);

    // load dO
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_do.with(*tma_barrier, mcast_mask),
          tDOgDO_mkl(_, blk_coord_q0/_2{}, _0{}, blk_coord_batch),
          tDOsDO(_, _0{})
      );
      cute::copy(
          mainloop_params.tma_load_do.with(*tma_barrier, mcast_mask),
          tDOgDO_mkl(_, blk_coord_q1/_2{}, _0{}, blk_coord_batch),
          tDOsDO(_, _1{})
      );
    }

    // load V
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_v.with(*tma_barrier, mcast_mask),
          tVgV_mkl(_, iter_index, _0{}, blk_coord_batch),
          tVsV(_, pipeline_load_mma_v_producer_state.index())
      );
    }

    ++pipeline_load_mma_v_producer_state;

    pipeline_load_compute_sum_odo_lse.producer_commit(pipeline_load_compute_sum_odo_lse_producer_state, cutlass::arch::cpasync_barrier_arrive);
    ++pipeline_load_compute_sum_odo_lse_producer_state;

    iter_index += 1;

    while (iter_index < iter_count) {
      pipeline_load_mma_k.producer_acquire(pipeline_load_mma_k_producer_state);
      tma_barrier = pipeline_load_mma_k.producer_get_barrier(pipeline_load_mma_k_producer_state);

      // load K
      if (cute::elect_one_sync()) {
        cute::copy(
            mainloop_params.tma_load_k.with(*tma_barrier, mcast_mask),
            tKgK_mkl(_, iter_index, _0{}, blk_coord_batch),
            tKsK(_, pipeline_load_mma_k_producer_state.index())
        );
      }

      ++pipeline_load_mma_k_producer_state;

      pipeline_load_mma_kt.producer_acquire(pipeline_load_mma_kt_producer_state);
      tma_barrier = pipeline_load_mma_kt.producer_get_barrier(pipeline_load_mma_kt_producer_state);

      // load KT
      if (cute::elect_one_sync()) {
        cute::copy(
            mainloop_params.tma_load_kt.with(*tma_barrier, mcast_mask),
            tKTgKT_mkl(_, _0{}, iter_index-1, blk_coord_batch),
            tKTsKT(_, pipeline_load_mma_k_producer_state.index())
        );
      }

      ++pipeline_load_mma_kt_producer_state;

      pipeline_load_mma_v.producer_acquire(pipeline_load_mma_v_producer_state);
      tma_barrier = pipeline_load_mma_v.producer_get_barrier(pipeline_load_mma_v_producer_state);

      // load V
      if (cute::elect_one_sync()) {
        cute::copy(
            mainloop_params.tma_load_v.with(*tma_barrier, mcast_mask),
            tVgV_mkl(_, iter_index, _0{}, blk_coord_batch),
            tVsV(_, pipeline_load_mma_v_producer_state.index())
        );
      }

      ++pipeline_load_mma_v_producer_state;

      iter_index += 1;
    }
    pipeline_load_mma_kt.producer_acquire(pipeline_load_mma_kt_producer_state);
    tma_barrier = pipeline_load_mma_kt.producer_get_barrier(pipeline_load_mma_kt_producer_state);

    // load KT
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_kt.with(*tma_barrier, mcast_mask),
          tKTgKT_mkl(_, _0{}, iter_index-1, blk_coord_batch),
          tKTsKT(_, pipeline_load_mma_k_producer_state.index())
      );
    }

    ++pipeline_load_mma_kt_producer_state;
  }


  template<class BlkCoord, class ProblemShape_>
  CUTLASS_DEVICE void mma(
      BlkCoord const& blk_coord,
      ProblemShape_ const& problem_shape,
      int iter_count,
      MainloopArguments const& mainloop_args,
      TensorStorage& shared_tensors,
      PipelineLoadMmaK& pipeline_load_mma_k,
      typename PipelineLoadMmaK::PipelineState& pipeline_load_mma_k_consumer_state,
      PipelineLoadMmaKT& pipeline_load_mma_kt,
      typename PipelineLoadMmaKT::PipelineState& pipeline_load_mma_kt_consumer_state,
      PipelineLoadMmaV& pipeline_load_mma_v,
      typename PipelineLoadMmaV::PipelineState& pipeline_load_mma_v_consumer_state,
      PipelineMmaComputeS& pipeline_mma_compute_s0,
      typename PipelineMmaComputeS::PipelineState& pipeline_mma_compute_s0_producer_state,
      PipelineMmaComputeS& pipeline_mma_compute_s1,
      typename PipelineMmaComputeS::PipelineState& pipeline_mma_compute_s1_producer_state,
      PipelineComputeMmaDS& pipeline_compute_mma_ds0,
      typename PipelineComputeMmaDS::PipelineState& pipeline_compute_mma_ds0_consumer_state,
      PipelineComputeMmaDS& pipeline_compute_mma_ds1,
      typename PipelineComputeMmaDS::PipelineState& pipeline_compute_mma_ds1_consumer_state,
      PipelineMmaComputeDQ& pipeline_mma_compute_dq0,
      typename PipelineMmaComputeDQ::PipelineState& pipeline_mma_compute_dq0_producer_state,
      PipelineMmaComputeDQ& pipeline_mma_compute_dq1,
      typename PipelineMmaComputeDQ::PipelineState& pipeline_mma_compute_dq1_producer_state) {

    auto [Q, K, D, D_VO, HB] = problem_shape;

    auto sQ = make_tensor(make_smem_ptr(shared_tensors.smem_q.begin()), SmemLayoutQ{});
    auto sK = make_tensor(make_smem_ptr(shared_tensors.smem_k.begin()), SmemLayoutK{});
    auto sDO = make_tensor(make_smem_ptr(shared_tensors.smem_do.begin()), SmemLayoutDO{});
    auto sV = make_tensor(make_smem_ptr(shared_tensors.smem_v.begin()), SmemLayoutV{});
    auto sKT = make_tensor(make_smem_ptr(shared_tensors.smem_kt.begin()), SmemLayoutKT{});

    auto tSrQ = TiledMmaQK::make_fragment_A(sQ);
    auto tSrK = TiledMmaQK::make_fragment_B(sK);

    auto tDPrDO = TiledMmaDOV::make_fragment_A(sDO);
    auto tDPrV  = TiledMmaDOV::make_fragment_B(sV);
    
    auto tDQ0rDS0 = make_tensor<typename TiledMmaDSK::FrgTypeA>(take<0,3>(typename CollectiveMmaDSK::SmemLayoutA{}));
    tDQ0rDS0.data() = TmemAllocation::kDS0;
    auto tDQ1rDS1 = make_tensor<typename TiledMmaDSK::FrgTypeA>(take<0,3>(typename CollectiveMmaDSK::SmemLayoutA{}));
    tDQ1rDS1.data() = TmemAllocation::kDS1;
    auto tDQrKT = TiledMmaDSK::make_fragment_B(sKT);

    TiledMmaQK tiled_mma_qk0, tiled_mma_qk1;
    TiledMmaDOV tiled_mma_dov0, tiled_mma_dov1;
    TiledMmaDSK tiled_mma_dsk0, tiled_mma_dsk1;

    tiled_mma_dsk0.accumulate_ = UMMA::ScaleOut::Zero;
    tiled_mma_dsk1.accumulate_ = UMMA::ScaleOut::Zero;

    auto tS0tS0 = TiledMmaQK::make_fragment_C(partition_shape_C(tiled_mma_qk0, select<0,1>(TileShapeQK{})));
    tS0tS0.data() = TmemAllocation::kS0;
    auto tS1tS1 = TiledMmaQK::make_fragment_C(partition_shape_C(tiled_mma_qk1, select<0,1>(TileShapeQK{})));
    tS1tS1.data() = TmemAllocation::kS1;

    auto tDP0tDP0 = TiledMmaDOV::make_fragment_C(partition_shape_C(tiled_mma_dov0, select<0,1>(TileShapeDOV{})));
    tDP0tDP0.data() = TmemAllocation::kDP0;
    auto tDP1tDP1 = TiledMmaDOV::make_fragment_C(partition_shape_C(tiled_mma_dov1, select<0,1>(TileShapeDOV{})));
    tDP1tDP1.data() = TmemAllocation::kDP1;

    auto tDQ0tDQ0 = TiledMmaDSK::make_fragment_C(partition_shape_C(tiled_mma_dsk0, select<0,1>(TileShapeDSK{})));
    tDQ0tDQ0.data() = TmemAllocation::kDQ0;
    auto tDQ1tDQ1 = TiledMmaDSK::make_fragment_C(partition_shape_C(tiled_mma_dsk1, select<0,1>(TileShapeDSK{})));
    tDQ1tDQ1.data() = TmemAllocation::kDQ1;

    pipeline_mma_compute_s0.producer_acquire(pipeline_mma_compute_s0_producer_state);
    pipeline_load_mma_k.consumer_wait(pipeline_load_mma_k_consumer_state);

    // S = Q*K
    tiled_mma_qk0.accumulate_ = UMMA::ScaleOut::Zero;
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tSrQ); ++k_block) {
      cute::gemm(tiled_mma_qk0,
                 tSrQ(_,_,k_block,_0{}),
                 tSrK(_,_,k_block,pipeline_load_mma_k_consumer_state.index()),
                 tS0tS0);
      tiled_mma_qk0.accumulate_ = UMMA::ScaleOut::One;
    }
    pipeline_mma_compute_s0.producer_commit(pipeline_mma_compute_s0_producer_state);
    ++pipeline_mma_compute_s0_producer_state;

    pipeline_mma_compute_s0.producer_acquire(pipeline_mma_compute_s0_producer_state);
    pipeline_load_mma_v.consumer_wait(pipeline_load_mma_v_consumer_state);

    // dP = dO*V
    tiled_mma_dov0.accumulate_ = UMMA::ScaleOut::Zero;
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tDPrDO); ++k_block) {
      cute::gemm(tiled_mma_dov0,
                 tDPrDO(_,_,k_block,_0{}),
                 tDPrV(_,_,k_block,pipeline_load_mma_v_consumer_state.index()),
                 tDP0tDP0);
      tiled_mma_dov0.accumulate_ = UMMA::ScaleOut::One;
    }
    pipeline_mma_compute_s0.producer_commit(pipeline_mma_compute_s0_producer_state);
    ++pipeline_mma_compute_s0_producer_state;

    pipeline_mma_compute_s1.producer_acquire(pipeline_mma_compute_s1_producer_state);
    // S = Q*K
    tiled_mma_qk1.accumulate_ = UMMA::ScaleOut::Zero;
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tSrQ); ++k_block) {
      cute::gemm(tiled_mma_qk1,
                 tSrQ(_,_,k_block,_1{}),
                 tSrK(_,_,k_block,pipeline_load_mma_k_consumer_state.index()),
                 tS1tS1);
      tiled_mma_qk1.accumulate_ = UMMA::ScaleOut::One;
    }
    pipeline_mma_compute_s1.producer_commit(pipeline_mma_compute_s1_producer_state);
    ++pipeline_mma_compute_s1_producer_state;

    pipeline_load_mma_k.consumer_release(pipeline_load_mma_k_consumer_state);
    ++pipeline_load_mma_k_consumer_state;

    pipeline_mma_compute_s1.producer_acquire(pipeline_mma_compute_s1_producer_state);
    // dP = dO*V
    tiled_mma_dov1.accumulate_ = UMMA::ScaleOut::Zero;
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tDPrDO); ++k_block) {
      cute::gemm(tiled_mma_dov1,
                 tDPrDO(_,_,k_block,_1{}),
                 tDPrV(_,_,k_block,pipeline_load_mma_v_consumer_state.index()),
                 tDP1tDP1);
      tiled_mma_dov1.accumulate_ = UMMA::ScaleOut::One;
    }
    pipeline_mma_compute_s1.producer_commit(pipeline_mma_compute_s1_producer_state);
    ++pipeline_mma_compute_s1_producer_state;

    pipeline_load_mma_v.consumer_release(pipeline_load_mma_v_consumer_state);
    ++pipeline_load_mma_v_consumer_state;

    iter_count -= 1;

    // dS & dP overlap
    while (iter_count > 0) {
      pipeline_mma_compute_s0.producer_acquire(pipeline_mma_compute_s0_producer_state);
      pipeline_compute_mma_ds0.consumer_wait(pipeline_compute_mma_ds0_consumer_state);
      pipeline_load_mma_kt.consumer_wait(pipeline_load_mma_kt_consumer_state);
      // dQ = dS*K
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tDQ0rDS0); ++k_block) {
        cute::gemm(tiled_mma_dsk0,
                   tDQ0rDS0(_,_,k_block),
                   tDQrKT(_,_,k_block,pipeline_load_mma_kt_consumer_state.index()),
                   tDQ0tDQ0);
        tiled_mma_dsk0.accumulate_ = UMMA::ScaleOut::One;
      }

      pipeline_load_mma_k.consumer_wait(pipeline_load_mma_k_consumer_state);
      // S = Q*K
      tiled_mma_qk0.accumulate_ = UMMA::ScaleOut::Zero;
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tSrQ); ++k_block) {
        cute::gemm(tiled_mma_qk0,
                   tSrQ(_,_,k_block,_0{}),
                   tSrK(_,_,k_block,pipeline_load_mma_k_consumer_state.index()),
                   tS0tS0);
        tiled_mma_qk0.accumulate_ = UMMA::ScaleOut::One;
      }

      pipeline_mma_compute_s0.producer_commit(pipeline_mma_compute_s0_producer_state);
      ++pipeline_mma_compute_s0_producer_state;

      pipeline_compute_mma_ds0.consumer_release(pipeline_compute_mma_ds0_consumer_state);
      ++pipeline_compute_mma_ds0_consumer_state;

      pipeline_mma_compute_s0.producer_acquire(pipeline_mma_compute_s0_producer_state);
      pipeline_load_mma_v.consumer_wait(pipeline_load_mma_v_consumer_state);      
      // dP = dO*V
      tiled_mma_dov0.accumulate_ = UMMA::ScaleOut::Zero;
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tDPrDO); ++k_block) {
        cute::gemm(tiled_mma_dov0,
                   tDPrDO(_,_,k_block,_0{}),
                   tDPrV(_,_,k_block,pipeline_load_mma_v_consumer_state.index()),
                   tDP0tDP0);
        tiled_mma_dov0.accumulate_ = UMMA::ScaleOut::One;
      }

      pipeline_mma_compute_s0.producer_commit(pipeline_mma_compute_s0_producer_state);
      ++pipeline_mma_compute_s0_producer_state;

      pipeline_mma_compute_s1.producer_acquire(pipeline_mma_compute_s1_producer_state);
      pipeline_compute_mma_ds1.consumer_wait(pipeline_compute_mma_ds1_consumer_state);
      // dQ = dS*K
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tDQ1rDS1); ++k_block) {
        cute::gemm(tiled_mma_dsk1,
                   tDQ1rDS1(_,_,k_block),
                   tDQrKT(_,_,k_block,pipeline_load_mma_kt_consumer_state.index()),
                   tDQ1tDQ1);
        tiled_mma_dsk1.accumulate_ = UMMA::ScaleOut::One;
      }

      pipeline_load_mma_kt.consumer_release(pipeline_load_mma_kt_consumer_state);
      ++pipeline_load_mma_kt_consumer_state;

      // S = Q*K
      tiled_mma_qk1.accumulate_ = UMMA::ScaleOut::Zero;
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tSrQ); ++k_block) {
        cute::gemm(tiled_mma_qk1,
                   tSrQ(_,_,k_block,_1{}),
                   tSrK(_,_,k_block,pipeline_load_mma_k_consumer_state.index()),
                   tS1tS1);
        tiled_mma_qk1.accumulate_ = UMMA::ScaleOut::One;
      }

      pipeline_mma_compute_s1.producer_commit(pipeline_mma_compute_s1_producer_state);
      ++pipeline_mma_compute_s1_producer_state;

      pipeline_load_mma_k.consumer_release(pipeline_load_mma_k_consumer_state);
      ++pipeline_load_mma_k_consumer_state;

      pipeline_compute_mma_ds1.consumer_release(pipeline_compute_mma_ds1_consumer_state);
      ++pipeline_compute_mma_ds1_consumer_state;

      pipeline_mma_compute_s1.producer_acquire(pipeline_mma_compute_s1_producer_state);
      // dP = dO*V
      tiled_mma_dov1.accumulate_ = UMMA::ScaleOut::Zero;
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tDPrDO); ++k_block) {
        cute::gemm(tiled_mma_dov1,
                   tDPrDO(_,_,k_block,_1{}),
                   tDPrV(_,_,k_block,pipeline_load_mma_v_consumer_state.index()),
                   tDP1tDP1);
        tiled_mma_dov1.accumulate_ = UMMA::ScaleOut::One;
      }

      pipeline_mma_compute_s1.producer_commit(pipeline_mma_compute_s1_producer_state);
      ++pipeline_mma_compute_s1_producer_state;

      pipeline_load_mma_v.consumer_release(pipeline_load_mma_v_consumer_state);
      ++pipeline_load_mma_v_consumer_state;

      iter_count -= 1;
    }
 
    pipeline_mma_compute_dq0.producer_acquire(pipeline_mma_compute_dq0_producer_state);   
    pipeline_compute_mma_ds0.consumer_wait(pipeline_compute_mma_ds0_consumer_state);
    pipeline_load_mma_kt.consumer_wait(pipeline_load_mma_kt_consumer_state);

    // dQ = dS*K
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tDQ0rDS0); ++k_block) {
      cute::gemm(tiled_mma_dsk0,
                 tDQ0rDS0(_,_,k_block),
                 tDQrKT(_,_,k_block,pipeline_load_mma_kt_consumer_state.index()),
                 tDQ0tDQ0);
      tiled_mma_dsk0.accumulate_ = UMMA::ScaleOut::One;
    }

    pipeline_mma_compute_dq0.producer_commit(pipeline_mma_compute_dq0_producer_state);
    ++pipeline_mma_compute_dq0_producer_state;

    pipeline_compute_mma_ds0.consumer_release(pipeline_compute_mma_ds0_consumer_state);
    ++pipeline_compute_mma_ds0_consumer_state;

    pipeline_mma_compute_dq1.producer_acquire(pipeline_mma_compute_dq1_producer_state);
    pipeline_compute_mma_ds1.consumer_wait(pipeline_compute_mma_ds1_consumer_state);

    // dQ = dS*K
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tDQ1rDS1); ++k_block) {
      cute::gemm(tiled_mma_dsk1,
                 tDQ1rDS1(_,_,k_block),
                 tDQrKT(_,_,k_block,pipeline_load_mma_kt_consumer_state.index()),
                 tDQ1tDQ1);
      tiled_mma_dsk1.accumulate_ = UMMA::ScaleOut::One;
    }

    pipeline_mma_compute_dq1.producer_commit(pipeline_mma_compute_dq1_producer_state);
    ++pipeline_mma_compute_dq1_producer_state;

    pipeline_compute_mma_ds1.consumer_release(pipeline_compute_mma_ds1_consumer_state);
    ++pipeline_compute_mma_ds1_consumer_state;

    pipeline_load_mma_kt.consumer_release(pipeline_load_mma_kt_consumer_state);
    ++pipeline_load_mma_kt_consumer_state;
  }

  template<class TensorG, class TensorR, class TensorC, class TensorShape>
  CUTLASS_DEVICE void store(
      TensorG gmem,
      TensorR const& regs,
      TensorC const& coord,
      TensorShape const& tensor_shape) {

    Tensor preds = cute::lazy::transform(coord, [&](auto const& c) { return elem_less(c, tensor_shape); });

    auto copy_op = make_cotiled_copy(
        Copy_Atom<UniversalCopy<uint128_t>, Element>{},
        make_layout(make_shape(_1{}, Int<sizeof(uint128_t) / sizeof(Element)>{})),
        regs.layout()
    );
    auto thr_copy = copy_op.get_slice(_0{});

    Tensor quantized_regs = quantize(regs);
    Tensor tCr = thr_copy.partition_S(quantized_regs);
    Tensor tCg = thr_copy.partition_D(gmem);
    Tensor tPc = thr_copy.partition_D(preds);

    copy_if(copy_op, tPc, tCr, tCg);
  }


  template<class Stage, class BlkCoord, class BlkOffset, class ProblemShape_>
  CUTLASS_DEVICE void epilogue_clear(
      Stage stage,
      BlkCoord const& blk_coord,
      BlkOffset const& blk_offset,
      ProblemShape_ const& problem_shape,
      MainloopArguments const& mainloop_args,
      EpilogueArguments const& epilogue_args) {

    auto [Q, K, D, D_VO, HB] = problem_shape;
    auto [blk_coord_q_, blk_coord_k, blk_coord_d, blk_coord_dv, blk_coord_batch] = blk_coord;

    auto blk_coord_q = (blk_coord_q_ / _2{} * _2{} + Stage{}) * _2{} + (blk_coord_q_ % size(AtomThrShapeMNK{}));

    auto mDQ_in = make_tensor(make_gmem_ptr(epilogue_args.ptr_dq), make_shape(Q, TileShapeDQK{}, HB), epilogue_args.stride_dq);
    auto mDQ = domain_offset(select<0,2,4>(blk_offset), mDQ_in);
    auto gDQ = local_tile(mDQ, CtaShapeDSK{}, make_coord(_,_,_), Step<_1, _1, X>{})
        (_, _, blk_coord_q, _0{}, blk_coord_batch);

    Tensor cDQ = domain_offset(
        make_coord(blk_coord_q * get<0>(CtaShapeDSK{}), _0{}),
        make_identity_tensor(take<0,2>(CtaShapeDSK{}))
    );

    for (int i = threadIdx.x; i < size(gDQ); i += blockDim.x) {
      if (elem_less(cDQ(i), select<0,2>(problem_shape))) {
        gDQ(i) = Element{0};
      }
    }
  }

  template<class Stage, class BlkCoord, class BlkOffset, class ProblemShape_>
  CUTLASS_DEVICE void epilogue(
      Stage stage,
      BlkCoord const& blk_coord,
      BlkOffset const& blk_offset,
      ProblemShape_ const& problem_shape,
      MainloopArguments const& mainloop_args,
      EpilogueArguments const& epilogue_args,
      PipelineMmaComputeDQ& pipeline_mma_compute_dq,
      typename PipelineMmaComputeDQ::PipelineState& pipeline_mma_compute_dq_consumer_state) {

    auto [Q, K, D, D_VO, HB] = problem_shape;
    auto [blk_coord_q_, blk_coord_k, blk_coord_d, blk_coord_dv, blk_coord_batch] = blk_coord;
    
    auto load_op = SM100_TMEM_LOAD_32dp32b32x{};
    
    auto tDQtDQ = partition_fragment_C(TiledMmaDSK{}, select<0,1>(TileShapeDSK{}))(make_coord(_,_),_0{},_0{});
    tDQtDQ.data() = is_same_v<Stage, _0> ? TmemAllocation::kDQ0 : TmemAllocation::kDQ1;

    auto blk_coord_q = (blk_coord_q_ / _2{} * _2{} + Stage{}) * _2{} + (blk_coord_q_ % size(AtomThrShapeMNK{}));

    auto mDQ_in = make_tensor(make_gmem_ptr(epilogue_args.ptr_dq), make_shape(Q, TileShapeDQK{}, HB), epilogue_args.stride_dq);
    auto mDQ = domain_offset(select<0,2,4>(blk_offset), mDQ_in);
    auto gDQ = local_tile(mDQ, CtaShapeDSK{}, make_coord(_,_,_), Step<_1, _1, X>{})
        (_, _, blk_coord_q, _0{}, blk_coord_batch);

    Tensor cDQ = domain_offset(
        make_coord(blk_coord_q * get<0>(CtaShapeDSK{}), _0{}),
        make_identity_tensor(take<0,2>(CtaShapeDSK{}))
    );

    auto tiled_t2r_dq = make_tmem_copy(load_op, tDQtDQ);
    auto thread_t2r_dq = tiled_t2r_dq.get_slice(threadIdx.x%size(tiled_t2r_dq));

    Tensor tTR_cDQ   = thread_t2r_dq.partition_D(cDQ);
    Tensor tTR_gDQ   = thread_t2r_dq.partition_D(gDQ);
    Tensor tTR_rDQ = make_tensor<ElementAcc>(shape(tTR_cDQ));
    Tensor tTR_tDQ = thread_t2r_dq.partition_S(tDQtDQ);

    pipeline_mma_compute_dq.consumer_wait(pipeline_mma_compute_dq_consumer_state);

    // load tDQtDQ
    cute::copy(tiled_t2r_dq, tTR_tDQ, tTR_rDQ);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size(tTR_rDQ); i++) {
      tTR_rDQ(i) = mainloop_args.softmax_scale * tTR_rDQ(i);
    }

    // store tDQgDQ
    store(tTR_gDQ, tTR_rDQ, tTR_cDQ, select<0,2>(problem_shape));

    pipeline_mma_compute_dq.consumer_release(pipeline_mma_compute_dq_consumer_state);
    ++pipeline_mma_compute_dq_consumer_state;
  }

  template<class BlkCoord, class BlkOffset, class ProblemShape_>
  CUTLASS_DEVICE void compute(
      BlkCoord const& blk_coord,
      BlkOffset const& blk_offset,
      ProblemShape_ const& problem_shape,
      int iter_count,
      MainloopArguments const& mainloop_args,
      EpilogueArguments const& epilogue_args,
      TensorStorage& shared_tensors,
      PipelineMmaComputeS& pipeline_mma_compute_s0,
      typename PipelineMmaComputeS::PipelineState& pipeline_mma_compute_s0_consumer_state,
      PipelineMmaComputeS& pipeline_mma_compute_s1,
      typename PipelineMmaComputeS::PipelineState& pipeline_mma_compute_s1_consumer_state,
      PipelineComputeMmaDS& pipeline_compute_mma_ds0,
      typename PipelineComputeMmaDS::PipelineState& pipeline_compute_mma_ds0_producer_state,
      PipelineComputeMmaDS& pipeline_compute_mma_ds1,
      typename PipelineComputeMmaDS::PipelineState& pipeline_compute_mma_ds1_producer_state,
      PipelineMmaComputeDQ& pipeline_mma_compute_dq0,
      typename PipelineMmaComputeDQ::PipelineState& pipeline_mma_compute_dq0_consumer_state,
      PipelineMmaComputeDQ& pipeline_mma_compute_dq1,
      typename PipelineMmaComputeDQ::PipelineState& pipeline_mma_compute_dq1_consumer_state,
      PipelineLoadComputeSumOdOLSE& pipeline_load_compute_sum_odo_lse,
      typename PipelineLoadComputeSumOdOLSE::PipelineState& pipeline_load_compute_sum_odo_lse_consumer_state) {


    auto [Q, K, D, D_VO, HB] = problem_shape;

    auto load_op = SM100_TMEM_LOAD_32dp32b32x{};
    auto store_op = SM100_TMEM_STORE_32dp32b32x{};
    
    Tensor tStS =  partition_fragment_C(TiledMmaQK{}, select<0,1>(TileShapeQK{}))(make_coord(_,_),_0{},_0{});
    Tensor tDPtDP =  partition_fragment_C(TiledMmaDOV{}, select<0,1>(TileShapeDOV{}))(make_coord(_,_),_0{},_0{});

    Tensor cS = make_identity_tensor(take<0,2>(CtaShapeQK{}));
    Tensor cDP = make_identity_tensor(take<0,2>(CtaShapeDOV{}));

    auto tiled_t2r = make_tmem_copy(load_op, tStS);
    auto thread_t2r = tiled_t2r.get_slice(threadIdx.x%size(tiled_t2r));

    Tensor tTR_cS = thread_t2r.partition_D(cS); 
    Tensor tTR_rS = make_tensor<ElementAcc>(shape(tTR_cS));

    Tensor tTR_cDP = thread_t2r.partition_D(cDP);
    Tensor tTR_rDP = make_tensor<ElementAcc>(shape(tTR_cDP));
    
    auto tDQrDS = make_tensor<typename TiledMmaDSK::FrgTypeA>(take<0,3>(typename CollectiveMmaDSK::SmemLayoutA{}));
    auto tiled_r2t = make_tmem_copy(store_op, tDQrDS);
    auto thread_r2t = tiled_r2t.get_slice(threadIdx.x%size(tiled_r2t));

    auto tDQcDP = TiledMmaDSK{}.get_slice(get<0>(blk_coord)%size(AtomThrShapeMNK{})).partition_A(cDP);
    auto tRT_cDS = thread_r2t.partition_S(tDQcDP);
    
    Tensor sLSE = make_tensor(make_smem_ptr(shared_tensors.smem_lse.begin()), SmemLayoutLSE{});
    Tensor sSumOdO = make_tensor(make_smem_ptr(shared_tensors.smem_sum_odo.begin()), SmemLayoutSumOdO{});
  
    int last_iter = iter_count - 1;
    int iter_index = 0;

    pipeline_load_compute_sum_odo_lse.consumer_wait(pipeline_load_compute_sum_odo_lse_consumer_state);

    CUTLASS_PRAGMA_NO_UNROLL
    while (iter_index < iter_count) {

      auto dispatch_bool = [](bool b, auto fn) {
        if (b) {
          fn(cute::true_type{});
        }
        else {
          fn(cute::false_type{});
        }
      };

      auto softmax_dsoftmax = [&](auto stage) {
        using Stage = decltype(stage);

        auto blk_coord_q = (get<0>(blk_coord) / _2{} * _2{} + Stage{}) * _2{} + (get<0>(blk_coord)%size(AtomThrShapeMNK{}));
        bool is_residual_q = blk_coord_q * get<0>(CtaShapeQK{}) >= get<0>(problem_shape);

        bool leading_causal_masking = false;
        if constexpr (std::is_base_of_v<cutlass::fmha::collective::CausalMask<true>, Mask>) {
	  leading_causal_masking = warp_uniform(iter_index >= blk_coord_q);
        } else if constexpr (std::is_base_of_v<cutlass::fmha::collective::CausalMask<false>, Mask>) {
          int offset = get<1>(problem_shape) - get<0>(problem_shape);
          int q_left = blk_coord_q * get<0>(CtaShapeQK{}) + offset;
          int q_right = q_left + get<0>(CtaShapeQK{}) - 1;
          int kv_left = iter_index * TileShapeK{};
          int kv_right = kv_left + TileShapeK{} - 1;

          leading_causal_masking = warp_uniform(!((q_left > kv_right) || (q_right < kv_left)));
        }
        bool trailing_residual_masking = false;
        if constexpr (std::is_base_of_v<cutlass::fmha::collective::ResidualMaskForBackward, Mask>) {
          trailing_residual_masking = warp_uniform((iter_index == last_iter) || is_residual_q);
        }

        // wait for S
        // compute P = softmax(S, LSE)
	if constexpr (Stage{} == _0{}) {
          pipeline_mma_compute_s0.consumer_wait(pipeline_mma_compute_s0_consumer_state);
        } else{
	  pipeline_mma_compute_s1.consumer_wait(pipeline_mma_compute_s1_consumer_state);		
        }

	constexpr ElementAcc log2_e = static_cast<ElementAcc>(M_LOG2E);
        float2 softmax_scale_log2_e;
        softmax_scale_log2_e.x = mainloop_args.softmax_scale * log2_e;
        softmax_scale_log2_e.y = mainloop_args.softmax_scale * log2_e;

	constexpr int kMufuPipeCount = 90;

	dispatch_bool(leading_causal_masking || trailing_residual_masking, [&](auto is_masked_tile) {
          tStS.data() = is_same_v<Stage, _0> ? TmemAllocation::kS0 : TmemAllocation::kS1;
          auto tTR_tS = thread_t2r.partition_S(tStS);
          cute::copy(tiled_t2r, tTR_tS, tTR_rS);

          // release S
          if constexpr (Stage{} == _0{}) {
            pipeline_mma_compute_s0.consumer_release(pipeline_mma_compute_s0_consumer_state);
            ++pipeline_mma_compute_s0_consumer_state;
          } else {
            pipeline_mma_compute_s1.consumer_release(pipeline_mma_compute_s1_consumer_state);
            ++pipeline_mma_compute_s1_consumer_state;
          }

          if constexpr (decltype(is_masked_tile)::value) {
            Mask{}.apply_mask(tTR_rS, [&](int i) {
              auto c = tTR_cS(i);
              return make_coord(get<0>(c) + blk_coord_q * get<0>(CtaShapeQK{}), get<1>(c) + iter_index * TileShapeK{});
            },   problem_shape);
          }

	  CUTLASS_PRAGMA_UNROLL
          for (int i = 0; i < kMufuPipeCount; i += 2) {
            float2 acc;
            float2 lse;
            float2 out;
            acc.x = tTR_rS(i);
            acc.y = tTR_rS(i + 1);
            lse.x = sLSE(get<0>(tTR_cS(i)), Stage{});
            lse.y = sLSE(get<0>(tTR_cS(i+1)), Stage{});
            cute::fma(out, softmax_scale_log2_e, acc, lse);
            tTR_rS(i) = ::exp2f(out.x);
            tTR_rS(i+1) = ::exp2f(out.y);
          }
        });

        // wait for dP
        if constexpr (Stage{} == _0{}) {
          pipeline_mma_compute_s0.consumer_wait(pipeline_mma_compute_s0_consumer_state);
          pipeline_compute_mma_ds0.producer_acquire(pipeline_compute_mma_ds0_producer_state);
        } else {
          pipeline_mma_compute_s1.consumer_wait(pipeline_mma_compute_s1_consumer_state);
          pipeline_compute_mma_ds1.producer_acquire(pipeline_compute_mma_ds1_producer_state);
        }

        // compute dS = dsoftmax(P, dP, sum_OdO)
        tDPtDP.data() = is_same_v<Stage, _0> ? TmemAllocation::kDP0 : TmemAllocation::kDP1;
        auto tTR_tDP = thread_t2r.partition_S(tDPtDP);
        cute::copy(tiled_t2r, tTR_tDP, tTR_rDP);

        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < size(tTR_rDP); i += 2) {
	  if (i + kMufuPipeCount < size(tTR_rDP)) {
	    float2 acc;
            float2 lse;
            float2 out;
            acc.x = tTR_rS(i + kMufuPipeCount);
            acc.y = tTR_rS(i + kMufuPipeCount + 1);
            lse.x = sLSE(get<0>(tTR_cS(i + kMufuPipeCount)), Stage{});
            lse.y = sLSE(get<0>(tTR_cS(i + kMufuPipeCount + 1)), Stage{});
            cute::fma(out, softmax_scale_log2_e, acc, lse);
            tTR_rS(i + kMufuPipeCount) = ::exp2f(out.x);
            tTR_rS(i + kMufuPipeCount + 1) = ::exp2f(out.y);
	  }

          float2 s;
          s.x = tTR_rS(i);
          s.y = tTR_rS(i+1);
          float2 dp;
          dp.x = tTR_rDP(i);
          dp.y = tTR_rDP(i+1);
          float2 odo;
          odo.x = sSumOdO(get<0>(tTR_cDP(i)), Stage{});
          odo.y = sSumOdO(get<0>(tTR_cDP(i+1)), Stage{});
          float2 dif;
          // sum odo is negated during preprocess
          cute::add(dif, dp, odo);
          float2 out;
          cute::mul(out, dif, s);
          tTR_rDP(i) = out.x;
          tTR_rDP(i+1) = out.y;
        }

        auto tRT_rDS = quantize(tTR_rDP);
        auto tRT_rDS_reshaped = composition(tRT_rDS, make_layout(shape(tRT_cDS)));

	tDQrDS.data() = is_same_v<Stage, _0> ? TmemAllocation::kDS0 : TmemAllocation::kDS1;
	auto tRT_tDS = thread_r2t.partition_D(tDQrDS);
        cute::copy(tiled_r2t, tRT_rDS_reshaped, tRT_tDS);

        // notify for dS
        cutlass::arch::fence_view_async_tmem_store();
        
	if constexpr (Stage{} == _0{}) {
          pipeline_compute_mma_ds0.producer_commit(pipeline_compute_mma_ds0_producer_state);
          ++pipeline_compute_mma_ds0_producer_state;

          // release dP
          pipeline_mma_compute_s0.consumer_release(pipeline_mma_compute_s0_consumer_state);
          ++pipeline_mma_compute_s0_consumer_state;
	} else {
	  pipeline_compute_mma_ds1.producer_commit(pipeline_compute_mma_ds1_producer_state);
          ++pipeline_compute_mma_ds1_producer_state;

          // release dP
          pipeline_mma_compute_s1.consumer_release(pipeline_mma_compute_s1_consumer_state);
          ++pipeline_mma_compute_s1_consumer_state;
	}
      };

      softmax_dsoftmax(_0{});
      softmax_dsoftmax(_1{});

      iter_index += 1;
    }

    pipeline_load_compute_sum_odo_lse.consumer_release(pipeline_load_compute_sum_odo_lse_consumer_state);
    ++pipeline_load_compute_sum_odo_lse_consumer_state;

    epilogue(
        _0{}, blk_coord, blk_offset, problem_shape, mainloop_args, epilogue_args,
        pipeline_mma_compute_dq0, pipeline_mma_compute_dq0_consumer_state
    );

    epilogue(
        _1{}, blk_coord, blk_offset, problem_shape, mainloop_args, epilogue_args,
        pipeline_mma_compute_dq1, pipeline_mma_compute_dq1_consumer_state
    );
  }


  CUTLASS_DEVICE void operator()(Params const& params, char* smem) {
    int warp_idx = cutlass::canonical_warp_idx_sync();
    auto role = warp_idx_to_role(warp_idx);
    uint32_t lane_predicate = cute::elect_one_sync();

    uint32_t cta_rank_in_cluster = cute::block_rank_in_cluster();
    int cta_coord_v = cta_rank_in_cluster % size<0>(AtomThrShapeMNK{});
    bool is_mma_leader_cta = cta_coord_v == 0;

    if (role == WarpRole::Load && lane_predicate) {
      prefetch_tma_descriptor(params.mainloop_params.tma_load_q.get_tma_descriptor());
      prefetch_tma_descriptor(params.mainloop_params.tma_load_k.get_tma_descriptor());
      prefetch_tma_descriptor(params.mainloop_params.tma_load_v.get_tma_descriptor());
      prefetch_tma_descriptor(params.mainloop_params.tma_load_do.get_tma_descriptor());
      prefetch_tma_descriptor(params.mainloop_params.tma_load_kt.get_tma_descriptor());
    }

    SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(smem);

    int initializing_warp = 0;
    typename PipelineLoadMmaK::Params pipeline_load_mma_k_params;
    if (role == WarpRole::Load) {
      pipeline_load_mma_k_params.role = PipelineLoadMmaK::ThreadCategory::Producer;
    }
    if (role == WarpRole::Mma) {
      pipeline_load_mma_k_params.role = PipelineLoadMmaK::ThreadCategory::Consumer;
    }
    pipeline_load_mma_k_params.is_leader = lane_predicate && (role == WarpRole::Load) && is_mma_leader_cta;
    // Also loads K in the first iteration
    pipeline_load_mma_k_params.transaction_bytes = kTransactionsBytesLoadK;
    pipeline_load_mma_k_params.initializing_warp = initializing_warp;
    PipelineLoadMmaK pipeline_load_mma_k(shared_storage.pipelines.load_mma_k, pipeline_load_mma_k_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineLoadMmaKT::Params pipeline_load_mma_kt_params;
    if (role == WarpRole::Load) {
      pipeline_load_mma_kt_params.role = PipelineLoadMmaKT::ThreadCategory::Producer;
    }
    if (role == WarpRole::Mma) {
      pipeline_load_mma_kt_params.role = PipelineLoadMmaKT::ThreadCategory::Consumer;
    }
    pipeline_load_mma_kt_params.is_leader = lane_predicate && (role == WarpRole::Load) && is_mma_leader_cta;
    // Also loads K in the first iteration
    pipeline_load_mma_kt_params.transaction_bytes = kTransactionsBytesLoadK;
    pipeline_load_mma_kt_params.initializing_warp = initializing_warp;
    PipelineLoadMmaKT pipeline_load_mma_kt(shared_storage.pipelines.load_mma_kt, pipeline_load_mma_kt_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineLoadMmaV::Params pipeline_load_mma_v_params;
    if (role == WarpRole::Load) {
      pipeline_load_mma_v_params.role = PipelineLoadMmaV::ThreadCategory::Producer;
    }
    if (role == WarpRole::Mma) {
      pipeline_load_mma_v_params.role = PipelineLoadMmaV::ThreadCategory::Consumer;
    }
    pipeline_load_mma_v_params.is_leader = lane_predicate && (role == WarpRole::Load) && is_mma_leader_cta;
    // Also loads V in the first iteration
    pipeline_load_mma_v_params.transaction_bytes = kTransactionsBytesLoadV;
    pipeline_load_mma_v_params.initializing_warp = initializing_warp++;
    PipelineLoadMmaV pipeline_load_mma_v(shared_storage.pipelines.load_mma_v, pipeline_load_mma_v_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineMmaComputeS::Params pipeline_mma_compute_s0_params;
    if (role == WarpRole::Mma) {
      pipeline_mma_compute_s0_params.role = PipelineMmaComputeS::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_mma_compute_s0_params.role = PipelineMmaComputeS::ThreadCategory::Consumer;
    }
    pipeline_mma_compute_s0_params.consumer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_mma_compute_s0_params.initializing_warp = initializing_warp;
    PipelineMmaComputeS pipeline_mma_compute_s0(
      shared_storage.pipelines.mma_compute_s0,
      pipeline_mma_compute_s0_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineMmaComputeS::Params pipeline_mma_compute_s1_params;
    if (role == WarpRole::Mma) {
      pipeline_mma_compute_s1_params.role = PipelineMmaComputeS::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_mma_compute_s1_params.role = PipelineMmaComputeS::ThreadCategory::Consumer;
    }
    pipeline_mma_compute_s1_params.consumer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_mma_compute_s1_params.initializing_warp = initializing_warp++;
    PipelineMmaComputeS pipeline_mma_compute_s1(
      shared_storage.pipelines.mma_compute_s1,
      pipeline_mma_compute_s1_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineComputeMmaDS::Params pipeline_compute_mma_ds0_params;
    if (role == WarpRole::Mma) {
      pipeline_compute_mma_ds0_params.role = PipelineComputeMmaDS::ThreadCategory::Consumer;
    }
    if (role == WarpRole::Compute) {
      pipeline_compute_mma_ds0_params.role = PipelineComputeMmaDS::ThreadCategory::Producer;
    }
    pipeline_compute_mma_ds0_params.producer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_compute_mma_ds0_params.consumer_arv_count = 1;
    pipeline_compute_mma_ds0_params.initializing_warp = initializing_warp;
    PipelineComputeMmaDS pipeline_compute_mma_ds0(
      shared_storage.pipelines.compute_mma_ds0,
      pipeline_compute_mma_ds0_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineComputeMmaDS::Params pipeline_compute_mma_ds1_params;
    if (role == WarpRole::Mma) {
      pipeline_compute_mma_ds1_params.role = PipelineComputeMmaDS::ThreadCategory::Consumer;
    }
    if (role == WarpRole::Compute) {
      pipeline_compute_mma_ds1_params.role = PipelineComputeMmaDS::ThreadCategory::Producer;
    }
    pipeline_compute_mma_ds1_params.producer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_compute_mma_ds1_params.consumer_arv_count = 1;
    pipeline_compute_mma_ds1_params.initializing_warp = initializing_warp++;
    PipelineComputeMmaDS pipeline_compute_mma_ds1(
      shared_storage.pipelines.compute_mma_ds1,
      pipeline_compute_mma_ds1_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineMmaComputeDQ::Params pipeline_mma_compute_dq0_params;
    if (role == WarpRole::Mma) {
      pipeline_mma_compute_dq0_params.role = PipelineMmaComputeDQ::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_mma_compute_dq0_params.role = PipelineMmaComputeDQ::ThreadCategory::Consumer;
    }
    pipeline_mma_compute_dq0_params.consumer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_mma_compute_dq0_params.initializing_warp = initializing_warp;
    PipelineMmaComputeDQ pipeline_mma_compute_dq0(
      shared_storage.pipelines.mma_compute_dq0,
      pipeline_mma_compute_dq0_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineMmaComputeDQ::Params pipeline_mma_compute_dq1_params;
    if (role == WarpRole::Mma) {
      pipeline_mma_compute_dq1_params.role = PipelineMmaComputeDQ::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_mma_compute_dq1_params.role = PipelineMmaComputeDQ::ThreadCategory::Consumer;
    }
    pipeline_mma_compute_dq1_params.consumer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_mma_compute_dq1_params.initializing_warp = initializing_warp++;
    PipelineMmaComputeDQ pipeline_mma_compute_dq1(
      shared_storage.pipelines.mma_compute_dq1,
      pipeline_mma_compute_dq1_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineLoadComputeSumOdOLSE::Params pipeline_load_compute_sum_odo_lse_params;
    if (role == WarpRole::Load) {
      pipeline_load_compute_sum_odo_lse_params.role = PipelineLoadComputeSumOdOLSE::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_load_compute_sum_odo_lse_params.role = PipelineLoadComputeSumOdOLSE::ThreadCategory::Consumer;
    }
    pipeline_load_compute_sum_odo_lse_params.producer_arv_count = NumThreadsPerWarp;
    pipeline_load_compute_sum_odo_lse_params.consumer_arv_count = kNumComputeWarps * NumThreadsPerWarp;
    pipeline_load_compute_sum_odo_lse_params.initializing_warp = initializing_warp;
    PipelineLoadComputeSumOdOLSE pipeline_load_compute_sum_odo_lse(
      shared_storage.pipelines.load_compute_sum_odo_lse,
      pipeline_load_compute_sum_odo_lse_params//,
      /*barrier init cute::true_type{}*/);
    
    TmemAllocator tmem_allocator;

    pipeline_init_arrive_relaxed(size(ClusterShape{}));

    pipeline_load_mma_k.init_masks(ClusterShape{});
    pipeline_load_mma_kt.init_masks(ClusterShape{});
    pipeline_load_mma_v.init_masks(ClusterShape{});
    pipeline_mma_compute_s0.init_masks(ClusterShape{});
    pipeline_mma_compute_s1.init_masks(ClusterShape{});
    pipeline_compute_mma_ds0.init_masks(ClusterShape{});
    pipeline_compute_mma_ds1.init_masks(ClusterShape{});
    pipeline_mma_compute_dq0.init_masks(ClusterShape{});
    pipeline_mma_compute_dq1.init_masks(ClusterShape{});

    typename decltype(pipeline_load_mma_k)::PipelineState pipeline_load_mma_k_consumer_state;
    typename decltype(pipeline_load_mma_kt)::PipelineState pipeline_load_mma_kt_consumer_state;
    typename decltype(pipeline_load_mma_v)::PipelineState pipeline_load_mma_v_consumer_state;
    typename decltype(pipeline_mma_compute_s0)::PipelineState pipeline_mma_compute_s0_consumer_state;
    typename decltype(pipeline_mma_compute_s1)::PipelineState pipeline_mma_compute_s1_consumer_state;
    typename decltype(pipeline_compute_mma_ds0)::PipelineState pipeline_compute_mma_ds0_consumer_state;
    typename decltype(pipeline_compute_mma_ds1)::PipelineState pipeline_compute_mma_ds1_consumer_state;
    typename decltype(pipeline_mma_compute_dq0)::PipelineState pipeline_mma_compute_dq0_consumer_state;
    typename decltype(pipeline_mma_compute_dq1)::PipelineState pipeline_mma_compute_dq1_consumer_state;
    typename decltype(pipeline_load_compute_sum_odo_lse)::PipelineState pipeline_load_compute_sum_odo_lse_consumer_state;

    auto pipeline_load_mma_k_producer_state = make_producer_start_state<decltype(pipeline_load_mma_k)>();
    auto pipeline_load_mma_kt_producer_state = make_producer_start_state<decltype(pipeline_load_mma_kt)>();
    auto pipeline_load_mma_v_producer_state = make_producer_start_state<decltype(pipeline_load_mma_v)>();
    auto pipeline_mma_compute_s0_producer_state = make_producer_start_state<decltype(pipeline_mma_compute_s0)>();
    auto pipeline_mma_compute_s1_producer_state = make_producer_start_state<decltype(pipeline_mma_compute_s1)>();
    auto pipeline_compute_mma_ds0_producer_state = make_producer_start_state<decltype(pipeline_compute_mma_ds0)>();
    auto pipeline_compute_mma_ds1_producer_state = make_producer_start_state<decltype(pipeline_compute_mma_ds1)>();
    auto pipeline_mma_compute_dq0_producer_state = make_producer_start_state<decltype(pipeline_mma_compute_dq0)>();
    auto pipeline_mma_compute_dq1_producer_state = make_producer_start_state<decltype(pipeline_mma_compute_dq1)>();
    auto pipeline_load_compute_sum_odo_lse_producer_state = make_producer_start_state<decltype(pipeline_load_compute_sum_odo_lse)>();

    pipeline_init_wait(size(ClusterShape{}));

    auto [Q, K, D, D_VO, HB] = params.problem_shape;
    auto [H, B] = HB;
    auto [H_R, H_K] = H;
    auto h_coord = idx2crd(blockIdx.y, make_layout(make_shape(H_R, H_K)));
    auto blk_coord = make_coord(blockIdx.x, _0{}, _0{}, _0{}, make_coord(h_coord, blockIdx.z));

    auto [problem_shape, blk_offset] = apply_variable_length_offset(
        params.problem_shape,
        blk_coord
    );
    int iter_count = ceil_div(get<1>(problem_shape), TileShapeK{});
    int iter_end = iter_count;
    if constexpr (std::is_base_of_v<cutlass::fmha::collective::CausalMask<true>, Mask>) {
      iter_end = min(iter_count, int(get<0>(blk_coord) / 2 * 2 * TileShapeQ{} / TileShapeK{}) + 2 * TileShapeQ{} / TileShapeK{});
    } else if constexpr (std::is_base_of_v<cutlass::fmha::collective::CausalMask<false>, Mask>) {
      int offset = get<1>(problem_shape) - get<0>(problem_shape);
      iter_end = min(iter_count, (int(get<0>(blk_coord) / 2 * 2 * TileShapeQ{}) + offset) / TileShapeK{} + 2 * TileShapeQ{} / TileShapeK{});
    }
    if (get<0>(blk_coord) / 2 * 2 * TileShapeQ{} >= get<0>(problem_shape)) {
      return;
    }
    iter_count = iter_end;

    if (iter_count <= 0) {
      epilogue_clear(
	  _0{},
          blk_coord,
          blk_offset,
          problem_shape,
          params.mainloop,
          params.epilogue
      );
      epilogue_clear(
          _1{},
          blk_coord,
          blk_offset,
          problem_shape,
          params.mainloop,
          params.epilogue
      );
      return;
    }

    if (role == WarpRole::Load) {
      warpgroup_reg_set<RegisterAllocation::kLoad>();

      load(
          blk_coord,
          blk_offset,
          problem_shape,
          iter_count,
          params.mainloop,
          params.mainloop_params,
          shared_storage.tensors,
          pipeline_load_mma_k, pipeline_load_mma_k_producer_state,
	  pipeline_load_mma_kt, pipeline_load_mma_kt_producer_state,
          pipeline_load_mma_v, pipeline_load_mma_v_producer_state,
	  pipeline_load_compute_sum_odo_lse, pipeline_load_compute_sum_odo_lse_producer_state
      );

    }
    else if (role == WarpRole::Mma) {
      warpgroup_reg_set<RegisterAllocation::kMma>();

      tmem_allocator.allocate(TmemAllocator::Sm100TmemCapacityColumns, &shared_storage.tmem_base_ptr);
      __syncwarp();
      if (is_mma_leader_cta) { 
        mma(
            blk_coord,
            problem_shape,
            iter_count,
            params.mainloop,
            shared_storage.tensors,
            pipeline_load_mma_k, pipeline_load_mma_k_consumer_state,
	    pipeline_load_mma_kt, pipeline_load_mma_kt_consumer_state,
            pipeline_load_mma_v, pipeline_load_mma_v_consumer_state,
            pipeline_mma_compute_s0, pipeline_mma_compute_s0_producer_state,
            pipeline_mma_compute_s1, pipeline_mma_compute_s1_producer_state,
            pipeline_compute_mma_ds0, pipeline_compute_mma_ds0_consumer_state,
	    pipeline_compute_mma_ds1, pipeline_compute_mma_ds1_consumer_state,
            pipeline_mma_compute_dq0, pipeline_mma_compute_dq0_producer_state,
	    pipeline_mma_compute_dq1, pipeline_mma_compute_dq1_producer_state
        );
      }
    }
    else if (role == WarpRole::Compute) {
      warpgroup_reg_set<RegisterAllocation::kCompute>();

      compute(
          blk_coord,
          blk_offset,
          problem_shape,
          iter_count,
          params.mainloop,
          params.epilogue,
          shared_storage.tensors,
          pipeline_mma_compute_s0, pipeline_mma_compute_s0_consumer_state,
	  pipeline_mma_compute_s1, pipeline_mma_compute_s1_consumer_state,
          pipeline_compute_mma_ds0, pipeline_compute_mma_ds0_producer_state,
	  pipeline_compute_mma_ds1, pipeline_compute_mma_ds1_producer_state,
          pipeline_mma_compute_dq0, pipeline_mma_compute_dq0_consumer_state,
	  pipeline_mma_compute_dq1, pipeline_mma_compute_dq1_consumer_state,
	  pipeline_load_compute_sum_odo_lse, pipeline_load_compute_sum_odo_lse_consumer_state
      );
    }
    else {
      warpgroup_reg_set<RegisterAllocation::kEmpty>();

      /* no-op */

    }

    __syncthreads();
    cute::cluster_sync();

    if (role == WarpRole::Mma) {
      uint32_t free_stage_ptr = shared_storage.tmem_base_ptr;
      tmem_allocator.free(free_stage_ptr, TmemAllocator::Sm100TmemCapacityColumns);
    }
   
  }

  static dim3 get_block_shape() {
    dim3 block(MaxThreadsPerBlock, 1, 1);
    return block;
  }

  static dim3 get_grid_shape(Params const& params) {
    auto [Q, K, D, D_VO, HB] = params.problem_shape;
    auto [H, B] = HB;
    auto [H_R, H_K] = H;
    dim3 grid(2 * ceil_div(Q, TileShapeQ{} * _2{}), H_R * H_K, B);
    return grid;
  }
};

}  // namespace cutlass::fmha::kernel
