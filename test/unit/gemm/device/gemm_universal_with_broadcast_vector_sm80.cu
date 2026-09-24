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
/*! \file
    \brief Tests the broadcast-vector convention of GemmUniversalWithBroadcast and
           GemmUniversalStreamkWithBroadcast for row-major and column-major outputs.

    The broadcast vector is indexed along the contiguous dimension of the output:
      - RowMajor output:    D(i, j) = alpha * AB(i, j) + beta * C(i, j) + V[j]   (V has N elements)
      - ColumnMajor output: D(i, j) = alpha * AB(i, j) + beta * C(i, j) + V[i]   (V has M elements)

    The column-major specializations are implemented by transposing the problem, so the
    underlying row-major kernel broadcasts V over its own columns, which are the rows of D.
*/

#include <iostream>
#include <vector>

#include "cutlass/cutlass.h"
#include "cutlass/gemm/device/gemm_universal_with_broadcast.h"
#include "cutlass/gemm/device/gemm_universal_streamk_with_broadcast.h"
#include "cutlass/gemm/threadblock/threadblock_swizzle_streamk.h"
#include "cutlass/util/device_memory.h"

#include "../../common/cutlass_unit_test.h"

////////////////////////////////////////////////////////////////////////////////

namespace {

template <typename Layout>
constexpr bool kIsColumnMajor = std::is_same_v<Layout, cutlass::layout::ColumnMajor>;

// Small integers keep every intermediate exactly representable in half precision,
// so the device result must match the reference bit-for-bit.
template <typename T>
void fill_integers(std::vector<T> &v, int seed, int range) {
  unsigned s = static_cast<unsigned>(seed) * 2654435761u + 1u;
  for (auto &x : v) {
    s = s * 1664525u + 1013904223u;
    x = T(float(int((s >> 16) % unsigned(2 * range + 1)) - range));
  }
}

template <typename Gemm, typename... ExtraArgs>
bool run_broadcast(
    cutlass::gemm::GemmUniversalMode mode, int m, int n, int k, int batch_count,
    ExtraArgs... extra_args) {

  using ElementA = typename Gemm::ElementA;
  using ElementB = typename Gemm::ElementB;
  using ElementC = typename Gemm::ElementC;
  using ElementCompute = typename Gemm::EpilogueOutputOp::ElementCompute;
  using ElementVector = typename Gemm::EpilogueOutputOp::ElementVector;
  using ElementT = typename Gemm::EpilogueOutputOp::ElementT;
  static_assert(std::is_same_v<typename Gemm::LayoutA, cutlass::layout::RowMajor>);
  static_assert(std::is_same_v<typename Gemm::LayoutB, cutlass::layout::ColumnMajor>);
  constexpr bool kColumnMajorOutput = kIsColumnMajor<typename Gemm::LayoutC>;

  int const vector_length = kColumnMajorOutput ? m : n;
  int64_t const lda = k, ldb = k;
  int64_t const ldc = kColumnMajorOutput ? m : n;

  auto offset_C = [&](int i, int j) { return kColumnMajorOutput ? i + j * ldc : i * ldc + j; };

  int64_t const batch_stride_A = int64_t(m) * k;
  int64_t const batch_stride_B = int64_t(k) * n;
  int64_t const batch_stride_C = int64_t(m) * n;
  int64_t const batch_stride_V = vector_length;

  std::vector<ElementA> host_A(batch_stride_A * batch_count);
  std::vector<ElementB> host_B(batch_stride_B * batch_count);
  std::vector<ElementC> host_C(batch_stride_C * batch_count);
  std::vector<ElementVector> host_V(batch_stride_V * batch_count);
  fill_integers(host_A, 1, 2);
  fill_integers(host_B, 2, 2);
  fill_integers(host_C, 3, 2);
  fill_integers(host_V, 4, 4);

  // Allocate the vector with exactly its documented length so that any read past it
  // is reported by compute-sanitizer.
  cutlass::DeviceAllocation<ElementA> A(host_A.size());
  cutlass::DeviceAllocation<ElementB> B(host_B.size());
  cutlass::DeviceAllocation<ElementC> C(host_C.size());
  cutlass::DeviceAllocation<ElementC> D(host_C.size());
  cutlass::DeviceAllocation<ElementT> T(host_C.size());
  cutlass::DeviceAllocation<ElementVector> V(host_V.size());
  A.copy_from_host(host_A.data());
  B.copy_from_host(host_B.data());
  C.copy_from_host(host_C.data());
  V.copy_from_host(host_V.data());

  ElementCompute const alpha = ElementCompute(1);
  ElementCompute const beta = ElementCompute(1);

  typename Gemm::Arguments args(
    mode,
    {m, n, k},
    batch_count,
    {alpha, beta},
    A.get(), B.get(), C.get(), D.get(),
    V.get(), T.get(),
    batch_stride_A, batch_stride_B, batch_stride_C, batch_stride_C,
    batch_stride_V, batch_stride_C,
    lda, ldb, ldc, ldc,
    /* ldr = */ 0,
    /* ldt = */ ldc,
    extra_args...);

  Gemm gemm_op;
  cutlass::Status status = gemm_op.can_implement(args);
  EXPECT_EQ(status, cutlass::Status::kSuccess) << cutlassGetStatusString(status);
  if (status != cutlass::Status::kSuccess) {
    return false;
  }

  cutlass::DeviceAllocation<uint8_t> workspace(Gemm::get_workspace_size(args));
  status = gemm_op.initialize(args, workspace.get());
  EXPECT_EQ(status, cutlass::Status::kSuccess) << cutlassGetStatusString(status);
  status = gemm_op();
  EXPECT_EQ(status, cutlass::Status::kSuccess) << cutlassGetStatusString(status);
  EXPECT_EQ(cudaDeviceSynchronize(), cudaSuccess);
  if (status != cutlass::Status::kSuccess) {
    return false;
  }

  std::vector<ElementC> host_D(host_C.size());
  std::vector<ElementT> host_T(host_C.size());
  D.copy_to_host(host_D.data());
  T.copy_to_host(host_T.data());

  int mismatches = 0;
  for (int l = 0; l < batch_count; ++l) {
    for (int i = 0; i < m; ++i) {
      for (int j = 0; j < n; ++j) {
        float acc = 0;
        for (int kk = 0; kk < k; ++kk) {
          acc += float(host_A[l * batch_stride_A + i * lda + kk]) *
                 float(host_B[l * batch_stride_B + j * ldb + kk]);
        }
        int64_t idx = l * batch_stride_C + offset_C(i, j);
        float v = float(host_V[l * batch_stride_V + (kColumnMajorOutput ? i : j)]);
        float expected = float(alpha) * acc + float(beta) * float(host_C[idx]) + v;
        if (float(host_D[idx]) != expected || float(host_T[idx]) != expected) {
          if (++mismatches <= 5) {
            std::cerr << "Mismatch at (l=" << l << ", i=" << i << ", j=" << j << "): D="
                      << float(host_D[idx]) << " T=" << float(host_T[idx])
                      << " expected=" << expected << "\n";
          }
        }
      }
    }
  }
  EXPECT_EQ(mismatches, 0) << "problem " << m << "x" << n << "x" << k << "x" << batch_count;
  return mismatches == 0;
}

using ElementAB = cutlass::half_t;
using ElementC = cutlass::half_t;
using ElementAccumulator = float;
using ThreadblockShape = cutlass::gemm::GemmShape<128, 128, 32>;
using WarpShape = cutlass::gemm::GemmShape<64, 64, 32>;
using InstructionShape = cutlass::gemm::GemmShape<16, 8, 16>;
using EpilogueOp = cutlass::epilogue::thread::LinearCombinationBiasElementwise<
  ElementC, ElementAccumulator, ElementAccumulator, ElementC, ElementC,
  128 / cutlass::sizeof_bits<ElementC>::value>;

template <typename LayoutC>
using GemmBroadcast = cutlass::gemm::device::GemmUniversalWithBroadcast<
  ElementAB, cutlass::layout::RowMajor, ElementAB, cutlass::layout::ColumnMajor,
  ElementC, LayoutC, ElementAccumulator,
  cutlass::arch::OpClassTensorOp, cutlass::arch::Sm80,
  ThreadblockShape, WarpShape, InstructionShape, EpilogueOp,
  cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>, 3>;

template <typename LayoutC>
using GemmStreamKBroadcast = cutlass::gemm::device::GemmUniversalStreamkWithBroadcast<
  ElementAB, cutlass::layout::RowMajor, ElementAB, cutlass::layout::ColumnMajor,
  ElementC, LayoutC, ElementAccumulator,
  cutlass::arch::OpClassTensorOp, cutlass::arch::Sm80,
  ThreadblockShape, WarpShape, InstructionShape, EpilogueOp,
  cutlass::gemm::threadblock::ThreadblockSwizzleStreamK, 3>;

} // namespace

////////////////////////////////////////////////////////////////////////////////

TEST(SM80_Device_GemmUniversalWithBroadcast_f16t_f16n_f16t_tensor_op_f32, vector_per_column) {
  using Gemm = GemmBroadcast<cutlass::layout::RowMajor>;
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 264, 136, 64, 1));
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 136, 264, 64, 1));
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kBatched, 264, 136, 64, 2));
}

TEST(SM80_Device_GemmUniversalWithBroadcast_f16t_f16n_f16n_tensor_op_f32, vector_per_row) {
  using Gemm = GemmBroadcast<cutlass::layout::ColumnMajor>;
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 264, 136, 64, 1));
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 136, 264, 64, 1));
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kBatched, 264, 136, 64, 2));
}

// Stream-K splits the K loop of the 6 output tiles below across many CTAs, which exercises
// the separate (fragment-wise) peer reduction of EpilogueStreamkWithBroadcast.
TEST(SM80_Device_GemmUniversalStreamkWithBroadcast_f16t_f16n_f16t_tensor_op_f32, vector_per_column) {
  using Gemm = GemmStreamKBroadcast<cutlass::layout::RowMajor>;
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 264, 136, 64, 1));
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 136, 264, 512, 1));
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 520, 392, 1024, 1));
  // avail_sms = 1: data-parallel schedule, no peer reduction
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 136, 264, 512, 1, 1));
}

TEST(SM80_Device_GemmUniversalStreamkWithBroadcast_f16t_f16n_f16n_tensor_op_f32, vector_per_row) {
  using Gemm = GemmStreamKBroadcast<cutlass::layout::ColumnMajor>;
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 264, 136, 64, 1));
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 136, 264, 512, 1));
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 520, 392, 1024, 1));
  // avail_sms = 1: data-parallel schedule, no peer reduction
  EXPECT_TRUE(run_broadcast<Gemm>(cutlass::gemm::GemmUniversalMode::kGemm, 136, 264, 512, 1, 1));
}

////////////////////////////////////////////////////////////////////////////////
