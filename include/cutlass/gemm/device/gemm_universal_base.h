/***************************************************************************************************
 * Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
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
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! 
  \file
  \brief The universal GEMM accommodates serial reductions, parallel reductions, batched strided, and 
    batched array variants.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/arch/arch.h"
#include "cutlass/device_kernel.h"

#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/threadblock/threadblock_swizzle.h"
#include "cutlass/gemm/kernel/gemm_universal.h"

#include "cutlass/gemm/kernel/default_gemm_universal.h"
#include "cutlass/gemm/device/default_gemm_configuration.h"

////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace device {

/////////////////////////////////////////////////////////////////////////////////////////////////


template <typename GemmKernel_>
class GemmUniversalBase {
public:

  using GemmKernel = GemmKernel_;
  using ThreadblockShape = typename GemmKernel::Mma::Shape;
  
  using ElementA = typename GemmKernel::ElementA;
  using LayoutA = typename GemmKernel::LayoutA;
  using TensorRefA = TensorRef<ElementA const, LayoutA>;
  static ComplexTransform const kTransformA = GemmKernel::kTransformA;

  using ElementB = typename GemmKernel::ElementB;
  using LayoutB = typename GemmKernel::LayoutB;
  using TensorRefB = TensorRef<ElementB const, LayoutB>;
  static ComplexTransform const kTransformB = GemmKernel::kTransformB;

  using ElementC = typename GemmKernel::ElementC;
  using LayoutC = typename GemmKernel::LayoutC;
  using TensorRefC = TensorRef<ElementC const, LayoutC>;
  using TensorRefD = TensorRef<ElementC, LayoutC>;

  using ElementAccumulator = typename GemmKernel::Mma::Policy::Operator::ElementC;

  using EpilogueOutputOp = typename GemmKernel::EpilogueOutputOp;
  using ThreadblockSwizzle = typename GemmKernel::ThreadblockSwizzle;
  using Operator = typename GemmKernel::Operator;

  /// Argument structure
  using Arguments = typename GemmKernel::Arguments;

protected:

  /// Kernel parameters object
  typename GemmKernel::Params params_;

protected:

  /// Private helper to obtain the grid dimensions with fix-up for split-K
  static void get_grid_shape_(gemm::GemmCoord &grid_tiled_shape, int &gemm_k_size, Arguments const &args) {

    // Determine grid shape
    ThreadblockSwizzle threadblock_swizzle;

    grid_tiled_shape = threadblock_swizzle.get_tiled_shape(
      args.problem_size, 
      {ThreadblockShape::kM, ThreadblockShape::kN, ThreadblockShape::kK},
      args.batch_count);
    
    gemm_k_size = args.problem_size.k();

    if (args.mode == GemmUniversalMode::kGemm || args.mode == GemmUniversalMode::kGemmSplitKParallel) {

      int const kAlignK = const_max(const_max(128 / sizeof_bits<ElementA>::value, 128 / sizeof_bits<ElementB>::value), 1);

      gemm_k_size = round_up(ceil_div(args.problem_size.k(), args.batch_count), kAlignK);
      
      if (gemm_k_size) {
        grid_tiled_shape.k() = ceil_div(args.problem_size.k(), gemm_k_size);
      }
    }
  }

public:

  /// Constructs the GEMM.
  GemmUniversalBase() { }

  /// Determines whether the GEMM can execute the given problem.
  static Status can_implement(Arguments const &args) {

    return GemmKernel::can_implement(args);
  }

  /// Gets the workspace size
  static size_t get_workspace_size(Arguments const &args) {
    
    size_t workspace_bytes = 0;

    // Determine grid shape
    cutlass::gemm::GemmCoord grid_tiled_shape;
    int gemm_k_size = 0;
    
    get_grid_shape_(grid_tiled_shape, gemm_k_size, args);
    
    if (args.mode == GemmUniversalMode::kGemmSplitKParallel) {

      // Split-K parallel always requires a temporary workspace
      workspace_bytes = 
        sizeof(ElementC) *
        size_t(args.batch_stride_D) *
        size_t(grid_tiled_shape.k());
    }
    else if (args.mode == GemmUniversalMode::kGemm && grid_tiled_shape.k() > 1) {

      // Serial split-K only requires a temporary workspace if the number of partitions along the
      // GEMM K dimension is greater than one.
      workspace_bytes = sizeof(int) * size_t(grid_tiled_shape.m()) * size_t(grid_tiled_shape.n());
    }
    
    return workspace_bytes;
  }

  /// Computes the grid shape
  static dim3 get_grid_shape(Arguments const &args) {

    ThreadblockSwizzle threadblock_swizzle;

    cutlass::gemm::GemmCoord grid_tiled_shape;
    int gemm_k_size = 0;

    get_grid_shape_(grid_tiled_shape, gemm_k_size, args);

    return threadblock_swizzle.get_grid_shape(grid_tiled_shape);    
  }

  /// Computes the maximum number of active blocks per multiprocessor
  static int maximum_active_blocks(int smem_capacity = -1) {

    int max_active_blocks = -1;
    int smem_size = int(sizeof(typename GemmKernel::SharedStorage));

    if (smem_size <= (48 << 10)) {

      cudaError_t result = cudaOccupancyMaxActiveBlocksPerMultiprocessor(
        &max_active_blocks,
        Kernel<GemmKernel>,
        GemmKernel::kThreadCount,
        smem_size);

      if (result == cudaSuccess) {
        return max_active_blocks;
      }
    }
    else {

      // Query assuming zero shared memory then compute occupancy limit based on SMEM
      cudaError_t result = cudaOccupancyMaxActiveBlocksPerMultiprocessor(
        &max_active_blocks,
        Kernel<GemmKernel>,
        GemmKernel::kThreadCount,
        0);

      if (result != cudaSuccess) {
        return -1;
      }

      if (smem_capacity < 0) {
        int device_idx = 0;
        result = cudaGetDevice(&device_idx);

        if (result != cudaSuccess) {
          return -1;
        }

        cudaDeviceProp properties;
        result = cudaGetDeviceProperties(&properties, device_idx);

        if (result != cudaSuccess) {
          return -1;
        }

        smem_capacity = static_cast<int>(properties.sharedMemPerMultiprocessor);
      }

      return std::min(max_active_blocks, smem_capacity / smem_size);
    }

    return -1;
  }

  /// Initializes GEMM state from arguments.
  Status initialize(Arguments const &args, void *workspace = nullptr, cudaStream_t stream = nullptr) {

    size_t workspace_bytes = get_workspace_size(args);

    if (workspace_bytes) {
      
      if (!workspace) {
        return Status::kErrorWorkspaceNull;
      }

      if (args.mode == GemmUniversalMode::kGemm) {
        cudaError_t result = cudaMemsetAsync(workspace, 0, workspace_bytes, stream);

        if (result != cudaSuccess) {
          return Status::kErrorInternal;
        }
      }
    }

    // Get CUDA grid shape
    cutlass::gemm::GemmCoord grid_tiled_shape;
    int gemm_k_size = 0;

    get_grid_shape_(grid_tiled_shape, gemm_k_size, args);

    // Initialize the Params structure
    params_ = typename GemmKernel::Params(
      args,
      grid_tiled_shape,
      gemm_k_size,
      static_cast<int *>(workspace)
    );

    return Status::kSuccess;
  }

  /// Lightweight update given a subset of arguments
  Status update(Arguments const &args, void *workspace = nullptr) {

    size_t workspace_bytes = get_workspace_size(args);

    if (workspace_bytes && !workspace) {
      return Status::kErrorWorkspaceNull;
    }
    
    params_.update(args, workspace);
    
    return Status::kSuccess;
  }

  /// Runs the kernel using initialized state.
  Status run(cudaStream_t stream = nullptr) {

    ThreadblockSwizzle threadblock_swizzle;

    dim3 grid = threadblock_swizzle.get_grid_shape(params_.grid_tiled_shape);
    dim3 block(GemmKernel::kThreadCount, 1, 1);

    cudaError_t result;

    int smem_size = int(sizeof(typename GemmKernel::SharedStorage));
    if (smem_size >= (48 << 10)) {
      result = cudaFuncSetAttribute(Kernel<GemmKernel>,
                                    cudaFuncAttributeMaxDynamicSharedMemorySize,
                                    smem_size);

      if (result != cudaSuccess) {
        return Status::kErrorInternal;
      }

      result = cudaFuncSetAttribute(
          Kernel<GemmKernel>,
          cudaFuncAttributePreferredSharedMemoryCarveout, 100);

      if (result != cudaSuccess) {
        return Status::kErrorInternal;
      }
    }

    cutlass::Kernel<GemmKernel><<<grid, block, smem_size, stream>>>(params_);

    result = cudaGetLastError();

    return result == cudaSuccess ? Status::kSuccess : Status::kErrorInternal;
  }

  /// Runs the kernel using initialized state.
  Status operator()(cudaStream_t stream = nullptr) {
    return run(stream);
  }

  /// Runs the kernel using initialized state.
  Status operator()(
    Arguments const &args, 
    void *workspace = nullptr, 
    cudaStream_t stream = nullptr) {
    
    Status status = initialize(args, workspace, stream);
    
    if (status == Status::kSuccess) {
      status = run(stream);
    }

    return status;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace device
} // namespace gemm
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
