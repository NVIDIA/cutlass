/***************************************************************************************************
 * Copyright (c) 2025 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/* \file
   \brief Defines operations for all grouped GEMM operations in CUTLASS Library.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/detail/collective.hpp"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/library/library.h"
#include "cutlass/library/util.h"
#include "gemm_operation_3x.hpp"
#include "library_internal.h"
#include <unordered_map>

///////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::library {

/// **** CAUTION ****
/// Unlike other operations, initialize() must be called when
/// certain arguments change. See initialize() for details.
template <typename Operator_>
class GroupedGemmUniversal3xOperation : public GemmOperation3xBase<Operator_> {
public:
  using Operator = Operator_;
  using OperatorArguments = typename Operator::Arguments;
  using ElementA = typename Operator::ElementA;
  using LayoutA = typename Operator::LayoutA;
  using ElementB = typename Operator::ElementB;
  using LayoutB = typename Operator::LayoutB;
  using ElementC = typename Operator::ElementC;
  using LayoutC = typename Operator::LayoutC;
  using ElementD = typename Operator::ElementD;
  using LayoutD = typename Operator::LayoutD;
  using ElementAccumulator = typename Operator::ElementAccumulator;
  using ElementCompute = typename Operator::EpilogueOutputOp::ElementCompute;

  using CollectiveMainloop = typename Operator::CollectiveMainloop;
  using CollectiveEpilogue = typename Operator::CollectiveEpilogue;
  using ThreadEpilogueOp = typename CollectiveEpilogue::ThreadEpilogueOp;

private:
  mutable CudaBuffer strideA_device;
  mutable CudaBuffer strideB_device;
  mutable CudaBuffer strideC_device;
  mutable CudaBuffer strideD_device;
  mutable std::vector<typename Operator::GemmKernel::InternalStrideA> strideA_host;
  mutable std::vector<typename Operator::GemmKernel::InternalStrideB> strideB_host;
  mutable std::vector<typename Operator::GemmKernel::InternalStrideC> strideC_host;
  mutable std::vector<typename Operator::GemmKernel::InternalStrideD> strideD_host;

public:
  GroupedGemmUniversal3xOperation(char const* name = "unknown_gemm")
      : GemmOperation3xBase<Operator_>(name, GemmKind::kGrouped) {
    this->description_.kind = OperationKind::kGroupedGemm;
    if constexpr (Operator::ArchTag::kMinComputeCapability >= 90) {
      dim3 cluster_dims(
        cute::size<0>(typename Operator::GemmKernel::ClusterShape{}),
        cute::size<1>(typename Operator::GemmKernel::ClusterShape{}),
        cute::size<2>(typename Operator::GemmKernel::ClusterShape{}));
      uint32_t threads_per_block = Operator::GemmKernel::MaxThreadsPerBlock;
      void const* kernel_ptr = (void*)(device_kernel<typename Operator::GemmKernel>);
      max_active_clusters = cutlass::KernelHardwareInfo::query_device_max_active_clusters(
        cluster_dims,
        threads_per_block,
        kernel_ptr);
    }
  }

  ~GroupedGemmUniversal3xOperation() override = default;

private:
  int max_active_clusters{};

protected:
  template <class FusionArgs, class = void> struct UpdateFusionArgs {
    static Status update_(FusionArgs const& fusion_args, GemmGroupedArguments const& arguments) {
      // If a custom EVT is instantiated then it is the users's responsibility
      // to ensure alpha and beta are updated appropriately
      return Status::kSuccess;
    }
  };

  template <class FusionArgs>
  struct UpdateFusionArgs<FusionArgs, cute::void_t<decltype(FusionArgs{}.alpha)>> {
    static Status update_(FusionArgs& fusion_args, GemmGroupedArguments const& arguments) {
      if (arguments.pointer_mode == ScalarPointerMode::kHost) {
        fusion_args.alpha = *static_cast<ElementCompute const*>(arguments.alpha);
        fusion_args.beta = *static_cast<ElementCompute const*>(arguments.beta);
        fusion_args.alpha_ptr = nullptr;
        fusion_args.beta_ptr = nullptr;
        fusion_args.alpha_ptr_array = nullptr;
        fusion_args.beta_ptr_array = nullptr;
        // Single alpha and beta for all groups
        fusion_args.dAlpha = {cute::_0{}, cute::_0{}, 0};
        fusion_args.dBeta = {cute::_0{}, cute::_0{}, 0};

        return Status::kSuccess;
      }
      else if (arguments.pointer_mode == ScalarPointerMode::kDevice) {
        fusion_args.alpha = 0;
        fusion_args.beta = 0;
        fusion_args.alpha_ptr = static_cast<ElementCompute const*>(arguments.alpha);
        fusion_args.beta_ptr = static_cast<ElementCompute const*>(arguments.beta);
        return Status::kSuccess;
      }
      else {
        return Status::kErrorInvalidProblem;
      }
    }
  };

  /// Constructs the arguments structure given the configuration and arguments
  Status
  update_arguments_(OperatorArguments& operator_args, GemmGroupedArguments const* arguments) const {

    Status status = UpdateFusionArgs<decltype(operator_args.epilogue.thread)>::update_(
      operator_args.epilogue.thread,
      *arguments);
    if (status != Status::kSuccess) {
      return status;
    }

    operator_args.mode = cutlass::gemm::GemmUniversalMode::kGrouped;
    operator_args.problem_shape = {
      arguments->problem_count,
      arguments->problem_sizes_3x,
      arguments->pointer_mode == ScalarPointerMode::kHost ? arguments->problem_sizes_3x_host
                                                          : nullptr};
    operator_args.mainloop.ptr_A =
      static_cast<const typename Operator::ElementA**>(arguments->ptr_A);
    operator_args.mainloop.ptr_B =
      static_cast<const typename Operator::ElementB**>(arguments->ptr_B);
    operator_args.epilogue.ptr_C =
      static_cast<const typename Operator::ElementC**>(arguments->ptr_C);
    operator_args.epilogue.ptr_D = static_cast<typename Operator::ElementD**>(arguments->ptr_D);

    operator_args.mainloop.dA =
      static_cast<typename Operator::GemmKernel::InternalStrideA*>(strideA_device.data());
    operator_args.mainloop.dB =
      static_cast<typename Operator::GemmKernel::InternalStrideB*>(strideB_device.data());
    operator_args.epilogue.dC =
      static_cast<typename Operator::GemmKernel::InternalStrideC*>(strideC_device.data());
    operator_args.epilogue.dD =
      static_cast<typename Operator::GemmKernel::InternalStrideD*>(strideD_device.data());

    operator_args.hw_info.sm_count = arguments->sm_count;
    if constexpr (Operator::ArchTag::kMinComputeCapability >= 90) {
      operator_args.hw_info.max_active_clusters = max_active_clusters;
    }
    
    if constexpr (Operator::ArchTag::kMinComputeCapability >= 100) {
      operator_args.hw_info.cluster_shape = dim3(
        arguments->cluster_shape.m(),
        arguments->cluster_shape.n(),
        arguments->cluster_shape.k());
      operator_args.hw_info.cluster_shape_fallback = dim3(
        arguments->cluster_shape_fallback.m(),
        arguments->cluster_shape_fallback.n(),
        arguments->cluster_shape_fallback.k());
    }
    

    return status;
  }

public:
  /// Returns success if the operation can proceed
  Status can_implement([[maybe_unused]] void const* configuration_ptr, void const* arguments_ptr)
    const override {
    GemmGroupedArguments const* arguments = static_cast<GemmGroupedArguments const*>(arguments_ptr);
    OperatorArguments args;

    auto status = update_arguments_(args, arguments);
    if (status != Status::kSuccess) {
      return status;
    }

    status = Operator::can_implement(args);
    return status;
  }

  /// Gets the host-side workspace
  uint64_t get_host_workspace_size(void const* configuration) const override {
    return sizeof(Operator);
  }

  /// Gets the device-side workspace
  uint64_t get_device_workspace_size(void const* configuration_ptr, void const* arguments_ptr)
    const override {

    OperatorArguments args;
    auto status = update_arguments_(args, static_cast<GemmGroupedArguments const*>(arguments_ptr));
    if (status != Status::kSuccess) {
      return 0;
    }

    uint64_t size = Operator::get_workspace_size(args);
    return size;
  }

  /// Initializes the workspace
  /// **** CAUTION ****
  /// Must be called when lda, ldb, ldc, or ldd change.
  /// The CUTLASS library stores the operations in a type-
  /// erased manifest. Therefore, only this class knows
  /// the type of strideA, strideB, strideC, and strideD.
  /// Since grouped GEMM needs to allocate storage for
  /// the strides on device, the concrete type of the stride
  /// must be known in order to copy in the correct memory
  /// layout on device.
  Status initialize(
    void const* configuration_ptr,
    void* host_workspace,
    void* device_workspace,
    cudaStream_t stream = nullptr) const override {

    auto const& config = *static_cast<GemmGroupedConfiguration const*>(configuration_ptr);

    auto num_groups = config.problem_count;
    strideA_device =
      CudaBuffer(sizeof(typename Operator::GemmKernel::InternalStrideA) * num_groups);
    strideB_device =
      CudaBuffer(sizeof(typename Operator::GemmKernel::InternalStrideB) * num_groups);
    strideC_device =
      CudaBuffer(sizeof(typename Operator::GemmKernel::InternalStrideC) * num_groups);
    strideD_device =
      CudaBuffer(sizeof(typename Operator::GemmKernel::InternalStrideD) * num_groups);

    strideA_host.resize(num_groups);
    strideB_host.resize(num_groups);
    strideC_host.resize(num_groups);
    strideD_host.resize(num_groups);
    for (int group_idx = 0; group_idx < num_groups; group_idx++) {
      strideA_host[group_idx] =
        cute::make_int_tuple_from<typename Operator::GemmKernel::InternalStrideA>(
          config.lda[group_idx]);
      strideB_host[group_idx] =
        cute::make_int_tuple_from<typename Operator::GemmKernel::InternalStrideB>(
          config.ldb[group_idx]);
      strideC_host[group_idx] =
        cute::make_int_tuple_from<typename Operator::GemmKernel::InternalStrideC>(
          config.ldc[group_idx]);
      strideD_host[group_idx] =
        cute::make_int_tuple_from<typename Operator::GemmKernel::InternalStrideD>(
          config.ldc[group_idx]);
    }
    CUDA_CHECK(cudaMemcpy(
      strideA_device.data(),
      strideA_host.data(),
      sizeof(typename Operator::GemmKernel::InternalStrideA) * num_groups,
      cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(
      strideB_device.data(),
      strideB_host.data(),
      sizeof(typename Operator::GemmKernel::InternalStrideB) * num_groups,
      cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(
      strideC_device.data(),
      strideC_host.data(),
      sizeof(typename Operator::GemmKernel::InternalStrideC) * num_groups,
      cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(
      strideD_device.data(),
      strideD_host.data(),
      sizeof(typename Operator::GemmKernel::InternalStrideD) * num_groups,
      cudaMemcpyHostToDevice));

    Operator* op = new (host_workspace) Operator;
    return Status::kSuccess;
  }

  /// **** CAUTION ****
  /// initialize() must be called if lda, ldb, ldc, or ldd change.
  Status run(
    void const* arguments_ptr,
    void* host_workspace,
    void* device_workspace = nullptr,
    cudaStream_t stream = nullptr) const override {

    OperatorArguments operator_args;
    auto const& args = *static_cast<GemmGroupedArguments const*>(arguments_ptr);

    Status status = update_arguments_(operator_args, &args);
    if (status != Status::kSuccess) {
      return status;
    }

    Operator* op = static_cast<Operator*>(host_workspace);
    // We need to call initialize() since we have to rebuild TMA desc for every new set of args
    status = op->run(operator_args, device_workspace, stream, nullptr, args.use_pdl);
    return status;
  }
};
///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::library

///////////////////////////////////////////////////////////////////////////////////////////////////
