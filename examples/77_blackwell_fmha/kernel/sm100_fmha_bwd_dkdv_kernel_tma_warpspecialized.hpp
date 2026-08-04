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
#include "cute/util/type_traits.hpp"

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
struct Sm100FmhaBwdDKDVKernelTmaWarpSpecialized {
  static_assert(std::is_same_v<decltype(get<2>(TileShape{})), decltype(get<3>(TileShape{}))>);
  using TileShapeQ = decltype(get<0>(TileShape{})); // Dim Q 
  using TileShapeK = decltype(get<1>(TileShape{})); // Dim K
  static_assert(std::is_same_v<TileShapeK, _256>, "tile shape K must be 256");
  using TileShapeDQK = decltype(get<2>(TileShape{})); // Dim D
  using TileShapeDVO = decltype(get<3>(TileShape{})); // Dim D

  using ClusterShape = Shape<_2, _1, _1>;
  using TmemAllocator = cute::TMEM::Allocator2Sm;
  using Schedule = cutlass::gemm::KernelTmaWarpSpecialized2SmSm100;

  struct TmemAllocation {
    static constexpr uint32_t kSizeDV =  TileShapeDVO{} * sizeof(ElementAcc) / _4{};
    static constexpr uint32_t kSizeDK =  TileShapeDQK{} * sizeof(ElementAcc) / _4{};

    static constexpr uint32_t kSizeP  = TileShapeQ{} * sizeof(ElementAcc) / _4{};
    static constexpr uint32_t kSizeDS = kSizeP;
      
    static constexpr uint32_t kDV = 0;
    static constexpr uint32_t kDK = kDV + kSizeDV;
    static constexpr uint32_t kS = kDK + kSizeDK;
    static constexpr uint32_t kP = kS;                  
    static constexpr uint32_t kDP = kP + kSizeP;
    static constexpr uint32_t kDS = kDP;
    static constexpr uint32_t kTotal = kDS + kSizeDS;
  };

  static_assert(
      TmemAllocation::kTotal <= TmemAllocator::Sm100TmemCapacityColumns,
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

  // compute S
  using CollectiveMmaKQ = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      Element, TensorStrideContiguousK_GQA, Alignment,
      Element, TensorStrideContiguousK, Alignment,
      ElementAcc,
      Shape<TileShapeK, TileShapeQ, TileShapeDQK>,
      ClusterShape, cutlass::gemm::collective::StageCount<kStages>,
      Schedule>::CollectiveOp;
  using TileShapeKQ = typename CollectiveMmaKQ::TileShape;
  using CtaShapeKQ = typename CollectiveMmaKQ::CtaShape_MNK;
  using TiledMmaKQ = typename CollectiveMmaKQ::TiledMma;

  // compute dP
  using CollectiveMmaVDO = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      Element, TensorStrideContiguousK_GQA, Alignment,
      Element, TensorStrideContiguousK, Alignment,
      ElementAcc,
      Shape<TileShapeK, TileShapeQ, TileShapeDVO>,
      ClusterShape, cutlass::gemm::collective::StageCount<kStages>,
      Schedule>::CollectiveOp;
  using TileShapeVDO = typename CollectiveMmaVDO::TileShape;
  using CtaShapeVDO = typename CollectiveMmaVDO::CtaShape_MNK;
  using TiledMmaVDO = typename CollectiveMmaVDO::TiledMma;
  
  // compute dV
  using CollectiveMmaPDO = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      // needs to match ordering of S calculation
      Element, TensorStrideContiguousK, Alignment,
      Element, TensorStrideContiguousMN, Alignment,
      ElementAcc,
      Shape<TileShapeK, TileShapeDVO, TileShapeQ>,
      ClusterShape, cutlass::gemm::collective::StageCount<kStages>,
      Schedule>::CollectiveOp;
  using TileShapePDO = typename CollectiveMmaPDO::TileShape;
  using CtaShapePDO  = typename CollectiveMmaPDO::CtaShape_MNK;
  using TiledMmaPDO = decltype(to_tiled_mma_sm100_ts(typename CollectiveMmaPDO::TiledMma{}));

  // compute dK
  using CollectiveMmaDSQ = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm100, cutlass::arch::OpClassTensorOp,
      // somewhat arbitrary since we dump to smem, need to agree with the next one
      Element, TensorStrideContiguousK , Alignment,
      Element, TensorStrideContiguousMN, Alignment,
      ElementAcc,
      Shape<TileShapeK, TileShapeDQK, TileShapeQ>,
      ClusterShape, cutlass::gemm::collective::StageCount<kStages>,
      Schedule>::CollectiveOp;
  using TileShapeDSQ = typename CollectiveMmaDSQ::TileShape;
  using CtaShapeDSQ  = typename CollectiveMmaDSQ::CtaShape_MNK;
  using TiledMmaDSQ = decltype(to_tiled_mma_sm100_ts(typename CollectiveMmaDSQ::TiledMma{}));

  using AtomThrShapeMNK = typename CollectiveMmaKQ::AtomThrShapeMNK;

  // pipelines are named Pipeline<Producer><Consumer><Resource>
  static constexpr int kComputeSDPStages = 1;
  static constexpr int kComputePDSStages = 1;
  static constexpr int LoadLSESumOdOStages = 1;

  using PipelineLoadMmaQ = PipelineTmaUmmaAsync<1, ClusterShape, AtomThrShapeMNK>;
  using PipelineLoadMmaQT = PipelineTmaUmmaAsync<1, ClusterShape, AtomThrShapeMNK>;
  using PipelineLoadMmaDO = PipelineTmaUmmaAsync<1, ClusterShape, AtomThrShapeMNK>;
  using PipelineLoadMmaDOT = PipelineTmaUmmaAsync<1, ClusterShape, AtomThrShapeMNK>;
  using PipelineLoadComputeLSE = PipelineAsync<LoadLSESumOdOStages>;
  using PipelineLoadComputeSumOdO = PipelineAsync<LoadLSESumOdOStages>;
  using PipelineMmaComputeS = PipelineUmmaAsync<kComputeSDPStages, AtomThrShapeMNK>;
  using PipelineMmaComputeDP = PipelineUmmaAsync<kComputeSDPStages, AtomThrShapeMNK>;
  using PipelineComputeMmaP  = PipelineUmmaConsumerAsync<kComputePDSStages, AtomThrShapeMNK>;
  using PipelineComputeMmaDS = PipelineUmmaConsumerAsync<kComputePDSStages, AtomThrShapeMNK>; 
  using PipelineMmaComputeDKDV = PipelineUmmaAsync<2, AtomThrShapeMNK>;

  struct PipelineStorage {
    alignas(16) typename PipelineLoadMmaQ::SharedStorage load_mma_q;
    alignas(16) typename PipelineLoadMmaDO::SharedStorage load_mma_do;
    alignas(16) typename PipelineLoadMmaQT::SharedStorage load_mma_qt;
    alignas(16) typename PipelineLoadMmaDOT::SharedStorage load_mma_dot;
    alignas(16) typename PipelineLoadComputeLSE::SharedStorage load_compute_lse;
    alignas(16) typename PipelineLoadComputeSumOdO::SharedStorage load_compute_sum_odo;
    alignas(16) typename PipelineMmaComputeS::SharedStorage mma_compute_s;
    alignas(16) typename PipelineMmaComputeDP::SharedStorage mma_compute_dp;
    alignas(16) typename PipelineComputeMmaP::SharedStorage compute_mma_p;
    alignas(16) typename PipelineComputeMmaDS::SharedStorage compute_mma_ds;
    alignas(16) typename PipelineMmaComputeDKDV::SharedStorage mma_compute_dkdv;
  };

  template<class Layout, class Stages = _1>
  static CUTE_DEVICE constexpr auto restage(Layout const& layout, Stages stages = {}) {
    return composition(layout, make_tuple(_, _, _, make_layout(stages)));
  }

  static constexpr int TilePerCta = 1;

  using SmemLayoutK = decltype(restage(typename CollectiveMmaKQ::SmemLayoutA{}, Int<TilePerCta>{}));
  using SmemLayoutV = decltype(restage(typename CollectiveMmaVDO::SmemLayoutA{}, Int<TilePerCta>{}));
  using SmemLayoutQ = decltype(restage(typename CollectiveMmaKQ::SmemLayoutB{}, _1{}));
  using SmemLayoutDO = decltype(restage(typename CollectiveMmaVDO::SmemLayoutB{}, _1{}));

  using SmemLayoutLSE = Layout<Shape<TileShapeQ, Int<LoadLSESumOdOStages> >>;
  using SmemLayoutSumOdO = Layout<Shape<TileShapeQ, Int<LoadLSESumOdOStages> >>;

  using SmemLayoutQT = decltype(restage(typename CollectiveMmaDSQ::SmemLayoutB{}, _1{}));
  using SmemLayoutDOT = decltype(restage(typename CollectiveMmaPDO::SmemLayoutB{}, _1{}));
  
  struct TensorStorage {
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutK>> smem_k;
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutV>> smem_v;
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutQ>> smem_q;
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutQT>> smem_qt;
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutDO>> smem_do;
    alignas(2048) cute::array<Element, cute::cosize_v<SmemLayoutDOT>> smem_dot;
    alignas(16) cute::array<ElementAcc, cute::cosize_v<SmemLayoutLSE>> smem_lse;
    alignas(16) cute::array<ElementAcc, cute::cosize_v<SmemLayoutSumOdO>> smem_sum_odo;
  };

  static constexpr int kTransactionsBytesLoadQ = size(AtomThrShapeMNK{}) * cutlass::bits_to_bytes(cosize(take<0,3>(SmemLayoutQ{})) * cute::sizeof_bits_v<Element>);
  static constexpr int kTransactionsBytesLoadDO = size(AtomThrShapeMNK{}) * cutlass::bits_to_bytes(cosize(take<0,3>(SmemLayoutDO{})) * cute::sizeof_bits_v<Element>);

  static constexpr int kTransactionsBytesLoadK = size(AtomThrShapeMNK{}) * cutlass::bits_to_bytes(cosize(take<0,3>(SmemLayoutK{})) * cute::sizeof_bits_v<Element>);
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

  using TMA_K = typename CollectiveMmaKQ::Params::TMA_A;
  using TMA_V = typename CollectiveMmaVDO::Params::TMA_A;
  using TMA_Q = typename CollectiveMmaKQ::Params::TMA_B;
  using TMA_DO = typename CollectiveMmaVDO::Params::TMA_B;
  using TMA_QT = typename CollectiveMmaDSQ::Params::TMA_B;
  using TMA_DOT = typename CollectiveMmaPDO::Params::TMA_B; 
 
  struct MainloopParams {
    TMA_K tma_load_k;
    TMA_V tma_load_v;
    TMA_Q tma_load_q;
    TMA_DO tma_load_do;
    TMA_QT tma_load_qt;
    TMA_DOT tma_load_dot;
  };

  struct EpilogueArguments {
    Element* ptr_dk;
    TensorStride_GQA stride_dk;
    Element* ptr_dv;
    TensorStride_GQA stride_dv;
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

    auto params_kq = CollectiveMmaKQ::to_underlying_arguments(
      make_shape(K, Q, D, HB),
      typename CollectiveMmaKQ::Arguments {
        args.mainloop.ptr_k, args.mainloop.stride_k,
        args.mainloop.ptr_q, args.mainloop.stride_q,
      }, /*workspace=*/nullptr);

    auto params_vdo = CollectiveMmaVDO::to_underlying_arguments(
      make_shape(K, Q, D_VO, HB),
      typename CollectiveMmaVDO::Arguments {
        args.mainloop.ptr_v, args.mainloop.stride_v,
        args.mainloop.ptr_do, args.mainloop.stride_do,
      }, /*workspace=*/nullptr);

    // explicitly construct TMA dscripstor 
    auto cluster_layout_vmnk = tiled_divide(make_layout(ClusterShape{}), make_tile(typename TiledMmaDSQ::AtomThrID{}));
    auto tensor_qt = make_tensor(args.mainloop.ptr_q, make_layout(make_shape(D, Q, HB), 
    make_stride(get<1>(args.mainloop.stride_q), get<0>(args.mainloop.stride_q), get<2>(args.mainloop.stride_q))));
    auto tensor_dot = make_tensor(args.mainloop.ptr_do, make_layout(make_shape(D_VO, Q, HB),
    make_stride(get<1>(args.mainloop.stride_do), get<0>(args.mainloop.stride_do), get<2>(args.mainloop.stride_do))));

    TMA_QT dsq_tma_load_b = make_tma_atom_B_sm100<typename TiledMmaDSQ::ValTypeB>(
        typename CollectiveMmaDSQ::GmemTiledCopyB{},
        tensor_qt,
        SmemLayoutQT{}(_,_,_,_0{}),
        TileShapeDSQ{},
        TiledMmaDSQ{},
        cluster_layout_vmnk);

    TMA_DOT pdo_tma_load_b = make_tma_atom_B_sm100<typename TiledMmaPDO::ValTypeB>(
	typename CollectiveMmaPDO::GmemTiledCopyB{},
        tensor_dot,
        SmemLayoutDOT{}(_,_,_,_0{}),
        TileShapePDO{},
        TiledMmaPDO{},
        cluster_layout_vmnk);

    return Params{
      args.problem_shape,
      args.mainloop,
      MainloopParams{
        params_kq.tma_load_a,
        params_vdo.tma_load_a,
        params_kq.tma_load_b,
        params_vdo.tma_load_b,
        dsq_tma_load_b,
        pdo_tma_load_b
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
      int iter_start,
      int iter_end,
      int iter_count,
      MainloopArguments const& mainloop_args,
      MainloopParams const& mainloop_params,
      TensorStorage& shared_tensors,
      PipelineLoadMmaQ& pipeline_load_mma_q,
      typename PipelineLoadMmaQ::PipelineState& pipeline_load_mma_q_producer_state,
      PipelineLoadMmaQT& pipeline_load_mma_qt,
      typename PipelineLoadMmaQT::PipelineState& pipeline_load_mma_qt_producer_state,
      PipelineLoadMmaDO& pipeline_load_mma_do,
      typename PipelineLoadMmaDO::PipelineState& pipeline_load_mma_do_producer_state,
      PipelineLoadMmaDOT& pipeline_load_mma_dot,
      typename PipelineLoadMmaDOT::PipelineState& pipeline_load_mma_dot_producer_state,
      PipelineLoadComputeLSE& pipeline_load_compute_lse,
      typename PipelineLoadComputeLSE::PipelineState& pipeline_load_compute_lse_producer_state,
      PipelineLoadComputeSumOdO& pipeline_load_compute_sum_odo,
      typename PipelineLoadComputeSumOdO::PipelineState& pipeline_load_compute_sum_odo_producer_state) {

    auto [Q, K, D, D_VO, HB] = problem_shape;
    int iter_index = iter_start;

    using X = Underscore;
    uint16_t mcast_mask = 0;
    auto [blk_coord_q, blk_coord_k, blk_coord_d, blk_coord_dv, blk_coord_batch] = blk_coord; 

    auto mK_in = mainloop_params.tma_load_k.get_tma_tensor(make_shape(K, D, HB));
    auto mV_in = mainloop_params.tma_load_v.get_tma_tensor(make_shape(K, D_VO, HB));
    auto mQ_in = mainloop_params.tma_load_q.get_tma_tensor(make_shape(Q, D, HB));
    auto mDO_in = mainloop_params.tma_load_do.get_tma_tensor(make_shape(Q, D_VO, HB));

    auto mQT_in = mainloop_params.tma_load_qt.get_tma_tensor(make_shape(D, Q, HB));
    auto mDOT_in = mainloop_params.tma_load_dot.get_tma_tensor(make_shape(D_VO, Q, HB));

    auto mK = domain_offset(select<1,2,4>(blk_offset), mK_in);
    auto mV = domain_offset(select<1,3,4>(blk_offset), mV_in);
    auto mQ = domain_offset(select<0,2,4>(blk_offset), mQ_in);
    auto mDO = domain_offset(select<0,3,4>(blk_offset), mDO_in);

    auto mQT = domain_offset(select<2,0,4>(blk_offset), mQT_in);
    auto mDOT = domain_offset(select<3,0,4>(blk_offset), mDOT_in);

    auto gK = local_tile(mK, TileShapeKQ{}, make_coord(_,_,_), Step<_1, X, _1>{});
    auto gQ = local_tile(mQ, TileShapeKQ{}, make_coord(_,_,_), Step<X, _1, _1>{});
    auto gV = local_tile(mV, TileShapeVDO{}, make_coord(_,_,_), Step<_1, X, _1>{});
    auto gDO = local_tile(mDO, TileShapeVDO{}, make_coord(_,_,_), Step<X, _1, _1>{});

    auto gQT = local_tile(mQT, TileShapeDSQ{}, make_coord(_,_,_), Step<X, _1, _1>{});
    auto gDOT = local_tile(mDOT, TileShapePDO{}, make_coord(_,_,_), Step<X, _1, _1>{});

    ThrMMA cta_mma_kq = TiledMmaKQ{}.get_slice(blk_coord_k % size(AtomThrShapeMNK{}));
    ThrMMA cta_mma_vdo = TiledMmaVDO{}.get_slice(blk_coord_k % size(AtomThrShapeMNK{}));
    ThrMMA cta_mma_dsq = TiledMmaDSQ{}.get_slice(blk_coord_k % size(AtomThrShapeMNK{}));
    ThrMMA cta_mma_pdo = TiledMmaPDO{}.get_slice(blk_coord_k % size(AtomThrShapeMNK{})); 

    auto tSTgK = cta_mma_kq.partition_A(gK);
    auto tSTgQ = cta_mma_kq.partition_B(gQ);
    auto tDPTgV = cta_mma_vdo.partition_A(gV);
    auto tDPTgDO = cta_mma_vdo.partition_B(gDO);

    auto tQTgQT = cta_mma_dsq.partition_B(gQT);
    auto tDOTgDOT = cta_mma_pdo.partition_B(gDOT);

    auto sQ = make_tensor(make_smem_ptr(shared_tensors.smem_q.begin()), SmemLayoutQ{});
    auto sK = make_tensor(make_smem_ptr(shared_tensors.smem_k.begin()), SmemLayoutK{});
    auto sV = make_tensor(make_smem_ptr(shared_tensors.smem_v.begin()), SmemLayoutV{});
    auto sDO = make_tensor(make_smem_ptr(shared_tensors.smem_do.begin()), SmemLayoutDO{});
   
    auto sQT = make_tensor(make_smem_ptr(shared_tensors.smem_qt.begin()), SmemLayoutQT{});
    auto sDOT = make_tensor(make_smem_ptr(shared_tensors.smem_dot.begin()), SmemLayoutDOT{});
    
    auto [tKgK_mkl, tKsK] = tma_partition(
        mainloop_params.tma_load_k, _0{}, make_layout(_1{}),
        group_modes<0,3>(sK), group_modes<0,3>(tSTgK));
    auto [tQgQ_mkl, tQsQ] = tma_partition(
        mainloop_params.tma_load_q, _0{}, make_layout(_1{}),
        group_modes<0,3>(sQ), group_modes<0,3>(tSTgQ));
    auto [tVgV_mkl, tVsV] = tma_partition(
        mainloop_params.tma_load_v, _0{}, make_layout(_1{}),
        group_modes<0,3>(sV), group_modes<0,3>(tDPTgV));
    auto [tDOgDO_mkl, tDOsDO] = tma_partition(
        mainloop_params.tma_load_do, _0{}, make_layout(_1{}),
        group_modes<0,3>(sDO), group_modes<0,3>(tDPTgDO));
    auto [tQTgQT_mkl, tQTsQT] = tma_partition(
        mainloop_params.tma_load_qt, _0{}, make_layout(_1{}),
        group_modes<0,3>(sQT), group_modes<0,3>(tQTgQT));
    auto [tDOTgDOT_mkl, tDOTsDOT] = tma_partition(
        mainloop_params.tma_load_dot, _0{}, make_layout(_1{}),
        group_modes<0,3>(sDOT), group_modes<0,3>(tDOTgDOT));

    pipeline_load_mma_q.producer_expect_transaction(pipeline_load_mma_q_producer_state, kTransactionsBytesLoadK);

    pipeline_load_mma_q.producer_acquire(pipeline_load_mma_q_producer_state);
    auto tma_barrier = pipeline_load_mma_q.producer_get_barrier(pipeline_load_mma_q_producer_state);

    // load K
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_k.with(*tma_barrier, mcast_mask),
          tKgK_mkl(_, blk_coord_k/_2{}, _0{}, blk_coord_batch),
          tKsK(_, _0{})
      );
    }
    // load Q
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_q.with(*tma_barrier, mcast_mask),
          tQgQ_mkl(_, iter_index, _0{}, blk_coord_batch),
          tQsQ(_, pipeline_load_mma_q_producer_state.index())
      );
    }

    ++pipeline_load_mma_q_producer_state;

    pipeline_load_compute_lse.producer_acquire(pipeline_load_compute_lse_producer_state);

    // load LSE
    // 32 threads loading 128 values of 32b each
    // so 4*32b=128b

    int thread_idx = threadIdx.x % NumThreadsPerWarp;
    constexpr int num_elements_per_threads = TileShapeQ::value / NumThreadsPerWarp;
    int smem_idx = TileShapeQ{} * pipeline_load_compute_lse_producer_state.index() + thread_idx * num_elements_per_threads;
    int gmem_idx = TileShapeQ{} * iter_index + thread_idx * num_elements_per_threads;
    auto mLSE = make_tensor(mainloop_args.ptr_lse, make_shape(Q, HB), mainloop_args.stride_lse);
    for (int i = 0; i < num_elements_per_threads; i++) {
      cutlass::arch::cp_async_zfill<4>(
          shared_tensors.smem_lse.begin() + smem_idx + i,
          &mLSE(gmem_idx + i, blk_coord_batch),
          gmem_idx + i < Q
      );
    }

    pipeline_load_compute_lse.producer_commit(pipeline_load_compute_lse_producer_state, cutlass::arch::cpasync_barrier_arrive);
    ++pipeline_load_compute_lse_producer_state;
    
    pipeline_load_mma_do.producer_expect_transaction(pipeline_load_mma_do_producer_state, kTransactionsBytesLoadV);

    pipeline_load_mma_do.producer_acquire(pipeline_load_mma_do_producer_state);
    tma_barrier = pipeline_load_mma_do.producer_get_barrier(pipeline_load_mma_do_producer_state);

    // load dV
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_v.with(*tma_barrier, mcast_mask),
          tVgV_mkl(_, blk_coord_k/_2{}, _0{}, blk_coord_batch),
          tVsV(_, _0{})
      );
    }

    // load dO
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_do.with(*tma_barrier, mcast_mask),
          tDOgDO_mkl(_, iter_index, _0{}, blk_coord_batch),
          tDOsDO(_, pipeline_load_mma_do_producer_state.index())
      );
    }

    ++pipeline_load_mma_do_producer_state;

    pipeline_load_compute_sum_odo.producer_acquire(pipeline_load_compute_sum_odo_producer_state);

    // load sum_OdO
    smem_idx = TileShapeQ{} * pipeline_load_compute_sum_odo_producer_state.index() + thread_idx * num_elements_per_threads;
    gmem_idx = TileShapeQ{} * iter_index + thread_idx * num_elements_per_threads;
    auto mSumOdO = make_tensor(mainloop_args.ptr_sum_odo, make_shape(Q, HB), mainloop_args.stride_sum_odo);
    for (int i = 0; i < num_elements_per_threads; i++) {
      cutlass::arch::cp_async_zfill<4>(
          shared_tensors.smem_sum_odo.begin() + smem_idx + i,
          &mSumOdO(gmem_idx + i, blk_coord_batch),
          gmem_idx + i < Q
      );
    }

    pipeline_load_compute_sum_odo.producer_commit(pipeline_load_compute_sum_odo_producer_state, cutlass::arch::cpasync_barrier_arrive);
    ++pipeline_load_compute_sum_odo_producer_state;

    auto iter_index_old = iter_index;
    auto blk_coord_batch_old = blk_coord_batch;

    iter_count -= 1;
    iter_index += 1;

    while (iter_count > 0) {
      if (iter_index == iter_end) {
        iter_index = iter_start;
        get<0,0>(blk_coord_batch) += 1;
      }

      pipeline_load_mma_dot.producer_acquire(pipeline_load_mma_dot_producer_state);
      tma_barrier = pipeline_load_mma_dot.producer_get_barrier(pipeline_load_mma_dot_producer_state);

      // load dOT
      if (cute::elect_one_sync()) {
        cute::copy(
            mainloop_params.tma_load_dot.with(*tma_barrier, mcast_mask),
            tDOTgDOT_mkl(_, _0{}, iter_index_old, blk_coord_batch_old),
            tDOTsDOT(_, pipeline_load_mma_dot_producer_state.index())
        );
      }

      ++pipeline_load_mma_dot_producer_state;

      pipeline_load_mma_q.producer_acquire(pipeline_load_mma_q_producer_state);
      tma_barrier = pipeline_load_mma_q.producer_get_barrier(pipeline_load_mma_q_producer_state);

      // load Q
      if (cute::elect_one_sync()) {
        cute::copy(
            mainloop_params.tma_load_q.with(*tma_barrier, mcast_mask),
            tQgQ_mkl(_, iter_index, _0{}, blk_coord_batch),
            tQsQ(_, pipeline_load_mma_q_producer_state.index())
        );
      }

      ++pipeline_load_mma_q_producer_state;

      pipeline_load_compute_lse.producer_acquire(pipeline_load_compute_lse_producer_state);

      // load LSE
      smem_idx = TileShapeQ{} * pipeline_load_compute_lse_producer_state.index() + thread_idx * num_elements_per_threads;
      gmem_idx = TileShapeQ{} * iter_index + thread_idx * num_elements_per_threads;
      for (int i = 0; i < num_elements_per_threads; i++) {
        cutlass::arch::cp_async_zfill<4>(
            shared_tensors.smem_lse.begin() + smem_idx + i,
            &mLSE(gmem_idx + i, blk_coord_batch),
            gmem_idx + i < Q
        );
      }

      pipeline_load_compute_lse.producer_commit(pipeline_load_compute_lse_producer_state, cutlass::arch::cpasync_barrier_arrive);
      ++pipeline_load_compute_lse_producer_state;

      pipeline_load_mma_qt.producer_acquire(pipeline_load_mma_qt_producer_state);
      tma_barrier = pipeline_load_mma_qt.producer_get_barrier(pipeline_load_mma_qt_producer_state);

      // load QT
      if (cute::elect_one_sync()) {
        cute::copy(
            mainloop_params.tma_load_qt.with(*tma_barrier, mcast_mask),
            tQTgQT_mkl(_, _0{}, iter_index_old, blk_coord_batch_old),
            tQTsQT(_, pipeline_load_mma_qt_producer_state.index())
        );
      }

      ++pipeline_load_mma_qt_producer_state;

      pipeline_load_mma_do.producer_acquire(pipeline_load_mma_do_producer_state);
      tma_barrier = pipeline_load_mma_do.producer_get_barrier(pipeline_load_mma_do_producer_state);

      // load dO
      if (cute::elect_one_sync()) {
        cute::copy(
            mainloop_params.tma_load_do.with(*tma_barrier, mcast_mask),
            tDOgDO_mkl(_, iter_index, _0{}, blk_coord_batch),
            tDOsDO(_, pipeline_load_mma_do_producer_state.index())
        );
      }

      ++pipeline_load_mma_do_producer_state;

      pipeline_load_compute_sum_odo.producer_acquire(pipeline_load_compute_sum_odo_producer_state);
      // load sum_OdO
      smem_idx = TileShapeQ{} * pipeline_load_compute_sum_odo_producer_state.index() + thread_idx * num_elements_per_threads;
      gmem_idx = TileShapeQ{} * iter_index + thread_idx * num_elements_per_threads;
      auto mSumOdO = make_tensor(mainloop_args.ptr_sum_odo, make_shape(Q, HB), mainloop_args.stride_sum_odo);
      for (int i = 0; i < num_elements_per_threads; i++) {
        cutlass::arch::cp_async_zfill<4>(
            shared_tensors.smem_sum_odo.begin() + smem_idx + i,
            &mSumOdO(gmem_idx + i, blk_coord_batch),
            gmem_idx + i < Q
        );
      }

      pipeline_load_compute_sum_odo.producer_commit(pipeline_load_compute_sum_odo_producer_state, cutlass::arch::cpasync_barrier_arrive);
      ++pipeline_load_compute_sum_odo_producer_state;

      // update indices
      iter_index_old = iter_index;
      blk_coord_batch_old = blk_coord_batch;

      iter_count -= 1;
      iter_index += 1;
    }
	
    pipeline_load_mma_dot.producer_acquire(pipeline_load_mma_dot_producer_state);
    tma_barrier = pipeline_load_mma_dot.producer_get_barrier(pipeline_load_mma_dot_producer_state);

    // load dOT
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_dot.with(*tma_barrier, mcast_mask),
          tDOTgDOT_mkl(_, _0{}, iter_index_old, blk_coord_batch_old),
          tDOTsDOT(_, pipeline_load_mma_dot_producer_state.index())
      );
    }

    ++pipeline_load_mma_dot_producer_state;

    pipeline_load_mma_qt.producer_acquire(pipeline_load_mma_qt_producer_state);
    tma_barrier = pipeline_load_mma_qt.producer_get_barrier(pipeline_load_mma_qt_producer_state);

    // load QT
    if (cute::elect_one_sync()) {
      cute::copy(
          mainloop_params.tma_load_qt.with(*tma_barrier, mcast_mask),
          tQTgQT_mkl(_, _0{}, iter_index_old, blk_coord_batch_old),
          tQTsQT(_, pipeline_load_mma_qt_producer_state.index())
      );
    }

    ++pipeline_load_mma_qt_producer_state;

  }


  template<class BlkCoord, class ProblemShape_>
  CUTLASS_DEVICE void mma(
      BlkCoord const& blk_coord,
      ProblemShape_ const& problem_shape,
      int iter_start,
      int iter_end,
      int iter_count,
      MainloopArguments const& mainloop_args,
      TensorStorage& shared_tensors,
      PipelineLoadMmaQ& pipeline_load_mma_q,
      typename PipelineLoadMmaQ::PipelineState& pipeline_load_mma_q_consumer_state,
      PipelineLoadMmaQT& pipeline_load_mma_qt,
      typename PipelineLoadMmaQT::PipelineState& pipeline_load_mma_qt_consumer_state,
      PipelineLoadMmaDO& pipeline_load_mma_do,
      typename PipelineLoadMmaDO::PipelineState& pipeline_load_mma_do_consumer_state,
      PipelineLoadMmaDOT& pipeline_load_mma_dot,
      typename PipelineLoadMmaDOT::PipelineState& pipeline_load_mma_dot_consumer_state,
      PipelineMmaComputeS& pipeline_mma_compute_s,
      typename PipelineMmaComputeS::PipelineState& pipeline_mma_compute_s_producer_state,
      PipelineMmaComputeDP& pipeline_mma_compute_dp,
      typename PipelineMmaComputeDP::PipelineState& pipeline_mma_compute_dp_producer_state,
      PipelineComputeMmaP& pipeline_compute_mma_p,
      typename PipelineComputeMmaP::PipelineState& pipeline_compute_mma_p_consumer_state,
      PipelineComputeMmaDS& pipeline_compute_mma_ds,
      typename PipelineComputeMmaDS::PipelineState& pipeline_compute_mma_ds_consumer_state,
      PipelineMmaComputeDKDV& pipeline_mma_compute_dkdv,
      typename PipelineMmaComputeDKDV::PipelineState& pipeline_mma_compute_dkdv_producer_state) {

    auto [Q, K, D, D_VO, HB] = problem_shape;

    auto sQ = make_tensor(make_smem_ptr(shared_tensors.smem_q.begin()), SmemLayoutQ{});
    auto sK = make_tensor(make_smem_ptr(shared_tensors.smem_k.begin()), SmemLayoutK{});
    auto sV = make_tensor(make_smem_ptr(shared_tensors.smem_v.begin()), SmemLayoutV{});
    auto sDO = make_tensor(make_smem_ptr(shared_tensors.smem_do.begin()), SmemLayoutDO{});

    auto sQT = make_tensor(make_smem_ptr(shared_tensors.smem_qt.begin()), SmemLayoutQT{});
    auto sDOT = make_tensor(make_smem_ptr(shared_tensors.smem_dot.begin()), SmemLayoutDOT{});

    Tensor tSTrK = TiledMmaKQ::make_fragment_A(sK);
    Tensor tSTrQ = TiledMmaKQ::make_fragment_B(sQ);

    Tensor tDPTrV = TiledMmaVDO::make_fragment_A(sV);
    Tensor tDPTrDO = TiledMmaVDO::make_fragment_B(sDO);

    Tensor tDKrDST = make_tensor<typename TiledMmaDSQ::FrgTypeA>(take<0,3>(typename CollectiveMmaDSQ::SmemLayoutA{}));
    tDKrDST.data() = TmemAllocation::kDS;
    Tensor tDKrQT = TiledMmaDSQ::make_fragment_B(sQT);

    Tensor tDVrP = make_tensor<typename TiledMmaPDO::FrgTypeA>(take<0,3>(typename CollectiveMmaPDO::SmemLayoutA{}));
    tDVrP.data() = TmemAllocation::kP;
    Tensor tDVrDOT = TiledMmaPDO::make_fragment_B(sDOT);

    TiledMmaKQ tiled_mma_kq;
    TiledMmaVDO tiled_mma_vdo;
    TiledMmaDSQ tiled_mma_dsq;
    TiledMmaPDO tiled_mma_pdo;

    tiled_mma_dsq.accumulate_ = UMMA::ScaleOut::Zero;
    tiled_mma_pdo.accumulate_ = UMMA::ScaleOut::Zero;

    auto tSTtST = TiledMmaKQ::make_fragment_C(partition_shape_C(tiled_mma_kq, select<0,1>(TileShapeKQ{})));
    tSTtST.data() = TmemAllocation::kS;

    auto tDPTtDPT = TiledMmaVDO::make_fragment_C(partition_shape_C(tiled_mma_vdo, select<0,1>(TileShapeVDO{})));
    tDPTtDPT.data() = TmemAllocation::kDP;

    auto tDKtDK = TiledMmaDSQ::make_fragment_C(partition_shape_C(tiled_mma_dsq, select<0,1>(TileShapeDSQ{})));
    tDKtDK.data() = TmemAllocation::kDK;

    auto tDVtDV =  TiledMmaPDO::make_fragment_C(partition_shape_C(tiled_mma_pdo, select<0,1>(TileShapePDO{})));
    tDVtDV.data() = TmemAllocation::kDV;

    pipeline_mma_compute_s.producer_acquire(pipeline_mma_compute_s_producer_state);
    pipeline_load_mma_q.consumer_wait(pipeline_load_mma_q_consumer_state);

    // S = Q*K
    tiled_mma_kq.accumulate_ = UMMA::ScaleOut::Zero;
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tSTrQ); ++k_block) {
      cute::gemm(tiled_mma_kq,
                 tSTrK(_,_,k_block,_0{}),
                 tSTrQ(_,_,k_block,pipeline_load_mma_q_consumer_state.index()),
                 tSTtST);
      tiled_mma_kq.accumulate_ = UMMA::ScaleOut::One;
    }

    pipeline_mma_compute_s.producer_commit(pipeline_mma_compute_s_producer_state);
    ++pipeline_mma_compute_s_producer_state;

    pipeline_load_mma_q.consumer_release(pipeline_load_mma_q_consumer_state);
    ++pipeline_load_mma_q_consumer_state;

    pipeline_mma_compute_dp.producer_acquire(pipeline_mma_compute_dp_producer_state);
    pipeline_load_mma_do.consumer_wait(pipeline_load_mma_do_consumer_state);

    // dP = dO*V
    tiled_mma_vdo.accumulate_ = UMMA::ScaleOut::Zero;
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tDPTrV); ++k_block) {
      cute::gemm(tiled_mma_vdo,
                 tDPTrV(_,_,k_block,_0{}),
                 tDPTrDO(_,_,k_block,pipeline_load_mma_do_consumer_state.index()),
                 tDPTtDPT);
      tiled_mma_vdo.accumulate_ = UMMA::ScaleOut::One;
    }
    
    pipeline_mma_compute_dp.producer_commit(pipeline_mma_compute_dp_producer_state);
    ++pipeline_mma_compute_dp_producer_state;

    pipeline_load_mma_do.consumer_release(pipeline_load_mma_do_consumer_state);
    ++pipeline_load_mma_do_consumer_state;

    iter_count -= 1;

    // in tmem, S & P overlap
    // and dP & dS overlap
    while (iter_count > 0) {
      pipeline_mma_compute_s.producer_acquire(pipeline_mma_compute_s_producer_state);
      pipeline_compute_mma_p.consumer_wait(pipeline_compute_mma_p_consumer_state);
      pipeline_load_mma_dot.consumer_wait(pipeline_load_mma_dot_consumer_state);

      // dV = P*dO
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tDVrP); ++k_block) {
        cute::gemm(tiled_mma_pdo,
                   tDVrP(_,_,k_block),
                   tDVrDOT(_,_,k_block,pipeline_load_mma_dot_consumer_state.index()),
                   tDVtDV);
        tiled_mma_pdo.accumulate_ = UMMA::ScaleOut::One;
      }
      pipeline_load_mma_dot.consumer_release(pipeline_load_mma_dot_consumer_state);
      ++pipeline_load_mma_dot_consumer_state;

      pipeline_load_mma_q.consumer_wait(pipeline_load_mma_q_consumer_state);
      // S = Q*K
      tiled_mma_kq.accumulate_ = UMMA::ScaleOut::Zero;
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tSTrQ); ++k_block) {
        cute::gemm(tiled_mma_kq,
                   tSTrK(_,_,k_block,_0{}),
                   tSTrQ(_,_,k_block,pipeline_load_mma_q_consumer_state.index()),
                   tSTtST);
        tiled_mma_kq.accumulate_ = UMMA::ScaleOut::One;
      }

      pipeline_mma_compute_s.producer_commit(pipeline_mma_compute_s_producer_state);
      ++pipeline_mma_compute_s_producer_state;

      pipeline_compute_mma_p.consumer_release(pipeline_compute_mma_p_consumer_state);
      ++pipeline_compute_mma_p_consumer_state;

      pipeline_load_mma_q.consumer_release(pipeline_load_mma_q_consumer_state);
      ++pipeline_load_mma_q_consumer_state;

      pipeline_mma_compute_dp.producer_acquire(pipeline_mma_compute_dp_producer_state);
      pipeline_compute_mma_ds.consumer_wait(pipeline_compute_mma_ds_consumer_state);
      pipeline_load_mma_qt.consumer_wait(pipeline_load_mma_qt_consumer_state);

      // dK = dS*Q
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tDKrDST); ++k_block) {
        cute::gemm(tiled_mma_dsq,
		   tDKrDST(_,_,k_block),
                   tDKrQT(_,_,k_block,pipeline_load_mma_qt_consumer_state.index()),
                   tDKtDK);
        tiled_mma_dsq.accumulate_ = UMMA::ScaleOut::One;
      }

      pipeline_load_mma_qt.consumer_release(pipeline_load_mma_qt_consumer_state);
      ++pipeline_load_mma_qt_consumer_state;

      pipeline_load_mma_do.consumer_wait(pipeline_load_mma_do_consumer_state);
      // dP = dO*V
      tiled_mma_vdo.accumulate_ = UMMA::ScaleOut::Zero;
      CUTLASS_PRAGMA_UNROLL
      for (int k_block = 0; k_block < size<2>(tDPTrV); ++k_block) {
        cute::gemm(tiled_mma_vdo,
                   tDPTrV(_,_,k_block,_0{}),
                   tDPTrDO(_,_,k_block,pipeline_load_mma_do_consumer_state.index()),
                   tDPTtDPT);
        tiled_mma_vdo.accumulate_ = UMMA::ScaleOut::One;
      }

      pipeline_mma_compute_dp.producer_commit(pipeline_mma_compute_dp_producer_state);
      ++pipeline_mma_compute_dp_producer_state;

      pipeline_compute_mma_ds.consumer_release(pipeline_compute_mma_ds_consumer_state);
      ++pipeline_compute_mma_ds_consumer_state;

      pipeline_load_mma_do.consumer_release(pipeline_load_mma_do_consumer_state);
      ++pipeline_load_mma_do_consumer_state;

      iter_count -= 1;
    }

    pipeline_mma_compute_dkdv.producer_acquire(pipeline_mma_compute_dkdv_producer_state);
    pipeline_compute_mma_p.consumer_wait(pipeline_compute_mma_p_consumer_state);
    pipeline_load_mma_dot.consumer_wait(pipeline_load_mma_dot_consumer_state);

    // dV = P*dO
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tDVrP); ++k_block) {
      cute::gemm(tiled_mma_pdo,
                 tDVrP(_,_,k_block),
                 tDVrDOT(_,_,k_block,pipeline_load_mma_dot_consumer_state.index()),
                 tDVtDV);
      tiled_mma_pdo.accumulate_ = UMMA::ScaleOut::One;
    }
   
    pipeline_mma_compute_dkdv.producer_commit(pipeline_mma_compute_dkdv_producer_state);
    ++pipeline_mma_compute_dkdv_producer_state;

    pipeline_compute_mma_p.consumer_release(pipeline_compute_mma_p_consumer_state);
    ++pipeline_compute_mma_p_consumer_state;

    pipeline_load_mma_dot.consumer_release(pipeline_load_mma_dot_consumer_state);
    ++pipeline_load_mma_dot_consumer_state;

    pipeline_mma_compute_dkdv.producer_acquire(pipeline_mma_compute_dkdv_producer_state);
    pipeline_compute_mma_ds.consumer_wait(pipeline_compute_mma_ds_consumer_state);
    pipeline_load_mma_qt.consumer_wait(pipeline_load_mma_qt_consumer_state);

    // dK = dS*Q
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tDKrDST); ++k_block) {
      cute::gemm(tiled_mma_dsq,
		 tDKrDST(_,_,k_block),
                 tDKrQT(_,_,k_block,pipeline_load_mma_qt_consumer_state.index()),
                 tDKtDK);
      tiled_mma_dsq.accumulate_ = UMMA::ScaleOut::One;
    }
 
    pipeline_mma_compute_dkdv.producer_commit(pipeline_mma_compute_dkdv_producer_state);
    ++pipeline_mma_compute_dkdv_producer_state;

    pipeline_compute_mma_ds.consumer_release(pipeline_compute_mma_ds_consumer_state);
    ++pipeline_compute_mma_ds_consumer_state;

    pipeline_load_mma_qt.consumer_release(pipeline_load_mma_qt_consumer_state);
    ++pipeline_load_mma_qt_consumer_state;
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


  template<class BlkCoord, class BlkOffset, class ProblemShape_>
  CUTLASS_DEVICE void epilogue_clear(
      BlkCoord const& blk_coord,
      BlkOffset const& blk_offset,
      ProblemShape_ const& problem_shape,
      MainloopArguments const& mainloop_args,
      EpilogueArguments const& epilogue_args) {

    auto [Q, K, D, D_VO, HB] = problem_shape;
    auto [blk_coord_q, blk_coord_k, blk_coord_d, blk_coord_dv, blk_coord_batch] = blk_coord;

    auto mDK_in = make_tensor(make_gmem_ptr(epilogue_args.ptr_dk), make_shape(K, TileShapeDQK{}, HB), epilogue_args.stride_dk);
    auto mDK = domain_offset(select<1,2,4>(blk_offset), mDK_in);
    auto gDK = local_tile(mDK, CtaShapeDSQ{}, make_coord(_,_,_), Step<_1, _1, X>{})
        (_, _, blk_coord_k, _0{}, blk_coord_batch);

    Tensor cDK = domain_offset(
        make_coord(blk_coord_k * get<0>(CtaShapeDSQ{}), _0{}),
        make_identity_tensor(take<0,2>(CtaShapeDSQ{}))
    );

    for (int i = threadIdx.x; i < size(gDK); i += blockDim.x) {
      if (elem_less(cDK(i), select<1,2>(problem_shape))) {
        gDK(i) = Element(0);
      }
    }

    auto mDV_in = make_tensor(make_gmem_ptr(epilogue_args.ptr_dv), make_shape(K, TileShapeDVO{}, HB), epilogue_args.stride_dv);
    auto mDV = domain_offset(select<1,3,4>(blk_offset), mDV_in);
    auto gDV = local_tile(mDV, CtaShapePDO{}, make_coord(_,_,_), Step<_1, _1, X>{})
        (_, _, blk_coord_k, _0{}, blk_coord_batch);

    Tensor cDV = domain_offset(
        make_coord(blk_coord_k * get<0>(CtaShapePDO{}), _0{}),
        make_identity_tensor(take<0,2>(CtaShapePDO{}))
    );
    
    for (int i = threadIdx.x; i < size(gDV); i += blockDim.x) {
      if (elem_less(cDV(i), select<1,3>(problem_shape))) {
        gDV(i) = Element(0);
      }
    }
  }

  template<class BlkCoord, class BlkOffset, class ProblemShape_>
  CUTLASS_DEVICE void epilogue(
      BlkCoord const& blk_coord,
      BlkOffset const& blk_offset,
      ProblemShape_ const& problem_shape,
      MainloopArguments const& mainloop_args,
      EpilogueArguments const& epilogue_args,
      PipelineMmaComputeDKDV& pipeline_mma_compute_dkdv,
      typename PipelineMmaComputeDKDV::PipelineState& pipeline_mma_compute_dkdv_consumer_state) {

    auto [Q, K, D, D_VO, HB] = problem_shape;
    auto [blk_coord_q, blk_coord_k, blk_coord_d, blk_coord_dv, blk_coord_batch] = blk_coord;

    auto load_op = SM100_TMEM_LOAD_32dp32b32x{};

    auto tDKtDK = TiledMmaDSQ::make_fragment_C(partition_shape_C(TiledMmaDSQ{}, select<0,1>(TileShapeDSQ{})))(make_coord(_,_),_0{},_0{});
    tDKtDK.data() = TmemAllocation::kDK;

    auto mDK_in = make_tensor(make_gmem_ptr(epilogue_args.ptr_dk), make_shape(K, TileShapeDQK{}, HB), epilogue_args.stride_dk);
    auto mDK = domain_offset(select<1,2,4>(blk_offset), mDK_in);
    auto gDK = local_tile(mDK, CtaShapeDSQ{}, make_coord(_,_,_), Step<_1, _1, X>{})
        (_, _, blk_coord_k, _0{}, blk_coord_batch);

    Tensor cDK = domain_offset(
        make_coord(blk_coord_k * get<0>(CtaShapeDSQ{}), _0{}),
        make_identity_tensor(take<0,2>(CtaShapeDSQ{}))
    );

    auto tiled_t2r_dk = make_tmem_copy(load_op, tDKtDK);
    auto thread_t2r_dk = tiled_t2r_dk.get_slice(threadIdx.x%size(tiled_t2r_dk));

    Tensor tTR_cDK   = thread_t2r_dk.partition_D(cDK);
    Tensor tTR_gDK   = thread_t2r_dk.partition_D(gDK);

    Tensor tTR_rDK = make_tensor<ElementAcc>(shape(tTR_cDK));
    Tensor tTR_tDK = thread_t2r_dk.partition_S(tDKtDK);
    
    auto tDVtDV = TiledMmaPDO::make_fragment_C(partition_shape_C(TiledMmaPDO{}, select<0,1>(TileShapePDO{})))(make_coord(_,_),_0{},_0{});
    tDVtDV.data() = TmemAllocation::kDV;

    auto mDV_in = make_tensor(make_gmem_ptr(epilogue_args.ptr_dv), make_shape(K, TileShapeDVO{}, HB), epilogue_args.stride_dv);
    auto mDV = domain_offset(select<1,3,4>(blk_offset), mDV_in);
    auto gDV = local_tile(mDV, CtaShapePDO{}, make_coord(_,_,_), Step<_1, _1, X>{})
	   (_, _, blk_coord_k, _0{}, blk_coord_batch);

    Tensor cDV = domain_offset(
        make_coord(blk_coord_k * get<0>(CtaShapePDO{}), _0{}),
        make_identity_tensor(take<0,2>(CtaShapePDO{}))
    );

    auto tiled_t2r_dv = make_tmem_copy(load_op, tDVtDV);
    auto thread_t2r_dv = tiled_t2r_dv.get_slice(threadIdx.x%size(tiled_t2r_dv));

    Tensor tTR_cDV   = thread_t2r_dv.partition_D(cDV);
    Tensor tTR_gDV   = thread_t2r_dv.partition_D(gDV);

    Tensor tTR_rDV = make_tensor<ElementAcc>(shape(tTR_cDV));
    Tensor tTR_tDV = thread_t2r_dv.partition_S(tDVtDV);

    pipeline_mma_compute_dkdv.consumer_wait(pipeline_mma_compute_dkdv_consumer_state);

    // load tDVtDV
    cute::copy(tiled_t2r_dv, tTR_tDV, tTR_rDV);

    // store tDVgDV
    store(tTR_gDV, tTR_rDV, tTR_cDV, select<1,3>(problem_shape));

    pipeline_mma_compute_dkdv.consumer_release(pipeline_mma_compute_dkdv_consumer_state);
    ++pipeline_mma_compute_dkdv_consumer_state;

    pipeline_mma_compute_dkdv.consumer_wait(pipeline_mma_compute_dkdv_consumer_state);

    // load tDKtDK
    cute::copy(tiled_t2r_dk, tTR_tDK, tTR_rDK);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size(tTR_rDK); i++) {
      tTR_rDK(i) = mainloop_args.softmax_scale * tTR_rDK(i);
    }

    // store tDKgDK
    store(tTR_gDK, tTR_rDK, tTR_cDK, select<1,2>(problem_shape));

    pipeline_mma_compute_dkdv.consumer_release(pipeline_mma_compute_dkdv_consumer_state);
    ++pipeline_mma_compute_dkdv_consumer_state;
  }

  template<class BlkCoord, class BlkOffset, class ProblemShape_>
  CUTLASS_DEVICE void compute(
      BlkCoord const& blk_coord,
      BlkOffset const& blk_offset,
      ProblemShape_ const& problem_shape,
      int iter_start,
      int iter_end,
      int iter_count,
      MainloopArguments const& mainloop_args,
      EpilogueArguments const& epilogue_args,
      TensorStorage& shared_tensors,
      PipelineLoadComputeLSE& pipeline_load_compute_lse,
      typename PipelineLoadComputeLSE::PipelineState& pipeline_load_compute_lse_consumer_state,
      PipelineLoadComputeSumOdO& pipeline_load_compute_sum_odo,
      typename PipelineLoadComputeSumOdO::PipelineState& pipeline_load_compute_sum_odo_consumer_state,
      PipelineMmaComputeS& pipeline_mma_compute_s,
      typename PipelineMmaComputeS::PipelineState& pipeline_mma_compute_s_consumer_state,
      PipelineMmaComputeDP& pipeline_mma_compute_dp,
      typename PipelineMmaComputeDP::PipelineState& pipeline_mma_compute_dp_consumer_state,
      PipelineComputeMmaP& pipeline_compute_mma_p,
      typename PipelineComputeMmaP::PipelineState& pipeline_compute_mma_p_producer_state,
      PipelineComputeMmaDS& pipeline_compute_mma_ds,
      typename PipelineComputeMmaDS::PipelineState& pipeline_compute_mma_ds_producer_state,
      PipelineMmaComputeDKDV& pipeline_mma_compute_dkdv,
      typename PipelineMmaComputeDKDV::PipelineState& pipeline_mma_compute_dkdv_consumer_state) {


    auto [Q, K, D, D_VO, HB] = problem_shape;
    int iter_index = iter_start;

    // in tmem, S & P overlap
    // and dP and dS overlap
    auto load_op = SM100_TMEM_LOAD_32dp32b32x{};
    auto store_op = SM100_TMEM_STORE_32dp32b32x{};

    Tensor tSTtST = partition_fragment_C(TiledMmaKQ{}, select<0,1>(TileShapeKQ{}))(make_coord(_,_),_0{},_0{});
    tSTtST.data() = TmemAllocation::kS;

    Tensor tDPTtDPT = partition_fragment_C(TiledMmaVDO{}, select<0,1>(TileShapeVDO{}))(make_coord(_,_),_0{},_0{});
    tDPTtDPT.data() = TmemAllocation::kDP;
    
    Tensor cST = make_identity_tensor(take<0,2>(CtaShapeKQ{}));
    Tensor cDPT = make_identity_tensor(take<0,2>(CtaShapeVDO{}));

    auto tiled_t2r_kq = make_tmem_copy(load_op, tSTtST);
    auto thread_t2r_kq = tiled_t2r_kq.get_slice(threadIdx.x%size(tiled_t2r_kq));

    Tensor tTR_cST = thread_t2r_kq.partition_D(cST);
    Tensor tTR_rST = make_tensor<ElementAcc>(shape(tTR_cST));
    Tensor tTR_tST = thread_t2r_kq.partition_S(tSTtST);

    auto tiled_t2r_vdo = make_tmem_copy(load_op, tDPTtDPT);
    auto thread_t2r_vdo = tiled_t2r_vdo.get_slice(threadIdx.x%size(tiled_t2r_vdo));
    
    Tensor tTR_cDPT = thread_t2r_vdo.partition_D(cDPT);
    Tensor tTR_rDPT = make_tensor<ElementAcc>(shape(tTR_cDPT));
    Tensor tTR_tDPT = thread_t2r_vdo.partition_S(tDPTtDPT);

    Tensor sLSE = make_tensor(make_smem_ptr(shared_tensors.smem_lse.begin()), SmemLayoutLSE{});
    Tensor sSumOdO = make_tensor(make_smem_ptr(shared_tensors.smem_sum_odo.begin()), SmemLayoutSumOdO{});
    
    auto tDVrP = make_tensor<typename TiledMmaPDO::FrgTypeA>(take<0,3>(typename CollectiveMmaPDO::SmemLayoutA{}));
    tDVrP.data() = TmemAllocation::kP;
    auto tDVcST = TiledMmaPDO{}.get_slice(get<1>(blk_coord) % size(AtomThrShapeMNK{})).partition_A(cST);

    auto tiled_r2t_pdo = make_tmem_copy(store_op, tDVrP);
    auto thread_r2t_pdo = tiled_r2t_pdo.get_slice(threadIdx.x%size(tiled_r2t_pdo));

    auto tRT_tP = thread_r2t_pdo.partition_D(tDVrP);
    auto tRT_cST = thread_r2t_pdo.partition_S(tDVcST);

    auto tDKrDS = make_tensor<typename TiledMmaDSQ::FrgTypeA>(take<0,3>(typename CollectiveMmaDSQ::SmemLayoutA{}));
    tDKrDS.data() = TmemAllocation::kDS;
    auto tDKcDPT = TiledMmaDSQ{}.get_slice(get<1>(blk_coord) % size(AtomThrShapeMNK{})).partition_A(cDPT);

    auto tiled_r2t_dsq = make_tmem_copy(store_op, tDKrDS);
    auto thread_r2t_dsq = tiled_r2t_dsq.get_slice(threadIdx.x%size(tiled_r2t_dsq));

    auto tRT_tDST = thread_r2t_dsq.partition_D(tDKrDS);
    auto tRT_cDPT = thread_r2t_dsq.partition_S(tDKcDPT);

    bool is_residual_k = get<1>(blk_coord) * get<0>(CtaShapeKQ{}) + get<0>(CtaShapeKQ{}) >= get<1>(problem_shape);
    int last_iter = iter_count - 1 + iter_index;

    CUTLASS_PRAGMA_NO_UNROLL
    while (iter_count > 0) {
      auto dispatch_bool = [](bool b, auto fn) {
        if (b) {
          fn(cute::true_type{});
        }
        else {
          fn(cute::false_type{});
        }
      };

      bool leading_causal_masking = false;
      if constexpr (std::is_base_of_v<cutlass::fmha::collective::CausalMask<true>, Mask>) {
        leading_causal_masking = warp_uniform(iter_index <= get<1>(blk_coord));
      } else if constexpr (std::is_base_of_v<cutlass::fmha::collective::CausalMask<false>, Mask>) {
        int offset = get<1>(problem_shape) - get<0>(problem_shape);
        int kv_left = get<1>(blk_coord) * int(get<0>(CtaShapeKQ{}));
        int kv_right = kv_left + int(get<0>(CtaShapeKQ{})) - 1;
        int q_left = iter_index * TileShapeQ{} + offset;
        int q_right = q_left + TileShapeQ{} - 1;

        leading_causal_masking = warp_uniform(!((q_left > kv_right) || (q_right < kv_left)));
      }
      bool trailing_residual_masking = false;
      if constexpr (std::is_base_of_v<cutlass::fmha::collective::ResidualMaskForBackward, Mask>) {
        trailing_residual_masking = warp_uniform((iter_index == last_iter) || is_residual_k);
      }

      // compute P = softmax(S, LSE)
      pipeline_load_compute_lse.consumer_wait(pipeline_load_compute_lse_consumer_state);
      pipeline_mma_compute_s.consumer_wait(pipeline_mma_compute_s_consumer_state);
      pipeline_compute_mma_p.producer_acquire(pipeline_compute_mma_p_producer_state);

      dispatch_bool(leading_causal_masking || trailing_residual_masking, [&](auto is_masked_tile) {
        cute::copy(tiled_t2r_kq, tTR_tST, tTR_rST);

        if constexpr (decltype(is_masked_tile)::value) {
          Mask{}.apply_mask(tTR_rST, [&](int i) {
            auto c_transpose = tTR_cST(i);
            return make_coord(get<1>(c_transpose) + iter_index * get<1>(CtaShapeKQ{}), get<0>(c_transpose) + get<1>(blk_coord) * get<0>(CtaShapeKQ{}));
          }, problem_shape);
        }

        constexpr ElementAcc log2_e = static_cast<ElementAcc>(M_LOG2E);
        float2 softmax_scale_log2_e;
        softmax_scale_log2_e.x = mainloop_args.softmax_scale * log2_e;
        softmax_scale_log2_e.y = mainloop_args.softmax_scale * log2_e;

        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < size(tTR_rST); i += 2) {
          float2 acc;
          float2 out;
          float2 lse;
          lse.x = sLSE(get<1>(tTR_cST(i)), pipeline_load_compute_lse_consumer_state.index());
          lse.y = sLSE(get<1>(tTR_cST(i+1)), pipeline_load_compute_lse_consumer_state.index());
          acc.x = tTR_rST(i);
          acc.y = tTR_rST(i+1);
          cute::fma(out, softmax_scale_log2_e, acc, lse);
          tTR_rST(i) = ::exp2f(out.x);
          tTR_rST(i+1) = ::exp2f(out.y);
        }

        auto tRT_rST = quantize(tTR_rST);
        auto tRT_rST_reshaped = composition(tRT_rST, make_layout(shape(tRT_cST)));
        
        cute::copy(tiled_r2t_pdo, tRT_rST_reshaped, tRT_tP);
      });

      // notify for P
      cutlass::arch::fence_view_async_tmem_store();
      pipeline_compute_mma_p.producer_commit(pipeline_compute_mma_p_producer_state);
      ++pipeline_compute_mma_p_producer_state;

      // release S
      pipeline_mma_compute_s.consumer_release(pipeline_mma_compute_s_consumer_state);
      ++pipeline_mma_compute_s_consumer_state;

      // release LSE
      pipeline_load_compute_lse.consumer_release(pipeline_load_compute_lse_consumer_state);
      ++pipeline_load_compute_lse_consumer_state;

      // compute dS = dsoftmax(P, dP, sum_OdO)
      pipeline_load_compute_sum_odo.consumer_wait(pipeline_load_compute_sum_odo_consumer_state);
      pipeline_mma_compute_dp.consumer_wait(pipeline_mma_compute_dp_consumer_state);
      pipeline_compute_mma_ds.producer_acquire(pipeline_compute_mma_ds_producer_state);

      cute::copy(tiled_t2r_vdo, tTR_tDPT, tTR_rDPT);

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tTR_rDPT); i += 2) {
        float2 st;
        st.x = tTR_rST(i);
        st.y = tTR_rST(i+1);
        float2 dpt;
        dpt.x = tTR_rDPT(i);
        dpt.y = tTR_rDPT(i+1);
        float2 dif;
        float2 odo;
        odo.x = sSumOdO(get<1>(tTR_cDPT(i)), pipeline_load_compute_sum_odo_consumer_state.index());
	odo.y = sSumOdO(get<1>(tTR_cDPT(i+1)), pipeline_load_compute_sum_odo_consumer_state.index());
        cute::add(dif, dpt, odo);
        float2 out;
        cute::mul(out, dif, st);
        tTR_rDPT(i) = out.x;
        tTR_rDPT(i+1) = out.y;
      }
      
      auto tRT_rDPT = quantize(tTR_rDPT);
      auto tRT_rDPT_reshaped = composition(tRT_rDPT, make_layout(tRT_cDPT.shape()));

      cute::copy(tiled_r2t_dsq, tRT_rDPT_reshaped, tRT_tDST);

      // notify for dS
      cutlass::arch::fence_view_async_tmem_store();
      pipeline_compute_mma_ds.producer_commit(pipeline_compute_mma_ds_producer_state);
      ++pipeline_compute_mma_ds_producer_state;

      // release dP
      pipeline_mma_compute_dp.consumer_release(pipeline_mma_compute_dp_consumer_state);
      ++pipeline_mma_compute_dp_consumer_state;
      
      // release OdO
      pipeline_load_compute_sum_odo.consumer_release(pipeline_load_compute_sum_odo_consumer_state);
      ++pipeline_load_compute_sum_odo_consumer_state;

      iter_count -= 1;
      iter_index += 1;
      if (iter_index == iter_end) {
        iter_index = iter_start;
      }
    }

    epilogue(
        blk_coord, blk_offset, problem_shape, mainloop_args, epilogue_args,
	pipeline_mma_compute_dkdv, pipeline_mma_compute_dkdv_consumer_state
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
      prefetch_tma_descriptor(params.mainloop_params.tma_load_qt.get_tma_descriptor());
      prefetch_tma_descriptor(params.mainloop_params.tma_load_dot.get_tma_descriptor());
    }

    SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(smem);

    int initializing_warp = 0;
    typename PipelineLoadMmaQ::Params pipeline_load_mma_q_params;
    if (role == WarpRole::Load) {
      pipeline_load_mma_q_params.role = PipelineLoadMmaQ::ThreadCategory::Producer;
    }
    if (role == WarpRole::Mma) {
      pipeline_load_mma_q_params.role = PipelineLoadMmaQ::ThreadCategory::Consumer;
    }
    pipeline_load_mma_q_params.is_leader = lane_predicate && (role == WarpRole::Load) && is_mma_leader_cta;
    // Also loads K in the first iteration
    pipeline_load_mma_q_params.transaction_bytes = kTransactionsBytesLoadQ;
    pipeline_load_mma_q_params.initializing_warp = initializing_warp;
    PipelineLoadMmaQ pipeline_load_mma_q(shared_storage.pipelines.load_mma_q, pipeline_load_mma_q_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineLoadMmaDO::Params pipeline_load_mma_do_params;
    if (role == WarpRole::Load) {
      pipeline_load_mma_do_params.role = PipelineLoadMmaDO::ThreadCategory::Producer;
    }
    if (role == WarpRole::Mma) {
      pipeline_load_mma_do_params.role = PipelineLoadMmaDO::ThreadCategory::Consumer;
    }
    pipeline_load_mma_do_params.is_leader = lane_predicate && (role == WarpRole::Load) && is_mma_leader_cta;
    // Also loads V in the first iteration
    pipeline_load_mma_do_params.transaction_bytes = kTransactionsBytesLoadDO;
    pipeline_load_mma_do_params.initializing_warp = initializing_warp++;
    PipelineLoadMmaDO pipeline_load_mma_do(shared_storage.pipelines.load_mma_do, pipeline_load_mma_do_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineLoadMmaQT::Params pipeline_load_mma_qt_params;
    if (role == WarpRole::Load) {
      pipeline_load_mma_qt_params.role = PipelineLoadMmaQT::ThreadCategory::Producer;
    }
    if (role == WarpRole::Mma) {
      pipeline_load_mma_qt_params.role = PipelineLoadMmaQT::ThreadCategory::Consumer;
    }
    pipeline_load_mma_qt_params.is_leader = lane_predicate && (role == WarpRole::Load) && is_mma_leader_cta;
    // Also loads K in the first iteration
    pipeline_load_mma_qt_params.transaction_bytes = kTransactionsBytesLoadQ;
    pipeline_load_mma_qt_params.initializing_warp = initializing_warp;
    PipelineLoadMmaQT pipeline_load_mma_qt(shared_storage.pipelines.load_mma_qt, pipeline_load_mma_qt_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineLoadMmaDOT::Params pipeline_load_mma_dot_params;
    if (role == WarpRole::Load) {
      pipeline_load_mma_dot_params.role = PipelineLoadMmaDOT::ThreadCategory::Producer;
    }
    if (role == WarpRole::Mma) {
      pipeline_load_mma_dot_params.role = PipelineLoadMmaDOT::ThreadCategory::Consumer;
    }
    pipeline_load_mma_dot_params.is_leader = lane_predicate && (role == WarpRole::Load) && is_mma_leader_cta;
    // Also loads V in the first iteration
    pipeline_load_mma_dot_params.transaction_bytes = kTransactionsBytesLoadDO;
    pipeline_load_mma_dot_params.initializing_warp = initializing_warp++;
    PipelineLoadMmaDOT pipeline_load_mma_dot(shared_storage.pipelines.load_mma_dot, pipeline_load_mma_dot_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineLoadComputeLSE::Params pipeline_load_compute_lse_params;
    if (role == WarpRole::Load) {
      pipeline_load_compute_lse_params.role = PipelineLoadComputeLSE::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_load_compute_lse_params.role = PipelineLoadComputeLSE::ThreadCategory::Consumer;
    }
    pipeline_load_compute_lse_params.producer_arv_count = NumThreadsPerWarp;
    pipeline_load_compute_lse_params.consumer_arv_count = kNumComputeWarps * NumThreadsPerWarp;
    pipeline_load_compute_lse_params.initializing_warp = initializing_warp;
    PipelineLoadComputeLSE pipeline_load_compute_lse(
      shared_storage.pipelines.load_compute_lse,
      pipeline_load_compute_lse_params//,
      /*barrier init cute::true_type{}*/);

    typename PipelineLoadComputeSumOdO::Params pipeline_load_compute_sum_odo_params;
    if (role == WarpRole::Load) {
      pipeline_load_compute_sum_odo_params.role = PipelineLoadComputeSumOdO::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_load_compute_sum_odo_params.role = PipelineLoadComputeSumOdO::ThreadCategory::Consumer;
    }
    pipeline_load_compute_sum_odo_params.producer_arv_count = NumThreadsPerWarp;
    pipeline_load_compute_sum_odo_params.consumer_arv_count = kNumComputeWarps * NumThreadsPerWarp;
    pipeline_load_compute_sum_odo_params.initializing_warp = initializing_warp++;
    PipelineLoadComputeSumOdO pipeline_load_compute_sum_odo(
      shared_storage.pipelines.load_compute_sum_odo,
      pipeline_load_compute_sum_odo_params//,
      /*barrier init cute::true_type{}*/);

    typename PipelineMmaComputeS::Params pipeline_mma_compute_s_params;
    if (role == WarpRole::Mma) {
      pipeline_mma_compute_s_params.role = PipelineMmaComputeS::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_mma_compute_s_params.role = PipelineMmaComputeS::ThreadCategory::Consumer;
    }
    pipeline_mma_compute_s_params.consumer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_mma_compute_s_params.initializing_warp = initializing_warp;
    PipelineMmaComputeS pipeline_mma_compute_s(
      shared_storage.pipelines.mma_compute_s,
      pipeline_mma_compute_s_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineMmaComputeDP::Params pipeline_mma_compute_dp_params;
    if (role == WarpRole::Mma) {
      pipeline_mma_compute_dp_params.role = PipelineMmaComputeDP::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_mma_compute_dp_params.role = PipelineMmaComputeDP::ThreadCategory::Consumer;
    }
    pipeline_mma_compute_dp_params.consumer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_mma_compute_dp_params.initializing_warp = initializing_warp++;
    PipelineMmaComputeDP pipeline_mma_compute_dp(
      shared_storage.pipelines.mma_compute_dp,
      pipeline_mma_compute_dp_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});
   
    typename PipelineComputeMmaP::Params pipeline_compute_mma_p_params;
    if (role == WarpRole::Mma) {
      pipeline_compute_mma_p_params.role = PipelineComputeMmaP::ThreadCategory::Consumer;
    }
    if (role == WarpRole::Compute) {
      pipeline_compute_mma_p_params.role = PipelineComputeMmaP::ThreadCategory::Producer;
    }
    pipeline_compute_mma_p_params.producer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_compute_mma_p_params.consumer_arv_count = 1;
    pipeline_compute_mma_p_params.initializing_warp = initializing_warp;
    PipelineComputeMmaP pipeline_compute_mma_p(
      shared_storage.pipelines.compute_mma_p,
      pipeline_compute_mma_p_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});
    
    typename PipelineComputeMmaDS::Params pipeline_compute_mma_ds_params;
    if (role == WarpRole::Mma) {
      pipeline_compute_mma_ds_params.role = PipelineComputeMmaDS::ThreadCategory::Consumer;
    }
    if (role == WarpRole::Compute) {
      pipeline_compute_mma_ds_params.role = PipelineComputeMmaDS::ThreadCategory::Producer;
    }
    pipeline_compute_mma_ds_params.producer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_compute_mma_ds_params.consumer_arv_count = 1;
    pipeline_compute_mma_ds_params.initializing_warp = initializing_warp++;
    PipelineComputeMmaDS pipeline_compute_mma_ds(
      shared_storage.pipelines.compute_mma_ds,
      pipeline_compute_mma_ds_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});

    typename PipelineMmaComputeDKDV::Params pipeline_mma_compute_dkdv_params;
    if (role == WarpRole::Mma) {
      pipeline_mma_compute_dkdv_params.role = PipelineMmaComputeDKDV::ThreadCategory::Producer;
    }
    if (role == WarpRole::Compute) {
      pipeline_mma_compute_dkdv_params.role = PipelineMmaComputeDKDV::ThreadCategory::Consumer;
    }
    pipeline_mma_compute_dkdv_params.consumer_arv_count = kNumComputeWarps * cutlass::NumThreadsPerWarp * size(AtomThrShapeMNK{});
    pipeline_mma_compute_dkdv_params.initializing_warp = initializing_warp;
    PipelineMmaComputeDKDV pipeline_mma_compute_dkdv(
      shared_storage.pipelines.mma_compute_dkdv,
      pipeline_mma_compute_dkdv_params,
      ClusterShape{}, /*barrier init*/ cute::true_type{}, /*mask calc*/cute::false_type{});
  
    TmemAllocator tmem_allocator;

    pipeline_init_arrive_relaxed(size(ClusterShape{}));

    pipeline_load_mma_q.init_masks(ClusterShape{});
    pipeline_load_mma_do.init_masks(ClusterShape{});
    pipeline_load_mma_qt.init_masks(ClusterShape{});
    pipeline_load_mma_dot.init_masks(ClusterShape{});
    pipeline_mma_compute_s.init_masks(ClusterShape{});
    pipeline_mma_compute_dp.init_masks(ClusterShape{});
    pipeline_compute_mma_p.init_masks(ClusterShape{});
    pipeline_compute_mma_ds.init_masks(ClusterShape{});
    pipeline_mma_compute_dkdv.init_masks(ClusterShape{});

    typename decltype(pipeline_load_mma_q)::PipelineState pipeline_load_mma_q_consumer_state;
    typename decltype(pipeline_load_mma_do)::PipelineState pipeline_load_mma_do_consumer_state;
    typename decltype(pipeline_load_mma_qt)::PipelineState pipeline_load_mma_qt_consumer_state;
    typename decltype(pipeline_load_mma_dot)::PipelineState pipeline_load_mma_dot_consumer_state;
    typename decltype(pipeline_load_compute_lse)::PipelineState pipeline_load_compute_lse_consumer_state;
    typename decltype(pipeline_load_compute_sum_odo)::PipelineState pipeline_load_compute_sum_odo_consumer_state;
    typename decltype(pipeline_mma_compute_s)::PipelineState pipeline_mma_compute_s_consumer_state;
    typename decltype(pipeline_mma_compute_dp)::PipelineState pipeline_mma_compute_dp_consumer_state;
    typename decltype(pipeline_compute_mma_p)::PipelineState pipeline_compute_mma_p_consumer_state;
    typename decltype(pipeline_compute_mma_ds)::PipelineState pipeline_compute_mma_ds_consumer_state;
    typename decltype(pipeline_mma_compute_dkdv)::PipelineState pipeline_mma_compute_dkdv_consumer_state;

    auto pipeline_load_mma_q_producer_state = make_producer_start_state<decltype(pipeline_load_mma_q)>();
    auto pipeline_load_mma_do_producer_state = make_producer_start_state<decltype(pipeline_load_mma_do)>();
    auto pipeline_load_mma_qt_producer_state = make_producer_start_state<decltype(pipeline_load_mma_qt)>();
    auto pipeline_load_mma_dot_producer_state = make_producer_start_state<decltype(pipeline_load_mma_dot)>();
    auto pipeline_load_compute_lse_producer_state = make_producer_start_state<decltype(pipeline_load_compute_lse)>();
    auto pipeline_load_compute_sum_odo_producer_state = make_producer_start_state<decltype(pipeline_load_compute_sum_odo)>();
    auto pipeline_mma_compute_s_producer_state = make_producer_start_state<decltype(pipeline_mma_compute_s)>();
    auto pipeline_mma_compute_dp_producer_state = make_producer_start_state<decltype(pipeline_mma_compute_dp)>();
    auto pipeline_compute_mma_p_producer_state = make_producer_start_state<decltype(pipeline_compute_mma_p)>();
    auto pipeline_compute_mma_ds_producer_state = make_producer_start_state<decltype(pipeline_compute_mma_ds)>();
    auto pipeline_mma_compute_dkdv_producer_state = make_producer_start_state<decltype(pipeline_mma_compute_dkdv)>();

    pipeline_init_wait(size(ClusterShape{}));

    auto [Q, K, D, D_VO, HB] = params.problem_shape;
    auto [H, B] = HB;
    auto [H_R, H_K] = H;

    auto blk_coord = make_coord(_0{}, blockIdx.x, _0{}, _0{}, make_coord(make_coord(0, blockIdx.y), blockIdx.z));
    auto [problem_shape, blk_offset] = apply_variable_length_offset(
        params.problem_shape,
        blk_coord
    );
    int iter_end = ceil_div(get<0>(problem_shape), TileShapeQ{});
    int iter_start = 0;
    if constexpr (std::is_base_of_v<cutlass::fmha::collective::CausalMask<true>, Mask>) {
      iter_start = get<1>(blk_coord) / 2 * TileShapeK{} / TileShapeQ{};
    } else if constexpr (std::is_base_of_v<cutlass::fmha::collective::CausalMask<false>, Mask>) {
      int offset = get<1>(problem_shape) - get<0>(problem_shape);
      iter_start = max(0, (int(get<1>(blk_coord) / 2 * TileShapeK{} - offset)) / (int)TileShapeQ{});
    }
    if (get<1>(blk_coord) / 2 * TileShapeK{} >= get<1>(problem_shape)) {
      return;
    }

    int iter_count = (iter_end - iter_start) * get<4,0,0>(problem_shape);

    if (iter_count <= 0) {
      epilogue_clear(
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
          iter_start,
	  iter_end,
          iter_count,
          params.mainloop,
          params.mainloop_params,
          shared_storage.tensors,
          pipeline_load_mma_q, pipeline_load_mma_q_producer_state,
	  pipeline_load_mma_qt, pipeline_load_mma_qt_producer_state,
          pipeline_load_mma_do, pipeline_load_mma_do_producer_state,
	  pipeline_load_mma_dot, pipeline_load_mma_dot_producer_state,
          pipeline_load_compute_lse, pipeline_load_compute_lse_producer_state,
          pipeline_load_compute_sum_odo, pipeline_load_compute_sum_odo_producer_state
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
            iter_start,
	    iter_end,
            iter_count,
            params.mainloop,
            shared_storage.tensors,
            pipeline_load_mma_q, pipeline_load_mma_q_consumer_state,
	    pipeline_load_mma_qt, pipeline_load_mma_qt_consumer_state,
            pipeline_load_mma_do, pipeline_load_mma_do_consumer_state,
	    pipeline_load_mma_dot, pipeline_load_mma_dot_consumer_state,
            pipeline_mma_compute_s, pipeline_mma_compute_s_producer_state,
            pipeline_mma_compute_dp, pipeline_mma_compute_dp_producer_state,
            pipeline_compute_mma_p, pipeline_compute_mma_p_consumer_state,
            pipeline_compute_mma_ds, pipeline_compute_mma_ds_consumer_state,
            pipeline_mma_compute_dkdv, pipeline_mma_compute_dkdv_producer_state
        );
      }
    }
    else if (role == WarpRole::Compute) {
      warpgroup_reg_set<RegisterAllocation::kCompute>();

      compute(
          blk_coord,
          blk_offset,
          problem_shape,
          iter_start,
	  iter_end,
          iter_count,
          params.mainloop,
          params.epilogue,
          shared_storage.tensors,
          pipeline_load_compute_lse, pipeline_load_compute_lse_consumer_state,
          pipeline_load_compute_sum_odo, pipeline_load_compute_sum_odo_consumer_state,
          pipeline_mma_compute_s, pipeline_mma_compute_s_consumer_state,
          pipeline_mma_compute_dp, pipeline_mma_compute_dp_consumer_state,
          pipeline_compute_mma_p, pipeline_compute_mma_p_producer_state,
          pipeline_compute_mma_ds, pipeline_compute_mma_ds_producer_state,
          pipeline_mma_compute_dkdv, pipeline_mma_compute_dkdv_consumer_state
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
    dim3 grid(ceil_div(K, TileShapeK{})*2, H_K, B);
    return grid;
  }

};

}  // namespace cutlass::fmha::kernel
