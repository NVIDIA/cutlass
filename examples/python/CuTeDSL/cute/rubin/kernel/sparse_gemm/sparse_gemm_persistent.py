# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import os
import sys
import argparse
from typing import Tuple, Type

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.utils as utils
import cutlass.cute as cute
from cutlass import testing
import cutlass.torch as cutlass_torch
import cutlass.utils.rubin_helpers as sm107_utils

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    # Imported sibling kernels also need the CuTeDSL root to resolve helpers.
    sys.path.insert(0, os.path.join(current_dir, "../../../.."))
    sys.path.insert(0, os.path.join(current_dir, "../../.."))

from blackwell.kernel.sparse_gemm.sparse_gemm_persistent import (
    SparsePersistentGemmKernel as BlackwellSparsePersistentGemmKernel,
    compare,
    create_sparse_tensors,
)


class SM107SparsePersistentGemmKernel(BlackwellSparsePersistentGemmKernel):
    """Sparse GEMM kernel for Rubin (SM107).

    Extends `BlackwellSparsePersistentGemmKernel` with SM107-specific behavior and limits.
    Key differences for SM107:
    - Extended SMEM capacity: 334848 bytes (328 KB) vs 232448 bytes (228 KB)
    - Extended TMEM capacity: 576 columns (288 KB) vs 512 columns (256 KB)
    - K dimension: 32 for Float16/BFloat16, 64 for Float8E4M3FN/Float8E5M2
    """

    def __init__(
        self,
        acc_dtype: Type[cutlass.Numeric],
        use_2cta_instrs: bool,
        mma_tiler: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int],
        use_tma_store: bool,
    ):
        # Initialize parent with 2D tiler for base setup
        super().__init__(
            acc_dtype, use_2cta_instrs, mma_tiler[:2], cluster_shape_mn, use_tma_store
        )
        self.arch = "sm_107"
        self.mma_tiler = mma_tiler

    def _create_tiled_mma(self):
        """Create sparse tiled MMA instruction using helper from rubin_helpers."""
        return sm107_utils.make_sparse_trivial_tiled_mma(
            self.a_raw_dtype,
            self.a_major_mode,
            self.b_major_mode,
            self.acc_dtype,
            self.cta_group,
            mma_tiler=self.mma_tiler[:2],  # Pass only (M, N) for sparse
        )


def run(
    mnkl: Tuple[int, int, int, int],
    ab_dtype: Type[cutlass.Numeric],
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler: Tuple[int, int, int] = (256, 256, 32),
    cluster_shape_mn: Tuple[int, int] = (2, 1),
    use_2cta_instrs: bool = True,
    use_tma_store: bool = True,
    tolerance: float = 1e-01,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    benchmark: str = "default",
    init_normal: bool = False,
    normal_mean: float = 0.0,
    normal_std: float = 1.0,
    **kwargs,
):
    """Execute sparse GEMM with 2:4 structured sparsity on Rubin (SM107).

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param ab_dtype: Data type for input tensors A and B
    :type ab_dtype: Type[cutlass.Numeric]
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[cutlass.Numeric]
    :param acc_dtype: Data type for accumulation
    :type acc_dtype: Type[cutlass.Numeric]
    :param a_major/b_major/c_major: Memory layout of tensor A/B/C
    :type a_major/b_major/c_major: str
    :param mma_tiler: MMA tiling size (M, N, K) - K=32 for Float16/BFloat16, K=64 for FP8
    :type mma_tiler: Tuple[int, int, int], optional
    :param cluster_shape_mn: Cluster shape (M, N)
    :type cluster_shape_mn: Tuple[int, int], optional
    :param use_2cta_instrs: Whether to use 2-CTA instructions
    :type use_2cta_instrs: bool, optional
    :param use_tma_store: Whether to use TMA store
    :type use_tma_store: bool, optional
    :param tolerance: Tolerance for reference validation, defaults to 1e-01
    :type tolerance: float, optional
    :param warmup_iterations: Number of warmup iterations, defaults to 0
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations, defaults to 1
    :type iterations: int, optional
    :param skip_ref_check: Whether to skip reference validation, defaults to False
    :type skip_ref_check: bool, optional
    :raises RuntimeError: If CUDA GPU is not available
    :raises ValueError: If problem size is invalid for 2:4 structured sparsity or if the configuration is unsupported
    :return: Execution time of the sparse GEMM kernel in microseconds
    :rtype: float
    """
    print("Running Rubin (SM107) Sparse GEMM (2:4 Structured) with:")
    print(f"mnkl: {mnkl}")
    print(f"AB dtype: {ab_dtype}, C dtype: {c_dtype}, Acc dtype: {acc_dtype}")
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"Mma Tiler (M, N, K): {mma_tiler}, Cluster Shape (M, N): {cluster_shape_mn}")
    print(f"2CTA MMA: {use_2cta_instrs}, TMA Store: {use_tma_store}")
    print(f"Tolerance: {tolerance}")
    print(f"Warmup iterations: {warmup_iterations}")
    print(f"Iterations: {iterations}")
    print(f"Skip reference checking: {skip_ref_check}")

    m, n, k, l = mnkl

    if not torch.cuda.is_available():
        raise RuntimeError("GPU required!")

    torch_stream = torch.cuda.current_stream()
    current_stream = cuda.CUstream(torch_stream.cuda_stream)

    # Create sparse tensors (reuse from blackwell)
    (
        a_compressed_tensor,
        b_tensor,
        e_tensor,
        c_tensor,
        a_torch_cpu,
        b_torch_cpu,
        c_torch_cpu,
        c_torch_gpu,
        a_compressed_torch_cpu,
        e_torch_cpu,
    ) = create_sparse_tensors(
        l,
        m,
        n,
        k,
        a_major,
        b_major,
        c_major,
        ab_dtype,
        c_dtype,
    )

    # Apply normal initialization if requested
    # Note: For sparse tensors, we can only control B's initialization
    # A is already sparsified by create_sparse_tensors
    if init_normal:
        b_torch_cpu.normal_(mean=normal_mean, std=normal_std)

    # Build sparse GEMM for Rubin
    gemm = SM107SparsePersistentGemmKernel(
        acc_dtype, use_2cta_instrs, mma_tiler, cluster_shape_mn, use_tma_store
    )

    # Check if configuration can be implemented
    if not gemm.can_implement(a_compressed_tensor, b_tensor, e_tensor, c_tensor):
        raise testing.CantImplementError(
            f"The current config is invalid/unsupported: use_2cta_instrs = {use_2cta_instrs}, "
            f"mma_tiler = {mma_tiler}, cluster_shape_mn = {cluster_shape_mn}, "
            f"use_tma_store = {use_tma_store}, ab_dtype = {ab_dtype}, c_dtype = {c_dtype}, "
            f"acc_dtype = {acc_dtype}, mnkl = {mnkl}"
        )

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    try:
        compiled_gemm = cute.compile(
            gemm,
            a_compressed_tensor,
            b_tensor,
            e_tensor,
            c_tensor,
            max_active_clusters,
            current_stream,
        )
    except (ValueError, TypeError) as e:
        raise testing.CantImplementError(
            f"Compilation failed for sparse GEMM config: {e}"
        ) from e

    if not skip_ref_check:
        compiled_gemm(a_compressed_tensor, b_tensor, e_tensor, c_tensor, current_stream)
        # Verify result - compare against reference using A matrix with 2:4 sparsity
        compare(a_torch_cpu, b_torch_cpu, c_torch_gpu, c_dtype, tolerance)

    if benchmark == "none":
        return 0

    # Benchmark kernel performance
    def generate_tensors():
        """Generate fresh tensor arguments for benchmarking."""
        a_compressed_tensor_bench, _ = cutlass_torch.cute_tensor_like(
            a_compressed_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor_bench, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        e_tensor_bench, _ = cutlass_torch.cute_tensor_like(
            e_torch_cpu, cutlass.Uint8, is_dynamic_layout=True, assumed_align=16
        )
        c_tensor_bench, _ = cutlass_torch.cute_tensor_like(
            c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        c_tensor_bench.mark_compact_shape_dynamic(
            mode=1 if c_major == "n" else 0,
            stride_order=(2, 0, 1) if c_major == "n" else (2, 1, 0),
            divisibility=16,
        )
        return testing.JitArguments(
            a_compressed_tensor_bench,
            b_tensor_bench,
            e_tensor_bench,
            c_tensor_bench,
            current_stream,
        )

    workspace_count = 1

    exec_time = testing.benchmark(
        compiled_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cupti=benchmark == "cupti",
    )

    return exec_time  # Return execution time in microseconds


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Sparse GEMM with 2:4 Structured Sparsity for Rubin (SM107)"
    )

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        return tuple(int(x.strip()) for x in s.split(","))

    parser.add_argument(
        "--mnkl", type=parse_comma_separated_ints, default=(256, 256, 512, 1)
    )
    parser.add_argument(
        "--mma_tiler",
        type=parse_comma_separated_ints,
        default=(128, 128, 32),
        help="MMA tiler (M, N, K). K=32 for Float16/BFloat16, K=64 for FP8",
    )
    parser.add_argument(
        "--cluster_shape_mn", type=parse_comma_separated_ints, default=(1, 1)
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--use_2cta_instrs", action="store_true")
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument("--use_tma_store", action="store_true")
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations to run the kernel",
    )
    parser.add_argument("--skip_ref_check", action="store_true")
    parser.add_argument(
        "--benchmark",
        type=str,
        default="default",
        choices=["cupti", "default", "none"],
        help="Benchmark the kernel with cupti or default (cutlass.testing.benchmark) or none",
    )
    parser.add_argument(
        "--init_normal",
        action="store_true",
        help="Use normal distribution for tensor initialization instead of random integers",
    )
    parser.add_argument(
        "--normal_mean",
        type=float,
        default=0.0,
        help="Mean for normal distribution initialization",
    )
    parser.add_argument(
        "--normal_std",
        type=float,
        default=1.0,
        help="Standard deviation for normal distribution initialization",
    )

    args = parser.parse_args()

    run(
        args.mnkl,
        args.ab_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.mma_tiler,
        args.cluster_shape_mn,
        args.use_2cta_instrs,
        args.use_tma_store,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.benchmark,
        args.init_normal,
        args.normal_mean,
        args.normal_std,
    )
    print("PASS")
