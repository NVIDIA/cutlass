/***************************************************************************************************
 * Copyright (c) 2017 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/fast_math.h"
#include "cutlass/matrix_coord.h"
#include "cutlass/complex.h"
#include "cutlass/tensor_ref.h"

#include "cutlass/arch/memory.h"
#include "cutlass/arch/cache_operation.h"

#include "cutlass/gemm/gemm.h"
#include "cutlass/layout/matrix.h"

#include "cutlass/numeric_conversion.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace kernel {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
    typename ElementA_,             /// matrix
    typename LayoutA_,
    typename ElementB_,             /// vector
    typename ElementC_,
    typename ElementAccumulator_,
    int kElementsPerAccess_,
    typename EpilogueOutputOp_
>
struct GemvStridedBatched {
public:

  using ElementA = ElementA_;
  using LayoutA = layout::RowMajor;
  using TensorRefA = TensorRef<ElementA, LayoutA>;

  static_assert(std::is_same<LayoutA, LayoutA_>::value,
                "Only supported for row-major A matrix");

  using ElementB = ElementB_;
  using ElementC = ElementC_;

  using ElementAccumulator = ElementAccumulator_;
  using EpilogueOutputOp = EpilogueOutputOp_;

  static ComplexTransform const kTransformA = ComplexTransform::kNone;
  static ComplexTransform const kTransformB = ComplexTransform::kNone;

  static FloatRoundStyle const Round = cutlass::FloatRoundStyle::round_to_nearest;

  // number of return elements in a global access
  static int const kElementsPerAccess = kElementsPerAccess_;
  
  using FragmentA = Array<ElementA, kElementsPerAccess>;
  using FragmentB = Array<ElementB, kElementsPerAccess>;
  using FragmentCompute = Array<ElementAccumulator, kElementsPerAccess>;

  // thread block shape (kThreadCount, mThreadCount)
  static int const kThreadCount = std::min(static_cast<int>(128 / (kElementsPerAccess * sizeof(ElementA))), 16);
  static int const mThreadCount = 128 / kThreadCount;

  // rolling tile shape
  static int const kTileA = kThreadCount * kElementsPerAccess;
  static int const mTileA = mThreadCount * 8;

  //
  // Structures
  //

  /// Argument structure
  struct Arguments
  {
    MatrixCoord problem_size;
    int32_t batch_count;
    typename EpilogueOutputOp::Params output_op;

    TensorRefA ref_A;

    ElementB const *ptr_B;
    ElementC const *ptr_C;
    ElementC *ptr_D;

    int64_t batch_stride_A;
    int64_t batch_stride_B;
    int64_t batch_stride_C;
    int64_t batch_stride_D;

    //
    // Methods
    //

    Arguments() : batch_count(0) {}

    Arguments(
        MatrixCoord problem_size,
        int32_t batch_count,

        typename EpilogueOutputOp::Params output_op,
        TensorRefA ref_A,
        void const *ptr_B,
        void const *ptr_C,
        void *ptr_D,

        int64_t batch_stride_A,
        int64_t batch_stride_B,
        int64_t batch_stride_C,
        int64_t batch_stride_D) : problem_size(problem_size),
                                  batch_count(batch_count),
                                  output_op(output_op),
                                  ref_A(ref_A),
                                  ptr_B(static_cast<ElementB const *>(ptr_B)),
                                  ptr_C(static_cast<ElementC const *>(ptr_C)),
                                  ptr_D(static_cast<ElementC *>(ptr_D)),

                                  batch_stride_A(batch_stride_A),
                                  batch_stride_B(batch_stride_B),
                                  batch_stride_C(batch_stride_C),
                                  batch_stride_D(batch_stride_D)
    {
    }

    Arguments(
        MatrixCoord problem_size,
        typename EpilogueOutputOp::Params output_op,
        TensorRefA ref_A,
        void const *ptr_B,
        void const *ptr_C,
        void *ptr_D) : Arguments(problem_size,
                                 1,
                                 1,
                                 output_op,
                                 ref_A,
                                 ptr_B,
                                 ptr_C,
                                 ptr_D,
                                 1,
                                 1,
                                 1,
                                 1)
    {
    }

    Status update(Arguments const &args)
    {
      problem_size = args.problem_size;
      batch_count = args.batch_count;
      output_op = args.output_op;
      ref_A = ref_A;
      ptr_B = args.ptr_B;
      ptr_C = args.ptr_C;
      ptr_D = args.ptr_D;
      batch_stride_A = args.batch_stride_A;
      batch_stride_B = args.batch_stride_B;
      batch_stride_C = args.batch_stride_C;
      batch_stride_D = args.batch_stride_D;

      return Status::kSuccess;
    }
  };

  using Params = Arguments;

  /// Shared memory storage structure
  union SharedStorage
  {
  };

public:
  //
  // Methods
  //

  CUTLASS_DEVICE
  GemvStridedBatched() {}

  /// Determines whether kernel satisfies alignment
  static Status can_implement(cutlass::MatrixCoord const &problem_size)
  {
    if (problem_size.column() % kElementsPerAccess != 0)
      return Status::kErrorMisalignedOperand;
    return Status::kSuccess;
  }

  static Status can_implement(Arguments const &args)
  {
    return can_implement(args.problem_size);
  }

  /// Executes one GEMV
  CUTLASS_DEVICE
  void operator()(Params const &params, SharedStorage &shared_storage)
  {
    // Loop over batch indices
    for (int batch_idx = blockIdx.z; batch_idx < params.batch_count; batch_idx += gridDim.z)
    {
      int k_col_id = threadIdx.x;
      int m_row_id = threadIdx.y;

      // problem_size (row = m, column = k)
      // matrix A (batch, m, k)
      // vector B (batch, 1, k)
      // vector C (batch, m, 1)
      // vector D (batch, m, 1)

      // move in the batch dimension
      ElementA const *ptr_A = params.ref_A.data() + batch_idx * params.batch_stride_A;
      ElementB const *ptr_B = params.ptr_B + batch_idx * params.batch_stride_B;

      ElementC const *ptr_C = params.ptr_C + batch_idx * params.batch_stride_C;
      ElementC *ptr_D = params.ptr_D + batch_idx * params.batch_stride_D;

      // move in the k dimension
      ptr_A += k_col_id * kElementsPerAccess;
      ptr_B += k_col_id * kElementsPerAccess;

      // move in the m dimension
      ptr_A += m_row_id * params.problem_size.column();
      ptr_C += m_row_id;
      ptr_D += m_row_id;

      NumericArrayConverter<ElementAccumulator, ElementA, kElementsPerAccess, Round> srcA_converter;
      NumericArrayConverter<ElementAccumulator, ElementB, kElementsPerAccess, Round> srcB_converter;

      for (; m_row_id < params.problem_size.row(); m_row_id += mTileA)
      {
        ElementAccumulator accum[mTileA / mThreadCount] = {0.f};

        FragmentB fragB;
        FragmentA fragA[mTileA / mThreadCount];

        int mElemCountPerTile = min(mTileA / mThreadCount, (params.problem_size.row() - m_row_id - 1) / mThreadCount + 1);

        int kUnroll = 0;

        for (; kUnroll < params.problem_size.column() / kTileA * kTileA; kUnroll += kTileA)
        {
          for (int m = 0; m < mElemCountPerTile; m++)
          {
            // fetch from matrix A
            arch::global_load<FragmentA,
                              sizeof(FragmentA),
                              arch::CacheOperation::LastUse>(fragA[m], (ptr_A + kUnroll + m * mThreadCount * params.problem_size.column()), true);
          }

          // fetch from vector B
          arch::global_load<FragmentB,
                            sizeof(FragmentB),
                            arch::CacheOperation::Always>(fragB, (ptr_B + kUnroll), true);

          for (int m = 0; m < mElemCountPerTile; m++)
          {
            FragmentCompute fragB_Compute = srcB_converter(fragB);
            FragmentCompute fragA_Compute = srcA_converter(fragA[m]);

            // Math
            CUTLASS_PRAGMA_UNROLL
            for (int e = 0; e < kElementsPerAccess; e++)
            {
              accum[m] += fragA_Compute.at(e) * fragB_Compute.at(e);
            }
          }
        }

        // calculate the rest of K elements
        // each thread fetch 1 element each time
        for (int k = kUnroll + k_col_id; k < params.problem_size.column(); k += kThreadCount)
        {
          ElementB b = *(ptr_B - k_col_id * kElementsPerAccess + k);
          for (int m = 0; m < mElemCountPerTile; m++)
          {
            ElementA a = *(ptr_A - k_col_id * kElementsPerAccess + k + m * mThreadCount * params.problem_size.column());
            accum[m] += ElementAccumulator(a) * ElementAccumulator(b);
          }
        }

        EpilogueOutputOp output_op(params.output_op);
        typename EpilogueOutputOp::FragmentOutput source_fragment[mTileA / mThreadCount];

        // prefetch from source matrix C
        if (output_op.is_source_needed())
        {
          for (int m = 0; m < mElemCountPerTile; m++)
          {
            source_fragment[m][0] = *(ptr_C + m * mThreadCount);
          }
        }

        typename EpilogueOutputOp::FragmentAccumulator accum_fragment;
        typename EpilogueOutputOp::FragmentOutput output_fragment;

        for (int m = 0; m < mElemCountPerTile; m++)
        {
          for (int mask = (kThreadCount >> 1); mask > 0; mask >>= 1)
          {
            accum[m] += __shfl_xor_sync(0xFFFFFFFF, accum[m], mask, 32);
          }

          if (k_col_id == 0)
          {
            accum_fragment[0] = accum[m];

            if (output_op.is_source_needed())
            {
              output_fragment = output_op(accum_fragment, source_fragment[m]);
            }
            else
            {
              output_fragment = output_op(accum_fragment);
            }

            *(ptr_D + m * mThreadCount) = output_fragment[0];
          }
        }

        ptr_A += mTileA * params.problem_size.column();
        ptr_C += mTileA;
        ptr_D += mTileA;
      }
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace kernel
} // namespace gemm
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
