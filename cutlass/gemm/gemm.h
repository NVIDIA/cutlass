/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
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
/*! \file
    \brief Implements a software-pipelined efficient GEMM.
*/
#pragma once

#if !defined(__CUDACC_RTC__)
#include <cuda.h>
#endif

#include <cutlass/coord.h>
#include <cutlass/util/platform.h>

namespace cutlass {
namespace gemm {

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Gemm_>
__global__ void gemm_kernel(typename Gemm_::Params params) {
  // Declare shared memory.
  __shared__ typename Gemm_::SharedStorage shared_storage;

  // Construct the GEMM object.
  Gemm_ gemm(params, shared_storage);
  // Run GEMM.
  gemm.multiply_add();
}

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Scalar_, typename Index_ = int>
struct GemmDesc {
  /// The dimensions of the GEMM.
  Index_ m, n, k;
  /// The alpha/beta scaling values.
  Scalar_ alpha, beta;
  /// The source matrix A.
  void const* d_a;
  /// The stride for A.
  Index_ lda;
  /// The source matrix B.
  void const* d_b;
  /// The stride for B.
  Index_ ldb;
  /// The source matrix C.
  void const* d_c;
  /// The stride for C.
  Index_ ldc;
  /// The destination matrix D.
  void* d_d;
  /// The stride for D.
  Index_ ldd;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmTraits_>
struct Gemm {
  /// This class.
  typedef Gemm<GemmTraits_> This_;
  /// The traits.
  typedef GemmTraits_ Traits;
  /// The shared storage.
  typedef typename Traits::SharedStorage SharedStorage;

  /// The scalar for A.
  typedef typename Traits::ScalarA ScalarA;
  /// The scalar for B.
  typedef typename Traits::ScalarB ScalarB;
  /// The scalar in the epilogue.
  typedef typename Traits::Epilogue::Scalar ScalarEpilogue;
  /// The scalar for C.
  typedef typename Traits::Epilogue::ScalarC ScalarC;
  /// The scalar for D.
  typedef typename Traits::Epilogue::ScalarD ScalarD;
  /// The index.
  typedef typename Traits::Index Index;

  /// The number of threads.
  static int const kThreads = Traits::GemmConfig::kThreads;

  /// The params.
  struct Params : public Traits::Params {
    CUTLASS_HOST_DEVICE int initialize(Index m,
                                       Index n,
                                       Index k,
                                       ScalarEpilogue alpha,
                                       ScalarA const* d_a,
                                       Index lda,
                                       ScalarB const* d_b,
                                       Index ldb,
                                       ScalarEpilogue beta,
                                       ScalarC const* d_c,
                                       Index ldc,
                                       ScalarD* d_d,
                                       Index ldd) {
      GemmDesc<ScalarEpilogue, Index> desc;
      desc.m = m;
      desc.n = n;
      desc.k = k;
      desc.alpha = alpha;
      desc.beta = beta;
      desc.d_a = reinterpret_cast<void const*>(d_a);
      desc.lda = lda;
      desc.d_b = reinterpret_cast<void const*>(d_b);
      desc.ldb = ldb;
      desc.d_c = reinterpret_cast<void const*>(d_c);
      desc.ldc = ldc;
      desc.d_d = reinterpret_cast<void*>(d_d);
      desc.ldd = ldd;
      return Traits::Params::initialize(desc);
    }
  };

#if !defined(__CUDACC_RTC__)
  /// Launch the kernel.
  static __host__ cudaError_t launch(Params const& params,
                                     cudaStream_t stream = cudaStreamDefault) {
    // Setup the grid.
    dim3 grid;
    grid.x = (params.m + Traits::OutputTile::kW - 1) / Traits::OutputTile::kW;
    grid.y = (params.n + Traits::OutputTile::kH - 1) / Traits::OutputTile::kH;

    // The number of threads.
    dim3 block;
    block.x = kThreads;

    // Launch the kernel.
    void const* params_ = reinterpret_cast<void const*>(&params);

    return cudaLaunchKernel(reinterpret_cast<void*>(&gemm_kernel<This_>),
                            grid,
                            block,
                            const_cast<void**>(&params_),
                            0,
                            stream);
  }

  /// Launch the kernel.
  static __host__ cudaError_t launch(CUfunction kernel,
                                     Params const& params,
                                     CUstream stream = CU_STREAM_LEGACY) {
    // Setup the grid.
    dim3 grid;
    grid.x = (params.m + Traits::OutputTile::kW - 1) / Traits::OutputTile::kW;
    grid.y = (params.n + Traits::OutputTile::kH - 1) / Traits::OutputTile::kH;

    // The number of threads.
    dim3 block;
    block.x = kThreads;

    // Launch the kernel.
    void* params_[] = {const_cast<void*>(reinterpret_cast<void const*>(&params))};

    // return cudaLaunchKernel(reinterpret_cast<void*>(&gemm_kernel<This_>), grid, block,
    //  const_cast<void**>(&params_), 0, stream);
    CUresult result = cuLaunchKernel(
        kernel, grid.x, grid.y, grid.z, block.x, block.y, block.z, 0, stream, params_, 0);

    if (result != CUDA_SUCCESS) {
      return cudaErrorLaunchFailure;
    }
    return cudaSuccess;
  }

#endif

  /// Ctor.
  CUTLASS_DEVICE Gemm(Params const& params_, SharedStorage& shared_storage_)
      : params(params_), shared_storage(shared_storage_) {}

  /// Do the GEMM.
  CUTLASS_DEVICE void multiply_add() {
    // Swizzle the IDs of the block (to enable better cache behavior).
    typename Traits::BlockSwizzle block_swizzle;
    dim3 block = block_swizzle.swizzle();

    // Scale the id.
    block.x *= Traits::OutputTile::kW;
    block.y *= Traits::OutputTile::kH;

    // We may want to use shared memory to clear the registers.
    typedef typename Traits::ClearAccumulators ClearAccumulators;

    // The streams to read A/B from global memory to shared memory.
    typename Traits::GlobalLoadStream global_stream(params, shared_storage, block);

    // Create the accumulator clear.
    ClearAccumulators clear(shared_storage.main_loop.clear);

    /// Define the mainloop iteration size
    typedef typename Traits::MultiplyAdd MultiplyAdd;

    // By how much we unroll the main loop.
    Index const kUnroll = static_cast<Index>(MultiplyAdd::AccumulatorsPerWarp::kD);

    // If we do not have enough steps in the main loop, trigger the residue code.
    if (params.k < kUnroll) {
      global_stream.residue(params.k, true);
    }

    // Fetch the fragments for A and B from global memory.
    global_stream.copy();

    // Copy the elements to shared memory (after transformation if needed).
    global_stream.commit();

    // Make sure the data is in shared memory.
    Traits::shared_store_fence(false);

    // The unrolling steps for the main loop.
    int const kUnrollingSteps =
        MultiplyAdd::AccumulatorsPerWarp::kD / MultiplyAdd::InstructionShape::kD;

    // Make sure we have at least 2 unrolling steps or our pipeling is not going to work.
    static_assert(kUnrollingSteps >= 2, "The pipelining assumes at least two steps");

    // The stream of data from shared memory to fragments.
    typename Traits::SharedLoadStream shared_load_stream(params, shared_storage);

    // Trigger the copy from shared memory for the 1st stream.
    shared_load_stream.copy(0);

    // Allocate the accumulators.
    typename MultiplyAdd::Accumulators accumulators;
    // Clear the accumulators.
    clear.clear(accumulators);

    // Enter the main loop and iterate.
    typedef typename Traits::Index Index;
    for (Index outer_k = params.k - kUnroll; outer_k > -kUnroll; outer_k -= kUnroll) {
      // If that's the last "load iteration" update the predicates.
      int const is_residue = outer_k <= kUnroll;
      if (is_residue) {
        global_stream.residue(outer_k);
      }

      // Load data for the next iteration of the main loop.
      global_stream.copy();

      CUTLASS_PRAGMA_UNROLL
      for (int step = 0; step < kUnrollingSteps - 1; ++step) {
        // Trigger the copy from shared memory for the next A/B values.
        shared_load_stream.copy(step + 1);
        // Make sure the values are available for the current iteration to do the multiply-add.
        shared_load_stream.commit(step);

        // Do the math on the fragments of the current iteration.
        MultiplyAdd multiply_add;
        multiply_add.multiply_add(shared_load_stream.fragment_a(step),
                                  shared_load_stream.fragment_b(step),
                                  accumulators,
                                  accumulators);
      }

      // Make sure the data from shared memory has been entirely consumed.
      Traits::shared_load_fence(true);

      // Commit the data in shared memory for A/B.
      global_stream.commit();

      // Make sure the data is in shared memory.
      Traits::shared_store_fence(true);

      // Move to the next stage for the load (if it makes sense).
      shared_load_stream.inc_stage();
      // Trigger the copy from shared memory for the next loop iteration.
      shared_load_stream.copy(0);
      // Make sure the values are available for the current iteration to do the multiply-add.
      shared_load_stream.commit(kUnrollingSteps - 1);

      // Do the math on the fragments of the current iteration.
      MultiplyAdd multiply_add;
      multiply_add.multiply_add(shared_load_stream.fragment_a(kUnrollingSteps - 1),
                                shared_load_stream.fragment_b(kUnrollingSteps - 1),
                                accumulators,
                                accumulators);
    }

    // Epilogue.
    typedef typename Traits::Epilogue Epilogue;
    Epilogue epilogue(params.epilogue, shared_storage.epilogue, params.m, params.n);
    epilogue.epilogue(cutlass::make_Coord(0, block.y, block.x), accumulators);
  }

  /// The params.
  Params const& params;
  /// The shared storage.
  SharedStorage& shared_storage;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace gemm
}  // namespace cutlass
