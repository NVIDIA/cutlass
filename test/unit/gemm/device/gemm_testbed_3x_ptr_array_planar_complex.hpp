/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Testbed for Ptr-Array and Grouped Planar Complex GEMM interface
*/



#pragma once

#include <iostream>
#include <fstream>
#include <sstream>

#include "../../common/cutlass_unit_test.h"
#include "gemm_testbed_3x.hpp"

#include "cutlass/util/host_tensor.h"
#include "cutlass/util/host_tensor_planar_complex.h"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_norm.h"
#include "cutlass/util/reference/host/gemm_planar_complex.h"
#include "cutlass/numeric_types.h"

#include "testbed_utils.h"

#include "cutlass/kernel_hardware_info.hpp"
#include "cutlass/layout/matrix.h"
#include "cutlass/matrix_coord.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/fast_math.h"
#include "cutlass/platform/platform.h"

#include "cute/int_tuple.hpp"
#include "cute/layout.hpp"


namespace test {
namespace gemm {
namespace device {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Gemm>
struct Testbed3xPlanarComplex {
  // Kernel data types
  using ElementA = typename Gemm::GemmKernel::ElementA;
  using StrideA  = typename Gemm::GemmKernel::StrideA;
  using ElementB = typename Gemm::GemmKernel::ElementB;
  using StrideB  = typename Gemm::GemmKernel::StrideB;
  using ElementC = std::conditional_t<std::is_void_v<typename Gemm::GemmKernel::ElementC>,
                    typename Gemm::GemmKernel::ElementD,typename Gemm::GemmKernel::ElementC>;
  using StrideC  = typename Gemm::GemmKernel::StrideC;
  using ElementD = typename Gemm::GemmKernel::ElementD;
  using StrideD  = typename Gemm::GemmKernel::StrideD;
  using ElementAccumulator = typename Gemm::GemmKernel::ElementAccumulator;
  using ProblemShapeType = typename Gemm::GemmKernel::ProblemShape;
  using EpilogueOutputOp = typename Gemm::EpilogueOutputOp;
  using ClusterShapeType = typename Gemm::GemmKernel::CollectiveMainloop::DispatchPolicy::ClusterShape;
  /// For custom EVTs
  using ElementCompute = typename EpilogueOutputOp::ElementCompute;
  using ElementScalar = typename EpilogueOutputOp::ElementScalar;

  static_assert(rank(StrideC{}) == 3, "StrideCD must be rank-3: [M, N, L]");
  static_assert(rank(StrideD{}) == 3, "StrideCD must be rank-3: [M, N, L]");

  static constexpr uint32_t mma_promotion_interval = 4;

  // Looks at Cute Stride to check Row / Column Major
  template<typename Stride>
  static constexpr bool is_row_or_col_major(){
    int stride_0 = int(cute::size<0>(Stride{}));
    int stride_1 = int(cute::size<1>(Stride{}));
    int depth = cute::depth(Stride{});
    return ((stride_0 == 1) || (stride_1 == 1)) && (depth == 1);
  }

  // Note: this limitation comes from testbed / not the library
  static_assert(is_row_or_col_major<StrideA>(),
    "ERROR : A Layout is neither Row / Column Major)");
  static_assert(is_row_or_col_major<StrideB>(),
    "ERROR : B Layout is neither Row / Column Major)");
  static_assert(is_row_or_col_major<StrideC>(),
    "ERROR : C Layout is neither Row / Column Major)");
  static_assert(is_row_or_col_major<StrideD>(),
    "ERROR : D Layout is neither Row / Column Major)");

  // Deduce Cutlass Layouts (RowMajor & ColumnMajor)
  using LayoutTagA = cutlass::detail::StrideToLayoutTagA_t<StrideA>;
  using LayoutTagB = cutlass::detail::StrideToLayoutTagB_t<StrideB>;
  using LayoutTagC = cutlass::detail::StrideToLayoutTagA_t<StrideC>;
  using LayoutTagD = cutlass::detail::StrideToLayoutTagA_t<StrideD>;

  /// Initialization
  StrideA stride_a;
  StrideB stride_b;
  StrideC stride_c;
  StrideD stride_d;

  typename LayoutTagA::Stride stride_factor_A;
  typename LayoutTagB::Stride stride_factor_B;
  typename LayoutTagC::Stride stride_factor_C;
  typename LayoutTagD::Stride stride_factor_D;

  cutlass::Distribution::Kind init_A;
  cutlass::Distribution::Kind init_B;
  cutlass::Distribution::Kind init_C;
  uint64_t seed;
  static constexpr uint64_t kDefaultSeed = 4096;

  // Data members
  std::vector<cutlass::HostTensorPlanarComplex<ElementA, LayoutTagA>> tensors_A;
  std::vector<cutlass::HostTensorPlanarComplex<ElementB, LayoutTagB>> tensors_B;
  std::vector<cutlass::HostTensorPlanarComplex<ElementC, LayoutTagC>> tensors_C;
  std::vector<cutlass::HostTensorPlanarComplex<ElementC, LayoutTagC>> tensors_D;
  std::vector<cutlass::HostTensorPlanarComplex<ElementC, LayoutTagC>> references_D;

  cutlass::DeviceAllocation<const ElementA *> device_tensors_A_real;
  cutlass::DeviceAllocation<const ElementA *> device_tensors_A_imag;

  cutlass::DeviceAllocation<const ElementB *> device_tensors_B_real;
  cutlass::DeviceAllocation<const ElementB *> device_tensors_B_imag;

  cutlass::DeviceAllocation<const ElementC *> device_tensors_C_real;
  cutlass::DeviceAllocation<const ElementC *> device_tensors_C_imag;

  cutlass::DeviceAllocation<ElementC *> device_tensors_D_real;
  cutlass::DeviceAllocation<ElementC *> device_tensors_D_imag;

  uint32_t sm_count;

  // Used to force multi-wave tests for persistent kernel schedules
  constexpr static int MaxSmCount = 16;
  using RasterOrderOptions = typename cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90::RasterOrderOptions;
  using DecompositionMode = typename cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90StreamKParams::DecompositionMode;

  cutlass::ComplexTransform TransformA = Gemm::kTransformA;
  cutlass::ComplexTransform TransformB = Gemm::kTransformB;

  //
  // Methods
  //
  Testbed3xPlanarComplex(
    cutlass::Distribution::Kind init_A_ = cutlass::Distribution::Uniform,
    cutlass::Distribution::Kind init_B_ = cutlass::Distribution::Uniform,
    cutlass::Distribution::Kind init_C_ = cutlass::Distribution::Uniform,
    uint64_t seed_ = kDefaultSeed
  ):
    stride_factor_A(typename LayoutTagA::Stride()),
    stride_factor_B(typename LayoutTagB::Stride()),
    stride_factor_C(typename LayoutTagC::Stride()),
    stride_factor_D(typename LayoutTagD::Stride()),
    init_A(init_A_), init_B(init_B_), init_C(init_C_), seed(seed_) { }

  /// Helper to initialize a tensor view
  template <typename Element, typename Layout>
  bool initialize_tensor(
    cutlass::TensorViewPlanarComplex<Element, Layout> view,
    cutlass::Distribution::Kind dist_kind,
    uint64_t seed) {

    if (dist_kind == cutlass::Distribution::Uniform) {
      double scope_max, scope_min;
      int bits_input = cutlass::sizeof_bits<Element>::value;
      int bits_output = cutlass::sizeof_bits<ElementD>::value;

      if (bits_input == 1) {
        scope_max = 2;
        scope_min = 0;
      }
      else if (bits_input <= 8) {
        scope_max = 2;
        scope_min = -2;
      }
      else if (bits_output == 16) {
        scope_max = 5;
        scope_min = -5;
      }
      else {
        scope_max = 8;
        scope_min = -8;
      }
      cutlass::reference::host::TensorFillRandomUniform(
        view, seed, scope_max, scope_min, 0);
    }

    else if (dist_kind == cutlass::Distribution::Gaussian) {
      cutlass::reference::host::TensorFillRandomGaussian(view, seed, 0, 0.5);
    }

    else if (dist_kind == cutlass::Distribution::AllOnes) {
      cutlass::reference::host::TensorFill(view, {Element(1), Element(0)});
    }
    else {
      EXPECT_TRUE(false) << "Not implemented";
      return false;
    }

    return true;
  }

  /// Initializes data structures
  void initialize(ProblemShapeType problem_shapes) {
    //
    // Allocate the GEMM workspace
    //
    auto [M, N, K, L] = problem_shapes.get_host_problem_shape();

    stride_a = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, 1));
    stride_b = cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(N, K, 1));
    stride_c = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(M, N, 1));
    stride_d = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(M, N, 1));

    auto a_coord = cutlass::make_Coord(M, K);
    auto c_coord = cutlass::make_Coord(M, N);
    // Cutlass has Row/Col major refers to MxK times KxN matrix product,
    // so the HostTensorB should be treated as KxN in "coord"'s view
    auto b_coord = cutlass::make_Coord(K, N);

    tensors_A.clear();
    tensors_B.clear();
    tensors_C.clear();
    tensors_D.clear();
    references_D.clear();

    for (int32_t i = 0; i < L; ++i) {
      tensors_A.push_back(cutlass::HostTensorPlanarComplex<ElementA, LayoutTagA>(a_coord, cutlass::layout::Affine2Layout_Factory<LayoutTagA>::layout_factory(a_coord, stride_factor_A)));
      tensors_B.push_back(cutlass::HostTensorPlanarComplex<ElementB, LayoutTagB>(b_coord, cutlass::layout::Affine2Layout_Factory<LayoutTagB>::layout_factory(b_coord, stride_factor_B)));
      tensors_C.push_back(cutlass::HostTensorPlanarComplex<ElementC, LayoutTagC>(c_coord, cutlass::layout::Affine2Layout_Factory<LayoutTagC>::layout_factory(c_coord, stride_factor_C)));
      tensors_D.push_back(cutlass::HostTensorPlanarComplex<ElementC, LayoutTagC>(c_coord, cutlass::layout::Affine2Layout_Factory<LayoutTagD>::layout_factory(c_coord, stride_factor_D)));
      references_D.push_back(cutlass::HostTensorPlanarComplex<ElementC, LayoutTagC>(c_coord, cutlass::layout::Affine2Layout_Factory<LayoutTagD>::layout_factory(c_coord, stride_factor_D), false));
      
      EXPECT_TRUE(initialize_tensor(tensors_A[i].host_view(), init_A, seed + 2022 + i));
      EXPECT_TRUE(initialize_tensor(tensors_B[i].host_view(), init_B, seed + 2021 + i));
      EXPECT_TRUE(initialize_tensor(tensors_C[i].host_view(), init_B, seed + 2020 + i));

      cutlass::reference::host::TensorFill(tensors_D[i].host_view(), cutlass::complex<ElementC>());
      cutlass::reference::host::TensorFill(references_D[i].host_view(), cutlass::complex<ElementC>());

      tensors_A[i].sync_device();
      tensors_B[i].sync_device();
      tensors_C[i].sync_device();
      tensors_D[i].sync_device();
    } 
  }

  /// Verifies the result is a GEMM
  bool verify(
      ProblemShapeType problem_shapes,
      ElementScalar alpha,
      ElementScalar beta)
  {
    using namespace cute;
    auto [M, N, K, L] = problem_shapes.get_host_problem_shape();

#if 0
    std::cout << " M : " << M << " N : " << N << " K : " << K << " L : " << L << std::endl;
#endif

    //
    // Compute reference
    //
    bool passed = false;
    for(int batch = 0; batch < L; ++batch) {
      cutlass::reference::host::GemmPlanarComplex<
            ElementA, LayoutTagA,
            ElementB, LayoutTagB,
            ElementC, LayoutTagC,
            ElementAccumulator
      >(
        cutlass::gemm::GemmCoord(M,N,K),
        alpha,
        tensors_A[batch].host_ref(),
        TransformA,
        tensors_B[batch].host_ref(),
        TransformB,
        beta,
        tensors_C[batch].host_ref(),
        references_D[batch].host_ref()
      ); 

      tensors_D[batch].sync_host();
      passed = cutlass::reference::host::TensorEquals(
        tensors_D[batch].host_view(), 
        references_D[batch].host_view()
      );

      EXPECT_TRUE(passed);

      if (!passed) {
        std::stringstream fname;
        fname << "error_Planar_Complex_Gemm_device_"
          << M << "x" << N << "x" << K << "x" << batch << "_"
          << cute::get<0>(typename Gemm::GemmKernel::TileShape{}) << "_"
          << cute::get<1>(typename Gemm::GemmKernel::TileShape{}) << "_"
          << cute::get<2>(typename Gemm::GemmKernel::TileShape{}) << ".txt";

        std::ofstream file(fname.str());
        file
          << "problem: " << ' ' << M << "x" << N << "x" << K << ", Batch idx = " << batch
          << ", alpha: " << alpha << ", beta: " << beta 
          << "\n\n";

        file
          << "A =\n" << tensors_A[batch].host_view()
          << "\nB =\n" << tensors_B[batch].host_view()
          << "\nC =\n" << tensors_C[batch].host_view()
          << "\n\nReference =\n" << references_D[batch].host_view()
          << "\n\nComputed =\n" << tensors_D[batch].host_view();
      }
    }
    return passed;
  }

  /// Returns true if the CUDA device is sufficient to execute the kernel.
  bool sufficient() {
    //
    // Determine SMEM requirements and waive if not satisfied
    //
    
    int smem_size = Gemm::GemmKernel::SharedStorageSize;

    int device_idx;
    cudaError_t result = cudaGetDevice(&device_idx);

    if (result != cudaSuccess) {
      throw std::runtime_error("cudaGetDevice() API call failed.");
    }

    cudaDeviceProp properties;
    result = cudaGetDeviceProperties(&properties, device_idx);
    this->sm_count = properties.multiProcessorCount;

    if (result != cudaSuccess) {
      throw std::runtime_error("cudaGetDeviceProperties() failed");
    }

    if (properties.sharedMemPerBlockOptin < size_t(smem_size)) {
      return false;
    }

    return true;
  }

  bool run(
    ProblemShapeType problem_shapes,
    ElementScalar alpha = ElementScalar(1),
    ElementScalar beta = ElementScalar(0),
    RasterOrderOptions raster_order = RasterOrderOptions::Heuristic,
    detail::MaxSwizzleSize max_swizzle = detail::MaxSwizzleSize{},
    detail::Splits splits = detail::Splits{},
    DecompositionMode decomposition_mode = DecompositionMode::Heuristic,
    unsigned int cluster_m = 0,
    unsigned int cluster_n = 0,
    unsigned int cluster_m_fallback = 0,
    unsigned int cluster_n_fallback = 0
    ) {
    // Waive test if insufficient CUDA device
    if (!sufficient()) {
      if (CUTLASS_TEST_UNIT_ENABLE_WARNINGS) {
        std::cerr << "Test waived due to insufficient CUDA device." << std::endl;
      }
      return true;
    }

    this->initialize(problem_shapes);

    //
    // Launch device kernel
    //

    //
    // Initialize the GEMM operator
    //

    cutlass::KernelHardwareInfo hw_info;
    hw_info.device_id = 0;

    this->sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);
    hw_info.sm_count = this->sm_count;
    if (not cute::is_static_v<ClusterShapeType>) {
      // Runtime and preferred cluster setting
      hw_info.cluster_shape = {cluster_m, cluster_n, 1};
      hw_info.cluster_shape_fallback = {cluster_m_fallback, cluster_n_fallback, 1};
    }

    typename Gemm::GemmKernel::TileScheduler::Arguments scheduler_args;
    if constexpr (cute::is_same_v<typename Gemm::GemmKernel::TileSchedulerTag, cutlass::gemm::StreamKScheduler>) {
      scheduler_args = { static_cast<int>(splits), static_cast<int>(max_swizzle), raster_order, decomposition_mode };
    }
    else {
      scheduler_args = { static_cast<int>(max_swizzle), raster_order };
    }

    auto [M, N, K, L] = problem_shapes.get_host_problem_shape();
    std::vector<ElementA *> ptr_A_real_host(L);
    std::vector<ElementA *> ptr_A_imag_host(L);

    std::vector<ElementB *> ptr_B_real_host(L);
    std::vector<ElementB *> ptr_B_imag_host(L);

    std::vector<ElementC *> ptr_C_real_host(L);
    std::vector<ElementC *> ptr_C_imag_host(L);

    std::vector<ElementC *> ptr_D_real_host(L);
    std::vector<ElementC *> ptr_D_imag_host(L);

    for (int32_t i = 0; i < L; ++i) {
      ptr_A_real_host.at(i) = tensors_A[i].device_data();
      ptr_A_imag_host.at(i) = tensors_A[i].device_data_imag();

      ptr_B_real_host.at(i) = tensors_B[i].device_data();
      ptr_B_imag_host.at(i) = tensors_B[i].device_data_imag();
  
      ptr_C_real_host.at(i) = tensors_C[i].device_data();
      ptr_C_imag_host.at(i) = tensors_C[i].device_data_imag();

      ptr_D_real_host.at(i) = tensors_D[i].device_data();
      ptr_D_imag_host.at(i) = tensors_D[i].device_data_imag();
    }

    device_tensors_A_real.reset(L);
    device_tensors_A_real.copy_from_host(ptr_A_real_host.data());
    device_tensors_A_imag.reset(L);
    device_tensors_A_imag.copy_from_host(ptr_A_imag_host.data());

    device_tensors_B_real.reset(L);
    device_tensors_B_real.copy_from_host(ptr_B_real_host.data());
    device_tensors_B_imag.reset(L);
    device_tensors_B_imag.copy_from_host(ptr_B_imag_host.data());

    device_tensors_C_real.reset(L);
    device_tensors_C_real.copy_from_host(ptr_C_real_host.data());
    device_tensors_C_imag.reset(L);
    device_tensors_C_imag.copy_from_host(ptr_C_imag_host.data());

    device_tensors_D_real.reset(L);
    device_tensors_D_real.copy_from_host(ptr_D_real_host.data());
    device_tensors_D_imag.reset(L);
    device_tensors_D_imag.copy_from_host(ptr_D_imag_host.data());

    auto arguments = typename Gemm::Arguments {
      cutlass::gemm::GemmUniversalMode::kArray,
      problem_shapes,
      {
        device_tensors_A_real.get(), stride_a, device_tensors_A_imag.get(), stride_a,
        device_tensors_B_real.get(), stride_b, device_tensors_B_imag.get(), stride_b
      },
      {
        {alpha, beta},
        device_tensors_C_real.get(), stride_c, device_tensors_C_imag.get(), stride_c,
        device_tensors_D_real.get(), stride_d, device_tensors_D_imag.get(), stride_d
      },
      hw_info,
      scheduler_args
    };

    Gemm gemm_op;

    size_t workspace_size = Gemm::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    cutlass::Status status = gemm_op.can_implement(arguments);

    if (status != cutlass::Status::kSuccess) {
      cudaError_t error = cudaGetLastError();
      std::cerr << "This test is not supported: " << cudaGetErrorString(error) << "\n";
      return true;
    }

    //
    // Run the GEMM
    //

    cudaError_t result;
    status = gemm_op.initialize(arguments, workspace.get());
    status = gemm_op.run();
    result = cudaDeviceSynchronize();
    if (result != cudaSuccess) {
      EXPECT_EQ(result, cudaSuccess) << "Error at Kernel Sync.";
      return false;
    }

    EXPECT_TRUE(status == cutlass::Status::kSuccess) << to_string(status);
    //
    // Verify
    //
    bool passed = this->verify(problem_shapes, alpha, beta);

    if (!passed) {
      std::cout << "Error : Failed : with alpha: " << alpha << ", beta: " << beta
                << "\n";
    }

    return passed;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace device
} // namespace gemm
} // namespace test
