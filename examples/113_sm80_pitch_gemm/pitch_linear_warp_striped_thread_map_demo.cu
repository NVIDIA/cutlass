/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 **************************************************************************************************/

#include <cmath>
#include <iomanip>
#include <iostream>
#include <set>
#include <vector>

#include "cutlass/gemm/device/gemm.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm80.h"

#include "helper.h"

using ElementA = double;
using ElementB = double;
using ElementC = double;
using ElementAccumulator = double;

using LayoutA = cutlass::layout::ColumnMajor;
using LayoutB = cutlass::layout::RowMajor;
using LayoutC = cutlass::layout::RowMajor;

using OperatorClass = cutlass::arch::OpClassTensorOp;
using ArchTag = cutlass::arch::Sm80;

using ShapeMMAThreadBlock = cutlass::gemm::GemmShape<128, 128, 8>;
using ShapeMMAWarp = cutlass::gemm::GemmShape<32, 32, 8>;
using ShapeMMAOp = cutlass::gemm::GemmShape<8, 8, 4>;
using SwizzleThreadBlock = cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>;
using EpilogueOp = cutlass::epilogue::thread::LinearCombination<
    ElementC, 1, ElementAccumulator, ElementAccumulator>;
constexpr int NumStages = 3;

using CutlassGemm = cutlass::gemm::device::Gemm<
    ElementA,
    LayoutA,
    ElementB,
    LayoutB,
    ElementC,
    LayoutC,
    ElementAccumulator,
    OperatorClass,
    ArchTag,
    ShapeMMAThreadBlock,
    ShapeMMAWarp,
    ShapeMMAOp,
    EpilogueOp,
    SwizzleThreadBlock,
    NumStages>;

using MmaCore = cutlass::gemm::threadblock::DefaultMmaCore<
    ShapeMMAThreadBlock,
    ShapeMMAWarp,
    ShapeMMAOp,
    ElementA,
    LayoutA,
    ElementB,
    LayoutB,
    ElementAccumulator,
    LayoutC,
    OperatorClass,
    NumStages,
    cutlass::arch::OpMultiplyAdd>;

template <typename ThreadMap>
void print_thread_map_offsets(char const* name) {
  std::cout << "\n" << name << "\n";
  std::cout << "Threads                = " << ThreadMap::kThreads << "\n";
  std::cout << "Shape                  = (" << ThreadMap::Shape::kContiguous << ", "
            << ThreadMap::Shape::kStrided << ")\n";
  std::cout << "ShapeInAccesses        = (" << ThreadMap::Detail::ShapeInAccesses::kContiguous << ", "
            << ThreadMap::Detail::ShapeInAccesses::kStrided << ")\n";
  std::cout << "WarpThreadArrangement  = (" << ThreadMap::Detail::WarpThreadArrangement::kContiguous
            << ", " << ThreadMap::Detail::WarpThreadArrangement::kStrided << ")\n";
  std::cout << "WarpAccessIterations   = ("
            << ThreadMap::Detail::WarpAccessIterations::kContiguous << ", "
            << ThreadMap::Detail::WarpAccessIterations::kStrided << ")\n";
  std::cout << "WarpArrangement        = (" << ThreadMap::Detail::kWarpsContiguous
            << ", " << ThreadMap::Detail::kWarpsStrided << ")\n";
  std::cout << "Iterations             = (" << ThreadMap::Iterations::kContiguous
            << ", " << ThreadMap::Iterations::kStrided << ")\n";
  std::cout << "Delta                  = (" << ThreadMap::Delta::kContiguous
            << ", " << ThreadMap::Delta::kStrided << ")\n";

  std::set<int> active_warps;
  for (int thread_id = 0; thread_id < ThreadMap::kThreads; ++thread_id) {
    int warp_id = thread_id / 32;
    auto coord = ThreadMap::initial_offset(thread_id);
    bool in_bounds = coord.contiguous() < ThreadMap::Shape::kContiguous &&
                     coord.strided() < ThreadMap::Shape::kStrided;
    if (in_bounds) {
      active_warps.insert(warp_id);
    }
    std::cout << "thread " << std::setw(3) << thread_id
              << "  warp " << std::setw(2) << warp_id
              << "  coord=(" << std::setw(3) << coord.contiguous() << ", "
              << std::setw(2) << coord.strided() << ")"
              << "  " << (in_bounds ? "in-bounds" : "out-of-bounds") << "\n";
  }

  std::cout << "active warps:";
  for (int warp_id : active_warps) {
    std::cout << " " << warp_id;
  }
  std::cout << "\nactive warp count = " << active_warps.size() << "\n";
}

int host_index_a(int row, int col, int lda) { return row + col * lda; }
int host_index_b(int row, int col, int ldb) { return row * ldb + col; }
int host_index_c(int row, int col, int ldc) { return row * ldc + col; }

int main() {
  int M = 128;
  int N = 128;
  int K = 8;
  int lda = M;
  int ldb = N;
  int ldc = N;

  double alpha = 1.0;
  double beta = 0.0;

  print_thread_map_offsets<typename MmaCore::IteratorThreadMapA>("IteratorThreadMapA");
  print_thread_map_offsets<typename MmaCore::IteratorThreadMapB>("IteratorThreadMapB");

  std::vector<ElementA> host_a(M * K);
  std::vector<ElementB> host_b(K * N);
  std::vector<ElementC> host_c(M * N);
  std::vector<ElementC> host_d(M * N);
  std::vector<double> reference(M * N, 0.0);

  for (int col = 0; col < K; ++col) {
    for (int row = 0; row < M; ++row) {
      double value = double((row + col) % 7 - 3);
      host_a[host_index_a(row, col, lda)] = ElementA(value);
    }
  }

  for (int row = 0; row < K; ++row) {
    for (int col = 0; col < N; ++col) {
      double value = double((2 * row + col) % 11 - 5);
      host_b[host_index_b(row, col, ldb)] = ElementB(value);
    }
  }

  for (int row = 0; row < M; ++row) {
    for (int col = 0; col < N; ++col) {
      host_c[host_index_c(row, col, ldc)] = ElementC(0.0);
    }
  }

  ElementA* device_a = nullptr;
  ElementB* device_b = nullptr;
  ElementC* device_c = nullptr;
  ElementC* device_d = nullptr;

  CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&device_a), sizeof(ElementA) * host_a.size()));
  CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&device_b), sizeof(ElementB) * host_b.size()));
  CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&device_c), sizeof(ElementC) * host_c.size()));
  CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&device_d), sizeof(ElementC) * host_d.size()));

  CUDA_CHECK(cudaMemcpy(device_a, host_a.data(), sizeof(ElementA) * host_a.size(),
                        cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(device_b, host_b.data(), sizeof(ElementB) * host_b.size(),
                        cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(device_c, host_c.data(), sizeof(ElementC) * host_c.size(),
                        cudaMemcpyHostToDevice));

  CutlassGemm gemm_op;
  typename CutlassGemm::Arguments args(
      {M, N, K},
      {device_a, lda},
      {device_b, ldb},
      {device_c, ldc},
      {device_d, ldc},
      {alpha, beta});

  cutlass::Status can_implement = gemm_op.can_implement(args);
  if (can_implement != cutlass::Status::kSuccess) {
    std::cerr << "can_implement failed: " << cutlassGetStatusString(can_implement) << "\n";
    return -1;
  }

  cutlass::Status status = gemm_op(args);
  if (status != cutlass::Status::kSuccess) {
    std::cerr << "CUTLASS GEMM launch failed: " << cutlassGetStatusString(status) << "\n";
    return -1;
  }

  CUDA_CHECK(cudaDeviceSynchronize());
  CUDA_CHECK(cudaMemcpy(host_d.data(), device_d, sizeof(ElementC) * host_d.size(),
                        cudaMemcpyDeviceToHost));

  for (int row = 0; row < M; ++row) {
    for (int col = 0; col < N; ++col) {
      double accum = 0.0;
      for (int k = 0; k < K; ++k) {
        double a = host_a[host_index_a(row, k, lda)];
        double b = host_b[host_index_b(k, col, ldb)];
        accum += a * b;
      }
      reference[host_index_c(row, col, ldc)] = accum;
    }
  }

  double max_abs_diff = 0.0;
  for (int row = 0; row < M; ++row) {
    for (int col = 0; col < N; ++col) {
      double got = host_d[host_index_c(row, col, ldc)];
      double ref = reference[host_index_c(row, col, ldc)];
      max_abs_diff = std::max(max_abs_diff, std::fabs(got - ref));
    }
  }
  bool passed = (max_abs_diff == 0.0);

  std::cout << "Verification: " << (passed ? "passed" : "failed")
            << ", max_abs_diff = " << max_abs_diff << "\n";
  std::cout << "D[0:4, 0:8]\n";
  for (int row = 0; row < 4; ++row) {
    for (int col = 0; col < 8; ++col) {
      std::cout << std::setw(10) << host_d[host_index_c(row, col, ldc)] << " ";
    }
    std::cout << "\n";
  }

  CUDA_CHECK(cudaFree(device_a));
  CUDA_CHECK(cudaFree(device_b));
  CUDA_CHECK(cudaFree(device_c));
  CUDA_CHECK(cudaFree(device_d));

  return 0;
}
