/***************************************************************************************************
 * Copyright (c) 2017 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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
/*!
  \file
  \brief The universal GEMM accommodates serial reductions, parallel reductions, batched strided, and
    batched array variants.
*/

#pragma once

// common
#include "cutlass/cutlass.h"
#include "cutlass/device_kernel.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/detail/layout.hpp"
#include "cutlass/detail/mma.hpp"
#include "cutlass/cuda_host_adapter.hpp"

#if !defined(__CUDACC_RTC__)
#include "cutlass/cluster_launch.hpp"
#include "cutlass/trace.h"
#endif // !defined(__CUDACC_RTC__)

// 3.x
#include "cutlass/gemm/kernel/gemm_universal.hpp"

#if defined(CUTLASS_ENABLE_SYCL)
#include "cutlass/util/sycl_event_manager.hpp"
#endif

#include "softmax_finalize.hpp"

////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::device {

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
////////////////////////////// CUTLASS 3.x API /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

template <class GemmKernel_>
class GemmSoftmaxAdapter
{
public:
  using GemmKernel = GemmKernel_;
  using TileShape = typename GemmKernel::TileShape;
  using ElementA = typename GemmKernel::ElementA;
  using ElementB = typename GemmKernel::ElementB;
  using ElementC = typename GemmKernel::ElementC;
  using ElementD = typename GemmKernel::ElementD;
  using ElementAccumulator = typename GemmKernel::ElementAccumulator;
  using DispatchPolicy = typename GemmKernel::DispatchPolicy;
  using CollectiveMainloop = typename GemmKernel::CollectiveMainloop;
  using CollectiveEpilogue = typename GemmKernel::CollectiveEpilogue;

  using SoftmaxFinalizeKernel = reduction::kernel::SoftmaxFinalize<
                                          ElementD, typename GemmKernel::StrideD,
                                          ElementAccumulator, typename GemmKernel::CollectiveEpilogue::StrideTmp,
                                          ElementD, typename GemmKernel::StrideD>;

  // Map back to 2.x type as best as possible
  using LayoutA = gemm::detail::StrideToLayoutTagA_t<typename GemmKernel::StrideA>;
  using LayoutB = gemm::detail::StrideToLayoutTagB_t<typename GemmKernel::StrideB>;
  using LayoutC = gemm::detail::StrideToLayoutTagC_t<typename GemmKernel::StrideC>;
  using LayoutD = gemm::detail::StrideToLayoutTagC_t<typename GemmKernel::StrideD>;
  using LayoutTmp = gemm::detail::StrideToLayoutTagC_t<typename GemmKernel::StrideD>;

  static bool const kEnableCudaHostAdapter = CUTLASS_ENABLE_CUDA_HOST_ADAPTER;

  static ComplexTransform const kTransformA = cute::is_same_v<typename GemmKernel::CollectiveMainloop::TransformA, cute::conjugate> ?
                                              ComplexTransform::kConjugate : ComplexTransform::kNone;
  static ComplexTransform const kTransformB = cute::is_same_v<typename GemmKernel::CollectiveMainloop::TransformB, cute::conjugate> ?
                                              ComplexTransform::kConjugate : ComplexTransform::kNone;

  // Legacy: Assume MultiplyAdd only since we do not use this tag type in 3.0
  using MathOperator = cutlass::arch::OpMultiplyAdd;

  using OperatorClass = cutlass::detail::get_operator_class_t<typename CollectiveMainloop::TiledMma>;

  using ArchTag = typename GemmKernel::ArchTag;

  // NOTE: Assume identity swizzle for now
  using ThreadblockSwizzle = cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>;

  // Assume TiledMma's ShapeMNK is the same as 2.x's ThreadblockShape
  using ThreadblockShape = cutlass::gemm::GemmShape<
      cute::size<0>(TileShape{}),
      cute::size<1>(TileShape{}),
      cute::size<2>(TileShape{})>;

  using ClusterShape = cutlass::gemm::GemmShape<
      cute::size<0>(typename GemmKernel::DispatchPolicy::ClusterShape{}),
      cute::size<1>(typename GemmKernel::DispatchPolicy::ClusterShape{}),
      cute::size<2>(typename GemmKernel::DispatchPolicy::ClusterShape{})>;

  // Instruction shape is easy too, since we get that directly from our TiledMma's atom shape
  using InstructionShape = cutlass::gemm::GemmShape<
      cute::size<0>(typename CollectiveMainloop::TiledMma::AtomShape_MNK{}),
      cute::size<1>(typename CollectiveMainloop::TiledMma::AtomShape_MNK{}),
      cute::size<2>(typename CollectiveMainloop::TiledMma::AtomShape_MNK{})>;

  // Legacy: provide a correct warp count, but no reliable warp shape
  static int const kThreadCount = GemmKernel::MaxThreadsPerBlock;

  // Warp shape is not a primary API type in 3.x
  // But we can best approximate it by inspecting the TiledMma
  // For this, we make the assumption that we always have 4 warps along M, and rest along N, none along K
  // We also always round up the warp count to 4 if the tiled mma is smaller than 128 threads
  static constexpr int WarpsInMma = cute::max(4, CUTE_STATIC_V(cute::size(typename GemmKernel::TiledMma{})) / 32);
  static constexpr int WarpsInMmaM = 4;
  static constexpr int WarpsInMmaN = cute::ceil_div(WarpsInMma, WarpsInMmaM);
  using WarpCount = cutlass::gemm::GemmShape<WarpsInMmaM, WarpsInMmaN, 1>;
  using WarpShape = cutlass::gemm::GemmShape<
      CUTE_STATIC_V(cute::tile_size<0>(typename CollectiveMainloop::TiledMma{})) / WarpsInMmaM,
      CUTE_STATIC_V(cute::tile_size<1>(typename CollectiveMainloop::TiledMma{})) / WarpsInMmaN,
      CUTE_STATIC_V(cute::tile_size<2>(typename CollectiveMainloop::TiledMma{}))>;

  static int constexpr kStages = CollectiveMainloop::DispatchPolicy::Stages;

  // Inspect TiledCopy for A and B to compute the alignment size
  static int constexpr kAlignmentA = cutlass::detail::get_alignment_count_from_gmem_tiled_copy<
      typename CollectiveMainloop::GmemTiledCopyA, ElementA, typename CollectiveMainloop::TiledMma::ValTypeA>();
  static int constexpr kAlignmentB = cutlass::detail::get_alignment_count_from_gmem_tiled_copy<
      typename CollectiveMainloop::GmemTiledCopyB, ElementB, typename CollectiveMainloop::TiledMma::ValTypeB>();
  static int constexpr kAlignmentC = cutlass::detail::get_alignment_count_from_gmem_tiled_copy<
      typename CollectiveEpilogue::GmemTiledCopyC, ElementC>();
  static int constexpr kAlignmentD = cutlass::detail::get_alignment_count_from_gmem_tiled_copy<
      typename CollectiveEpilogue::GmemTiledCopyD, ElementD>();

  using EpilogueOutputOp = typename CollectiveEpilogue::ThreadEpilogueOp;

  // Split-K preserves splits that are 128b aligned
  static int constexpr kSplitKAlignment = cute::max(
      128 / sizeof_bits<ElementA>::value, 128 / sizeof_bits<ElementB>::value);

  /// Argument structure: User API
  using Arguments = typename GemmKernel::Arguments;

  struct Params{
    typename GemmKernel::Params gemm_params;
    typename SoftmaxFinalizeKernel::Params softmax_params;
  };

private:

  /// Kernel API parameters object
  Params params_;

public:

  /// Access the Params structure
  Params const& params() const {
    return params_;
  }

  /// Determines whether the GEMM can execute the given problem.
  static Status
  can_implement(Arguments const& args) {
    if (GemmKernel::can_implement(args)) {
      return Status::kSuccess;
    }
    else {
      return Status::kInvalid;
    }
  }

  /// Gets the workspace size
  static size_t
  get_workspace_size(Arguments const& args) {
    size_t workspace_bytes = 0;
    if (args.mode == GemmUniversalMode::kGemmSplitKParallel) {
      workspace_bytes += sizeof(int) * size_t(cute::size<0>(TileShape{})) * size_t(cute::size<1>(TileShape{}));
    }

    CUTLASS_TRACE_HOST("  workspace_bytes: " << workspace_bytes);

    workspace_bytes += GemmKernel::get_workspace_size(args);
    return workspace_bytes;
  }

  /// Computes the grid shape
  static dim3
  get_grid_shape(Arguments const& args, void* workspace = nullptr) {
    auto tmp_params = GemmKernel::to_underlying_arguments(args, workspace);
    return GemmKernel::get_grid_shape(tmp_params);
  }

  /// Computes the grid shape
  static dim3
  get_grid_shape(Params const& params) {
    return GemmKernel::get_grid_shape(params.gemm_params);
  }

  /// Computes the maximum number of active blocks per multiprocessor
  static int maximum_active_blocks(int /* smem_capacity */ = -1) {
    CUTLASS_TRACE_HOST("GemmUniversal::maximum_active_blocks()");
    int max_active_blocks = -1;
    int smem_size = GemmKernel::SharedStorageSize;

    // first, account for dynamic smem capacity if needed
    cudaError_t result;
    if (smem_size >= (48 << 10)) {
      CUTLASS_TRACE_HOST("  Setting smem size to " << smem_size);
      result = cudaFuncSetAttribute(
          device_kernel<GemmKernel>,
          cudaFuncAttributeMaxDynamicSharedMemorySize,
          smem_size);
      if (cudaSuccess != result) {
        result = cudaGetLastError(); // to clear the error bit
        CUTLASS_TRACE_HOST(
          "  cudaFuncSetAttribute() returned error: "
          << cudaGetErrorString(result));
        return -1;
      }
    }

    // query occupancy after setting smem size
    result = cudaOccupancyMaxActiveBlocksPerMultiprocessor(
        &max_active_blocks,
        device_kernel<GemmKernel>,
        GemmKernel::MaxThreadsPerBlock,
        smem_size);

    if (cudaSuccess != result) {
      result = cudaGetLastError(); // to clear the error bit
      CUTLASS_TRACE_HOST(
        "  cudaOccupancyMaxActiveBlocksPerMultiprocessor() returned error: "
        << cudaGetErrorString(result));
      return -1;
    }

    CUTLASS_TRACE_HOST("  max_active_blocks: " << max_active_blocks);
    return max_active_blocks;
  }

  void initialize_softmax_params(Arguments const& args, typename SoftmaxFinalizeKernel::Arguments& softmax_args){
    softmax_args.M = get<0>(args.problem_shape);
    softmax_args.dataN = get<1>(args.problem_shape);
    softmax_args.partialN = cute::ceil_div(get<1>(args.problem_shape), cute::shape<1>(TileShape{}));
    softmax_args.batch_count = get<3>(args.problem_shape);
    softmax_args.dInput = args.epilogue.dD;
    softmax_args.dPartial = args.epilogue.dTmp;
    softmax_args.dOutput = args.epilogue.dD;
    softmax_args.ptr_in = args.epilogue.ptr_D;
    softmax_args.ptr_partial_max = args.epilogue.ptr_max;
    softmax_args.ptr_partial_sum = args.epilogue.ptr_sum;
    softmax_args.ptr_out = args.epilogue.ptr_D;
  }

  /// Initializes GEMM state from arguments.
  Status
  initialize(
    Arguments const& args,
    void* workspace = nullptr,
    cudaStream_t stream = nullptr,
    CudaHostAdapter* cuda_adapter = nullptr) {

    CUTLASS_TRACE_HOST("GemmUniversal::initialize() - workspace "
      << workspace << ", stream: " << (stream ? "non-null" : "null"));

    // Initialize the workspace
    Status status = GemmKernel::initialize_workspace(args, workspace, stream, cuda_adapter);
    if (status != Status::kSuccess) {
      return status;
    }
    // Initialize the Params structure
    params_.gemm_params = GemmKernel::to_underlying_arguments(args, workspace);
    initialize_softmax_params(args, params_.softmax_params.args);

    // Don't set the function attributes - require the CudaHostAdapter to set it.
    if constexpr (kEnableCudaHostAdapter) {
      CUTLASS_ASSERT(cuda_adapter);
      return Status::kSuccess;
    }
    else {
      //
      // Account for dynamic smem capacity if needed
      //
      int smem_size = GemmKernel::SharedStorageSize;

      CUTLASS_ASSERT(cuda_adapter == nullptr);

#if !defined(CUTLASS_ENABLE_SYCL)
      if (smem_size >= (48 << 10)) {
        CUTLASS_TRACE_HOST("  Setting smem size to " << smem_size);
        cudaError_t result = cudaFuncSetAttribute(
            device_kernel<GemmKernel>,
            cudaFuncAttributeMaxDynamicSharedMemorySize,
            smem_size);
        if (cudaSuccess != result) {
          result = cudaGetLastError(); // to clear the error bit
          CUTLASS_TRACE_HOST("  cudaFuncSetAttribute() returned error: " << cudaGetErrorString(result));
          return Status::kErrorInternal;
        }
      }
#endif
    }
    return Status::kSuccess;
  }

  /// Update API is preserved in 3.0, but does not guarantee a lightweight update of params.
  Status
  update(Arguments const& args, void* workspace = nullptr) {
    CUTLASS_TRACE_HOST("GemmUniversal()::update() - workspace: " << workspace);

    size_t workspace_bytes = get_workspace_size(args);
    if (workspace_bytes > 0 && nullptr == workspace) {
      return Status::kErrorWorkspaceNull;
    }

    params_.gemm_params = GemmKernel::to_underlying_arguments(args, workspace);
    initialize_softmax_params(args, params_.softmax_params.args);
    return Status::kSuccess;
  }

  /// Primary run() entry point API that is static allowing users to create and manage their own params.
  /// Supplied params struct must be construct by calling GemmKernel::to_underling_arguments()
  static Status
  run(Params& params,
      cudaStream_t stream = nullptr,
      CudaHostAdapter *cuda_adapter = nullptr,
      bool launch_with_pdl = false) {
    CUTLASS_TRACE_HOST("GemmUniversal::run()");
    dim3 const block = GemmKernel::get_block_shape();
    dim3 const grid = get_grid_shape(params);

    // configure smem size and carveout
    int smem_size = GemmKernel::SharedStorageSize;

    Status launch_result{ Status::kSuccess };
    // Use extended launch API only for mainloops that use it
    if constexpr (GemmKernel::ArchTag::kMinComputeCapability >= 90) {
#if !defined(CUTLASS_ENABLE_SYCL)
      constexpr bool is_static_1x1x1 = cute::is_static_v<typename GemmKernel::DispatchPolicy::ClusterShape> and
                                       cute::size(typename GemmKernel::DispatchPolicy::ClusterShape{}) == 1;
      dim3 cluster(cute::size<0>(typename GemmKernel::DispatchPolicy::ClusterShape{}),
                   cute::size<1>(typename GemmKernel::DispatchPolicy::ClusterShape{}),
                   cute::size<2>(typename GemmKernel::DispatchPolicy::ClusterShape{}));
      void* kernel_params[] = {&params};

      if constexpr (kEnableCudaHostAdapter) {
        //
        // Use the cuda host adapter
        //
        CUTLASS_ASSERT(cuda_adapter);
        if (cuda_adapter) {

          if (launch_with_pdl) {
            CUTLASS_TRACE_HOST(
              "GemmUniversal::run() does not support launching with PDL and a custom cuda adapter.");
            return Status::kErrorInternal;
          }
          launch_result = cuda_adapter->launch(grid,
                                               cluster,
                                               block,
                                               smem_size,
                                               stream,
                                               kernel_params,
                                               0);
        }
        else {
          return Status::kErrorInternal;
        }
      }
      else {
        CUTLASS_ASSERT(cuda_adapter == nullptr);
        void const* kernel = (void const*) device_kernel<GemmKernel>;
        if constexpr (GemmKernel::ArchTag::kMinComputeCapability == 90) {
          if (is_static_1x1x1 && not launch_with_pdl) {
            device_kernel<GemmKernel><<<grid, block, smem_size, stream>>>(params);
          }
          else {
            launch_result = ClusterLauncher::launch(
              grid, cluster, block, smem_size, stream, kernel, kernel_params, launch_with_pdl);
          }
        }
      }
#endif
    }
    else {
      launch_result = Status::kSuccess;
      if constexpr (kEnableCudaHostAdapter) {
        CUTLASS_ASSERT(cuda_adapter);
        if (cuda_adapter) {
          void* kernel_params[] = {&params.gemm_params};

          launch_result = cuda_adapter->launch(
            grid, block, smem_size, stream, kernel_params, 0
          );

        }
        else {
          return Status::kErrorInternal;
        }
      }
      else {
        CUTLASS_ASSERT(cuda_adapter == nullptr);
#if defined(CUTLASS_ENABLE_SYCL)
        const auto sycl_block = syclcompat::dim3(block.x, block.y, block.z);
        const auto sycl_grid = syclcompat::dim3(grid.x, grid.y, grid.z);

        using namespace syclcompat::experimental;
#if defined (SYCL_INTEL_TARGET)
        auto event = launch<device_kernel<GemmKernel>>(launch_policy{
          sycl_grid, sycl_block, local_mem_size{static_cast<std::size_t>(smem_size)}, 
          kernel_properties{sycl_exp::sub_group_size<DispatchPolicy::SubgroupSize>}
        }, params.gemm_params);
#else
        auto event = launch<device_kernel<GemmKernel>>(launch_policy{
          sycl_grid, sycl_block, local_mem_size{static_cast<std::size_t>(smem_size)}},
          params.gemm_params);
#endif
        const auto sycl_block2 = syclcompat::dim3(32, std::min(32, params.softmax_params.args.M), 1);
        const auto sycl_grid2 = syclcompat::dim3(cute::ceil_div(params.softmax_params.args.M, sycl_block2.x), 
                                                 params.softmax_params.args.batch_count, 
                                                 1);
        auto event2 = launch<device_kernel<SoftmaxFinalizeKernel>>(launch_policy{
          sycl_grid2, sycl_block2, local_mem_size{SoftmaxFinalizeKernel::SharedStorageSize}},
          params.softmax_params);
        EventManager::getInstance().addEvent(event2);
#else
        device_kernel<GemmKernel><<<grid, block, smem_size, stream>>>(params.gemm_params);
#endif
      }
    }

    cudaError_t result = cudaGetLastError();
    if (cudaSuccess == result && Status::kSuccess == launch_result) {
      return Status::kSuccess;
    }
    else {
      CUTLASS_TRACE_HOST("  Kernel launch failed. Reason: " << result);
      return Status::kErrorInternal;
    }
  }

  //
  // Non-static launch overloads that first create and set the internal params struct of this kernel handle.
  //

  /// Launches the kernel after first constructing Params internal state from supplied arguments.
  Status
  run(
    Arguments const& args,
    void* workspace = nullptr,
    cudaStream_t stream = nullptr,
    CudaHostAdapter *cuda_adapter = nullptr,
    bool launch_with_pdl = false
  ) {
    Status status = initialize(args, workspace, stream, cuda_adapter);

    if (Status::kSuccess == status) {
      status = run(params_, stream, cuda_adapter, launch_with_pdl);
    }
    return status;
  }

  /// Launches the kernel after first constructing Params internal state from supplied arguments.
  Status
  operator()(
    Arguments const& args,
    void* workspace = nullptr,
    cudaStream_t stream = nullptr,
    CudaHostAdapter *cuda_adapter = nullptr,
    bool launch_with_pdl = false) {
    return run(args, workspace, stream, cuda_adapter, launch_with_pdl);
  }

  /// Overload that allows a user to re-launch the same kernel without updating internal params struct.
  Status
  run(
    cudaStream_t stream = nullptr,
    CudaHostAdapter *cuda_adapter = nullptr,
    bool launch_with_pdl = false) {
    return run(params_, stream, cuda_adapter, launch_with_pdl);
  }

  /// Overload that allows a user to re-launch the same kernel without updating internal params struct.
  Status
  operator()(cudaStream_t stream = nullptr, CudaHostAdapter *cuda_adapter = nullptr, bool launch_with_pdl = false) {
    return run(params_, stream, cuda_adapter, launch_with_pdl);
  }
};

////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::device

////////////////////////////////////////////////////////////////////////////////
