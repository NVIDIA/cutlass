/***************************************************************************************************
 * Copyright (c) 2017-2021, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Template for a double-buffered threadblock-scoped GEMM kernel.
*/

#pragma once

#include "cutlass/aligned_buffer.h"
#include "cutlass/arch/memory.h"
#include "cutlass/array.h"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/numeric_types.h"
#include "cutlass/arch/cache_operation.h"
#include "customized_transform.h"
#include "cutlass/numeric_conversion.h"
// #include "cutlass/gemm/threadblock/mma_base.h"
// #include "customized_mma_base.h"

#include "customized_regular_scale_bias_iterator.h"
#include "customized_scale_bias_iterator.h"
#include "customized_predicated_scale_bias_vector_access_iterator.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace threadblock {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// Size of the Gemm problem - concept: gemm::GemmShape<>
    typename Shape_,
    /// Element type of scale and bias vectors 
    typename ElementScaleBias_,
    /// Layout of scale and bias vectors
    typename LayoutScaleBias_,
    /// Policy describing tuning details (concept: MmaPolicy)
    typename Policy_,
    /// WarpIterator to load Scale or Bias vector from the shared memory
    typename WarpShape_,
    typename InstructionShape_,
    typename MmaCore_,
    /// Number of stages,
    int Stages,
    /// Used for partial specialization
    typename Enable = bool>
class MmaFpropFusionBase {
 public:
  ///< Size of the Gemm problem - concept: gemm::GemmShape<>
  using Shape = Shape_;

  ///< Element type of scale and bias vectors 
  using ElementScaleBias = ElementScaleBias_;

  /// Layout of scale and bias vectors
  using LayoutScaleBias = LayoutScaleBias_;

  ///< Policy describing tuning details
  using Policy = Policy_;

  ///< WarpIterator to load Scale or Bias vector from the shared memory

  using WarpShape = WarpShape_;
  using InstructionShape = InstructionShape_;
  using MmaCore = MmaCore_;

  using WarpMmaTensorOp = typename MmaCore::MmaTensorOp;
  using MmaPolicy = typename MmaCore::MmaPolicy;
  static int const kThreadCount = 32;

  using WarpIteratorScaleBias = cutlass::gemm::warp::WarpIteratorScaleBias<
      MatrixShape<WarpShape::kM, WarpShape::kK>, ElementScaleBias,
      LayoutScaleBias, MatrixShape<InstructionShape::kM, InstructionShape::kK>,
      typename WarpMmaTensorOp::IteratorA::Base::Policy, kThreadCount,
      MmaCore::WarpCount::kK>;

  //
  // Dependent types
  //

  /// Warp-level Mma
  using Operator = typename Policy::Operator;

  /// Shape describing the overall GEMM computed from shared memory
  /// by each warp.
  using WarpGemm = typename Policy::Operator::Shape;

  /// Shape describing the number of warps filling the CTA
  using WarpCount = cutlass::gemm::GemmShape<Shape::kM / WarpGemm::kM,
                                             Shape::kN / WarpGemm::kN,
                                             Shape::kK / WarpGemm::kK>;

  /// Number of warp-level GEMM oeprations
  static int const kWarpGemmIterations =
      (WarpGemm::kK / Operator::Policy::MmaShape::kK);

  /// Number of stages
  static int const kStages = Stages;

  /// Tensor reference to the A operand
  using TensorRefA = TensorRef<typename Operator::ElementA, typename Operator::LayoutA>;

  /// Tensor reference to the scale and bias vectors
  using TensorRefScaleBias = TensorRef<ElementScaleBias, LayoutScaleBias>;

  /// Tensor reference to the B operand
  using TensorRefB = TensorRef<typename Operator::ElementB, typename Operator::LayoutB>;

  //
  // Nested structs
  //

  /// Shared storage object needed by threadblock-scoped GEMM
  class SharedStorage {
   public:
    //
    // Type definitions
    //

    /// Shape of the A matrix operand in shared memory
    using ShapeA = MatrixShape<Shape::kM + Policy::SmemPaddingA::kRow,
                               Shape::kK * kStages +
                                   Policy::SmemPaddingA::kColumn>;

    /// Shape of the A scale and bias vectors in shared memory
    using ShapeScaleBias =
        MatrixShape<1 + Policy::SmemPaddingA::kRow,
                    2 * Shape::kK * kStages + Policy::SmemPaddingA::kColumn>;

    /// Shape of the B matrix operand in shared memory
    using ShapeB =
        MatrixShape<Shape::kK * kStages + Policy::SmemPaddingB::kRow,
                    Shape::kN + Policy::SmemPaddingB::kColumn>;

   public:
    //
    // Data members
    //

    /// Buffer for A operand
    AlignedBuffer<typename Operator::ElementA, ShapeA::kCount> operand_A;

    /// Buffer for B operand
    AlignedBuffer<typename Operator::ElementB, ShapeB::kCount> operand_B;

    /// Buffer for A operand Scale and Bias
    AlignedBuffer<ElementScaleBias, ShapeScaleBias::kCount> operand_A_scale_bias;

   public:

    //
    // Methods
    //

    /// Returns a layout object for the A matrix
    CUTLASS_DEVICE
    static typename Operator::LayoutA LayoutA() {
      return Operator::LayoutA::packed({ShapeA::kRow, ShapeA::kColumn});
    }

    /// Returns a layout object for the B matrix
    CUTLASS_HOST_DEVICE
    static typename Operator::LayoutB LayoutB() {
      return Operator::LayoutB::packed({ShapeB::kRow, ShapeB::kColumn});
    }

    /// Returns a layout object for the A scale and bias vectors
    CUTLASS_DEVICE
    static LayoutScaleBias LayoutScaleBias() {
      return LayoutScaleBias::packed(
          {ShapeScaleBias::kRow, ShapeScaleBias::kColumn});
    }

    /// Returns a TensorRef to the A operand
    CUTLASS_HOST_DEVICE
    TensorRefA operand_A_ref() {
      return TensorRefA{operand_A.data(), LayoutA()};
    }

    /// Returns a TensorRef to the B operand
    CUTLASS_HOST_DEVICE
    TensorRefB operand_B_ref() {
      return TensorRefB{operand_B.data(), LayoutB()};
    }

    /// Returns a TensorRef to the A operand Scale vector
    CUTLASS_HOST_DEVICE
    TensorRefScaleBias operand_A_scale_bias_ref() {
      return TensorRefScaleBias{operand_A_scale_bias.data(), LayoutScaleBias()};
    }
  };

 protected:

  //
  // Data members
  //

  /// Iterator to load a warp-scoped tile of A operand from shared memory
  typename Operator::IteratorA warp_tile_iterator_A_;

  /// Iterator to load a warp-scoped tile of A operand scale and bias vector
  /// from shared memory
  WarpIteratorScaleBias warp_tile_iterator_A_scale_bias_;

  /// Iterator to load a warp-scoped tile of B operand from shared memory
  typename Operator::IteratorB warp_tile_iterator_B_;

public:

  /// Construct from tensor references
  CUTLASS_DEVICE
  MmaFpropFusionBase(
      ///< Shared storage needed for internal use by threadblock-scoped GEMM
      SharedStorage &shared_storage,
      ///< ID within the threadblock
      int thread_idx,
      ///< ID of warp
      int warp_idx,
      ///< ID of each thread within a warp
      int lane_idx)
      : warp_tile_iterator_A_(shared_storage.operand_A_ref(), lane_idx),
        warp_tile_iterator_A_scale_bias_(
            shared_storage.operand_A_scale_bias_ref(), lane_idx),
        warp_tile_iterator_B_(shared_storage.operand_B_ref(), lane_idx) {}
};


/// Structure to compute the matrix product targeting CUDA cores and SIMT math
/// instructions.
template <
    /// Size of the Gemm problem - concept: gemm::GemmShape<>
    typename Shape_,
    /// Iterates over tiles of A operand in global memory
    //  (concept: ReadableTileIterator | ForwardTileIterator |
    //  MaskedTileIterator)
    typename IteratorA_,
    /// Iterates over tiles of A operand in shared memory
    /// (concept: WriteableTileIterator | RandomAccessTileIterator)
    typename SmemIteratorA_,
    /// Cache operation for operand A
    cutlass::arch::CacheOperation::Kind CacheOpA,
    /// Iterates over tiles of B operand in global memory
    //  (concept: ReadableTileIterator | ForwardTileIterator |
    //  MaskedTileIterator)
    typename IteratorB_,
    /// Iterates over tiles of B operand in shared memory
    /// (concept: WriteableTileIterator | RandomAccessTileIterator)
    typename SmemIteratorB_,
    /// Cache operation for operand B
    cutlass::arch::CacheOperation::Kind CacheOpB,
    /// Data type of accumulator matrix
    typename ElementC_,
    /// Data type of accumulator matrix
    typename LayoutC_,
    /// Policy describing tuning details (concept: MmaPolicy)
    typename Policy_,
    /// Number of stages,
    typename ThreadblockShape_,
    typename WarpShape_,
    typename InstructionShape_,
    typename MmaCore_,
    typename ElementScaleBias_,
    typename LayoutScaleBias_,
    int Stages,
    /// Use zfill or predicate for out-of-bound cp.async
    SharedMemoryClearOption SharedMemoryClear = SharedMemoryClearOption::kNone,
    /// Used for partial specialization
    typename Enable = bool>
class MyMmaMultistage : public MmaFpropFusionBase<Shape_, ElementScaleBias_,
                       LayoutScaleBias_, Policy_,
                       WarpShape_, InstructionShape_, MmaCore_, Stages> {

public:
  ///< Size of the Gemm problem - concept: gemm::GemmShape<>
  using Shape = Shape_;
  ///< Iterates over tiles of A operand in global memory
  using IteratorA = IteratorA_;
  ///< Iterates over tiles of B operand in global memory
  using IteratorB = IteratorB_;
  ///< Data type of accumulator matrix
  using ElementC = ElementC_;

  using ElementScaleBias = ElementScaleBias_;
  using LayoutScaleBias = LayoutScaleBias_;
  ///< Layout of accumulator matrix
  using LayoutC = LayoutC_;
  ///< Policy describing tuning details
  using Policy = Policy_;
  using ThreadblockShape = ThreadblockShape_;
  using WarpShape = WarpShape_;
  using InstructionShape = InstructionShape_;

  // using IteratorScaleBias = IteratorA;

  using IteratorScaleBias =
      cutlass::gemm::threadblock::PredicatedScaleBiasVectorAccessIterator<
          cutlass::MatrixShape<1, ThreadblockShape::kK>, ElementScaleBias,
          LayoutScaleBias>;

  // using WarpIteratorScaleBias = WarpIteratorScaleBias_;



  using SmemIteratorA = SmemIteratorA_;
  using SmemIteratorB = SmemIteratorB_;
  using SmemIteratorScaleBias =
      cutlass::gemm::threadblock::RegularScaleBiasVectorAccessIterator<
          cutlass::MatrixShape<1, ThreadblockShape::kK>, ElementScaleBias,
          LayoutScaleBias>;

  using MmaCore = MmaCore_;


  using WarpMmaTensorOp = typename MmaCore::MmaTensorOp;
  using MmaPolicy = typename MmaCore::MmaPolicy;
  static int const kThreadCount = 32;

  using WarpIteratorScaleBias = cutlass::gemm::warp::WarpIteratorScaleBias<
      MatrixShape<WarpShape::kM, WarpShape::kK>, ElementScaleBias,
      LayoutScaleBias, MatrixShape<InstructionShape::kM, InstructionShape::kK>,
      typename WarpMmaTensorOp::IteratorA::Base::Policy, kThreadCount,
      MmaCore::WarpCount::kK>;

  using Base = MmaFpropFusionBase<Shape, typename IteratorScaleBias::Element,
                         typename IteratorScaleBias::Layout, Policy,
                         WarpShape, InstructionShape, MmaCore, Stages>;

  static cutlass::arch::CacheOperation::Kind const kCacheOpA = CacheOpA;
  static cutlass::arch::CacheOperation::Kind const kCacheOpB = CacheOpB;
  static cutlass::arch::CacheOperation::Kind const kCacheOpScaleBias = CacheOpA;
  //
  // Dependent types
  //

  /// Fragment of accumulator tile
  using FragmentC = typename Policy::Operator::FragmentC;

  /// Warp-level Mma
  using Operator = typename Policy::Operator;

  /// Minimum architecture is Sm80 to support cp.async
  using ArchTag = arch::Sm80;
  
  /// Complex transform on A operand
  static ComplexTransform const kTransformA = Operator::kTransformA;

  /// Complex transform on B operand
  static ComplexTransform const kTransformB = Operator::kTransformB;

  /// Internal structure exposed for introspection.
  struct Detail {

    static_assert(Base::kWarpGemmIterations > 1,
                  "The pipelined structure requires at least two warp-level "
                  "GEMM operations.");

    /// Number of cp.async instructions to load one stage of operand A
    static int const AsyncCopyIterationsPerStageA =
        IteratorA::ThreadMap::Iterations::kCount;

    /// Number of cp.async instructions to load one stage of operand B
    static int const AsyncCopyIterationsPerStageB =
        IteratorB::ThreadMap::Iterations::kCount;

    /// Number of stages
    static int const kStages = Stages;

    /// Number of cp.async instructions to load on group of operand A
    static int const kAccessesPerGroupA =
        (AsyncCopyIterationsPerStageA + Base::kWarpGemmIterations - 1) / Base::kWarpGemmIterations;

    /// Number of cp.async instructions to load on group of operand B
    static int const kAccessesPerGroupB =
        (AsyncCopyIterationsPerStageB + Base::kWarpGemmIterations - 1) / Base::kWarpGemmIterations;
  };

 private:

  using WarpLoadedFragmentA = typename Operator::FragmentA;
  using WarpLoadedFragmentB = typename Operator::FragmentB;
  // using WarpTransformedFragmentA = typename Operator::TransformedFragmentA;
  using WarpTransformedFragmentB = typename Operator::TransformedFragmentB;
  using WarpLoadedFragmentScaleBias = typename WarpIteratorScaleBias::Fragment;
  using WarpTransformedFragmentA = Array<ElementScaleBias, WarpLoadedFragmentA::kElements>;

 private:

  //
  // Data members
  //

  /// Iterator to write threadblock-scoped tile of A operand to shared memory
  SmemIteratorA smem_iterator_A_;

  SmemIteratorScaleBias smem_iterator_A_scale_bias_;

  /// Iterator to write threadblock-scoped tile of B operand to shared memory
  SmemIteratorB smem_iterator_B_;

public:

  /// Construct from tensor references
  CUTLASS_DEVICE
  MyMmaMultistage(
      ///< Shared storage needed for internal use by threadblock-scoped GEMM
      typename Base::SharedStorage &shared_storage,
      ///< ID within the threadblock
      int thread_idx,
      ///< ID of warp
      int warp_idx,
      ///< ID of each thread within a warp
      int lane_idx
    ):
      Base(shared_storage, thread_idx, warp_idx, lane_idx),
      smem_iterator_A_(shared_storage.operand_A_ref(), thread_idx),
      smem_iterator_A_scale_bias_(shared_storage.operand_A_scale_bias_ref(), thread_idx),
      smem_iterator_B_(shared_storage.operand_B_ref(), thread_idx)
  {
    // Compute warp location within threadblock tile by mapping the warp_id to
    // three coordinates:
    //   _m: the warp's position within the threadblock along the M dimension
    //   _n: the warp's position within the threadblock along the N dimension
    //   _k: the warp's position within the threadblock along the K dimension

    int warp_idx_mn = warp_idx % (Base::WarpCount::kM * Base::WarpCount::kN);
    int warp_idx_k = warp_idx / (Base::WarpCount::kM * Base::WarpCount::kN);

    int warp_idx_m = warp_idx_mn % Base::WarpCount::kM;
    int warp_idx_n = warp_idx_mn / Base::WarpCount::kM;

    // Add per-warp offsets in units of warp-level tiles
    this->warp_tile_iterator_A_.add_tile_offset(
        {warp_idx_m, Base::kWarpGemmIterations * warp_idx_k});
    this->warp_tile_iterator_B_.add_tile_offset(
        {Base::kWarpGemmIterations * warp_idx_k, warp_idx_n});
  }

  CUTLASS_DEVICE
  void copy_tiles_and_advance(IteratorA &iterator_A,
                              IteratorScaleBias &iterator_A_scale_bias,
                              IteratorB &iterator_B,
                              int group_start_A = 0, int group_start_B = 0) {
    iterator_A.set_iteration_index(group_start_A *
                                   IteratorA::kAccessesPerVector);
    this->smem_iterator_A_.set_iteration_index(group_start_A);

    // Async Copy for operand A
    CUTLASS_PRAGMA_UNROLL
    for (int j = 0; j < Detail::kAccessesPerGroupA; ++j) {
      if (group_start_A + j < Detail::AsyncCopyIterationsPerStageA) {
        typename IteratorA::AccessType *dst_ptr =
            reinterpret_cast<typename IteratorA::AccessType *>(
                this->smem_iterator_A_.get());

        int const kSrcBytes = sizeof_bits<typename IteratorA::Element>::value *
                              IteratorA::ThreadMap::kElementsPerAccess /
                              IteratorA::kAccessesPerVector / 8;

        CUTLASS_PRAGMA_UNROLL
        for (int v = 0; v < IteratorA::kAccessesPerVector; ++v) {
          auto gmem_ptr = iterator_A.get();
          // if (iterator_A.valid()) {
          //   float dtmp[8];
          //   auto ptr = *(iterator_A.get());
          //   for (int kk = 0; kk < 8; kk++) {
          //     dtmp[kk] = static_cast<float>(ptr[kk]);
          //   }
          //   printf("tid = %d, bid = %d, group_start_A = %d, j = %d, A = {%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f}.\n", threadIdx.x, blockIdx.x, group_start_A, j, dtmp[0], dtmp[1], dtmp[2], dtmp[3], dtmp[4], dtmp[5], dtmp[6], dtmp[7]);
          // }
          
          {
            cutlass::arch::cp_async<kSrcBytes, kCacheOpA>(
                dst_ptr + v, gmem_ptr, iterator_A.valid());
          }

          ++iterator_A;
        }

        ++this->smem_iterator_A_;
      }
    }

    // Async Copy for operand A scale and bias vector.  Scale and bias vectors
    // are small.  One iteration is enough.
    if (group_start_A == 0) {
      typename IteratorScaleBias::AccessType *dst_ptr =
          reinterpret_cast<typename IteratorScaleBias::AccessType *>(
              this->smem_iterator_A_scale_bias_.get());

      int const kSrcBytes =
          sizeof_bits<typename IteratorScaleBias::Element>::value *
          IteratorScaleBias::kElementsPerAccess / 8;

      cutlass::arch::cp_async<kSrcBytes, kCacheOpScaleBias>(
          dst_ptr, iterator_A_scale_bias.get(), iterator_A_scale_bias.valid());
    }

    iterator_B.set_iteration_index(group_start_B *
                                   IteratorB::kAccessesPerVector);
    this->smem_iterator_B_.set_iteration_index(group_start_B);

    // Async Copy for operand B
    CUTLASS_PRAGMA_UNROLL
    for (int j = 0; j < Detail::kAccessesPerGroupB; ++j) {
      if (group_start_B + j < Detail::AsyncCopyIterationsPerStageB) {
        typename IteratorB::AccessType *dst_ptr =
            reinterpret_cast<typename IteratorB::AccessType *>(
                this->smem_iterator_B_.get());

        int const kSrcBytes = sizeof_bits<typename IteratorB::Element>::value *
                              IteratorB::ThreadMap::kElementsPerAccess /
                              IteratorB::kAccessesPerVector / 8;

        CUTLASS_PRAGMA_UNROLL
        for (int v = 0; v < IteratorB::kAccessesPerVector; ++v) {
          auto gmem_ptr = iterator_B.get();

          {
            cutlass::arch::cp_async<kSrcBytes, kCacheOpB>(
                dst_ptr + v, gmem_ptr, iterator_B.valid());
          }

          ++iterator_B;
        }
        ++this->smem_iterator_B_;
      }
    }
  }

  /// Perform a threadblock-scoped matrix multiply-accumulate
  CUTLASS_DEVICE
  void operator()(
      ///< problem size of GEMM
      int problem_size_k,
      int gemm_k_iterations,
      ElementScaleBias* gamma_vec,
      ElementScaleBias* beta_vec,
      float *mean_vec_ptr,
      float *mean_square_vec_ptr,
      ///< destination accumulator tile
      FragmentC &accum,
      ///< iterator over A operand in global memory
      IteratorA iterator_A,
      ///< iterator over B operand in global memory
      IteratorB iterator_B,
      ///< initial value of accumulator
      FragmentC const &src_accum) {
    using AccessType = Array<float, 8>;
    IteratorScaleBias iterator_A_scale_bias(problem_size_k, gamma_vec, beta_vec, threadIdx.x);

    AccessType mean_frag, mean_square_frag;
    int tid = threadIdx.x;
    int vector_offset = (tid % 64) / 32 * 64 + (tid % 32) / 4 + blockIdx.x * 128;
    float *mean_vec_local_ptr = mean_vec_ptr + vector_offset;
    float *mean_square_vec_local_ptr = mean_square_vec_ptr + vector_offset;

    CUTLASS_PRAGMA_UNROLL
    for (int idx = 0; idx < 8; idx++) {
      cutlass::arch::global_load<float, 
                      sizeof(float)
                      >(
              mean_frag[idx], mean_vec_local_ptr + 8 * idx, true);

      cutlass::arch::global_load<float, 
                      sizeof(float)
                      >(
              mean_square_frag[idx], mean_square_vec_local_ptr + 8 * idx, true);

      // mean_frag[idx] = *(mean_vec_local_ptr + 8 * idx);
      // mean_square_frag[idx] = *(mean_square_vec_local_ptr + 8 * idx);

    }

    //
    // Prologue
    //
    NumericArrayConverter<ElementScaleBias, ElementC, WarpLoadedFragmentA::kElements, FloatRoundStyle::round_to_nearest> ConverterSrc2Tgt;
    NumericArrayConverter<ElementC, ElementScaleBias, WarpLoadedFragmentA::kElements, FloatRoundStyle::round_to_nearest> ConverterTgt2Src;
    // Issue several complete stages
    CUTLASS_PRAGMA_UNROLL
    for (int stage = 0; stage < Base::kStages - 1;
         ++stage, --gemm_k_iterations) {

      iterator_A.clear_mask(gemm_k_iterations == 0);
      iterator_B.clear_mask(gemm_k_iterations == 0);

      iterator_A.set_iteration_index(0);
      this->smem_iterator_A_.set_iteration_index(0);

      // Async Copy for operand A
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < Detail::AsyncCopyIterationsPerStageA; ++j) {
        typename IteratorA::AccessType *dst_ptr =
            reinterpret_cast<typename IteratorA::AccessType *>(
                this->smem_iterator_A_.get());

        CUTLASS_PRAGMA_UNROLL
        for (int v = 0; v < IteratorA::kAccessesPerVector; ++v) {
          int const kSrcBytes =
              sizeof_bits<typename IteratorA::Element>::value *
              IteratorA::ThreadMap::kElementsPerAccess /
              IteratorA::kAccessesPerVector / 8;

          int src_bytes = (iterator_A.valid() ? kSrcBytes : 0);

          cutlass::arch::cp_async_zfill<kSrcBytes, kCacheOpA>(
              dst_ptr + v, iterator_A.get(), iterator_A.valid());

          ++iterator_A;
        }

        ++this->smem_iterator_A_;
      }

      // Async Copy for operand A scale and bias vectors.  Scale and bias
      // vectors are small.  One iteration is enough.
      {
        typename IteratorScaleBias::AccessType *dst_ptr =
            reinterpret_cast<typename IteratorScaleBias::AccessType *>(
                this->smem_iterator_A_scale_bias_.get());

        int const kSrcBytes =
            sizeof_bits<typename IteratorScaleBias::Element>::value *
            IteratorScaleBias::kElementsPerAccess / 8;

        cutlass::arch::cp_async<kSrcBytes, kCacheOpScaleBias>(
            dst_ptr, iterator_A_scale_bias.get(), iterator_A_scale_bias.valid());

        


        // if (iterator_A_scale_bias.valid()) 
        // {
        //     float tt[8];
        //     auto ptr = iterator_A_scale_bias.get();

        //     for (int kk = 0; kk < 8; kk++) {
        //       tt[kk] = static_cast<float>(ptr[0][kk]);
        //     }

        //     printf("tid = %d, gamma = {%5.2f,%5.2f,%5.2f,%5.2f | %5.2f,%5.2f,%5.2f,%5.2f}.\n",\
        //     threadIdx.x, tt[0], tt[1], tt[2], tt[3], tt[4], tt[5], tt[6], tt[7]);
        // }


      }


      iterator_B.set_iteration_index(0);
      this->smem_iterator_B_.set_iteration_index(0);

      // Async Copy for operand B
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < Detail::AsyncCopyIterationsPerStageB; ++j) {
        typename IteratorB::AccessType *dst_ptr =
            reinterpret_cast<typename IteratorB::AccessType *>(
                this->smem_iterator_B_.get());

        CUTLASS_PRAGMA_UNROLL
        for (int v = 0; v < IteratorB::kAccessesPerVector; ++v) {
          int const kSrcBytes =
              sizeof_bits<typename IteratorB::Element>::value *
              IteratorB::ThreadMap::kElementsPerAccess /
              IteratorB::kAccessesPerVector / 8;

          cutlass::arch::cp_async_zfill<kSrcBytes, kCacheOpB>(
              dst_ptr + v, iterator_B.get(), iterator_B.valid());

          ++iterator_B;
        }

        ++this->smem_iterator_B_;
      }

      // Move to the next stage
      iterator_A.add_tile_offset({0, 1});
      iterator_A_scale_bias.add_tile_offset(1);
      iterator_B.add_tile_offset({1, 0});

      this->smem_iterator_A_.add_tile_offset({0, 1});
      this->smem_iterator_A_scale_bias_.add_tile_offset({0, 1});
      this->smem_iterator_B_.add_tile_offset({1, 0});

      // Defines the boundary of a stage of cp.async.
      cutlass::arch::cp_async_fence();
    }

    // Perform accumulation in the 'd' output operand
    accum = src_accum;

    //
    // Clear the remaining tiles of SMEM. This is a functional requirement for some kernels
    // so that all accumulator elements outside the GEMM footprint are zero.
    //


    // Waits until kStages-2 stages have committed.
    cutlass::arch::cp_async_wait<Base::kStages - 2>();
    __syncthreads();

    // float tmp[32];
    // float bias_tmp[8];
    // float mean_vec_tmp[8];

    int tid_base = (threadIdx.x % 4) * 2;

    // Pair of fragments used to overlap shared memory loads and math
    // instructions
    WarpLoadedFragmentA warp_loaded_frag_A[2];
    WarpLoadedFragmentB warp_loaded_frag_B[2];
    WarpLoadedFragmentScaleBias warp_loaded_frag_A_scale_bias[2];

    // WarpTransformedFragmentA warp_transformed_frag_A[2];
    // WarpTransformedFragmentB warp_transformed_frag_B[2];

    // printf("kCount = %d, perstage = %d, group = %d, stages = %d, perVec = %d, len = %d.\n", IteratorA::ThreadMap::Iterations::kCount, Detail::AsyncCopyIterationsPerStageA, Detail::kAccessesPerGroupA, Base::kStages, IteratorA::kAccessesPerVector, WarpLoadedFragmentScaleBias::kElements);

    Operator warp_mma;

    cutlass::gemm::warp::GemmScaleBiasTransform<WarpLoadedFragmentA,
                                            WarpLoadedFragmentScaleBias,
                                            AccessType>
        elementwise_transform;

    this->warp_tile_iterator_A_.set_kgroup_index(0);
    this->warp_tile_iterator_A_scale_bias_.set_kgroup_index(0);
    this->warp_tile_iterator_B_.set_kgroup_index(0);

    this->warp_tile_iterator_A_.load(warp_loaded_frag_A[0]);
    this->warp_tile_iterator_A_scale_bias_.load(
        warp_loaded_frag_A_scale_bias[0]);
    this->warp_tile_iterator_B_.load(warp_loaded_frag_B[0]);

    
    ++this->warp_tile_iterator_A_;
    ++this->warp_tile_iterator_A_scale_bias_;
    ++this->warp_tile_iterator_B_;

    iterator_A.clear_mask(gemm_k_iterations == 0);
    iterator_B.clear_mask(gemm_k_iterations == 0);

    int smem_write_stage_idx = Base::kStages - 1;
    int smem_read_stage_idx = 0;

    // warp_mma.transform(warp_transformed_frag_A[0], warp_transformed_frag_B[0],
    //                    warp_loaded_frag_A[0], warp_loaded_frag_B[0]);

    // warp_transformed_frag_A[0] = ConverterSrc2Tgt(warp_loaded_frag_A[0]);

    elementwise_transform(warp_loaded_frag_A[0],
                         warp_loaded_frag_A_scale_bias[0],
                         mean_frag,
                         mean_square_frag);

    // warp_loaded_frag_A[0] = ConverterTgt2Src(warp_transformed_frag_A[0]);

    // tf32x3 kernels use staging accumulation. warp_mma uses a temporary
    // accumulator and this temporary accumulator is added to the final
    // accumulator once in every mainloop iteration.
    plus<FragmentC> plus_accum;

    FragmentC tmp_accum;

    if (platform::is_same<typename Operator::MathOperator,
                          arch::OpMultiplyAddFastF32>::value
      || platform::is_same<typename Operator::MathOperator,
                           arch::OpMultiplyAddComplexFastF32>::value) {

      tmp_accum.clear();
    }

    //
    // Mainloop
    //

    CUTLASS_GEMM_LOOP
    for (; gemm_k_iterations > (-Base::kStages + 1);) {
      //
      // Loop over GEMM K dimension
      //

      // Computes a warp-level GEMM on data held in shared memory
      // Each "warp_mma_k" refers to a warp-level matrix multiply-accumulate
      CUTLASS_PRAGMA_UNROLL
      for (int warp_mma_k = 0; warp_mma_k < Base::kWarpGemmIterations;
           ++warp_mma_k) {

        // Load warp-level tiles from shared memory, wrapping to k offset if
        // this is the last group as the case may be.

        this->warp_tile_iterator_A_.set_kgroup_index((warp_mma_k + 1) % Base::kWarpGemmIterations);
        this->warp_tile_iterator_A_scale_bias_.set_kgroup_index(
            (warp_mma_k + 1) % Base::kWarpGemmIterations);
        this->warp_tile_iterator_B_.set_kgroup_index((warp_mma_k + 1) % Base::kWarpGemmIterations);


        this->warp_tile_iterator_A_.load(warp_loaded_frag_A[(warp_mma_k + 1) % 2]);
        this->warp_tile_iterator_A_scale_bias_.load(
            warp_loaded_frag_A_scale_bias[(warp_mma_k + 1) % 2]);
        this->warp_tile_iterator_B_.load(warp_loaded_frag_B[(warp_mma_k + 1) % 2]);

        ++this->warp_tile_iterator_A_;
        ++this->warp_tile_iterator_A_scale_bias_;
        ++this->warp_tile_iterator_B_;



        if (warp_mma_k > 0){
          // warp_mma.transform(warp_transformed_frag_A[warp_mma_k % 2],
          //                    warp_transformed_frag_B[warp_mma_k % 2],
          //                    warp_loaded_frag_A[warp_mma_k % 2],
          //                    warp_loaded_frag_B[warp_mma_k % 2]);

          // warp_transformed_frag_A[warp_mma_k % 2] = ConverterSrc2Tgt(warp_loaded_frag_A[warp_mma_k % 2]);
        
          elementwise_transform(
              warp_loaded_frag_A[warp_mma_k % 2],
              warp_loaded_frag_A_scale_bias[warp_mma_k % 2],
                         mean_frag,
                         mean_square_frag);
          
          // warp_loaded_frag_A[warp_mma_k % 2] = ConverterTgt2Src(warp_transformed_frag_A[warp_mma_k % 2]);
        }

        // for (int kk = 0; kk < 32; kk++) {
        //     tmp[kk] = static_cast<float>(warp_loaded_frag_A[warp_mma_k % 2][kk]);
        //     // if (tmp[kk] > 65536. || tmp[kk] < (float)0.) {
        //     //     tmp[kk] = 0.;
        //     // }
        // }

        // for (int kk = 0; kk < 8; kk++) {
        //   bias_tmp[kk] = static_cast<float>(warp_loaded_frag_A_scale_bias[warp_mma_k % 2][kk]);
        // }

        // for (int kk = 0; kk < 8; kk++) {
        //   mean_vec_tmp[kk] = static_cast<float>(mean_frag[kk]);
        // }

        // if (tmp[3] > 0.1 && warp_mma_k == 0) 
        // {
        //     printf("tid = %d, bid = {%d,%d}, gemm_k_iterations = %d, warp_mma_k = %d, mean = {%5.2f,%5.2f,%5.2f,%5.2f | %5.2f,%5.2f,%5.2f,%5.2f}, data = {%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f}, {%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f}, {%5.2f,%5.2f,%5.2f,%5.2f}.\n",\
        //     threadIdx.x, blockIdx.x, blockIdx.y, gemm_k_iterations, warp_mma_k, mean_vec_tmp[0], mean_vec_tmp[1], mean_vec_tmp[2], mean_vec_tmp[3], mean_vec_tmp[4], mean_vec_tmp[5], mean_vec_tmp[6], mean_vec_tmp[7], \
        //     tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7], 
        //     tmp[8], tmp[9], tmp[10], tmp[11], tmp[12], tmp[13], tmp[14], tmp[15], 
        //     tmp[16], tmp[17], tmp[18], tmp[19]);
        // }

        if (platform::is_same<typename Operator::MathOperator,
                              arch::OpMultiplyAddFastF32>::value
          || platform::is_same<typename Operator::MathOperator,
                               arch::OpMultiplyAddComplexFastF32>::value) {

          warp_mma(
            tmp_accum, 
            warp_loaded_frag_A[warp_mma_k % 2],
            warp_loaded_frag_B[warp_mma_k % 2], 
            tmp_accum
          );

          if (warp_mma_k == 0) {
            accum = plus_accum(accum, tmp_accum);
            tmp_accum.clear();
          }
        } else {
          warp_mma(
            accum, 
            warp_loaded_frag_A[warp_mma_k % 2],
            warp_loaded_frag_B[warp_mma_k % 2], 
            accum
          );
        }

        // Issue global->shared copies for the this stage
        if (warp_mma_k < Base::kWarpGemmIterations - 1) {
          int group_start_iteration_A, group_start_iteration_B;

          group_start_iteration_A = warp_mma_k * Detail::kAccessesPerGroupA;
          group_start_iteration_B = warp_mma_k * Detail::kAccessesPerGroupB;

          copy_tiles_and_advance(iterator_A, iterator_A_scale_bias, iterator_B,
                               group_start_iteration_A,
                               group_start_iteration_B);
        }

        if (warp_mma_k + 2 == Base::kWarpGemmIterations) {
          int group_start_iteration_A, group_start_iteration_B;
          group_start_iteration_A =
              (warp_mma_k + 1) * Detail::kAccessesPerGroupA;
          group_start_iteration_B =
              (warp_mma_k + 1) * Detail::kAccessesPerGroupB;

          copy_tiles_and_advance(iterator_A, iterator_A_scale_bias, iterator_B,
                               group_start_iteration_A,
                               group_start_iteration_B);

          // Inserts a memory fence between stages of cp.async instructions.
          cutlass::arch::cp_async_fence();

          // Waits until kStages-2 stages have committed.
          arch::cp_async_wait<Base::kStages - 2>();
          __syncthreads();

          // Move to the next stage
          iterator_A.add_tile_offset({0, 1});
          iterator_A_scale_bias.add_tile_offset(1);
          iterator_B.add_tile_offset({1, 0});

          this->smem_iterator_A_.add_tile_offset({0, 1});
          this->smem_iterator_A_scale_bias_.add_tile_offset({0, 1});
          this->smem_iterator_B_.add_tile_offset({1, 0});

          // Add negative offsets to return iterators to the 'start' of the
          // circular buffer in shared memory
          if (smem_write_stage_idx == (Base::kStages - 1)) {
            this->smem_iterator_A_.add_tile_offset({0, -Base::kStages});
            this->smem_iterator_A_scale_bias_.add_tile_offset(
                {0, -Base::kStages});
            this->smem_iterator_B_.add_tile_offset({-Base::kStages, 0});
            smem_write_stage_idx = 0;
          } else {
            ++smem_write_stage_idx;
          }

          if (smem_read_stage_idx == (Base::kStages - 1)) {
            this->warp_tile_iterator_A_.add_tile_offset(
                {0, -Base::kStages * Policy::kPartitionsK *
                        Base::kWarpGemmIterations});
            this->warp_tile_iterator_A_scale_bias_.add_tile_offset(
                {0, -Base::kStages * Policy::kPartitionsK *
                        Base::kWarpGemmIterations});
            this->warp_tile_iterator_B_.add_tile_offset(
                {-Base::kStages * Policy::kPartitionsK *
                     Base::kWarpGemmIterations,
                 0});
            smem_read_stage_idx = 0;
          } else {
            ++smem_read_stage_idx;
          }

          --gemm_k_iterations;
          iterator_A.clear_mask(gemm_k_iterations == 0);
          iterator_B.clear_mask(gemm_k_iterations == 0);
        }

        // Do any conversions feeding the first stage at the end of the loop so
        // we can start right away on mma instructions
        if (warp_mma_k + 1 == Base::kWarpGemmIterations) {
          // warp_mma.transform(warp_transformed_frag_A[(warp_mma_k + 1) % 2],
          //                    warp_transformed_frag_B[(warp_mma_k + 1) % 2],
          //                    warp_loaded_frag_A[(warp_mma_k + 1) % 2],
          //                    warp_loaded_frag_B[(warp_mma_k + 1) % 2]);

          // warp_transformed_frag_A[(warp_mma_k + 1) % 2] = ConverterSrc2Tgt(warp_loaded_frag_A[(warp_mma_k + 1) % 2]);

          elementwise_transform(
              warp_loaded_frag_A[(warp_mma_k + 1) % 2],
              warp_loaded_frag_A_scale_bias[(warp_mma_k + 1) % 2],
                         mean_frag,
                         mean_square_frag);

          // warp_loaded_frag_A[(warp_mma_k + 1) % 2] = ConverterTgt2Src(warp_transformed_frag_A[(warp_mma_k + 1) % 2]);
        
        }
      }//warp-k

    }//outer

    if (platform::is_same<typename Operator::MathOperator,
                          arch::OpMultiplyAddFastF32>::value
      || platform::is_same<typename Operator::MathOperator,
                           arch::OpMultiplyAddComplexFastF32>::value) {
      accum = plus_accum(accum, tmp_accum); 
    }


  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace threadblock
}  // namespace gemm
}  // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
