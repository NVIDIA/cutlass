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
    \brief Base functionality for common types of Stream-K GEMM kernel parameters
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/trace.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/fast_math.h"


/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace kernel {

/////////////////////////////////////////////////////////////////////////////////////////////////


/// Argument structure
struct StreamkArgumentsBase
{
  //
  // Data members
  //

  GemmUniversalMode mode;
  GemmCoord problem_size;
  int batch_count;

  int avail_sms;          /// The number of SMs that StreamK dispatch heuristics will attempt to load-balance across (-1 defaults to device width, 1 implies classic data-parallel scheduling)

  //
  // Methods
  //

  StreamkArgumentsBase() :
    mode(GemmUniversalMode::kGemm),
    batch_count(1),
    avail_sms(-1)
  {}

  /// constructs an arguments structure
  StreamkArgumentsBase(
    GemmUniversalMode mode,
    GemmCoord problem_size,
    int batch_count,
    int avail_sms = -1
  ) :
    mode(mode),
    problem_size(problem_size),
    batch_count(batch_count),
    avail_sms(avail_sms)
  {}

};


/// Parameters structure
template <
  typename ThreadblockSwizzle,
  typename ThreadblockShape,
  typename GemmKernel>
struct StreamkParamsBase
{
  //
  // Data members
  //
  GemmUniversalMode mode;

  ThreadblockSwizzle block_mapping;

  void *barrier_workspace;
  void *partials_workspace;

  /// Workspace bytes per thread block
  size_t kWorkspaceBytesPerBlock;

  protected:

    //
    // Host-only dispatch-utilities
    //

    /// Pad the given allocation size up to the nearest cache line
    static size_t cacheline_align_up(size_t size)
    {
      static const int CACHELINE_SIZE = 128;
      return (size + CACHELINE_SIZE - 1) / CACHELINE_SIZE * CACHELINE_SIZE;
    }

    /// Get the workspace size needed for barrier
    size_t get_barrier_workspace_size() const
    {
      // For atomic reduction, each SK-block needs a synchronization flag.  For parallel reduction,
      // each reduction block needs its own synchronization flag.
      int sk_blocks = block_mapping.sk_regions() * block_mapping.sk_blocks_per_region();
      int num_flags = fast_max(sk_blocks, block_mapping.reduction_blocks);

      return cacheline_align_up(sizeof(typename Barrier::T) * num_flags);
    }

    /// Get the workspace size needed for intermediate partial sums
    size_t get_partials_workspace_size() const
    {
      int sk_blocks = block_mapping.sk_regions() * block_mapping.sk_blocks_per_region();
      return cacheline_align_up(kWorkspaceBytesPerBlock * sk_blocks);
    }


  public:

    //
    // Host dispatch API
    //

    /// Default constructor
    StreamkParamsBase() = default;

    /// Constructor
    StreamkParamsBase(
      StreamkArgumentsBase const &args,  /// GEMM application arguments
      int device_sms,                    /// Number of SMs on the device
      int sm_occupancy,                  /// Kernel SM occupancy (in thread blocks)
      size_t kWorkspaceBytesPerBlock)
    :
      mode(args.mode),
      barrier_workspace(nullptr),
      partials_workspace(nullptr),
      kWorkspaceBytesPerBlock(kWorkspaceBytesPerBlock)
    {
      // Number of SMs to make available for StreamK decomposition
      int avail_sms = (args.avail_sms == -1) ?
                        device_sms :
                        fast_min(args.avail_sms, device_sms);

      // Initialize the block mapping structure
      block_mapping = ThreadblockSwizzle(
        typename ThreadblockSwizzle::template KernelTraits<GemmKernel>(),
        args.mode,
        args.problem_size,
        {ThreadblockShape::kM, ThreadblockShape::kN, ThreadblockShape::kK},
        args.batch_count,
        sm_occupancy,
        device_sms,
        avail_sms);
    }


    /// Returns the workspace size (in bytes) needed for these parameters
    size_t get_workspace_size() const
    {
      return
        get_barrier_workspace_size() +
        get_partials_workspace_size();
    }


    /// Assign and initialize the specified workspace buffer.  Assumes
    /// the memory allocated to workspace is at least as large as get_workspace_size().
    Status init_workspace(
      void *workspace,
      cudaStream_t stream = nullptr)
    {
      uint8_t *ptr = static_cast<uint8_t*>(workspace);

      // Establish partials workspace
      partials_workspace = nullptr;
      size_t partials_workspace_bytes = get_partials_workspace_size();
      if (partials_workspace_bytes > 0)
      {
        if (!workspace) {
          return Status::kErrorWorkspaceNull;
        }
        partials_workspace = ptr;
        ptr += partials_workspace_bytes;
      }

      // Establish barrier workspace
      barrier_workspace = nullptr;
      size_t barrier_workspace_bytes = get_barrier_workspace_size();
      if (barrier_workspace_bytes > 0)
      {
        if (!workspace) {
          return Status::kErrorWorkspaceNull;
        }
        barrier_workspace = ptr;
        ptr += barrier_workspace_bytes;
      }

      // Zero-initialize barrier workspace
      if (barrier_workspace)
      {
        size_t barrier_workspace_bytes = get_barrier_workspace_size();

        CUTLASS_TRACE_HOST("  Initialize " << barrier_workspace_bytes << " barrier bytes");

        cudaError_t result = cudaMemsetAsync(
          barrier_workspace,
          0,
          barrier_workspace_bytes,
          stream);

        if (result != cudaSuccess) {
          CUTLASS_TRACE_HOST("  cudaMemsetAsync() returned error " << cudaGetErrorString(result));
          return Status::kErrorInternal;
        }
      }

      return Status::kSuccess;
    }


    /// Returns the GEMM volume in thread block tiles
    cutlass::gemm::GemmCoord get_tiled_shape() const
    {
      return block_mapping.tiled_shape();
    }


    /// Returns the total number of thread blocks to launch
    int get_grid_blocks() const
    {
      dim3 grid_dims = get_grid_dims();
      return grid_dims.x * grid_dims.y * grid_dims.z;
    }


    /// Returns the grid extents in thread blocks to launch
    dim3 get_grid_dims() const
    {
      return block_mapping.get_grid_dims();
    }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace kernel
} // namespace gemm
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
