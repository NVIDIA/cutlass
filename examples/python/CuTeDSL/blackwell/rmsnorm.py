# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

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

import argparse
import ctypes
import functools
import math
from typing import Optional, Tuple, Union

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
from cutlass import Boolean, Float32, Int32, Int64
from cutlass.cute.runtime import make_ptr

# Support both direct execution and module import
try:
    from .reduce import row_reduce
except ImportError:
    from reduce import row_reduce

"""
RMSNorm: Root Mean Square Layer Normalization for Hopper & Blackwell (SM90+)
====================================================================

A high-performance RMSNorm implementation using CuTe DSL with cluster-based
reduction for large hidden dimensions.

RMSNorm computes: y = x / sqrt(mean(x²) + eps) * weight

Key Features:
-------------
1. CLUSTER SYNCHRONIZATION (SM90+)
   - Multiple CTAs cooperate to process large N dimensions
   - Each CTA handles N/cluster_n elements, then reduces across the cluster
   - Uses mbarrier for efficient cross-CTA synchronization

2. ARCHITECTURE-SPECIFIC TUNING
   - SM80 (Ampere): Single-CTA execution (cluster_n=1)
   - SM90 (Hopper): Cluster support enabled for large N
   - SM100 (Blackwell): Same as SM90

3. VECTORIZED MEMORY ACCESS
   - 128-bit vectorized loads/stores for optimal memory throughput
   - TiledCopy abstraction for organized gmem↔smem↔rmem transfers

Cluster Size Selection (FP16):
------------------------------
- N <= 16K: cluster_n = 1 (single CTA)
- N <= 32K: cluster_n = 2
- N <= 64K: cluster_n = 4
- N <= 128K: cluster_n = 8
- Larger: cluster_n = 16

To run this example:

.. code-block:: bash

    python examples/python/CuTeDSL/blackwell/rmsnorm.py --M 2048 --N 4096 --dtype BFloat16
    python examples/python/CuTeDSL/blackwell/rmsnorm.py --M 2048 --N 4096 --dtype BFloat16 --benchmark
    python examples/python/CuTeDSL/blackwell/rmsnorm.py --M 2048 --N 32768 --dtype BFloat16 --benchmark

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/python/CuTeDSL/blackwell/rmsnorm.py --M 2048 --N 4096 --dtype BFloat16 --skip_ref_check
"""

# =============================================================================
# Architecture Detection
# =============================================================================


@functools.lru_cache(maxsize=16)
def get_sm_version(device: Optional[Union[int, torch.device, str]] = None) -> int:
    """Get the SM (compute capability) version of a CUDA device."""
    if not torch.cuda.is_available():
        return 80  # Default fallback
    props = torch.cuda.get_device_properties(device)
    return props.major * 10 + props.minor


def supports_cluster() -> bool:
    """Check if the current device supports cluster operations (SM90+)."""
    return get_sm_version() >= 90


# =============================================================================
# Predicate Utility
# =============================================================================


@cute.jit
def predicate_k(tXcX: cute.Tensor, limit: int) -> cute.Tensor:
    """Create predicate tensor for bounds checking."""
    tXpX = cute.make_rmem_tensor(
        cute.make_layout(
            (cute.size(tXcX, mode=[0, 1]), cute.size(tXcX, mode=[1]), cute.size(tXcX, mode=[2])),
            stride=(cute.size(tXcX, mode=[2]), 0, 1),
        ),
        Boolean,
    )
    for rest_v in cutlass.range_constexpr(tXpX.shape[0]):
        for rest_k in cutlass.range_constexpr(tXpX.shape[2]):
            tXpX[rest_v, 0, rest_k] = cute.elem_less(tXcX[(0, rest_v), 0, rest_k][1], limit)
    return tXpX


# =============================================================================
# RMSNorm Configuration Class
# =============================================================================


class RMSNormConfig:
    """
    Configuration for the RMSNorm kernel.

    This class encapsulates all kernel configuration computed once at initialization,
    following CuTe-DSL conventions from official CUTLASS examples.
    """

    COPY_BITS = 128  # 128-bit vectorized loads

    def __init__(
        self,
        dtype: type[cutlass.Numeric],
        N: int,
        has_weight: bool = True,
        sm_version: int | None = None,
    ):
        self.dtype = dtype
        self.N = N
        self.has_weight = has_weight
        self.sm_version = sm_version if sm_version is not None else get_sm_version()

        # Vector size for 128-bit loads
        self.vec_size = self.COPY_BITS // dtype.width

        # Compute cluster size (SM90+ only)
        self.cluster_n = self._compute_cluster_n(N, dtype, self.sm_version)

        # N per CTA for cluster case
        self.N_per_cta = N // self.cluster_n

        # Thread configuration using static methods
        self.threads_per_row = self._compute_threads_per_row(self.N_per_cta)
        self.num_threads = self._compute_num_threads(self.N_per_cta)

        # Derived values
        self.num_vec_blocks = max(
            1, (self.N_per_cta // self.vec_size + self.threads_per_row - 1) // self.threads_per_row
        )
        self.rows_per_block = self.num_threads // self.threads_per_row
        self.cols_per_tile = self.vec_size * self.num_vec_blocks * self.threads_per_row
        self.warps_per_row = max(self.threads_per_row // 32, 1)

    @staticmethod
    def _compute_cluster_n(N: int, dtype: type[cutlass.Numeric], sm_version: int) -> int:
        """Compute optimal cluster size based on N and architecture."""
        if sm_version < 90:
            return 1

        if dtype.width == 16:  # FP16/BF16
            if N <= 16 * 1024:
                return 1
            elif N <= 32 * 1024:
                return 2
            elif N <= 64 * 1024:
                return 4
            elif N <= 128 * 1024:
                return 8
            else:
                return 16
        else:  # FP32
            if N <= 32 * 1024:
                return 1
            elif N <= 64 * 1024:
                return 2
            elif N <= 128 * 1024:
                return 4
            elif N <= 256 * 1024:
                return 8
            else:
                return 16

    @staticmethod
    def _compute_threads_per_row(N_per_cta: int) -> int:
        """Compute optimal threads per row based on N per CTA."""
        if N_per_cta <= 64:
            return 8
        elif N_per_cta <= 128:
            return 16
        elif N_per_cta <= 3072:
            return 32
        elif N_per_cta <= 6144:
            return 64
        elif N_per_cta <= 16384:
            return 128
        else:
            return 256

    @staticmethod
    def _compute_num_threads(N_per_cta: int) -> int:
        """Compute total threads per block."""
        return 128 if N_per_cta <= 16384 else 256

    @staticmethod
    def _make_tv_layout(
        threads_per_row: int,
        rows_per_block: int,
        vec_size: int,
        num_vec_blocks: int,
    ) -> tuple:
        """Create Thread-Value layout for coalesced vectorized memory access."""
        shape = (
            (threads_per_row, rows_per_block),
            (vec_size, num_vec_blocks),
        )
        stride = (
            (vec_size * rows_per_block, 1),
            (rows_per_block, rows_per_block * vec_size * threads_per_row),
        )
        return shape, stride

    def smem_size_in_bytes(self) -> int:
        """Calculate shared memory requirement in bytes."""
        tile_bytes = self.rows_per_block * self.cols_per_tile * (self.dtype.width // 8)
        reduction_bytes = self.rows_per_block * self.warps_per_row * self.cluster_n * 4
        mbar_bytes = 8 if self.cluster_n > 1 else 0
        return tile_bytes + reduction_bytes + mbar_bytes


# =============================================================================
# RMSNorm Kernel Class
# =============================================================================


class RMSNormKernel:
    """
    RMSNorm kernel with cluster synchronization for large N.

    Features:
    - Cluster-based reduction for large N (SM90+)
    - Multiple CTAs cooperate via mbarrier
    - Single reduction (sum of squares) with cluster-level aggregation

    Example:
        >>> kernel = RMSNormKernel(cutlass.Float16, N=4096)
        >>> kernel(x_ptr, w_ptr, o_ptr, M, eps, stream)
    """

    def __init__(
        self,
        dtype: cutlass.Numeric,
        N: int,
        has_weight: bool = True,
        config: RMSNormConfig | None = None,
    ):
        # Use provided config or create new one
        if config is not None:
            self.cfg = config
        else:
            self.cfg = RMSNormConfig(dtype, N, has_weight)

        # Expose key attributes for convenience
        self.dtype = self.cfg.dtype
        self.N = self.cfg.N
        self.has_weight = self.cfg.has_weight
        self.cluster_n = self.cfg.cluster_n

    @cute.jit
    def __call__(
        self,
        x_ptr: cute.Pointer,
        w_ptr: cute.Pointer | None,
        o_ptr: cute.Pointer,
        M: Int32,
        eps: Float32,
        stream: cuda.CUstream,
    ):
        """Host function to launch the RMSNorm kernel."""
        cfg = self.cfg

        # Create CuTe tensors from raw pointers
        mX = cute.make_tensor(
            x_ptr,
            cute.make_layout((M, cfg.N), stride=(cfg.N, 1)),
        )
        mO = cute.make_tensor(
            o_ptr,
            cute.make_layout((M, cfg.N), stride=(cfg.N, 1)),
        )

        if cutlass.const_expr(cfg.has_weight and w_ptr is not None):
            mW = cute.make_tensor(
                w_ptr,
                cute.make_layout((cfg.N,), stride=(1,)),
            )
        else:
            mW = None

        # Create TV layout using static helper
        tv_shape, tv_stride = RMSNormConfig._make_tv_layout(
            cfg.threads_per_row,
            cfg.rows_per_block,
            cfg.vec_size,
            cfg.num_vec_blocks,
        )
        tv_layout = cute.make_layout(tv_shape, stride=tv_stride)
        tiler_mn = (cfg.rows_per_block, cfg.cols_per_tile)

        self.kernel(mX, mW, mO, eps, tv_layout, tiler_mn).launch(
            grid=[cute.ceil_div(M, cfg.rows_per_block), cfg.cluster_n, 1],
            block=[cfg.num_threads, 1, 1],
            cluster=[1, cfg.cluster_n, 1] if cutlass.const_expr(cfg.cluster_n > 1) else None,
            smem=cfg.smem_size_in_bytes(),
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        mX: cute.Tensor,
        mW: cute.Tensor | None,
        mO: cute.Tensor,
        eps: Float32,
        tv_layout: cute.Layout,
        tiler_mn: cute.Shape,
    ):
        """Device kernel implementing RMSNorm with cluster support."""
        cfg = self.cfg
        tidx, _, _ = cute.arch.thread_idx()
        bidx, _, _ = cute.arch.block_idx()

        if cutlass.const_expr(cfg.cluster_n > 1):
            cluster_y = cute.arch.block_idx()[1]
        else:
            cluster_y = cutlass.const_expr(0)

        M = mX.shape[0]
        threads_per_row = tv_layout.shape[0][0]
        warps_per_row = max(threads_per_row // 32, 1)
        rows_per_block = tiler_mn[0]

        # =====================================================================
        # Allocate shared memory
        # =====================================================================
        smem = utils.SmemAllocator()

        sX = smem.allocate_tensor(
            mX.element_type,
            cute.make_ordered_layout(tiler_mn, order=(1, 0)),
            byte_alignment=16,
        )

        if cutlass.const_expr(cfg.cluster_n == 1):
            reduction_buffer = smem.allocate_tensor(
                Float32,
                cute.make_layout((rows_per_block, warps_per_row)),
                byte_alignment=4,
            )
            mbar_ptr = None
        else:
            reduction_buffer = smem.allocate_tensor(
                Float32,
                cute.make_layout((rows_per_block, (warps_per_row, cfg.cluster_n))),
                byte_alignment=4,
            )
            mbar_ptr = smem.allocate_array(Int64, num_elems=1)

        # =====================================================================
        # Initialize cluster
        # =====================================================================
        if cutlass.const_expr(cfg.cluster_n > 1):
            if tidx == 0:
                cute.arch.mbarrier_init(mbar_ptr, 1)
            cute.arch.mbarrier_init_fence()
            cute.arch.cluster_arrive_relaxed()
            cute.arch.cluster_wait()

        # =====================================================================
        # Create identity tensor and partition
        # =====================================================================
        idX = cute.make_identity_tensor(mX.shape)

        gX = cute.local_tile(mX, tiler_mn, (bidx, cluster_y))
        gO = cute.local_tile(mO, tiler_mn, (bidx, cluster_y))
        cX = cute.local_tile(idX, tiler_mn, (bidx, cluster_y))

        if cutlass.const_expr(cfg.has_weight and mW is not None):
            mW_expanded_layout = cute.prepend(
                mW.layout, cute.make_layout((tiler_mn[0],), stride=(0,))
            )
            mW_2d = cute.make_tensor(mW.iterator, mW_expanded_layout)
            gW = cute.local_tile(mW_2d, tiler_mn, (0, cluster_y))

        # =====================================================================
        # Create TiledCopy operations
        # =====================================================================
        copy_atom_load_async = cute.make_copy_atom(
            cute.nvgpu.cpasync.CopyG2SOp(),
            mX.element_type,
            num_bits_per_copy=RMSNormConfig.COPY_BITS,
        )

        copy_atom_load_W = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            mX.element_type,
            num_bits_per_copy=RMSNormConfig.COPY_BITS,
        )

        copy_atom_store = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(),
            mO.element_type,
            num_bits_per_copy=RMSNormConfig.COPY_BITS,
        )

        tiled_copy_load = cute.make_tiled_copy(copy_atom_load_async, tv_layout, tiler_mn)
        tiled_copy_W = cute.make_tiled_copy(copy_atom_load_W, tv_layout, tiler_mn)
        tiled_copy_store = cute.make_tiled_copy(copy_atom_store, tv_layout, tiler_mn)

        thr_copy_X = tiled_copy_load.get_slice(tidx)
        thr_copy_W = tiled_copy_W.get_slice(tidx)
        thr_copy_O = tiled_copy_store.get_slice(tidx)

        # Partition tensors
        tXgX = thr_copy_X.partition_S(gX)
        tXsX = thr_copy_X.partition_D(sX)
        tXgO = thr_copy_O.partition_D(gO)
        tXcX = thr_copy_X.partition_S(cX)

        # Register fragments
        tXrX = cute.make_fragment_like(tXgX)
        tXrO = cute.make_fragment_like(tXgO)

        if cutlass.const_expr(cfg.has_weight and mW is not None):
            tWgW = thr_copy_W.partition_S(gW)
            tWrW = cute.make_fragment_like(tWgW)
            tXrW = thr_copy_X.retile(tWrW)

        # =====================================================================
        # Bounds checking
        # =====================================================================
        tXpX = predicate_k(tXcX, limit=cfg.N)

        row_coord = tXcX[(0, 0), 0, 0]
        row_in_bounds = row_coord[0] < M

        # =====================================================================
        # Async copy global → shared
        # =====================================================================
        if row_in_bounds:
            cute.copy(copy_atom_load_async, tXgX, tXsX, pred=tXpX)

        cute.arch.cp_async_commit_group()

        # Load weight while waiting
        if cutlass.const_expr(cfg.has_weight and mW is not None):
            tWpW = predicate_k(thr_copy_W.partition_S(cX), limit=cfg.N)
            cute.copy(copy_atom_load_W, tWgW, tWrW, pred=tWpW)

        cute.arch.cp_async_wait_group(0)

        # =====================================================================
        # Pass 1: Compute sum of squares with cluster reduction
        # =====================================================================
        cute.autovec_copy(tXsX, tXrX)
        x = tXrX.load().to(Float32)

        x_sq = x * x
        sum_sq = row_reduce(
            x_sq,
            cute.ReductionOp.ADD,
            threads_per_row,
            reduction_buffer,
            mbar_ptr,
            cfg.cluster_n,
            Float32(0.0),
        )

        # rstd = 1 / sqrt(mean(x²) + eps)
        mean_sq = sum_sq / cfg.N
        rstd = cute.math.rsqrt(mean_sq + eps, fastmath=True)

        # Sync after reduction
        if cutlass.const_expr(cfg.cluster_n > 1):
            cute.arch.cluster_arrive_relaxed()
            cute.arch.cluster_wait()
        else:
            cute.arch.barrier()

        # =====================================================================
        # Pass 2: Normalize and output
        # =====================================================================
        cute.autovec_copy(tXsX, tXrX)
        x = tXrX.load().to(Float32)

        y = x * rstd

        # Apply weight if present
        if cutlass.const_expr(cfg.has_weight and mW is not None):
            w = tXrW.load().to(Float32)
            y = y * w

        # Store to global memory
        tXrO.store(y.to(cfg.dtype))

        if row_in_bounds:
            cute.copy(copy_atom_store, tXrO, tXgO, pred=tXpX)


# =============================================================================
# Kernel Compilation and Caching
# =============================================================================

# Mapping from torch dtype to cutlass dtype
_torch_to_cutlass_dtype = {
    torch.float16: cutlass.Float16,
    torch.bfloat16: cutlass.BFloat16,
    torch.float32: cutlass.Float32,
}

# Cache for compiled kernels
_compile_cache: dict = {}


def get_compiled_kernel(
    dtype: type[cutlass.Numeric],
    N: int,
    has_weight: bool,
    stream: cuda.CUstream,
):
    """
    Get or compile the RMSNorm kernel for the given configuration.

    Uses compilation cache to avoid recompiling for same (dtype, N, has_weight) tuples.

    :param dtype: Data type (Float16, BFloat16, Float32)
    :type dtype: type[cutlass.Numeric]
    :param N: Hidden dimension size
    :type N: int
    :param has_weight: Whether weight is applied
    :type has_weight: bool
    :param stream: CUDA stream
    :type stream: cuda.CUstream
    :return: Compiled kernel function
    """
    key = (dtype, N, has_weight)
    if key not in _compile_cache:
        kernel_obj = RMSNormKernel(dtype, N, has_weight)

        # Compile with representative arguments
        compiled_kernel = cute.compile(
            kernel_obj,
            make_ptr(dtype, 16, cute.AddressSpace.gmem, assumed_align=16),  # x_ptr
            make_ptr(dtype, 16, cute.AddressSpace.gmem, assumed_align=16)
            if has_weight
            else None,  # w_ptr
            make_ptr(dtype, 16, cute.AddressSpace.gmem, assumed_align=16),  # o_ptr
            Int32(1),  # M (dummy)
            Float32(1e-6),  # eps (dummy)
            stream,
        )

        _compile_cache[key] = compiled_kernel

    return _compile_cache[key]


# =============================================================================
# Tensor Creation Utilities
# =============================================================================


def create_tensors(
    M: int,
    N: int,
    dtype: type[cutlass.Numeric],
    has_weight: bool,
) -> Tuple:
    """Create input, weight, and output tensors for RMSNorm."""
    torch.manual_seed(42)
    torch_dtype = cutlass_torch.dtype(dtype)

    x = torch.randn(M, N, device="cuda", dtype=torch_dtype)
    weight = torch.randn(N, device="cuda", dtype=torch_dtype) if has_weight else None
    out = torch.empty_like(x)

    return x, weight, out


def rmsnorm_ref(
    x: torch.Tensor,
    weight: torch.Tensor | None = None,
    eps: float = 1e-6,
) -> torch.Tensor:
    """Reference RMSNorm implementation in PyTorch."""
    x_f32 = x.float()
    rms = torch.sqrt(torch.mean(x_f32**2, dim=-1, keepdim=True) + eps)
    x_norm = x_f32 / rms
    if weight is not None:
        x_norm = x_norm * weight.float()
    return x_norm.to(x.dtype)


# =============================================================================
# Run Function
# =============================================================================


def run(
    M: int,
    N: int,
    dtype: type[cutlass.Numeric],
    has_weight: bool = True,
    eps: float = 1e-6,
    tolerance: float = 1e-2,
    warmup_iterations: int = 2,
    iterations: int = 100,
    skip_ref_check: bool = False,
    benchmark: bool = False,
) -> float:
    """
    Execute RMSNorm and optionally benchmark performance.

    :param M: Number of rows (batch size * sequence length)
    :type M: int
    :param N: Hidden dimension size
    :type N: int
    :param dtype: Data type (Float16, BFloat16, Float32)
    :type dtype: type[cutlass.Numeric]
    :param has_weight: Whether to apply learnable weight
    :type has_weight: bool
    :param eps: Epsilon for numerical stability
    :type eps: float
    :param tolerance: Tolerance for correctness check
    :type tolerance: float
    :param warmup_iterations: Warmup iterations for benchmarking
    :type warmup_iterations: int
    :param iterations: Number of benchmark iterations
    :type iterations: int
    :param skip_ref_check: Skip reference correctness check
    :type skip_ref_check: bool
    :param benchmark: Enable benchmarking
    :type benchmark: bool
    :return: Execution time in microseconds (if benchmark=True, else 0)
    :rtype: float
    """
    print("Running RMSNorm test with:")
    print(f"  M: {M}, N: {N}")
    print(f"  dtype: {dtype}")
    print(f"  has_weight: {has_weight}")
    print(f"  eps: {eps}")
    print(f"  SM version: {get_sm_version()}")

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU is required to run this example!")

    # Get CUDA stream
    torch_stream = torch.cuda.current_stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    # Create tensors
    x, weight, out = create_tensors(M, N, dtype, has_weight)

    # Get configuration info
    config = RMSNormConfig(dtype, N, has_weight)
    print(f"  cluster_n: {config.cluster_n}")
    print(f"  threads_per_row: {config.threads_per_row}")
    print(f"  rows_per_block: {config.rows_per_block}")

    # Get compiled kernel
    compiled_kernel = get_compiled_kernel(dtype, N, has_weight, stream)

    # Create pointers for kernel call
    x_ptr = make_ptr(dtype, x.data_ptr())
    w_ptr = make_ptr(dtype, weight.data_ptr()) if weight is not None else None
    out_ptr = make_ptr(dtype, out.data_ptr())

    # Run kernel and verify
    if not skip_ref_check:
        compiled_kernel(x_ptr, w_ptr, out_ptr, Int32(M), Float32(eps), stream)
        torch.cuda.synchronize()

        ref = rmsnorm_ref(x, weight, eps)
        torch.testing.assert_close(out, ref, atol=tolerance, rtol=tolerance)
        print("Correctness check passed!")

    if not benchmark:
        return 0.0

    # Benchmark
    print(f"\nBenchmarking with {warmup_iterations} warmup, {iterations} iterations...")

    def generate_tensors():
        x, weight, out = create_tensors(M, N, dtype, has_weight)
        x_ptr = make_ptr(dtype, x.data_ptr())
        w_ptr = make_ptr(dtype, weight.data_ptr()) if weight is not None else None
        out_ptr = make_ptr(dtype, out.data_ptr())
        return testing.JitArguments(x_ptr, w_ptr, out_ptr, Int32(M), Float32(eps), stream)

    exec_time_us = testing.benchmark(
        compiled_kernel,
        workspace_generator=generate_tensors,
        workspace_count=10,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        stream=stream,
    )

    # Calculate throughput
    torch_dtype = cutlass_torch.dtype(dtype)
    bytes_per_elem = torch.tensor([], dtype=torch_dtype).element_size()
    total_bytes = M * N * bytes_per_elem * 2  # read x, write out
    if has_weight:
        total_bytes += N * bytes_per_elem  # read weight (amortized across M)

    throughput_gbps = (total_bytes / (exec_time_us / 1e6)) / 1e9

    print(f"Kernel execution time: {exec_time_us:.2f} us")
    print(f"Memory throughput: {throughput_gbps:.2f} GB/s")

    return exec_time_us


# =============================================================================
# Main Entry Point
# =============================================================================


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="RMSNorm kernel example for Blackwell (SM100)"
    )

    parser.add_argument("--M", type=int, default=2048, help="Number of rows")
    parser.add_argument("--N", type=int, default=4096, help="Hidden dimension size")
    parser.add_argument(
        "--dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        help="Data type (Float16, BFloat16, Float32)",
    )
    parser.add_argument(
        "--has_weight",
        action="store_true",
        default=True,
        help="Apply learnable weight",
    )
    parser.add_argument(
        "--no_weight",
        action="store_true",
        help="Disable learnable weight",
    )
    parser.add_argument(
        "--eps",
        type=float,
        default=1e-6,
        help="Epsilon for numerical stability",
    )
    parser.add_argument(
        "--tolerance",
        type=float,
        default=1e-2,
        help="Tolerance for correctness check",
    )
    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=2,
        help="Warmup iterations for benchmarking",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=100,
        help="Number of benchmark iterations",
    )
    parser.add_argument(
        "--skip_ref_check",
        action="store_true",
        help="Skip reference correctness check",
    )
    parser.add_argument(
        "--benchmark",
        action="store_true",
        help="Enable benchmarking",
    )

    args = parser.parse_args()

    # Handle weight flag
    has_weight = args.has_weight and not args.no_weight

    run(
        M=args.M,
        N=args.N,
        dtype=args.dtype,
        has_weight=has_weight,
        eps=args.eps,
        tolerance=args.tolerance,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        skip_ref_check=args.skip_ref_check,
        benchmark=args.benchmark,
    )

    print("PASS")

