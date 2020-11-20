/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
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
/*

This example shows fusing two GEMM mainloops into one kernel. The first GEMM computes relu(alpha*A*B) and 
the second GEMM computes relu(alpha*A*B+beta*C). The performance measuring environment compares against
two unfused GEMM operations, demonstrating a speedup of the fused kernel on the 
NVIDIA Turing GPU architecture.

Problem size:
  GEMM1 (M,N,K): 128*1600, 64, 576
  GEMM2 (M,N,K): 128*1600, 128, 64

Note that GEMM1_N = GEMM2_K

The example requires the number of threadblocks be the same across 2 GEMMs and 
thread_block_tile_N = problem_N so the data required by each layer is threadblock-resident. It 
also requires warp_tile_N = thread_block_tile_N so the data required by each warp is 
register-file-resident.

Performance:
  - fp16 on Tesla T4 @ 1590MHz (non-fused vs. fused): 1.39011 ms vs. 1.26035 ms
  - int8 on Tesla T4 @ 1590MHz (non-fused vs. fused): 0.751759 ms vs. 0.62971 ms
  - fp16 on Quadro RTX 8000 @ 1890MHz (non-fused vs. fused): 0.721144 ms vs. 0.629864 ms
  - int8 on Quadro RTX 8000 @ 1890MHz (non-fused vs. fused): 0.379049 ms vs. 0.324764 ms
  - int8 on GA100 @ 1200MHz (non-fused vs. fused): 0.153795 ms vs. 0.129874 ms

*/

#include "b2b_gemm_f16t_f16n_f16t_tensor_op_f16_sm75.h"
#include "b2b_gemm_s8n_s8t_s8n_tensor_op_s32_sm75.h"
#include "b2b_gemm_s8n_s8t_s8n_tensor_op_s32_sm80.h"

int run() {

#if defined(CUTLASS_ARCH_MMA_SM80_SUPPORTED)
  run_nonfused_gemm_s8_sm80();
  run_fused_gemm_s8_sm80();
#elif defined(CUTLASS_ARCH_MMA_SM75_SUPPORTED)
  run_nonfused_gemm_f16();
  run_fused_gemm_f16();
  run_nonfused_gemm_s8();
  run_fused_gemm_s8();
#endif

  return 0;
}

int main() {

  bool notSupported = false;

  // Turing Tensor Core operations exposed with mma.sync are first available in CUDA 10.2.
  //
  // CUTLASS must be compiled with CUDA 10.1 Toolkit to run these examples.
  if (!(__CUDACC_VER_MAJOR__ > 10 || (__CUDACC_VER_MAJOR__ == 10 && __CUDACC_VER_MINOR__ >= 2))) {
    std::cerr << "Turing Tensor Core operations must be compiled with CUDA 10.2 Toolkit or later." << std::endl;

    notSupported = true;
  }

  cudaDeviceProp props;

  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (error != cudaSuccess) {
    std::cerr << "cudaGetDeviceProperties() returned an error: " << cudaGetErrorString(error) << std::endl;
    return -1;
  }

  if (!(props.major * 10 + props.minor >= 75)) {
    std::cerr << "Turing Tensor Ops must be run on a machine with compute capability at least 75."
              << std::endl;

    notSupported = true;
  }

  if (notSupported) {
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  return run();
}

