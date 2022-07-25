#pragma once

#include "cutlass/arch/arch.h"
#include "cutlass/device_kernel.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/trace.h"

////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace contrib {
namespace gemm {
namespace device {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Gemm
template <typename GemmKernel_>
class GemmGrouped {
 public:
  using GemmKernel = GemmKernel_;

  /// Argument structure
  using Arguments = typename GemmKernel::Arguments;

 protected:
  /// Kernel parameters object
  typename GemmKernel::Params params_;

 public:
  /// Constructs the GEMM.
  GemmGrouped() {
  }

  /// Determines whether the GEMM can execute the given problem.
  static Status can_implement(Arguments const& args) {
    return Status::kSuccess;
  }

  /// Gets the workspace size
  static size_t get_workspace_size(Arguments const& args) {
    // This kerenl does not utilize a workspace
    return size_t();
  }

  /// Computes the grid shape
  static dim3 get_grid_shape(Arguments const& args) {
    return dim3(args.threadblock_count, 1, 1);
  }

  /// Computes the maximum number of active blocks per multiprocessor
  static int maximum_active_blocks(int smem_capacity = -1) {
    CUTLASS_TRACE_HOST("GemmUniversalBase::maximum_active_blocks()");

    int max_active_blocks = -1;
    int smem_size = int(sizeof(typename GemmKernel::SharedStorage));

    CUTLASS_TRACE_HOST("  smem_size: " << smem_size << " bytes");

    if (smem_size <= (48 << 10)) {
      cudaError_t result = cudaOccupancyMaxActiveBlocksPerMultiprocessor(
          &max_active_blocks, Kernel<GemmKernel>, GemmKernel::kThreadCount, smem_size);

      if (result == cudaSuccess) {
        CUTLASS_TRACE_HOST("  max_active_blocks: " << max_active_blocks);
        return max_active_blocks;
      }
    } else {
      // Query assuming zero shared memory then compute occupancy limit based on SMEM
      cudaError_t result = cudaOccupancyMaxActiveBlocksPerMultiprocessor(
          &max_active_blocks, Kernel<GemmKernel>, GemmKernel::kThreadCount, 0);

      if (result != cudaSuccess) {
        CUTLASS_TRACE_HOST("  cudaOccupancyMaxActiveBlocksPerMultiprocessor() returned error "
                           << cudaGetErrorString(result));

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

      int occupancy = std::min(max_active_blocks, smem_capacity / smem_size);

      CUTLASS_TRACE_HOST("  occupancy: " << occupancy);

      return occupancy;
    }

    CUTLASS_TRACE_HOST("  returning internal error");

    return -1;
  }

  /// Initializes GEMM state from arguments.
  Status initialize(Arguments const& args,
                    void* workspace = nullptr,
                    cudaStream_t stream = nullptr) {
    // CUTLASS_TRACE_HOST("GemmGrouped2D::initialize() - workspace "
    //                    << workspace << ", stream: " << (stream ? "non-null" : "null"));

    // Workspace
    size_t workspace_bytes = get_workspace_size(args);

    if (workspace_bytes && !workspace) {
      return Status::kErrorWorkspaceNull;
    }

    // Initialize the Params structure
    params_ = typename GemmKernel::Params(args, workspace);

    // Specify shared memory capacity for kernel.
    int smem_size = int(sizeof(typename GemmKernel::SharedStorage));

    if (smem_size >= (48 << 10)) {
      cudaError_t result = cudaFuncSetAttribute(
          Kernel<GemmKernel>, cudaFuncAttributeMaxDynamicSharedMemorySize, smem_size);

      if (result != cudaSuccess) {
        return Status::kErrorInternal;
      }
    }

    return Status::kSuccess;
  }

  /// Lightweight update given a subset of arguments
  Status update(Arguments const& args, void* workspace = nullptr) {
    size_t workspace_bytes = get_workspace_size(args);

    if (workspace_bytes && !workspace) {
      return Status::kErrorWorkspaceNull;
    }

    params_.update(args, workspace);

    return Status::kSuccess;
  }

  /// Runs the kernel using initialized state.
  Status run(cudaStream_t stream = nullptr) {
    //
    // Configure grid and block dimensions
    //

    if (!params_.problem_visitor.problem_count) {
      return Status::kSuccess;
    }

    dim3 grid(params_.threadblock_count, 1, 1);
    dim3 block(GemmKernel::kThreadCount, 1, 1);

    int smem_size = int(sizeof(typename GemmKernel::SharedStorage));

    //
    // Launch kernel
    //

    // Launch
    cutlass::Kernel<GemmKernel><<<grid, block, smem_size, stream>>>(params_);

    //
    // Query for errors
    //
    cudaError_t result = cudaGetLastError();

    if (result != cudaSuccess) {
      CUTLASS_TRACE_HOST("  grid launch failed with error " << cudaGetErrorString(result));
      return Status::kErrorInternal;
    }

    return Status::kSuccess;
  }

  /// Runs the kernel using initialized state.
  Status operator()(cudaStream_t stream = nullptr) {
    return run(stream);
  }

  /// Runs the kernel using initialized state.
  Status operator()(Arguments const& args,
                    void* workspace = nullptr,
                    cudaStream_t stream = nullptr) {
    Status status = initialize(args, workspace, stream);

    if (status == Status::kSuccess) {
      status = run(stream);
    }

    return status;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace device
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
