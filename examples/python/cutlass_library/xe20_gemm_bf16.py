#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2025 Intel Corporation, All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###############################################################################

"""
Test the generated CUTLASS GEMM kernel (sycl_tla_gemm_xe20_bf16)
"""

import ctypes
from ctypes import c_void_p, c_int, c_size_t, c_uint8, c_uint16, POINTER, byref
import numpy as np
from ml_dtypes import bfloat16
import time
from pathlib import Path


def test_sycl_tla_gemm_xe20_bf16():
    """Test the compiled sycl_tla_gemm_xe20_bf16 function"""
    
    # Load the shared library
    lib_path = Path(__file__).parent / '../../../build/examples/11_xe20_cutlass_library/libxe20_cutlass_library_bf16.so'
    if not lib_path.exists():
        print(f"Error: {lib_path} not found!")
        print("Please build the library first: ninja xe20_cutlass_library_bf16")
        return
    
    lib = ctypes.CDLL(str(lib_path))
    
    # Define function signature
    # int sycl_tla_gemm_xe20_bf16(
    #   const cutlass::bfloat16_t* X, const cutlass::bfloat16_t* W, const cutlass::bfloat16_t* Bias, cutlass::bfloat16_t* Y,
    #   const int M, const int N, const int K, const int B,
    #   const int lda, const int ldb, const int ldc, const int ldd,
    #   const int X_offset, const int W_offset, const int Bias_offset, const int Y_offset,
    #   const uint8_t swizzle,
    #   size_t* workspace_size, uint8_t* workspace, sycl::queue* stream)
    lib.sycl_tla_gemm_xe20_bf16.argtypes = [
        c_void_p,  # X (input A)
        c_void_p,  # W (input B)
        c_void_p,  # Bias (input Bias)
        c_void_p,  # Y (output)
        c_int,     # M
        c_int,     # N
        c_int,     # K
        c_int,     # B (batch)
        c_int,     # lda
        c_int,     # ldb
        c_int,     # ldc
        c_int,     # ldd
        c_int,     # X_offset
        c_int,     # W_offset
        c_int,     # Bias_offset
        c_int,     # Y_offset
        c_uint8,   # swizzle
        POINTER(c_size_t),  # workspace_size
        c_void_p,  # workspace
        c_void_p,  # stream (sycl::queue*)
    ]
    lib.sycl_tla_gemm_xe20_bf16.restype = c_uint16
    
    print("="*80)
    print("Testing sycl_tla_gemm_xe20_bf16 (BF16 256x256x32 GEMM With Bias)")
    print("="*80)
    
    # Problem dimensions (matching the kernel tile: 256x256x32)
    M = 256
    N = 256
    K = 32
    B = 1  # batch size

    # # Use small problem shape for debugging
    # M = 8
    # N = 8
    # K = 8
    # B = 1

    print(f"\nProblem size: M={M}, N={N}, K={K}, B={B}")
    print(f"  A: {M} x {K} (bfloat16, row-major)")
    print(f"  B: {K} x {N} (bfloat16, row-major)")
    print(f"  C: {M} x {N} (bfloat16, column-major)")
    print(f"  D: {M} x {N} (bfloat16, row-major)")
    
    # Leading dimensions (column-major for inputs, row-major for output)
    lda = K   # MxK row-major: leading dimension is K
    ldb = N   # KXN row-major: leading dimension is N
    ldc = M   # MXN column-major: leading dimension is M
    ldd = N   # MXN row-major: leading dimension is N
    
    print(f"\nLeading dimensions: lda={lda}, ldb={ldb}, ldc={ldc}, ldd={ldd}")
    
    # Initialize input/output matrices with random values
    X = np.random.uniform(low=0, high=100, size=(M * K)).astype(bfloat16)
    W = np.random.uniform(low=0, high=100, size=(K * N)).astype(bfloat16)
    Bias = np.random.uniform(low=0, high=100, size=(M * N)).astype(bfloat16)
    Y = np.zeros(M * N, dtype=bfloat16)

    # # Initialize inputs with known values for debugging
    # X    = 128 * np.ones(M * K, dtype=bfloat16)
    # W    =   2 * np.ones(K * N, dtype=bfloat16)
    # Bias = 100 * np.ones(M * N, dtype=bfloat16)
    # Bias[ 8] = 111
    # Bias[16] = 222
    # Bias[24] = 333
    # Y = np.zeros(M * N, dtype=bfloat16)

    print(f"\nAllocated matrices:")
    print(f"  X: {X.nbytes} bytes")
    print(f"  W: {W.nbytes} bytes")
    print(f"  Y: {Y.nbytes} bytes")
    
    # Query workspace size
    print("\n1. Querying workspace size...")
    workspace_size = c_size_t(0)
    result = lib.sycl_tla_gemm_xe20_bf16(
        c_void_p(),  # X (not needed for workspace query)
        c_void_p(),  # W
        c_void_p(),  # Bias
        c_void_p(),  # Y
        M, N, K, B,
        lda, ldb, ldc, ldd,
        0, 0, 0, 0,  # offsets
        1,  # swizzle
        byref(workspace_size),
        c_void_p(),  # workspace
        c_void_p(),  # stream (NULL = use default)
    )
    
    if result != 0:
        print(f"   ✗ Workspace query failed with code {result}")
        return
    
    print(f"   ✓ Workspace required: {workspace_size.value} bytes")
    
    # Allocate workspace if needed
    workspace = None
    workspace_ptr = c_void_p()
    if workspace_size.value > 0:
        workspace = np.zeros(workspace_size.value, dtype=np.uint8)
        workspace_ptr = workspace.ctypes.data_as(c_void_p)
        print(f"   ✓ Workspace allocated")
    
    # Run GEMM
    print("\n2. Executing GEMM...")
    
    X_ptr = X.ctypes.data_as(c_void_p)
    W_ptr = W.ctypes.data_as(c_void_p)
    Bias_ptr = Bias.ctypes.data_as(c_void_p)
    Y_ptr = Y.ctypes.data_as(c_void_p)

    # Warmup run
    result = lib.sycl_tla_gemm_xe20_bf16(
        X_ptr, W_ptr, Bias_ptr, Y_ptr,
        M, N, K, B,
        lda, ldb, ldc, ldd,
        0, 0, 0, 0,  # offsets
        1,  # swizzle
        None,  # workspace_size (None = execute mode, not query)
        workspace_ptr,
        c_void_p(),  # stream (NULL = use default)
    )

    if result != 0:
        print(f"   ✗ GEMM execution failed with code {result}")
        return
    
    print(f"   ✓ Warmup run completed")
    
    # Benchmark
    print("\n3. Benchmarking...")
    num_runs = 10
    times = []
    
    for i in range(num_runs):
        start = time.time()
        result = lib.sycl_tla_gemm_xe20_bf16(
            X_ptr, W_ptr, Bias_ptr, Y_ptr,
            M, N, K, B,
            lda, ldb, ldc, ldd,
            0, 0, 0, 0,
            1,
            None,  # workspace_size (None = execute mode)
            workspace_ptr,
            c_void_p(),
        )
        elapsed = time.time() - start
        
        if result != 0:
            print(f"   ✗ Run {i+1} failed with code {result}")
            continue
        
        times.append(elapsed)
    
    if not times:
        print("   ✗ All runs failed!")
        return
    
    # Calculate statistics
    avg_time = np.mean(times)
    min_time = np.min(times)
    max_time = np.max(times)
    std_time = np.std(times)
    
    # Calculate FLOPS (2*M*N*K for GEMM)
    flops = 2 * M * N * K
    avg_gflops = flops / avg_time / 1e9
    peak_gflops = flops / min_time / 1e9
    
    print(f"\n{'='*80}")
    print(f"Performance Results ({num_runs} runs)")
    print(f"{'='*80}")
    print(f"  Average time: {avg_time*1000:.3f} ms")
    print(f"  Min time:     {min_time*1000:.3f} ms")
    print(f"  Max time:     {max_time*1000:.3f} ms")
    print(f"  Std dev:      {std_time*1000:.3f} ms")
    print(f"")
    print(f"  Average GFLOPS: {avg_gflops:.2f}")
    print(f"  Peak GFLOPS:    {peak_gflops:.2f}")
    print(f"{'='*80}")
    
    # Check output (basic sanity check)
    non_zero = np.count_nonzero(Y)
    print(f"\nOutput sanity check:")
    print(f"  Non-zero elements: {non_zero}/{Y.size}")
    print(f"  Output range: [{Y.min()}, {Y.max()}]")
    
    return avg_gflops


def benchmark_multiple_sizes():
    """Benchmark different problem sizes"""
    
    print("\n" + "="*80)
    print("Benchmarking Multiple Problem Sizes")
    print("="*80)
    
    # Test different sizes (all should be compatible with 256x256x32 tile)
    sizes = [
        (256, 256, 32),
        (512, 512, 32),
        (256, 256, 64),
        (512, 512, 64),
        (1024, 1024, 32),
    ]
    
    # Note: This would require modifying the function to accept variable sizes
    # For now, the kernel is hard-coded to 256x256x32
    print("\nNote: Current kernel is optimized for 256x256x32 tile size")
    print("Multi-size benchmarking would require different kernel configurations")


if __name__ == "__main__":
    try:
        gflops = test_sycl_tla_gemm_xe20_bf16()
        if gflops:
            print(f"\n✓ Test completed successfully!")
            print(f"  Average performance: {gflops:.2f} GFLOPS")
    except Exception as e:
        print(f"\n✗ Test failed with exception:")
        print(f"  {e}")
        import traceback
        traceback.print_exc()
