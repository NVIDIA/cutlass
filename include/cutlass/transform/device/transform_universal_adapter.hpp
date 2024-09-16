/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Transform Kernel Universal adapter
*/

#pragma once

// common
#include "cutlass/cutlass.h"
#include "cutlass/cluster_launch.hpp"
#include "cutlass/device_kernel.h"
#include "cutlass/cuda_host_adapter.hpp"

namespace cutlass::transform::device {

template <class TransformKernel_>
class TransformUniversalAdapter
{
public:
  using TransformKernel = TransformKernel_;
  using Arguments = typename TransformKernel::Arguments;
  using Params = typename TransformKernel::Params;

private:
  Params params_;
  static constexpr bool const EnableCudaHostAdapter = CUTLASS_ENABLE_CUDA_HOST_ADAPTER;

public:
  Params const& params() const {
    return this->params_;
  }

  static Status
  can_implement(Arguments const& args) {
    return TransformKernel::can_implement(args);
  }

  static size_t
  get_workspace_size(Arguments const& args) {
    return TransformKernel::get_workspace_size(args);
  }

  static dim3
  get_grid_shape(Arguments const& args, void* workspace = nullptr) {
    auto tmp_params = TransformKernel::to_underlying_arguments(args, workspace);
    return TransformKernel::get_grid_shape(tmp_params);
  }

  static dim3
  get_grid_shape(Params const& params) {
    return TransformKernel::get_grid_shape(params);
  }

  Status
  initialize(
    Arguments & args,
    void* workspace = nullptr,
    cudaStream_t stream = nullptr,
    CudaHostAdapter *cuda_adapter = nullptr) {

    CUTLASS_TRACE_HOST("TransformUniversalAdapter::initialize() - workspace "
      << workspace << ", stream: " << (stream ? "non-null" : "null"));

    // Initialize the workspace
    Status status = TransformKernel::initialize_workspace(args, workspace, stream, cuda_adapter);
    if (status != Status::kSuccess) {
      return status;
    }

    // Initialize the Params structure
    this->params_ = TransformKernel::to_underlying_arguments(args, workspace);

    // Don't set the function attributes - require the CudaHostAdapter to set it.
    if constexpr (EnableCudaHostAdapter) {
      CUTLASS_ASSERT(cuda_adapter);
      return Status::kSuccess;
    }
    else {
      //
      // Account for dynamic smem capacity if needed
      //
      int smem_size = TransformKernel::SharedStorageSize;

      CUTLASS_ASSERT(cuda_adapter == nullptr);

      if (smem_size >= (48 << 10)) {
        CUTLASS_TRACE_HOST("  Setting smem size to " << smem_size);
        cudaError_t result = cudaFuncSetAttribute(
          device_kernel<TransformKernel>,
          cudaFuncAttributeMaxDynamicSharedMemorySize,
          smem_size);
        if (cudaSuccess != result) {
          result = cudaGetLastError();
          CUTLASS_TRACE_HOST("  cudaFuncSetAttribute() returned error: " << cudaGetErrorString(result));
          return Status::kErrorInternal;
        }
      }
    }

    return Status::kSuccess;
  }

  static Status
  run(
    Params& params,
    cudaStream_t stream = nullptr,
    CudaHostAdapter *cuda_adapter = nullptr,
    int32_t kernel_index = 0) {

    CUTLASS_TRACE_HOST("TransformUniversalAdapter::run()");
    dim3 const block = TransformKernel::get_block_shape();
    dim3 const grid = get_grid_shape(params);
    // Currently only support 1x1x1 for transform kernel.
    dim3 const cluster = {1,1,1};

    // configure smem size and carveout
    int smem_size = TransformKernel::SharedStorageSize;

    Status launch_result;

    // Use extended launch API only for mainloops that use it
    if constexpr(TransformKernel::ArchTag::kMinComputeCapability >= 90) {
      void* kernel_params[] = {&params};

      if constexpr (EnableCudaHostAdapter) {
        //
        // Use the cuda host adapter
        //
        CUTLASS_ASSERT(cuda_adapter);
        if (cuda_adapter) {
          launch_result = cuda_adapter->launch(
            grid, cluster, block, smem_size, stream, kernel_params, kernel_index);
        }
        else {
          return Status::kErrorInternal;
        }
      }
      else {
        CUTLASS_ASSERT(cuda_adapter == nullptr);
        void const* kernel = (void const*) device_kernel<TransformKernel>;
        launch_result = ClusterLauncher::launch(
          grid, cluster, block, smem_size, stream, kernel, kernel_params);
      }
    }
    else {
      launch_result = Status::kSuccess;
      if constexpr (EnableCudaHostAdapter) {
        CUTLASS_ASSERT(cuda_adapter);
        if (cuda_adapter) {
          void* kernel_params[] = {&params};
          launch_result = cuda_adapter->launch(
            grid, block, smem_size, stream, kernel_params, 0);
        }
        else {
          return Status::kErrorInternal;
        }
      }
      else {
        CUTLASS_ASSERT(cuda_adapter == nullptr);
        device_kernel<TransformKernel><<<grid, block, smem_size, stream>>>(params);
      }
    }

    cudaError_t result = cudaGetLastError();
    if (cudaSuccess == result && Status::kSuccess == launch_result) {
      return Status::kSuccess;
    } else {
      CUTLASS_TRACE_HOST("  Kernel launch failed. Reason: " << result);
      return Status::kErrorInternal;
    }
  }

  Status
  run(
    Arguments & args,
    void* workspace = nullptr,
    cudaStream_t stream = nullptr,
    CudaHostAdapter *cuda_adapter = nullptr,
    int32_t kernel_index = 0) {

    Status status = initialize(args, workspace, stream, cuda_adapter);
    if (Status::kSuccess == status) {
      status = run(this->params_, stream, cuda_adapter, kernel_index);
    }
    return status;
  }

  Status
  operator()(
    Arguments & args,
    void* workspace = nullptr,
    cudaStream_t stream = nullptr,
    CudaHostAdapter *cuda_adapter = nullptr) {
    return run(args, workspace, stream, cuda_adapter);
  }

  Status
  run(
    cudaStream_t stream = nullptr, 
    CudaHostAdapter *cuda_adapter = nullptr) {
    return run(this->params_, stream, cuda_adapter);
  }

  Status
  operator()(
    cudaStream_t stream = nullptr,
    CudaHostAdapter *cuda_adapter = nullptr) {
    return run(this->params_, stream, cuda_adapter);
  }
};

} // namespace cutlass::transform::device
