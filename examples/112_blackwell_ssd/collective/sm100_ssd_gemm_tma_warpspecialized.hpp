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

#include "cutlass/cutlass.h"
#include "cutlass/gemm/collective/collective_builder.hpp"

#include "cutlass/cutlass.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/gemm/gemm.h"

#include "../utils/pipeline.h"

namespace cutlass::ssd::collective {

using namespace cute;

template<
  class Element_,
  class ElementDA_,
  class ElementAcc_,
  class ElementD_,
  class TileShape_,
  int StagesInput_,
  int StagesOutput_,
  class TiledMmaIntra1_,
  class TiledMmaIntra2_,
  class TiledMmaInter1_,
  class TiledMmaInter2_,
  class SmemLayoutX_,
  class SmemLayoutB_,
  class SmemLayoutC_,
  class SmemLayoutP_,
  class SmemLayoutBT_,
  class SmemLayoutPT_,
  class SmemLayoutQ_,
  class TmemLayoutB_,
  class TmemLayoutQ_
>
struct SsdMainloopTmaWarpSpecialized {


  using Element = Element_;
  using ElementDA = ElementDA_;
  using ElementAcc = ElementAcc_;
  static constexpr int StagesInput = StagesInput_;
  static constexpr int StagesOutput = StagesOutput_;

  using TileShape = TileShape_;                                                                     // (L,D,N)

  // avoid "warning #3357-D: capturing structured bindings is a C++20 feature"
  static constexpr auto L = get<0>(TileShape{});
  static constexpr auto D = get<1>(TileShape{});
  static constexpr auto N = get<2>(TileShape{});

  using TileShapeIntraBMM1 = decltype(make_shape(L, L, N));                                         // (L,L,N)
  using TileShapeIntraBMM2 = decltype(make_shape(L, D, N));                                         // (L,D,L)
  using TileShapeInterBMM1 = decltype(make_shape(N, D, L));                                         // (N,D,L)
  using TileShapeInterBMM2 = decltype(make_shape(L, D, N));                                         // (L,D,N)

  // 16B alignment lets us use TMA
  static constexpr int Alignment = 16 / sizeof(Element);

  using TiledMmaIntra1 = TiledMmaIntra1_;
  using TiledMmaIntra2 = TiledMmaIntra2_;
  using TiledMmaInter1 = TiledMmaInter1_;
  using TiledMmaInter2 = TiledMmaInter2_;
  using SmemLayoutX = SmemLayoutX_;
  using SmemLayoutB = SmemLayoutB_;
  using SmemLayoutC = SmemLayoutC_;
  using SmemLayoutP = SmemLayoutP_;
  using SmemLayoutBT = SmemLayoutBT_;
  using SmemLayoutPT = SmemLayoutPT_;
  using TmemLayoutB = TmemLayoutB_;
  using TmemLayoutQ = TmemLayoutQ_;
  using SmemLayoutQ = SmemLayoutQ_;

  using ClusterShape = Shape<_1, _1, _1>;
  using ClusterLayout_VMNK = decltype(tiled_divide(make_layout(
      ClusterShape{}),
      make_tile(typename TiledMmaIntra1::AtomThrID{})));

  using AtomThrShapeMNK = Shape<decltype(shape<0>(typename TiledMmaIntra1::ThrLayoutVMNK{})), _1, _1>;

  using MainloopPipelineX = cutlass::PipelineTmaMultiConsumersAsync<
                               StagesInput,
                               ClusterShape,
                               AtomThrShapeMNK>;
  using MainloopPipelineB = cutlass::PipelineTmaMultiConsumersAsync<
                               StagesInput,
                               ClusterShape,
                               AtomThrShapeMNK>;
  using MainloopPipelineC = cutlass::PipelineTmaMultiConsumersAsync<
                               StagesInput,
                               ClusterShape,
                               AtomThrShapeMNK>;
  using MainloopPipelineDelta = cutlass::PipelineTmaMultiConsumersAsync<
                               StagesInput,
                               ClusterShape,
                               AtomThrShapeMNK>;
  using MainloopPipelineIntra = cutlass::PipelineUmmaAsync<1, AtomThrShapeMNK>;
  using MainloopPipelineInter = cutlass::PipelineUmmaAsync<1, AtomThrShapeMNK>;
  using AccumulatorPipeline   = cutlass::PipelineUmmaAsync<1, AtomThrShapeMNK>;
  using AccumulatorPipelineState = typename AccumulatorPipeline::PipelineState;

  static constexpr int kXLoadBytes = size(SmemLayoutX{}(_,_,_,_0{})) * sizeof(Element);
  static constexpr int kBLoadBytes = size(SmemLayoutB{}(_,_,_,_0{})) * sizeof(Element);
  static constexpr int kCLoadBytes = size(SmemLayoutC{}(_,_,_,_0{})) * sizeof(Element);
  static constexpr int kDeltaLoadBytes = get<0>(TileShape{}) * sizeof(Element);
  static constexpr int kDeltaALoadBytes = get<0>(TileShape{}) * sizeof(ElementDA);

  struct TensorStorage : cute::aligned_struct<128, _0> {
    cute::array_aligned<Element, cute::cosize_v<SmemLayoutX>> smem_x;
    cute::array_aligned<Element, cute::cosize_v<SmemLayoutB>> smem_b;
    cute::array_aligned<Element, cute::cosize_v<SmemLayoutC>> smem_c;
    cute::array_aligned<Element, cute::cosize_v<SmemLayoutP>> smem_p;
    cute::array_aligned<Element, get<0>(TileShape{}) * StagesInput> smem_delta;
    cute::array_aligned<ElementDA, get<0>(TileShape{}) * StagesInput> smem_delta_a;
    cute::array_aligned<Element, get<1>(TileShape{}) * StagesInput> smem_d;
  };

  // TMEM management (for LDN = 128x64x128)
  static constexpr uint32_t tmem_intra_1_Acc = 0;
  static constexpr uint32_t tmem_intra_2_A   = tmem_intra_1_Acc + 128;
  static constexpr uint32_t tmem_intra_2_Acc = tmem_intra_2_A   +  64;
  static constexpr uint32_t tmem_inter_1_A   = tmem_intra_2_Acc +  64;
  static constexpr uint32_t tmem_inter_1_Acc = tmem_inter_1_A   +  64;
  static constexpr uint32_t tmem_inter_2_Acc = tmem_inter_1_Acc +  64;

  using StrideX     = cute::tuple<int, _1, int, int>;     // (D,L,C,B)
  using StrideB     = cute::tuple<_1, int, int, int>;     // (L,N,C,B)
  using StrideC     = cute::tuple<_1, int, int, int>;     // (L,N,C,B)
  using StrideDelta = cute::tuple<_1, int, int>;          // (L,C,B)

  using LayoutX     = decltype(make_layout(make_shape(D, L, int32_t(0), int32_t(0)), make_stride(int32_t(0), _1{}, L, int32_t(0))));  // (D,L,C,B)
  using LayoutB     = decltype(make_layout(make_shape(L, N, int32_t(0), int32_t(0)), make_stride(_1{}, int32_t(0), L, int32_t(0))));  // (L,N,C,B)
  using LayoutC     = decltype(make_layout(make_shape(L, N, int32_t(0), int32_t(0)), make_stride(_1{}, int32_t(0), L, int32_t(0))));  // (L,N,C,B)
  using LayoutDelta = decltype(make_layout(make_shape(L,    int32_t(0), int32_t(0)), make_stride(_1{},             L, int32_t(0))));  // (L,C,B)

  // Not support Mcast
  using GmemTiledCopyX = cute::SM90_TMA_LOAD;
  using GmemTiledCopyB = cute::SM90_TMA_LOAD;
  using GmemTiledCopyC = cute::SM90_TMA_LOAD;

  struct Arguments {
    const Element* ptr_X{nullptr};
    const ElementDA* ptr_DeltaA{nullptr};
    const Element* ptr_Delta{nullptr};
    const Element* ptr_B{nullptr};
    const Element* ptr_C{nullptr};
    LayoutX        layout_X{};
    LayoutB        layout_B{};
    LayoutC        layout_C{};
    LayoutDelta    layout_Delta{};
  };

  template <class TensorX, class ClusterShapeVMNK>
  static constexpr auto
  get_tma_load_x_instance(TensorX const& tensor_x, ClusterShapeVMNK const& cluster_shape_vmnk) {
    return make_tma_atom_B_sm100<Element>(
        GmemTiledCopyX{},
        tensor_x,
        SmemLayoutX{}(_,_,_,cute::Int<0>{}),
        TileShapeIntraBMM2{},
        TiledMmaIntra2{},
        cluster_shape_vmnk);
  }

  template <class TensorB, class ClusterShapeVMNK>
  static constexpr auto
  get_tma_load_b_instance(TensorB const& tensor_b, ClusterShapeVMNK const& cluster_shape_vmnk) {
    return make_tma_atom_B_sm100<Element>(
        GmemTiledCopyB{},
        tensor_b,
        SmemLayoutB{}(_,_,_,cute::Int<0>{}),
        TileShapeIntraBMM1{},
        TiledMmaIntra1{},
        cluster_shape_vmnk);
  }

  template <class TensorC, class ClusterShapeVMNK>
  static constexpr auto
  get_tma_load_c_instance(TensorC const& tensor_c, ClusterShapeVMNK const& cluster_shape_vmnk) {
    return make_tma_atom_A_sm100<Element>(
        GmemTiledCopyC{},
        tensor_c,
        SmemLayoutC{}(_,_,_,cute::Int<0>{}),
        TileShapeIntraBMM1{},
        TiledMmaIntra1{},
        cluster_shape_vmnk);
  }

  struct Params {
    using TMA_X = decltype(get_tma_load_x_instance(
        make_tensor(
            make_gmem_ptr(recast_ptr<Element>(nullptr)),
            LayoutX{}),
        ClusterLayout_VMNK{}));
    using TMA_B = decltype(get_tma_load_b_instance(
        make_tensor(
            make_gmem_ptr(recast_ptr<Element>(nullptr)),
            LayoutB{}),
        ClusterLayout_VMNK{}));
    using TMA_C = decltype(get_tma_load_c_instance(
        make_tensor(
            make_gmem_ptr(recast_ptr<Element>(nullptr)),
            LayoutC{}),
        ClusterLayout_VMNK{}));
    using TensorDelta = decltype(make_tensor(
      make_gmem_ptr(static_cast<Element const*>(nullptr)),
      LayoutDelta{}));
    using TensorDeltaA = decltype(make_tensor(
      make_gmem_ptr(static_cast<ElementDA const*>(nullptr)),
      LayoutDelta{}));

    TMA_X         tma_load_x;
    TMA_B         tma_load_b;
    TMA_C         tma_load_c;
    TensorDelta   tensor_delta;
    TensorDeltaA  tensor_delta_a;
  };

  template<class ProblemShape>
  static bool can_implement(ProblemShape const& problem_size, Arguments const& args) {
    return true;
  }

  template<class ProblemShape>
  static Params to_underlying_arguments(ProblemShape const& problem_size, Arguments const& args, void* workspace) {

    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;
    
    Tensor tensor_x = make_tensor(make_gmem_ptr(args.ptr_X), args.layout_X);
    Tensor tensor_b = make_tensor(make_gmem_ptr(args.ptr_B), args.layout_B);
    Tensor tensor_c = make_tensor(make_gmem_ptr(args.ptr_C), args.layout_C);
    Tensor tensor_delta = make_tensor(make_gmem_ptr(args.ptr_Delta), args.layout_Delta);
    Tensor tensor_delta_a = make_tensor(make_gmem_ptr(args.ptr_DeltaA), args.layout_Delta);

#if 0
    print("tensor_x      : ");print(tensor_x);print("\n");
    print("smem_X        : ");print(SmemLayoutX{});print("\n");
    print("tensor_b      : ");print(tensor_b);print("\n");
    print("smem_b        : ");print(SmemLayoutB{});print("\n");
    print("tensor_c      : ");print(tensor_c);print("\n");
    print("smem_c        : ");print(SmemLayoutC{});print("\n");
    print("tensor_delta  : ");print(tensor_delta);print("\n");
    print("tensor_delta_a: ");print(tensor_delta_a);print("\n");
    print("tile          : ");print(TileShape{});print("\n");
    print("tileIntra1    : ");print(TileShapeIntraBMM1{});print("\n");
    print("tileIntra2    : ");print(TileShapeIntraBMM2{});print("\n");
    print("tileInter1    : ");print(TileShapeInterBMM1{});print("\n");
    print("tileInter2    : ");print(TileShapeInterBMM2{});print("\n");
#endif

    typename Params::TMA_X tma_load_x = get_tma_load_x_instance(
        tensor_x,
        ClusterLayout_VMNK{});
    typename Params::TMA_B tma_load_b = get_tma_load_b_instance(
        tensor_b,
        ClusterLayout_VMNK{});
    typename Params::TMA_C tma_load_c = get_tma_load_c_instance(
        tensor_c,
        ClusterLayout_VMNK{});

    return Params{
      tma_load_x,
      tma_load_b,
      tma_load_c,
      tensor_delta,
      tensor_delta_a
    };
  }

  CUTLASS_DEVICE
  static void prefetch_tma_descriptors(Params const& params) {
    cute::prefetch_tma_descriptor(params.tma_load_x.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_b.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_c.get_tma_descriptor());
  }


  template <
    class Params, class ProblemShape
  >
  CUTLASS_DEVICE 
  auto load_x_init(Params const& params, ProblemShape const& problem_size) {

    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor mX_mkl = params.tma_load_x.get_tma_tensor(make_shape(D,L,C,EH*B));
    Tensor gX_mkl = local_tile(mX_mkl, TileShapeIntraBMM2{}, make_coord(_,_,_), Step<X,_1,_1>{});        // (BLK_M,BLK_K,m,k,l)

#if 0
    if (threadIdx.x % 32 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0)) {
      print("mX_mkl  : ");print(mX_mkl);print("\n");
      print("gX_mkl  : ");print(gX_mkl);print("\n");
      print("tma_desc_  : ");print(params.tma_load_x.tma_desc_);print("\n");
    }
#endif
    return make_tuple(gX_mkl);
  }
  
  template<
    class Params, class ProblemShape,
    class MainloopPipelineX, class PipelineStateX,
    class MainloopPipelineDelta, class PipelineStateDelta,
    class GTensorX,
    class TensorStorage
  >
  CUTLASS_DEVICE
  void load_x_delta(
    int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    MainloopPipelineX& pipeline_x, PipelineStateX& pipeline_x_producer_state,
    MainloopPipelineDelta& pipeline_delta, PipelineStateDelta& pipeline_delta_producer_state,
    cute::tuple<GTensorX> const& load_inputs,
    TensorStorage& shared_tensors) {
    
    int lane_predicate = cute::elect_one_sync();

    if (lane_predicate) {

      auto& gDelta = params.tensor_delta;
      auto& gDeltaA = params.tensor_delta_a;
      
      Element* ptr_delta = shared_tensors.smem_delta.data();
      ElementDA* ptr_delta_a = shared_tensors.smem_delta_a.data();
      auto smem_layout = make_layout(make_shape(get<0>(TileShape{}), Int<StagesInput>{}));
      auto sDelta = cute::as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(ptr_delta), smem_layout));
      auto sDeltaA = cute::as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(ptr_delta_a), smem_layout));

      auto bulk_atom_dt = Copy_Atom<SM90_BULK_COPY_AUTO, Element>{};
      auto bulk_atom_dA = Copy_Atom<SM90_BULK_COPY_AUTO, ElementDA>{};

      Tensor sX_ = make_tensor(make_smem_ptr(shared_tensors.smem_x.data()), SmemLayoutX{});       // (BLK_M,BLK_K,PIPE)
      Tensor sX  = as_position_independent_swizzle_tensor(sX_);                                  // (BLK_M,BLK_K,PIPE)
      
      ThrMMA cta_mma = TiledMmaIntra2{}.get_slice(blockIdx.x % size(typename TiledMmaIntra2::AtomThrID{}));

      Tensor gX_mkl = get<0>(load_inputs);
      Tensor tCgX_mk = cta_mma.partition_B(gX_mkl);

      auto [tXgX_mk, tXsX] = tma_partition(params.tma_load_x,
          group_modes<0,3>(sX), group_modes<0,3>(tCgX_mk));
      auto tXgX = tXgX_mk(_,_0{},_0{},_,blk_coord);

      // Disable multicast
      uint16_t mcast_mask_x = 0;

      auto chunk = get<3>(problem_size);
      // Mainloop
      CUTLASS_PRAGMA_NO_UNROLL
      for (int chunk_idx = 0; chunk_idx < chunk; ++chunk_idx) {
        int write_stage_x = pipeline_x_producer_state.index();
        int write_stage_delta = pipeline_delta_producer_state.index();

        using BarrierTypeX = typename MainloopPipelineX::ProducerBarrierType;
        BarrierTypeX* tma_barrier_x = pipeline_x.producer_get_barrier(pipeline_x_producer_state);
        using BarrierTypeDelta = typename MainloopPipelineDelta::ProducerBarrierType;
        BarrierTypeDelta* tma_barrier_delta = pipeline_delta.producer_get_barrier(pipeline_delta_producer_state);

        pipeline_x.producer_acquire(pipeline_x_producer_state);

        copy(params.tma_load_x.with(*tma_barrier_x, mcast_mask_x), tXgX(_,chunk_idx), tXsX(_,write_stage_x));

        pipeline_delta.producer_acquire(pipeline_delta_producer_state);

        copy(bulk_atom_dt.with(*tma_barrier_delta), gDelta(_,chunk_idx,blk_coord), sDelta(_,write_stage_delta));
        copy(bulk_atom_dA.with(*tma_barrier_delta), gDeltaA(_,chunk_idx,blk_coord), sDeltaA(_,write_stage_delta));

        // Advance pipeline_state
        ++pipeline_x_producer_state;
        ++pipeline_delta_producer_state;
      }
    }
  }

  /// Perform a Producer Epilogue to prevent early exit of blocks in a Cluster
  template<
    class MainloopPipeline, class PipelineState
  >
  CUTLASS_DEVICE void
  load_x_tail(MainloopPipeline pipeline, PipelineState pipeline_state) {
    int lane_predicate = cute::elect_one_sync();

    // Issue the epilogue waits
    if (lane_predicate) {
      /* This helps avoid early exit of blocks in Cluster
       * Waits for all stages to either be released (all 
       * Consumer UNLOCKs), or if the stage was never used
       * then would just be acquired since the phase was 
       * still inverted from make_producer_start_state
       */
      pipeline.producer_tail(pipeline_state);
    }
  }

  template <
    class Params, class ProblemShape
  >
  CUTLASS_DEVICE 
  auto load_b_init(Params const& params, ProblemShape const& problem_size) {

    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor mB_mkl = params.tma_load_b.get_tma_tensor(make_shape(L,N,C,G*B));
    Tensor gB_mkl = local_tile(mB_mkl, TileShapeIntraBMM1{}, make_coord(_,_,_), Step<_1, X,_1>{});        // (BLK_M,BLK_K,m,k,l)

    return make_tuple(gB_mkl);
  }

  template <
    class Params, class ProblemShape
  >
  CUTLASS_DEVICE 
  auto load_c_init(Params const& params, ProblemShape const& problem_size) {

    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor mC_mkl = params.tma_load_c.get_tma_tensor(make_shape(L,N,C,G*B));
    Tensor gC_mkl = local_tile(mC_mkl, TileShapeIntraBMM1{}, make_coord(_,_,_), Step<X,_1,_1>{});        // (BLK_M,BLK_K,n,k,l)

    return make_tuple(gC_mkl);
  }
  
  template<
    class Params, class ProblemShape,
    class MainloopPipelineB, class PipelineStateB,
    class MainloopPipelineC, class PipelineStateC,
    class GTensorB, class GTensorC,
    class TensorStorage
  >
  CUTLASS_DEVICE
  void load_b_c(
    int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    MainloopPipelineB& pipeline_b, PipelineStateB& pipeline_b_producer_state,
    MainloopPipelineC& pipeline_c, PipelineStateC& pipeline_c_producer_state,
    cute::tuple<GTensorB> const& load_inputs_b, cute::tuple<GTensorC> const& load_inputs_c, 
    TensorStorage& shared_tensors) {
    
    int lane_predicate = cute::elect_one_sync();

    if (lane_predicate) {
      Tensor sB_ = make_tensor(make_smem_ptr(shared_tensors.smem_b.data()), SmemLayoutB{});       // (BLK_M,BLK_K,PIPE)
      Tensor sB  = as_position_independent_swizzle_tensor(sB_);                                  // (BLK_M,BLK_K,PIPE)
      Tensor sC_ = make_tensor(make_smem_ptr(shared_tensors.smem_c.data()), SmemLayoutC{});       // (BLK_M,BLK_K,PIPE)
      Tensor sC  = as_position_independent_swizzle_tensor(sC_);                                  // (BLK_M,BLK_K,PIPE)

      //
      // Prepare the TMA loads for B&C
      //

      Tensor gB_mkl = get<0>(load_inputs_b);
      Tensor gC_mkl = get<0>(load_inputs_c);

      ThrMMA cta_mma = TiledMmaIntra1{}.get_slice(blockIdx.x % size(typename TiledMmaIntra1::AtomThrID{}));

      Tensor tCgC_mk = cta_mma.partition_A(gC_mkl);
      Tensor tCgB_mk = cta_mma.partition_B(gB_mkl);

      auto [tCgC_, tCsC] = tma_partition(params.tma_load_c,
          group_modes<0,3>(sC), group_modes<0,3>(tCgC_mk));
      auto tCgC = tCgC_(_,_0{},_0{},_,blk_coord);

      auto [tBgB_, tBsB] = tma_partition(params.tma_load_b,
          group_modes<0,3>(sB), group_modes<0,3>(tCgB_mk));
      auto tBgB = tBgB_(_,_0{},_0{},_,blk_coord);

#if 0
    if (threadIdx.x % 32 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0)) {
      print("gC  : ");print(gC);print("\n");
      print("tCgC  : ");print(tCgC);print("\n");
      print("tCsC  : ");print(tCsC);print("\n");
    }
#endif
      // no multicast
      // Disable multicast
      uint16_t mcast_mask_b = 0;
      uint16_t mcast_mask_c = 0;

      auto chunk = get<3>(problem_size);
      // Mainloop
      CUTLASS_PRAGMA_NO_UNROLL
      for (int chunk_idx = 0; chunk_idx < chunk; ++chunk_idx) {
        int write_stage_b = pipeline_b_producer_state.index();
        int write_stage_c = pipeline_c_producer_state.index();

        using BarrierTypeB = typename MainloopPipelineB::ProducerBarrierType;
        BarrierTypeB* tma_barrier_b = pipeline_b.producer_get_barrier(pipeline_b_producer_state);
        using BarrierTypeC = typename MainloopPipelineC::ProducerBarrierType;
        BarrierTypeC* tma_barrier_c = pipeline_c.producer_get_barrier(pipeline_c_producer_state);

        pipeline_b.producer_acquire(pipeline_b_producer_state);

        copy(params.tma_load_b.with(*tma_barrier_b, mcast_mask_b), tBgB(_,chunk_idx), tBsB(_,write_stage_b));

        pipeline_c.producer_acquire(pipeline_c_producer_state);

        copy(params.tma_load_c.with(*tma_barrier_c, mcast_mask_c), tCgC(_,chunk_idx), tCsC(_,write_stage_c));

        // Advance pipeline_state
        ++pipeline_b_producer_state;
        ++pipeline_c_producer_state;
      }
    }
  }

  /// Perform a Producer Epilogue to prevent early exit of blocks in a Cluster
  template<
    class MainloopPipeline, class PipelineState
  >
  CUTLASS_DEVICE void
  load_b_c_tail(MainloopPipeline pipeline, PipelineState pipeline_state) {
    int lane_predicate = cute::elect_one_sync();

    // Issue the epilogue waits
    if (lane_predicate) {
      /* This helps avoid early exit of blocks in Cluster
       * Waits for all stages to either be released (all 
       * Consumer UNLOCKs), or if the stage was never used
       * then would just be acquired since the phase was 
       * still inverted from make_producer_start_state
       */
      pipeline.producer_tail(pipeline_state);
    }
  }

  template<
    class TiledMma,
    class FragmentA, class FragmentB,
    class FrgEngine, class FrgLayout
  >
  CUTLASS_DEVICE
  auto mma(
    int read_A_stage, int read_B_stage,
    cute::tuple<TiledMma, FragmentA, FragmentB> const& mma_inputs,
    cute::Tensor<FrgEngine, FrgLayout>& accumulators) {
    auto [tiled_mma, tCrA, tCrB] = mma_inputs;
    tiled_mma.accumulate_ = UMMA::ScaleOut::Zero;
    CUTLASS_PRAGMA_UNROLL
    for (int k_block = 0; k_block < size<2>(tCrA); ++k_block) {
      // (V,M,K) x (V,N,K) => (V,M,N)
      cute::gemm(tiled_mma, tCrA(_,_,k_block,read_A_stage), tCrB(_,_,k_block,read_B_stage), accumulators);
      tiled_mma.accumulate_ = UMMA::ScaleOut::One;
    }
  }

  CUTLASS_DEVICE auto
  get_mma_intra_acc(){
    static constexpr uint32_t tmem_base_ptr = 0; // reserved all tmem columns
    auto acc_shape_1 = partition_shape_C(TiledMmaIntra1{}, take<0,2>(TileShapeIntraBMM1{}));
    auto accumulator_1 = TiledMmaIntra1::make_fragment_C(append(acc_shape_1,
                                                         Int<1>{}));
    accumulator_1.data() = tmem_base_ptr + tmem_intra_1_Acc;

    auto acc_shape_2 = partition_shape_C(TiledMmaIntra2{}, take<0,2>(TileShapeIntraBMM2{}));
    auto accumulator_2 = TiledMmaIntra2::make_fragment_C(append(acc_shape_2,
                                                         Int<1>{}));
    accumulator_2.data() = tmem_base_ptr + tmem_intra_2_Acc;
    return cute::make_tuple(accumulator_1, accumulator_2);
  }

  CUTLASS_DEVICE auto
  mma_intra_init(TensorStorage& shared_tensors) {
    // Init Intra1
    TiledMmaIntra1 tiled_mma_1;

    Tensor sB = make_tensor(make_smem_ptr(shared_tensors.smem_b.data()), SmemLayoutB{});
    Tensor sC = make_tensor(make_smem_ptr(shared_tensors.smem_c.data()), SmemLayoutC{});

    Tensor tCrC = tiled_mma_1.make_fragment_A(sC);
    Tensor tCrB = tiled_mma_1.make_fragment_B(sB);

    // Init Intra2
    TiledMmaIntra2 tiled_mma_2;

    Tensor sX = make_tensor(make_smem_ptr(shared_tensors.smem_x.data()), SmemLayoutX{});
    Tensor tCrQ = tiled_mma_2.make_fragment_A(shape(TmemLayoutQ{}));
    Tensor tCrX = tiled_mma_2.make_fragment_B(sX);

    static constexpr uint32_t tmem_base_ptr = 0; // reserved all tmem columns
    tCrQ.data() = tmem_base_ptr + tmem_intra_2_A;
#if 0
    if (threadIdx.x % 32 == 0) {
      print("sB   : ");print(sB);print("\n");
      print("sC   : ");print(sC);print("\n");
      print("sX   : ");print(sX);print("\n");
      print("tCrC : ");print(tCrC);print("\n");
      print("tCrB : ");print(tCrB);print("\n");
      print("tCrQ : ");print(tCrQ);print("\n");
      print("tCrX : ");print(tCrX);print("\n");
    }
#endif
    return cute::make_tuple(
      cute::make_tuple(tiled_mma_1, tCrC, tCrB), // mma intra 1
      cute::make_tuple(tiled_mma_2, tCrQ, tCrX)  // mma intra 2
    );
  }

  template<
    class MainloopPipelineB, class PipelineStateB,
    class MainloopPipelineC, class PipelineStateC,
    class MainloopPipelineX, class PipelineStateX,
    class MainloopPipelineIntra, class PipelineStateIntra,
    class TiledMma_1, class FragmentA_1, class FragmentB_1,
    class TiledMma_2, class FragmentA_2, class FragmentB_2,
    class FragmentC_1, class FragmentC_2
  >
  CUTLASS_DEVICE
  auto mma_intra(
    MainloopPipelineB& pipeline_b, PipelineStateB& pipeline_b_consumer_state,
    MainloopPipelineC& pipeline_c, PipelineStateC& pipeline_c_consumer_state,
    MainloopPipelineX& pipeline_x, PipelineStateX& pipeline_x_consumer_state,
    MainloopPipelineIntra& pipeline_intra, PipelineStateIntra& pipeline_intra_producer_state,
    cute::tuple<TiledMma_1, FragmentA_1, FragmentB_1> const& mma_inputs_1,
    cute::tuple<TiledMma_2, FragmentA_2, FragmentB_2> const& mma_inputs_2,
    cute::tuple<FragmentC_1, FragmentC_2>& acc_intra) {

    auto [acc_intra_1, acc_intra_2] = acc_intra;
    // require B&C
    auto pipeline_b_token = pipeline_b.consumer_try_wait(pipeline_b_consumer_state);
    auto pipeline_c_token = pipeline_c.consumer_try_wait(pipeline_c_consumer_state);
    auto pipeline_x_token = pipeline_x.consumer_try_wait(pipeline_x_consumer_state);
    pipeline_b.consumer_wait(pipeline_b_consumer_state, pipeline_b_token);
    pipeline_c.consumer_wait(pipeline_c_consumer_state, pipeline_c_token);
    pipeline_x.consumer_wait(pipeline_x_consumer_state, pipeline_x_token);
    // do we need try wait?
    pipeline_intra.producer_acquire(pipeline_intra_producer_state);
    {
      auto read_A_stage = pipeline_c_consumer_state.index();
      auto read_B_stage = pipeline_b_consumer_state.index();
      auto accumulator = acc_intra_1(_,_,_,_0{});
      mma(read_A_stage, read_B_stage, mma_inputs_1, accumulator);
    }
    // release B&C
    pipeline_b.consumer_release_from_umma(pipeline_b_consumer_state);
    pipeline_c.consumer_release_from_umma(pipeline_c_consumer_state);
    pipeline_intra.producer_commit(pipeline_intra_producer_state);
    ++pipeline_b_consumer_state;
    ++pipeline_c_consumer_state;
    ++pipeline_intra_producer_state;
    // MMA Intra2
    pipeline_intra.producer_acquire(pipeline_intra_producer_state);
    {
      auto read_B_stage = pipeline_x_consumer_state.index();
      auto accumulator = acc_intra_2(_,_,_,_0{});
      mma(_0{}, read_B_stage, mma_inputs_2, accumulator);
    }
    pipeline_intra.producer_commit(pipeline_intra_producer_state);
    pipeline_x.consumer_release_from_umma(pipeline_x_consumer_state);
    ++pipeline_x_consumer_state;
    ++pipeline_intra_producer_state;
  }

  CUTLASS_DEVICE auto
  get_mma_inter_acc(){
    static constexpr uint32_t tmem_base_ptr = 0; // reserved all tmem columns
    auto acc_shape_1 = partition_shape_C(TiledMmaInter1{}, take<0,2>(TileShapeInterBMM1{}));
    auto accumulator_1 = TiledMmaInter1::make_fragment_C(append(acc_shape_1,
                                                         Int<1>{}));
    accumulator_1.data() = tmem_base_ptr + tmem_inter_1_Acc;

    auto acc_shape_2 = partition_shape_C(TiledMmaInter2{}, take<0,2>(TileShapeInterBMM2{}));
    auto accumulator_2 = TiledMmaInter2::make_fragment_C(append(acc_shape_2,
                                                         Int<1>{}));
    accumulator_2.data() = tmem_base_ptr + tmem_inter_2_Acc;
    return cute::make_tuple(accumulator_1, accumulator_2);
  }

  CUTLASS_DEVICE auto
  mma_inter_init(TensorStorage& shared_tensors) {
    // Init Inter1
    TiledMmaInter1 tiled_mma_1;

    Tensor sX = make_tensor(make_smem_ptr(shared_tensors.smem_x.data()), SmemLayoutX{});

    Tensor tCrB = tiled_mma_1.make_fragment_A(shape(TmemLayoutB{}));
    Tensor tCrX = tiled_mma_1.make_fragment_B(sX);

    static constexpr uint32_t tmem_base_ptr = 0; // reserved all tmem columns
    tCrB.data() = tmem_base_ptr + tmem_inter_1_A;

    // Init Inter2
    TiledMmaInter2 tiled_mma_2;

    Tensor sC = make_tensor(make_smem_ptr(shared_tensors.smem_c.data()), SmemLayoutC{});
    Tensor sP = make_tensor(make_smem_ptr(shared_tensors.smem_p.data()), SmemLayoutP{});

    Tensor tCrC = tiled_mma_2.make_fragment_A(sC);
    Tensor tCrP = tiled_mma_2.make_fragment_B(sP);

    return cute::make_tuple(
      cute::make_tuple(tiled_mma_1, tCrB, tCrX), // mma intra 1
      cute::make_tuple(tiled_mma_2, tCrC, tCrP)  // mma intra 2
    );
  }

  template<
    class MainloopPipelineC, class PipelineStateC,
    class MainloopPipelineX, class PipelineStateX,
    class MainloopPipelineInter, class PipelineStateInter,
    class MainloppPipelineAcc, class PipelineStateAcc,
    class TiledMma_1, class FragmentA_1, class FragmentB_1,
    class TiledMma_2, class FragmentA_2, class FragmentB_2,
    class FragmentC_1, class FragmentC_2
  >
  CUTLASS_DEVICE
  auto mma_inter(
    MainloopPipelineC& pipeline_c, PipelineStateC& pipeline_c_consumer_state,
    MainloopPipelineX& pipeline_x, PipelineStateX& pipeline_x_consumer_state,
    MainloopPipelineInter& pipeline_inter, PipelineStateInter& pipeline_inter_producer_state,
    MainloppPipelineAcc& pipeline_acc, PipelineStateAcc& pipeline_acc_producer_state,
    cute::tuple<TiledMma_1, FragmentA_1, FragmentB_1> const& mma_inputs_1,
    cute::tuple<TiledMma_2, FragmentA_2, FragmentB_2> const& mma_inputs_2,
    cute::tuple<FragmentC_1, FragmentC_2>& acc_inter) {
    
    auto [acc_inter_1, acc_inter_2] = acc_inter;

    // require C
    auto pipeline_x_token = pipeline_x.consumer_try_wait(pipeline_x_consumer_state);
    auto pipeline_c_token = pipeline_c.consumer_try_wait(pipeline_c_consumer_state);

    pipeline_x.consumer_wait(pipeline_x_consumer_state, pipeline_x_token);
    // MMA inter 1
    pipeline_inter.producer_acquire(pipeline_inter_producer_state);
    {
      auto read_B_stage = pipeline_x_consumer_state.index();
      auto accumulator = acc_inter_1(_,_,_,_0{});
      mma(_0{}, read_B_stage, mma_inputs_1, accumulator);
    }
    // release B&C
    pipeline_x.consumer_release_from_umma(pipeline_x_consumer_state);
    ++pipeline_x_consumer_state;

    pipeline_c.consumer_wait(pipeline_c_consumer_state, pipeline_c_token);
    // MMA inter 2
    pipeline_acc.producer_acquire(pipeline_acc_producer_state);
    {
      auto read_A_stage = pipeline_c_consumer_state.index();
      auto accumulator = acc_inter_2(_,_,_,_0{});
      mma(read_A_stage, _0{}, mma_inputs_2, accumulator);
    }
    pipeline_c.consumer_release_from_umma(pipeline_c_consumer_state);
    pipeline_inter.producer_commit(pipeline_inter_producer_state);
    pipeline_acc.producer_commit(pipeline_acc_producer_state);
    ++pipeline_c_consumer_state;
    ++pipeline_inter_producer_state;
    ++pipeline_acc_producer_state;

  }

  template<
    class FragmentC_1, class FragmentC_2,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto state_init(
    cute::tuple<FragmentC_1, FragmentC_2>& acc_inter,
    TensorStorage& shared_tensors) {

    int thread_idx = threadIdx.x % cutlass::NumThreadsPerWarpGroup;
    using CopyAtomT2R = SM100_TMEM_LOAD_16dp256b8x;
    using CopyOpR2S = SM90_U16x8_STSM_T;

    auto synchronize = [&] () { cutlass::arch::NamedBarrier::sync(128, cutlass::arch::ReservedNamedBarriers::TransposeBarrier); };

    // Pre inter 2
    auto accumulator = get<0>(acc_inter);
    auto tIntra = make_tensor(accumulator.data(), get<0>(accumulator.layout()));
    Tensor sP = make_tensor(make_smem_ptr(shared_tensors.smem_p.data()), SmemLayoutPT{});
    auto tiled_t2r = make_tmem_copy(CopyAtomT2R{}, tIntra);
    auto thr_t2r = tiled_t2r.get_slice(thread_idx);
    auto tTR_sP = thr_t2r.partition_D(sP(_,_,_0{}));
    auto tTR_rP_compute = make_tensor<ElementAcc>(shape(tTR_sP));
    auto tTR_rP = make_tensor<Element>(shape(tTR_sP));

    clear(tTR_rP);
    clear(tTR_rP_compute);

    auto tiled_r2s = make_tiled_copy_D(Copy_Atom<CopyOpR2S, Element>{}, tiled_t2r);
    auto thr_r2s = tiled_r2s.get_slice(thread_idx);
    auto tRS_sP = thr_r2s.partition_D(sP(_,_,_0{}));
    auto tRS_rP = thr_r2s.retile_S(tTR_rP);

    copy(tiled_r2s, tRS_rP, tRS_sP);
    cutlass::arch::fence_view_async_shared();

    synchronize();
    return make_tuple(tTR_rP_compute);
  }

  template<
    class MainloopPipelineB, class PipelineStateB,
    class MainloopPipelineDelta, class PipelineStateDelta,
    class MainloopPipelineInter, class PipelineStateInter,
    class FragmentC_1, class FragmentC_2,
    class TensorState,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto pre_inter(
    MainloopPipelineB& pipeline_b, PipelineStateB& pipeline_b_consumer_state,
    MainloopPipelineDelta& pipeline_delta, PipelineStateDelta& pipeline_delta_consumer_state,
    MainloopPipelineInter& pipeline_inter, PipelineStateInter& pipeline_inter_consumer_state,
    cute::tuple<FragmentC_1, FragmentC_2>& acc_inter,
    TensorState& tState,
    TensorStorage& shared_tensors) {

    static constexpr uint32_t tmem_base_ptr = 0; // reserved all tmem columns
    int thread_idx = threadIdx.x % cutlass::NumThreadsPerWarpGroup;
    using CopyAtomR2T = SM100_TMEM_STORE_16dp128b16x;
    using CopyAtomT2R = SM100_TMEM_LOAD_16dp256b8x;
    using CoptAtomS2R = SM75_U32x4_LDSM_N;
    using CopyOpR2S = SM90_U16x8_STSM_T;

    // Pipeline check
    auto pipeline_b_token = pipeline_b.consumer_try_wait(pipeline_b_consumer_state);
    auto pipeline_delta_token = pipeline_delta.consumer_try_wait(pipeline_delta_consumer_state);
    pipeline_b.consumer_wait(pipeline_b_consumer_state, pipeline_b_token);
    pipeline_delta.consumer_wait(pipeline_delta_consumer_state, pipeline_delta_token);

    // Pre inter 1
    TiledMmaInter1 tiled_mma_1;
    Tensor sB = make_tensor(make_smem_ptr(shared_tensors.smem_b.data()), SmemLayoutBT{});
    Tensor tBtB = tiled_mma_1.make_fragment_A(shape(TmemLayoutB{}));
    tBtB.data() = tmem_base_ptr + tmem_inter_1_A;

    auto tiled_s2t = make_tmem_copy(CopyAtomR2T{}, tBtB(_,_,_,0));
    auto thr_s2t = tiled_s2t.get_slice(thread_idx);
    auto tiled_s2r = make_tiled_copy_S(Copy_Atom<CoptAtomS2R, Element>{}, tiled_s2t);
    auto thr_s2r = tiled_s2r.get_slice(thread_idx);

    auto tBsB_s2r = thr_s2r.partition_S(sB);
    auto tBtB_r2t = thr_s2t.partition_D(tBtB);
    auto tBrB_r2t = make_tensor<Element>(shape(thr_s2t.partition_S(sB(_,_,_,_0{}))));
    auto tBrB_s2r = thr_s2r.retile_D(tBrB_r2t);

    auto ts0 = size<0>(TileShape{});
    Layout row_layout = make_layout(make_shape ( ts0,  ts0, Int<StagesInput>{}),
                                    make_stride(_0{}, _1{}, ts0));

    Tensor sDelta   = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta.data()), row_layout));
    Tensor sDeltaA  = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta_a.data()), row_layout));

    auto thr_mma = tiled_mma_1.get_thread_slice(thread_idx);
    auto tCsDelta = thr_mma.partition_A(sDelta);
    auto tCsDeltaA = thr_mma.partition_A(sDeltaA);

    auto tBsDelta = thr_s2t.partition_S(tCsDelta(_,_,_,pipeline_delta_consumer_state.index()));
    auto tBrDelta = make_tensor<Element>(shape(tBsDelta));
    auto tBsDeltaA = thr_s2t.partition_S(tCsDeltaA(_,_,_,pipeline_delta_consumer_state.index()));
    auto tBrDeltaA = make_tensor<ElementDA>(shape(tBsDeltaA));

    Layout linear_layout = make_layout(make_shape ( ts0, Int<StagesInput>{}),
                                       make_stride(_1{},                ts0));
    Tensor sDeltaA_last = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta_a.data()), linear_layout));
    
#if 0
    if (threadIdx.x % 128 == 0) {
      print("sB       : ");print(sB);print("\n");
      print("sB       : ");print(SmemLayoutB{});print("\n");
      print("tBtB     : ");print(tBtB);print("\n");
      print("tBsB_s2r : ");print(tBsB_s2r);print("\n");
      print("tBtB_r2t : ");print(tBtB_r2t);print("\n");
      print("tBrB_r2t : ");print(tBrB_r2t);print("\n");
      print("tBrB_s2r : ");print(tBrB_s2r);print("\n");
      print("tBsDelta   : ");print(tBsDelta);print("\n");
      print("tBsDeltaA  : ");print(tBsDeltaA);print("\n");
      print("tBrDelta   : ");print(tBrDelta);print("\n");
      print("tBrDeltaA  : ");print(tBrDeltaA);print("\n");
    }
#endif 

    copy(tiled_s2r, tBsB_s2r(_,_,_,_,pipeline_b_consumer_state.index()), tBrB_s2r);
    
    copy(tBsDelta, tBrDelta);
    copy(tBsDeltaA, tBrDeltaA);

    ElementAcc last_column = ElementAcc(0.f);
    last_column = sDeltaA_last(_,pipeline_delta_consumer_state.index())(int(ts0) - 1);

    cutlass::arch::fence_view_async_shared();

    auto tCompute = make_tensor<ElementAcc>(shape(tBrB_s2r));
    auto tBrB_Compute = make_tensor<ElementAcc>(shape(tBrB_s2r));
    auto tBrDelta_Compute = make_tensor<ElementAcc>(shape(tBrDelta));
    auto tBrDeltaA_Compute = make_tensor<ElementAcc>(shape(tBrDeltaA));

    type_convert<Element, ElementAcc>(tBrB_s2r, tBrB_Compute);
    type_convert<Element, ElementAcc>(tBrDelta, tBrDelta_Compute);
    type_convert<ElementDA, ElementAcc>(tBrDeltaA, tBrDeltaA_Compute);

    auto tBrDeltaA_packed = recast<float2>(tBrDeltaA_Compute);
    auto tBrDelta_packed = recast<float2>(tBrDelta_Compute);
    auto tBrB_packed = recast<float2>(tBrB_Compute);
    auto tCompute_packed = recast<float2>(tCompute);
    CUTLASS_PRAGMA_UNROLL
    for (int ii = 0; ii < size(tCompute_packed); ++ii) {
      tBrDeltaA_Compute(2 * ii) = expf(last_column - tBrDeltaA_Compute(2 * ii));
      tBrDeltaA_Compute(2 * ii + 1) = expf(last_column - tBrDeltaA_Compute(2 * ii + 1));

      cute::mul(tCompute_packed(ii), tBrDelta_packed(ii), tBrDeltaA_packed(ii));
      cute::mul(tCompute_packed(ii), tBrB_packed(ii), tCompute_packed(ii));
    }

    type_convert<ElementAcc, Element>(tCompute, tBrB_r2t);

    copy(tiled_s2t, tBrB_r2t, tBtB_r2t(_,_,_,_,_0{}));
    cutlass::arch::fence_view_async_tmem_store();

    // Pipeline update
    pipeline_b.consumer_release_from_threads(pipeline_b_consumer_state); 
    pipeline_delta.consumer_release_from_threads(pipeline_delta_consumer_state); 
    pipeline_inter.consumer_release(pipeline_inter_consumer_state);
    ++pipeline_b_consumer_state;
    ++pipeline_delta_consumer_state;
    ++pipeline_inter_consumer_state;

    // Pipeline check
    pipeline_inter.consumer_wait(pipeline_inter_consumer_state);

    // Pre inter 2
    auto accumulator = get<0>(acc_inter);
    auto tIntra = make_tensor(accumulator.data(), get<0>(accumulator.layout()));
    Tensor sP = make_tensor(make_smem_ptr(shared_tensors.smem_p.data()), SmemLayoutPT{});
    auto tiled_t2r = make_tmem_copy(CopyAtomT2R{}, tIntra);
    auto thr_t2r = tiled_t2r.get_slice(thread_idx);
    auto tTR_tP = thr_t2r.partition_S(tIntra);
    auto tTR_sP = thr_t2r.partition_D(sP(_,_,_0{}));
    auto tTR_rP_compute = make_tensor<ElementAcc>(shape(tTR_sP));
    auto tTR_rP = make_tensor<Element>(shape(tTR_sP));

    auto tiled_r2s = make_tiled_copy_D(Copy_Atom<CopyOpR2S, Element>{}, tiled_t2r);
    auto thr_r2s = tiled_r2s.get_slice(thread_idx);
    auto tRS_sP = thr_r2s.partition_D(sP(_,_,_0{}));
    auto tRS_rP = thr_r2s.retile_S(tTR_rP);

    copy(tiled_t2r, tTR_tP, tTR_rP_compute);
    cutlass::arch::fence_view_async_tmem_load();
    
    for (int ii = 0; ii < size(tTR_rP_compute); ++ii) {
      tTR_rP_compute(ii) = tTR_rP_compute(ii) + expf(last_column) * static_cast<ElementAcc>(tState(ii));
    }

    type_convert<ElementAcc,Element>(tTR_rP_compute,tTR_rP);
    // Update the state
    copy(tTR_rP_compute, tState);

    copy(tiled_r2s, tRS_rP, tRS_sP);
    // Fence for the next iteration `pipeline_inter.consumer_release`
    cutlass::arch::fence_view_async_shared();

#if 0
    if (threadIdx.x % 128 == 0) {
      print("accumulator:");print(accumulator);print("\n");
      print("sP       : ");print(sP);print("\n");
      print("sP       : ");print(SmemLayoutP{});print("\n");
      print("tTR_tP   : ");print(tTR_tP);print("\n");
      print("tTR_sP   : ");print(tTR_sP);print("\n");
      print("tTR_rP   : ");print(tTR_rP);print("\n");
      print("tRS_sP   : ");print(tRS_sP);print("\n");
      print("tRS_rP   : ");print(tRS_rP);print("\n");
    }
#endif

  }

  template<
    class MainloopPipelineDelta, class PipelineStateDelta,
    class MainloopPipelineIntra, class PipelineStateIntra,
    class FragmentC_1, class FragmentC_2
  >
  CUTLASS_DEVICE
  auto pre_intra(
    MainloopPipelineDelta& pipeline_delta, PipelineStateDelta& pipeline_delta_consumer_state,
    MainloopPipelineIntra& pipeline_intra, PipelineStateIntra& pipeline_intra_consumer_state,
    cute::tuple<FragmentC_1, FragmentC_2>& acc_intra,
    TensorStorage& shared_tensors) {
    
    static constexpr uint32_t tmem_base_ptr = 0; // reserved all tmem columns
    int thread_idx = threadIdx.x % cutlass::NumThreadsPerWarpGroup;
    using CopyAtomT2R = SM100_TMEM_LOAD_16dp256b16x;
    using CopyAtomR2T = SM100_TMEM_STORE_16dp128b16x;

    // require B&C
    auto pipeline_delta_token = pipeline_delta.consumer_try_wait(pipeline_delta_consumer_state);
    pipeline_delta.consumer_wait(pipeline_delta_consumer_state, pipeline_delta_token);
    // PreIntra2
    auto pipeline_intra_token = pipeline_intra.consumer_try_wait(pipeline_intra_consumer_state);
    pipeline_intra.consumer_wait(pipeline_intra_consumer_state, pipeline_intra_token);
    
    TiledMmaIntra2 tiled_mma_2;

    auto accumulator = get<0>(acc_intra);
    Tensor tQ = tiled_mma_2.make_fragment_A(shape(TmemLayoutQ{}));
    // Tensor tQ = tiled_mma_2.make_fragment_A(shape(TmemLayoutQ{}));
    tQ.data() = tmem_base_ptr + tmem_intra_2_A;

    auto tIntra = make_tensor(accumulator.data(), get<0>(accumulator.layout()));
    auto tiled_t2r = make_tmem_copy(CopyAtomT2R{}, tIntra);
    auto thr_t2r = tiled_t2r.get_slice(thread_idx);
    auto tTR_tQ = thr_t2r.partition_S(tIntra);
    auto tTR_sQ = thr_t2r.partition_D(make_tensor<ElementAcc>(make_shape(get<0>(TileShape{}), get<0>(TileShape{}))));
    auto tTR_rQ = make_tensor<ElementAcc>(shape(tTR_sQ));

    auto tiled_r2t = make_tmem_copy(CopyAtomR2T{}, tQ);
    auto thr_r2t = tiled_r2t.get_slice(thread_idx);
    auto tRT_rQ = make_tensor<Element>(shape(thr_r2t.partition_S(tQ)));
    auto tRT_tQ = thr_r2t.partition_D(tQ);
    auto tCompute = make_tensor<ElementAcc>(shape(tRT_rQ));

    auto ts0 = size<0>(TileShape{});
    Layout row_layout = make_layout(make_shape ( ts0,  ts0, Int<StagesInput>{}),
                                    make_stride(_0{}, _1{}, ts0));
    Layout col_layout = make_layout(make_shape ( ts0,  ts0, Int<StagesInput>{}),
                                    make_stride(_1{}, _0{}, ts0));
    Tensor coord_tensor = make_coord_tensor(make_identity_layout(make_shape(ts0, ts0)));

    Tensor sDelta   = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta.data()), row_layout));
    Tensor sDeltaA_Row = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta_a.data()), row_layout));
    Tensor sDeltaA_Col = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta_a.data()), col_layout));

    auto tQsDeltaA_Row = thr_t2r.partition_D(sDeltaA_Row)(_,_,_,pipeline_delta_consumer_state.index());
    auto tQsDeltaA_Col = thr_t2r.partition_D(sDeltaA_Col)(_,_,_,pipeline_delta_consumer_state.index());
    auto tQsDelta  = thr_t2r.partition_D(sDelta)(_,_,_,pipeline_delta_consumer_state.index());
    auto tCoord    = thr_t2r.partition_D(coord_tensor);

    auto tQrDeltaA_Row = make_tensor<ElementDA>(shape(tQsDeltaA_Row));
    auto tQrDeltaA_Col = make_tensor<ElementDA>(shape(tQsDeltaA_Col));
    auto tQrDelta  = make_tensor<Element>(shape(tQsDelta));

    auto tCrDeltaA_Row = make_tensor<ElementAcc>(shape(tQsDeltaA_Row));
    auto tCrDeltaA_Col = make_tensor<ElementAcc>(shape(tQsDeltaA_Col));
    auto tCrDelta  = make_tensor<ElementAcc>(shape(tQsDelta));

#if 0
    if (threadIdx.x % 128 == 0) {
      print("SmemLayoutQ:");print(SmemLayoutQ{});print("\n");
      print("row_layout:");print(row_layout);print("\n");
      print("col_layout:");print(col_layout);print("\n");
      print("tQ       : ");print(tQ);print("\n");
      print("accumulator: ");print(accumulator);print("\n");
      print("tTR_tQ   : ");print(tTR_tQ);print("\n");
      print("tTR_sQ   : ");print(tTR_sQ);print("\n");
      print("tTR_rQ   : ");print(tTR_rQ);print("\n");
      print("tRT_rQ   : ");print(tRT_rQ);print("\n");
      print("tRT_tQ   : ");print(tRT_tQ);print("\n");
    }
#endif

    copy(tiled_t2r, tTR_tQ, tTR_rQ);
    cutlass::arch::fence_view_async_tmem_load();

    copy(tQsDeltaA_Row, tQrDeltaA_Row);
    copy(tQsDeltaA_Col, tQrDeltaA_Col);
    copy(tQsDelta     , tQrDelta);

    // Data convert
    type_convert<Element, ElementAcc>(tQsDelta, tCrDelta);
    type_convert<ElementDA, ElementAcc>(tQrDeltaA_Row, tCrDeltaA_Row);
    type_convert<ElementDA, ElementAcc>(tQrDeltaA_Col, tCrDeltaA_Col);

    // SegSum
    #pragma unroll
    for (int ii = 0; ii < size(tTR_rQ); ++ii) {
      ElementAcc tmp(0);
      tmp = tQrDeltaA_Col(ii) - tCrDeltaA_Row(ii);
      tCompute(ii) = expf(tmp) * tCrDelta(ii) * tTR_rQ(ii);
    }
    #pragma unroll
    for (int ii = 0; ii < size(tTR_rQ); ++ii) {
      auto [m,n] = tCoord(ii);
      if (m < n) {
        tCompute(ii) = 0;
      }
    }

    type_convert<ElementAcc, Element>(tCompute, tRT_rQ);

    copy(tiled_r2t, tRT_rQ, tRT_tQ);
    cutlass::arch::fence_view_async_tmem_store();

    // release B&C
    pipeline_intra.consumer_release(pipeline_intra_consumer_state); 

    ++pipeline_intra_consumer_state;
  }

  template<
    class ElementSrc, class ElementDst,
    class TensorSrc, class TensorDst
  >
  CUTLASS_DEVICE
  auto type_convert(
    TensorSrc& tS,
    TensorDst& tD) {

    static constexpr int FragmentSize = 2;
    NumericArrayConverter<ElementDst, ElementSrc, FragmentSize> converter;

    auto tS_frg = recast<Array<ElementSrc, FragmentSize>>(tS);
    auto tD_frg = recast<Array<ElementDst, FragmentSize>>(tD);

    CUTLASS_PRAGMA_UNROLL
    for (int ii = 0; ii < size(tS_frg); ++ii) {
      tD_frg(ii) = converter(tS_frg(ii));
    }
  }
};


}  // namespace cutlass::ssd::collective
